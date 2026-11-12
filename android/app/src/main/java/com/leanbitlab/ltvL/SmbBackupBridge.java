package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import com.hierynomus.msdtyp.AccessMask;
import com.hierynomus.msfscc.FileAttributes;
import com.hierynomus.msfscc.fileinformation.FileStandardInformation;
import com.hierynomus.mssmb2.*;
import com.hierynomus.protocol.commons.socket.ProxySocketFactory;
import com.hierynomus.smbj.SMBClient;
import com.hierynomus.smbj.SmbConfig;
import com.hierynomus.smbj.auth.AuthenticationContext;
import com.hierynomus.smbj.auth.NtlmAuthenticator;
import com.hierynomus.smbj.share.DiskShare;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;
import java.util.concurrent.*;
import org.json.JSONObject;

/** Bounded native SMB I/O; credentials never leave the encrypted native account store. */
final class SmbBackupBridge {
    private static final ExecutorService IO = Executors.newFixedThreadPool(2);
    private static final ScheduledExecutorService DEADLINES = Executors.newSingleThreadScheduledExecutor();
    private static final Map<String, Job> JOBS = new ConcurrentHashMap<>();
    private static final Map<String, java.util.concurrent.atomic.AtomicLong> REVISIONS = new ConcurrentHashMap<>();
    private static final Map<String, Object> PROFILE_LOCKS = new ConcurrentHashMap<>();
    private static final Set<SMB2CreateOptions> FILE_OPTIONS = EnumSet.of(SMB2CreateOptions.FILE_NON_DIRECTORY_FILE, SMB2CreateOptions.FILE_OPEN_REPARSE_POINT);
    private static final Set<SMB2ShareAccess> SHARING = EnumSet.of(SMB2ShareAccess.FILE_SHARE_READ);
    static final class Job {
        volatile boolean cancelled, expired;
        long revision;
        volatile Socket socket;
        void check() throws IOException { if (cancelled) throw new IOException("cancelled"); }
        synchronized void cancel(boolean timeout) {
            cancelled = true; expired |= timeout;
            try { if (socket != null) socket.close(); } catch (IOException ignored) { }
        }
    }
    static SmbConfig config(Job job, SmbBackupPolicy target) {
        return SmbConfig.builder()
            .withDialects(SMB2Dialect.SMB_2_0_2, SMB2Dialect.SMB_2_1,
                SMB2Dialect.SMB_3_0, SMB2Dialect.SMB_3_0_2, SMB2Dialect.SMB_3_1_1)
            .withAuthenticators(new NtlmAuthenticator.Factory())
            .withSigningRequired(true).withDfsEnabled(false)
            .withTimeout(20, TimeUnit.SECONDS).withSoTimeout(20, TimeUnit.SECONDS)
            .withReadBufferSize(64 * 1024).withWriteBufferSize(64 * 1024)
            .withSocketFactory(new ProxySocketFactory(8000) {
                @Override public Socket createSocket(String host, int port) throws IOException {
                    if (!host.equalsIgnoreCase(target.host) || port != target.port) throw new Failure("unsupported");
                    job.check();
                    Socket socket = new Socket();
                    job.socket = socket;
                    job.check();
                    socket.connect(new InetSocketAddress(host, port), 8000);
                    job.check();
                    return socket;
                }
            }).build();
    }
    static void register(Context context, BinaryMessenger messenger) {
        Context app = context.getApplicationContext();
        Handler main = new Handler(Looper.getMainLooper());
        new MethodChannel(messenger, "cutelauncher/smb_backup").setMethodCallHandler((call, result) -> {
            String id = call.argument("operationId");
            if (id == null || !id.matches("[a-f0-9]{32}")) { result.error("configuration", "Invalid operation", null); return; }
            if (call.method.equals("cancel")) {
                Job job = JOBS.get(id); if (job != null) job.cancel(false);
                result.success(true); return;
            }
            if (!Set.of("info", "identity", "connect", "disconnect", "check", "list", "listTemporary", "upload", "download", "delete", "deleteTemporary").contains(call.method)) {
                result.notImplemented(); return;
            }
            final String profile;
            try { profile = BackupAccountProfile.id(call.argument("profile")); }
            catch (Exception error) { result.error("configuration", "Invalid profile", null); return; }
            Job job = new Job();
            if (JOBS.size() >= 4 || JOBS.putIfAbsent(id, job) != null) { result.error("busy", "Operation busy", null); return; }
            var revision = REVISIONS.computeIfAbsent(profile, ignored -> new java.util.concurrent.atomic.AtomicLong());
            if (call.method.equals("connect") || call.method.equals("disconnect")) job.revision = revision.incrementAndGet();
            ScheduledFuture<?> deadline = DEADLINES.schedule(() -> job.cancel(true), 90, TimeUnit.SECONDS);
            IO.execute(() -> {
                try {
                    Object value = run(app, call, profile, job);
                    job.check();
                    main.post(() -> result.success(value));
                } catch (Exception error) {
                    String code = job.expired ? "timeout" : job.cancelled ? "cancelled" : errorCode(error);
                    // SMB exceptions may contain server paths or account names. Do not export them.
                    main.post(() -> result.error(code, "SMB operation failed", null));
                } finally {
                    deadline.cancel(false); job.cancel(false); JOBS.remove(id, job);
                }
            });
        });
    }
    static final class Failure extends IOException {
        final String code; Failure(String code) { super(code); this.code = code; }
    }
    static String errorCode(Exception error) {
        if (error instanceof Failure failure) return failure.code;
        if (error instanceof IllegalArgumentException || error instanceof URISyntaxException) return "configuration";
        if (error instanceof SMBApiException smb) {
            return switch (smb.getStatus()) {
                case STATUS_ACCESS_DENIED, STATUS_LOGON_FAILURE, STATUS_ACCOUNT_DISABLED -> "authorization";
                case STATUS_OBJECT_NAME_NOT_FOUND, STATUS_OBJECT_PATH_NOT_FOUND, STATUS_BAD_NETWORK_NAME -> "missing";
                case STATUS_OBJECT_NAME_COLLISION, STATUS_SHARING_VIOLATION -> "conflict";
                default -> "server";
            };
        }
        if (error instanceof SocketTimeoutException || error instanceof TimeoutException) return "timeout";
        if (error instanceof SecurityException) return "storage";
        return "network";
    }
    static void requireAuthenticated(boolean guest, boolean anonymous) throws Failure {
        if (guest || anonymous) throw new Failure("authorization");
    }
    private static String identity(JSONObject account) throws Exception {
        if (account == null) return "";
        return java.util.Base64.getEncoder().encodeToString(MessageDigest.getInstance("SHA-256")
            .digest((account.getString("user") + "\n" + account.getString("password")).getBytes(StandardCharsets.UTF_8)));
    }
    private static Object run(Context app, MethodCall call, String profile, Job job) throws Exception {
        job.check();
        CloudAccountStore store = BackupAccountProfile.store(app, "smb", profile);
        Object lock = PROFILE_LOCKS.computeIfAbsent(profile, ignored -> new Object());
        if (call.method.equals("disconnect")) {
            synchronized (lock) { job.check();
                if (job.revision != REVISIONS.get(profile).get()) throw new SecurityException();
                store.disconnect(); }
            return true;
        }
        JSONObject account;
        synchronized (lock) { account = store.snapshot(); }
        if (call.method.equals("identity")) return identity(account);
        if (call.method.equals("info")) {
            if (account == null) return Map.of("configured", false, "url", "", "user", "");
            JSONObject payload = new JSONObject(account.getString("password"));
            return Map.of("configured", true, "url", payload.getString("url"), "user", account.getString("user"));
        }
        boolean connecting = call.method.equals("connect");
        String user, password, url;
        String previous = identity(account);
        if (connecting) {
            user = call.argument("user"); password = call.argument("password"); url = call.argument("url");
            CloudAccountStore.validate(user, password);
        } else {
            String expected = call.argument("identity");
            if (account == null || expected == null || !expected.equals(previous)) throw new SecurityException();
            JSONObject payload = new JSONObject(account.getString("password"));
            user = account.getString("user"); password = payload.getString("password"); url = payload.getString("url");
        }
        SmbBackupPolicy target = new SmbBackupPolicy(url);
        int split = user.indexOf('\\');
        String domain = split < 0 ? "" : user.substring(0, split);
        String login = split < 0 ? user : user.substring(split + 1);
        if (login.isEmpty() || login.contains("\\")) throw new IllegalArgumentException();
        char[] secret = password.toCharArray();
        try (SMBClient client = new SMBClient(config(job, target));
             var connection = client.connect(target.host, target.port);
             var session = connection.authenticate(new AuthenticationContext(login, secret, domain))) {
            requireAuthenticated(session.isGuest(), session.isAnonymous());
            try (var resource = session.connectShare(target.share)) {
            job.check();
            if (!(resource instanceof DiskShare share)) throw new IllegalArgumentException();
            if (connecting || call.method.equals("check") || call.method.equals("list") || call.method.equals("listTemporary")) {
                try (var directory = share.openDirectory(target.folder, EnumSet.of(AccessMask.FILE_LIST_DIRECTORY),
                        EnumSet.noneOf(FileAttributes.class), EnumSet.allOf(SMB2ShareAccess.class), SMB2CreateDisposition.FILE_OPEN,
                        EnumSet.of(SMB2CreateOptions.FILE_DIRECTORY_FILE))) {
                    if (call.method.equals("check")) return true;
                    if (connecting) {
                        synchronized (lock) { synchronized (job) {
                            job.check();
                            if (job.revision != REVISIONS.get(profile).get()) throw new SecurityException();
                            if (!identity(store.snapshot()).equals(previous)) throw new SecurityException();
                            store.save("https://smb.invalid/", user, new JSONObject().put("url", target.url).put("password", password).toString());
                        } }
                        return true;
                    }
                    var files = new ArrayList<Map<String, String>>(); int count = 0;
                    boolean temporary = call.method.equals("listTemporary");
                    for (var entry : directory) {
                        job.check();
                        if (++count > 4096) throw new Failure("size");
                        if ((entry.getFileAttributes() & (0x10 | 0x400)) != 0) continue;
                        String name = entry.getFileName();
                        if (SmbBackupPolicy.validName(name, temporary)) files.add(Map.of("name", name, "id", name));
                    }
                    return files;
                }
            }
            String name = call.argument("name");
            boolean temporary = call.method.equals("deleteTemporary");
            String remote = target.path(name, temporary);
            switch (call.method) {
                case "upload" -> {
                    java.io.File source = localFile(app, call.argument("path"));
                    long size = source.length();
                    if (size == 0 || size > SmbBackupPolicy.MAX_BYTES) throw new IllegalArgumentException();
                    String pending = target.path(name + ".partial", true);
                    try (var file = share.openFile(pending, EnumSet.of(AccessMask.GENERIC_WRITE, AccessMask.DELETE),
                            EnumSet.of(FileAttributes.FILE_ATTRIBUTE_NORMAL), SHARING, SMB2CreateDisposition.FILE_CREATE, FILE_OPTIONS)) {
                        boolean published = false;
                        try (InputStream input = new FileInputStream(source)) {
                            byte[] buffer = new byte[65536]; long offset = 0; int count;
                            while ((count = input.read(buffer)) != -1) {
                                job.check();
                                if (offset + count > SmbBackupPolicy.MAX_BYTES) throw new Failure("size");
                                long written = file.write(buffer, offset, 0, count);
                                if (written != count) throw new Failure("file");
                                offset += written;
                            }
                            if (offset != size) throw new Failure("size");
                            file.flush(); job.check(); file.rename(remote, false); published = true;
                        } finally { if (!published) try { file.deleteOnClose(); } catch (Exception ignored) { } }
                    }
                }
                case "download" -> {
                    java.io.File pending = localFile(app, call.argument("path"));
                    boolean complete = false;
                    try (var file = share.openFile(remote, EnumSet.of(AccessMask.GENERIC_READ),
                            EnumSet.noneOf(FileAttributes.class), SHARING, SMB2CreateDisposition.FILE_OPEN, FILE_OPTIONS)) {
                        long size = file.getFileInformation(FileStandardInformation.class).getEndOfFile();
                        if (size == 0 || size > SmbBackupPolicy.MAX_BYTES) throw new Failure("size");
                        try (OutputStream output = new FileOutputStream(pending)) {
                            byte[] buffer = new byte[65536]; long offset = 0; int count;
                            while ((count = file.read(buffer, offset)) != -1) {
                                job.check();
                                if (count == 0 || offset + count > size) throw new Failure("size");
                                output.write(buffer, 0, count); offset += count;
                            }
                            if (offset != size) throw new Failure("size");
                            output.flush(); job.check(); complete = true;
                        }
                    } finally { if (!complete) pending.delete(); }
                }
                case "delete", "deleteTemporary" -> {
                    try (var file = share.openFile(remote, EnumSet.of(AccessMask.DELETE),
                            EnumSet.noneOf(FileAttributes.class), SHARING, SMB2CreateDisposition.FILE_OPEN, FILE_OPTIONS)) {
                        job.check(); file.deleteOnClose();
                    }
                }
                default -> throw new IllegalArgumentException();
            }
            return true;
            }
        } finally { Arrays.fill(secret, '\0'); }
    }
    static java.io.File localFile(Context app, String path) throws IOException {
        if (path == null) throw new IllegalArgumentException();
        java.io.File file = new java.io.File(path).getCanonicalFile();
        for (java.io.File root : List.of(app.getCacheDir(), new java.io.File(app.getDataDir(), "app_flutter"))) {
            if (file.toPath().startsWith(root.getCanonicalFile().toPath()) && !file.equals(root.getCanonicalFile())) return file;
        }
        throw new SecurityException();
    }
}

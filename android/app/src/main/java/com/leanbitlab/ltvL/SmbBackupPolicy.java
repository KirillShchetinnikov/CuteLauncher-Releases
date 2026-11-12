package com.leanbitlab.ltvL;

import java.net.URI;
import java.util.ArrayList;
import java.util.regex.Pattern;

/** Strict share-relative paths. No credentials, traversal or alternate streams in URLs. */
final class SmbBackupPolicy {
    static final long MAX_BYTES = 64L * 1024 * 1024;
    static final Pattern NAME = Pattern.compile("^cute-(backup|sync)-(shared|[a-f0-9]{32})-[a-f0-9]{32}-[0-9]{1,16}-[a-f0-9]{16}(?:-[A-Za-z0-9_]{1,64})?\\.json$");
    final String url, host, share, folder;
    final int port;
    SmbBackupPolicy(String value) throws Exception {
        if (value == null || value.length() > 2048 || value.chars().anyMatch(c -> c < 32 || c == 127)) throw new IllegalArgumentException();
        URI uri = new URI(value.replace(" ", "%20"));
        if (!"smb".equals(uri.getScheme()) || uri.getHost() == null || uri.getUserInfo() != null
            || uri.getRawQuery() != null || uri.getRawFragment() != null || uri.getPort() == 0 || uri.getPort() > 65535) throw new IllegalArgumentException();
        host = uri.getHost().replace("[", "").replace("]", "");
        port = uri.getPort() < 0 ? 445 : uri.getPort();
        String path = uri.getRawPath();
        if (path == null || !path.startsWith("/")) throw new IllegalArgumentException();
        String[] raw = path.substring(1).split("/", -1);
        var parts = new ArrayList<String>();
        for (int i = 0; i < raw.length; i++) {
            if (i == raw.length - 1 && raw[i].isEmpty() && !parts.isEmpty()) break;
            String part = new URI("x:///" + raw[i]).getPath().substring(1);
            if (part.isEmpty() || part.equals(".") || part.equals("..") || part.endsWith(".") || part.endsWith(" ")
                || part.length() > 255 || part.chars().anyMatch(c -> c < 32 || c == 127 || "\\/:*?\"<>|".indexOf(c) >= 0)) throw new IllegalArgumentException();
            parts.add(part);
        }
        if (parts.isEmpty()) throw new IllegalArgumentException();
        share = parts.remove(0);
        folder = String.join("\\", parts);
        url = uri.toASCIIString();
    }
    static boolean validName(String name, boolean temporary) {
        if (name == null) return false;
        if (temporary) return name.endsWith(".partial") && NAME.matcher(name.substring(0, name.length() - 8)).matches();
        return NAME.matcher(name).matches();
    }
    String path(String name, boolean temporary) {
        if (!validName(name, temporary)) throw new IllegalArgumentException();
        return folder.isEmpty() ? name : folder + "\\" + name;
    }
}

package io.cutelauncher.fixture.documents;

import android.app.Activity;
import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Intent;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import android.provider.OpenableColumns;
import android.provider.DocumentsContract;
import android.provider.DocumentsProvider;
import android.widget.Button;
import android.widget.LinearLayout;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;

/** Test-only picker/provider APK. Install exclusively on an isolated emulator. */
public class DocumentsFixture extends Activity {
    private static final String AUTHORITY = "io.cutelauncher.fixture.documents";
    public static class OpenDocument extends DocumentsFixture { }
    public static class GetContent extends DocumentsFixture { }
    public static class CreateDocument extends DocumentsFixture { }
    public static class OpenTree extends DocumentsFixture { }
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        if (getIntent().getBooleanExtra("delete_source", false)) {
            new File(getFilesDir(), "valid.png").delete(); finish(); return;
        }
        LinearLayout layout = new LinearLayout(this); layout.setOrientation(LinearLayout.VERTICAL);
        if (Intent.ACTION_OPEN_DOCUMENT_TREE.equals(getIntent().getAction())) {
            add(layout, "Choose fixture folder", () -> {
                setResult(RESULT_OK, new Intent().setData(DocumentsContract.buildTreeDocumentUri(AUTHORITY, "root"))
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION));
                finish();
            });
            add(layout, "Choose backup folder", () -> {
                setResult(RESULT_OK, new Intent().setData(DocumentsContract.buildTreeDocumentUri(AUTHORITY + ".backups", "root"))
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION | Intent.FLAG_GRANT_PREFIX_URI_PERMISSION));
                finish();
            });
            add(layout, "Cancel", () -> { setResult(RESULT_CANCELED); finish(); });
            setContentView(layout); return;
        }
        String mime = getIntent().getType();
        String path = mime != null && !mime.startsWith("image/") ? "backup.json" : "valid.png";
        add(layout, "Valid document", () -> choose(path));
        add(layout, "Corrupt document", () -> choose("corrupt.png"));
        add(layout, "Provider error", () -> choose("failure"));
        add(layout, "Cancel", () -> { setResult(RESULT_CANCELED); finish(); });
        setContentView(layout);
    }
    private void add(LinearLayout layout, String label, Runnable action) {
        Button button = new Button(this); button.setText(label); button.setOnClickListener(v -> action.run());
        layout.addView(button);
    }
    private void choose(String path) {
        setResult(RESULT_OK, new Intent().setData(Uri.parse("content://" + AUTHORITY + "/" + path))
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION));
        finish();
    }
    public static class Backups extends DocumentsProvider {
        @Override public boolean onCreate() { return true; }
        private File folder() { File f = new File(getContext().getFilesDir(), "backups"); f.mkdirs(); return f; }
        private File doc(String id) throws FileNotFoundException {
            if ("root".equals(id)) return folder();
            if (!id.matches("[A-Za-z0-9_.-]+")) throw new FileNotFoundException("Name");
            return new File(folder(), id);
        }
        @Override public Cursor queryRoots(String[] p) {
            MatrixCursor c = new MatrixCursor(new String[]{DocumentsContract.Root.COLUMN_ROOT_ID, DocumentsContract.Root.COLUMN_DOCUMENT_ID,
                DocumentsContract.Root.COLUMN_TITLE, DocumentsContract.Root.COLUMN_FLAGS});
            c.addRow(new Object[]{"root", "root", "Backup fixture", DocumentsContract.Root.FLAG_SUPPORTS_CREATE}); return c;
        }
        private MatrixCursor cursor() { return new MatrixCursor(new String[]{DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE, DocumentsContract.Document.COLUMN_FLAGS}); }
        private void row(MatrixCursor c, String id) throws FileNotFoundException {
            File f = doc(id);
            c.addRow(new Object[]{id, id, f.isDirectory() ? DocumentsContract.Document.MIME_TYPE_DIR : "application/json", f.length(),
                f.isDirectory() ? DocumentsContract.Document.FLAG_DIR_SUPPORTS_CREATE : DocumentsContract.Document.FLAG_SUPPORTS_WRITE
                    | DocumentsContract.Document.FLAG_SUPPORTS_DELETE | DocumentsContract.Document.FLAG_SUPPORTS_RENAME});
        }
        @Override public Cursor queryDocument(String id, String[] p) throws FileNotFoundException { MatrixCursor c = cursor(); row(c, id); return c; }
        @Override public Cursor queryChildDocuments(String id, String[] p, String sort) throws FileNotFoundException {
            MatrixCursor c = cursor(); File[] fs = doc(id).listFiles(); if (fs != null) for (File f : fs) row(c, f.getName()); return c;
        }
        @Override public ParcelFileDescriptor openDocument(String id, String mode, android.os.CancellationSignal signal) throws FileNotFoundException {
            return ParcelFileDescriptor.open(doc(id), ParcelFileDescriptor.parseMode(mode));
        }
        @Override public String createDocument(String parent, String mime, String name) throws FileNotFoundException {
            if (!"root".equals(parent)) throw new FileNotFoundException();
            try { if (!doc(name).createNewFile()) throw new FileNotFoundException("Exists"); }
            catch (java.io.IOException e) { throw new FileNotFoundException(e.toString()); } return name;
        }
        @Override public String renameDocument(String id, String name) throws FileNotFoundException {
            if (!doc(id).renameTo(doc(name))) throw new FileNotFoundException("Rename"); return name;
        }
        @Override public void deleteDocument(String id) throws FileNotFoundException {
            if ("root".equals(id) || !doc(id).delete()) throw new FileNotFoundException("Delete");
        }
        @Override public boolean isChildDocument(String parent, String child) { return "root".equals(parent) && !"root".equals(child); }
    }
    public static class Provider extends ContentProvider {
        @Override public boolean onCreate() {
            try {
                Bitmap image = Bitmap.createBitmap(640, 360, Bitmap.Config.ARGB_8888);
                image.eraseColor(Color.rgb(25, 75, 125));
                try (FileOutputStream stream = new FileOutputStream(new File(getContext().getFilesDir(), "valid.png"))) {
                    image.compress(Bitmap.CompressFormat.PNG, 100, stream);
                } finally { image.recycle(); }
                try (FileOutputStream stream = new FileOutputStream(new File(getContext().getFilesDir(), "corrupt.png"))) {
                    stream.write(new byte[]{1, 2, 3, 4});
                }
                return true;
            } catch (Exception failure) { throw new IllegalStateException(failure); }
        }
        private File file(Uri uri) throws FileNotFoundException {
            String name = uri.getLastPathSegment();
            if ("nested.png".equals(name)) name = "valid.png";
            if (!"valid.png".equals(name) && !"corrupt.png".equals(name) && !"backup.json".equals(name))
                throw new FileNotFoundException("Injected provider failure");
            return new File(getContext().getFilesDir(), name);
        }
        @Override public ParcelFileDescriptor openFile(Uri uri, String mode) throws FileNotFoundException {
            return ParcelFileDescriptor.open(file(uri), mode.contains("w")
                ? ParcelFileDescriptor.MODE_READ_WRITE | ParcelFileDescriptor.MODE_CREATE | ParcelFileDescriptor.MODE_TRUNCATE
                : ParcelFileDescriptor.MODE_READ_ONLY);
        }
        @Override public Cursor query(Uri uri, String[] projection, String selection, String[] args, String order) {
            if (uri.getPath().endsWith("/children")) {
                MatrixCursor tree = new MatrixCursor(new String[]{DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_MIME_TYPE});
                if (uri.getPath().contains("/document/sub/")) {
                    tree.addRow(new Object[]{"nested.png", "image/png"});
                } else {
                    tree.addRow(new Object[]{"valid.png", "image/png"});
                    tree.addRow(new Object[]{"corrupt.png", "image/png"});
                    tree.addRow(new Object[]{"sub", DocumentsContract.Document.MIME_TYPE_DIR});
                }
                return tree;
            }
            MatrixCursor cursor = new MatrixCursor(new String[]{OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE});
            try { File f = file(uri); cursor.addRow(new Object[]{f.getName(), f.length()}); }
            catch (FileNotFoundException ignored) { }
            return cursor;
        }
        @Override public String getType(Uri uri) { return uri.getPath().endsWith(".json") ? "application/json" : "image/png"; }
        @Override public Uri insert(Uri uri, ContentValues values) { throw new UnsupportedOperationException(); }
        @Override public int update(Uri uri, ContentValues values, String selection, String[] args) { throw new UnsupportedOperationException(); }
        @Override public int delete(Uri uri, String selection, String[] args) { throw new UnsupportedOperationException(); }
    }
}

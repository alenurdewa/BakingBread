package com.bakingbread.util;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import javax.servlet.ServletContext;
import javax.servlet.http.Part;

public final class FileStore {
    private FileStore() {}

    public static String savePart(Part part, ServletContext context, String folderName, String prefix) throws IOException {
        if (part == null || part.getSize() <= 0) {
            return null;
        }

        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.trim().isEmpty()) {
            return null;
        }

        String sanitized = submitted.replaceAll("[\\/]+", "_").replaceAll("[^a-zA-Z0-9._-]", "_");
        String storedName = prefix + "_" + System.currentTimeMillis() + "_" + sanitized;

        String uploadBase = context.getRealPath("/uploads");
        if (uploadBase == null) {
            uploadBase = context.getRealPath("/");
        }
        if (uploadBase == null) {
            throw new IOException("Impossibile risolvere il percorso degli upload.");
        }

        File targetDir = new File(uploadBase, folderName);
        if (!targetDir.exists() && !targetDir.mkdirs()) {
            throw new IOException("Impossibile creare la cartella upload: " + targetDir.getAbsolutePath());
        }

        File targetFile = new File(targetDir, storedName);
        try (InputStream in = part.getInputStream(); FileOutputStream out = new FileOutputStream(targetFile)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }

        return "/uploads/" + folderName + "/" + storedName;
    }
}

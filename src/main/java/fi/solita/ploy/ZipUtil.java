// Copyright © 2012-2013 Solita Oy <www.solita.fi>
// This software is released under the MIT License.
// The license text is at http://opensource.org/licenses/MIT

package fi.solita.ploy;

import java.io.IOException;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.*;

import static java.nio.file.StandardCopyOption.COPY_ATTRIBUTES;

public class ZipUtil {

    public static List<String> list(String zipFile) throws IOException {
        final List<String> results = new ArrayList<>();
        try (FileSystem fs = openZip(zipFile)) {
            for (final Path root : fs.getRootDirectories()) {
                Files.walkFileTree(root, new SimpleFileVisitor<Path>() {
                    @Override
                    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
                        results.add(root.relativize(file).toString());
                        return FileVisitResult.CONTINUE;
                    }
                });
            }
        } catch (Throwable t) {
            t.printStackTrace();
            throw t;
        }
        return results;
    }

    public static void add(String zipFile, String file, String targetDir) throws IOException {
        try (FileSystem fs = openZip(zipFile)) {
            Path source = Paths.get(file);
            Files.walkFileTree(source, new CopyRecursively(source, fs.getPath(targetDir)));
        } catch (Throwable t) {
            t.printStackTrace();
            throw t;
        }
    }

    public static void unzip(String zipFile, String targetDir) throws IOException {
        final Path target = Paths.get(targetDir).toRealPath();
        try (FileSystem fs = openZip(zipFile)) {
            for (final Path root : fs.getRootDirectories()) {
                Files.walkFileTree(root, new CopyRecursively(root, target));
            }
        } catch (Throwable t) {
            t.printStackTrace();
            throw t;
        }
    }

    private static FileSystem openZip(String zipFile) throws IOException {
        return FileSystems.newFileSystem(Paths.get(zipFile), null);
    }


    private static class CopyRecursively extends SimpleFileVisitor<Path> {
        private final Path sourceDir;
        private final Path targetDir;

        public CopyRecursively(Path sourceDir, Path targetDir) {
            if (!Files.isDirectory(sourceDir)) {
                sourceDir = sourceDir.getParent();
            }
            this.targetDir = targetDir;
            this.sourceDir = sourceDir;
        }

        @Override
        public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
            Files.createDirectories(targetDir.resolve(sourceDir.relativize(dir).toString()));
            return FileVisitResult.CONTINUE;
        }

        @Override
        public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
            Path targetFile = targetDir.resolve(sourceDir.relativize(file).toString());
            Files.createDirectories(targetFile.getParent());
            Files.copy(file, targetFile, COPY_ATTRIBUTES);
            return FileVisitResult.CONTINUE;
        }
    }
}

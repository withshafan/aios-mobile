import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {
  /// Request storage permissions
  Future<bool> requestPermissions() async {
    if (await Permission.storage.request().isGranted) return true;
    if (await Permission.manageExternalStorage.request().isGranted) return true;
    return false;
  }

  /// Get the downloads directory path (or fallback to app documents)
  Future<Directory> getBaseDirectory() async {
    // First try the external downloads directory
    final dir = Directory('/storage/emulated/0/Download');
    if (await dir.exists()) return dir;
    // Fallback to app's document directory
    return await getApplicationDocumentsDirectory();
  }

  /// List files and folders in a given directory
  Future<List<FileSystemEntity>> listFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    return dir.listSync();
  }

  /// Read a text file
  Future<String> readFile(String path) async {
    final file = File(path);
    return await file.readAsString();
  }

  /// Create a new text file
  Future<void> createFile(String parentPath, String fileName, String content) async {
    final file = File('$parentPath/$fileName');
    await file.writeAsString(content);
  }

  /// Delete a file or empty directory
  Future<void> deleteEntity(String path) async {
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.file) {
      await File(path).delete();
    } else if (entity == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    }
  }
}

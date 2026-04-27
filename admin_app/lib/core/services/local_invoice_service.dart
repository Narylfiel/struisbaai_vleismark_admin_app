import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalInvoiceFile {
  final String filename;
  final Uint8List bytes;
  final int size;
  final DateTime lastModified;

  const LocalInvoiceFile({
    required this.filename,
    required this.bytes,
    required this.size,
    required this.lastModified,
  });
}

class LocalInvoiceService {
  static const _keyProcessedFiles = 'local_processed_invoice_files';
  static const _keyFolderPath = 'invoice_local_folder_path';

  Future<String?> getFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFolderPath);
  }

  Future<void> setFolderPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFolderPath, path);
  }

  Future<List<Map<String, dynamic>>> _getProcessed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProcessedFiles);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        jsonDecode(raw) as List,
      );
    } catch (_) {
      return [];
    }
  }

  Future<bool> isProcessed(String filename, int size) async {
    final list = await _getProcessed();
    return list.any(
      (e) => e['filename'] == filename && e['size'] == size,
    );
  }

  Future<void> markProcessed(String filename, int size) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getProcessed();
    list.add({'filename': filename, 'size': size});
    await prefs.setString(_keyProcessedFiles, jsonEncode(list));
  }

  Future<void> clearProcessed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProcessedFiles);
  }

  Future<List<LocalInvoiceFile>> scanForInvoices() async {
    final path = await getFolderPath();
    if (path == null || path.isEmpty) return [];

    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final results = <LocalInvoiceFile>[];

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last.toLowerCase();
      if (!name.endsWith('.pdf')) continue;

      final stat = await entity.stat();
      final size = stat.size;
      final filename = entity.uri.pathSegments.last;

      final alreadyDone = await isProcessed(filename, size);
      if (alreadyDone) continue;

      final bytes = await entity.readAsBytes();
      results.add(LocalInvoiceFile(
        filename: filename,
        bytes: bytes,
        size: size,
        lastModified: stat.modified,
      ));
    }

    return results;
  }
}

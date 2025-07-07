import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class FileService {
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;
    
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      
      // For Android 11+ (API 30+), also request MANAGE_EXTERNAL_STORAGE
      if (status.isGranted) {
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        return manageStatus.isGranted;
      }
      return status.isGranted;
    }
    
    return true; // iOS doesn't need explicit permission for app documents
  }

  static Future<String> getDownloadPath() async {
    if (kIsWeb) {
      throw UnsupportedError('Web platform should use different download method');
    }
    
    if (Platform.isAndroid) {
      // Try to get external storage directory
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Create Downloads folder if it doesn't exist
          final downloadsDir = Directory('${directory.path}/Downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir.path;
        }
      } catch (e) {
        print('Error accessing external storage: $e');
      }
      
      // Fallback to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
    
    throw UnsupportedError('Platform not supported');
  }

  static Future<bool> saveExcelFile(Uint8List fileBytes, String fileName) async {
    try {
      if (kIsWeb) {
        // For web, we'll handle this differently
        return await _saveExcelFileWeb(fileBytes, fileName);
      }
      
      // Request permission first
      bool hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }
      
      // Get download path
      String downloadPath = await getDownloadPath();
      
      // Create file
      final file = File('$downloadPath/$fileName');
      await file.writeAsBytes(fileBytes);
      
      print('File saved to: ${file.path}');
      return true;
    } catch (e) {
      print('Error saving file: $e');
      return false;
    }
  }

  static Future<bool> _saveExcelFileWeb(Uint8List fileBytes, String fileName) async {
    // For web platform, we'll use a different approach
    // This will be handled by the calling widget with conditional imports
    return false;
  }

  static String generateFileName(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.xlsx';
  }
}
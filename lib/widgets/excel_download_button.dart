import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:typed_data';
import '../services/file_service.dart';
import '../utils/platform_utils.dart';

class ExcelDownloadButton extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String fileName;
  final String buttonText;
  final List<String> headers;
  final Color? backgroundColor;
  final Color? textColor;

  const ExcelDownloadButton({
    Key? key,
    required this.data,
    required this.fileName,
    required this.buttonText,
    required this.headers,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  Future<void> _downloadExcel(BuildContext context) async {
    try {
      // Create Excel file
      var excelFile = excel.Excel.createExcel();
      var sheet = excelFile[fileName];

      // Add headers
      sheet.appendRow(headers);

      // Add data
      for (var item in data) {
        List<dynamic> row = [];
        for (String header in headers) {
          // Map header to data key
          String key = _mapHeaderToKey(header);
          row.add(item[key]?.toString() ?? '');
        }
        sheet.appendRow(row);
      }

      final fileBytes = excelFile.encode();
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      final fullFileName = FileService.generateFileName(fileName);
      final uint8FileBytes = Uint8List.fromList(fileBytes);

      if (PlatformUtils.isWeb) {
        await _downloadForWeb(uint8FileBytes, fullFileName);
      } else {
        bool success = await FileService.saveExcelFile(uint8FileBytes, fullFileName);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File berhasil disimpan: $fullFileName'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to save file');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadForWeb(Uint8List fileBytes, String fileName) async {
    if (kIsWeb) {
      // Web-specific download logic will be handled by conditional imports
      // For now, show a message that web download is not supported in mobile build
      throw Exception('Web download not supported in mobile build');
    }
  }

  String _mapHeaderToKey(String header) {
    // Map display headers to data keys
    switch (header.toLowerCase()) {
      case 'no':
      case 'no.':
        return 'no';
      case 'nama barang':
        return 'nama';
      case 'spesifikasi':
        return 'spesifikasi';
      case 'jumlah':
        return 'jumlah';
      case 'pic':
        return 'pic';
      case 'peletakkan':
        return 'peletakkan';
      case 'picking slip':
        return 'picking';
      default:
        return header.toLowerCase().replaceAll(' ', '_');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: data.isNotEmpty ? () => _downloadExcel(context) : null,
      icon: Icon(Icons.download),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.green.shade700,
        foregroundColor: textColor ?? Colors.white,
      ),
    );
  }
}
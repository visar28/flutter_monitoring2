import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart' as excel;
import '../services/file_service.dart';
import '../utils/platform_utils.dart';

// Conditional import for web
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show Blob, Url, AnchorElement;

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
          // Map header to data key (you might need to adjust this mapping)
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

      if (PlatformUtils.isWeb) {
        await _downloadForWeb(fileBytes, fullFileName);
      } else {
        bool success = await FileService.saveExcelFile(fileBytes, fullFileName);
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
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
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
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/pdf_constants.dart';

class PDFStorageService {
  const PDFStorageService();

  /// Save PDF bytes to storage and return file path
  Future<String> savePDFToStorage(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${directory.path}/${PDFConstants.pdfDirectory}');
      
      // Create directory if it doesn't exist
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final file = File('${pdfDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF to storage: $e');
    }
  }

  /// Load PDF bytes from storage
  Future<Uint8List> loadPDFFromStorage(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('PDF file not found at path: $filePath');
      }

      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to load PDF from storage: $e');
    }
  }

  /// Check if PDF file exists at given path
  Future<bool> pdfExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete PDF file from storage
  Future<bool> deletePDF(String filePath) async {
    try {
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to delete PDF: $e');
    }
  }

  /// Get PDF file size in bytes
  Future<int> getPDFFileSize(String filePath) async {
    try {
      final file = File(filePath);
      
      if (await file.exists()) {
        return await file.length();
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all PDF files from storage directory
  Future<void> clearAllPDFs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${directory.path}/${PDFConstants.pdfDirectory}');
      
      if (await pdfDir.exists()) {
        await for (final entity in pdfDir.list()) {
          if (entity is File && entity.path.endsWith(PDFConstants.fileExtension)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to clear PDF storage: $e');
    }
  }

  /// Get list of all PDF files in storage
  Future<List<String>> getAllPDFPaths() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${directory.path}/${PDFConstants.pdfDirectory}');
      
      if (!await pdfDir.exists()) {
        return [];
      }

      final List<String> pdfPaths = [];
      
      await for (final entity in pdfDir.list()) {
        if (entity is File && entity.path.endsWith(PDFConstants.fileExtension)) {
          pdfPaths.add(entity.path);
        }
      }
      
      return pdfPaths;
    } catch (e) {
      return [];
    }
  }

  /// Get storage directory path
  Future<String> getStorageDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${PDFConstants.pdfDirectory}';
  }
}
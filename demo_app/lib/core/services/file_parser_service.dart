import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:hrms_demo/data/models/bulk_employee_row.dart';
import 'package:excel/excel.dart';
import 'package:xml/xml.dart' as xml;

/// Service for parsing CSV and Excel files into BulkEmployeeRow objects
class FileParserService {
  /// Parse a file (CSV or Excel) into a list of BulkEmployeeRow objects
  Future<List<BulkEmployeeRow>> parseFile(String filePath) async {
    // Extract file extension reliably across platforms (Windows uses backslashes)
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex >= 0 ? fileName.substring(dotIndex + 1).toLowerCase() : '';

    if (extension == 'csv') {
      return _parseCsv(filePath);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return _parseExcel(filePath);
    } else {
      throw UnsupportedError('Unsupported file format: "$extension". Please use CSV or Excel (.xlsx, .xls) files.');
    }
  }

  /// Parse file from bytes (for web platform where file path is a blob URL)
  Future<List<BulkEmployeeRow>> parseFileFromBytes(String fileName, List<int> bytes) async {
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex >= 0 ? fileName.substring(dotIndex + 1).toLowerCase() : '';

    if (extension == 'csv') {
      return _parseCsvFromBytes(bytes);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return _parseExcelFromBytes(bytes);
    } else {
      throw UnsupportedError('Unsupported file format: "$extension". Please use CSV or Excel (.xlsx, .xls) files.');
    }
  }

  /// Parse a CSV file
  Future<List<BulkEmployeeRow>> _parseCsv(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // Try multiple encodings for Arabic text support
    String content;
    try {
      // First try UTF-8
      final bytes = await file.readAsBytes();
      content = utf8.decode(bytes);
    } catch (e) {
      try {
        // Try Windows-1256 (Arabic)
        final bytes = await file.readAsBytes();
        content = _decodeWindows1256(bytes);
      } catch (e2) {
        // Fallback to Latin-1
        final bytes = await file.readAsBytes();
        content = latin1.decode(bytes);
      }
    }

    final lines = _parseCsvLines(content);
    if (lines.isEmpty) {
      throw Exception('The CSV file is empty');
    }

    // First line is header
    final headers = _parseCsvRow(lines[0]);
    if (headers.isEmpty) {
      throw Exception('No headers found in CSV file');
    }

    final rows = <BulkEmployeeRow>[];
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      final values = _parseCsvRow(lines[i]);
      final map = <String, dynamic>{};

      for (var j = 0; j < headers.length && j < values.length; j++) {
        map[headers[j]] = values[j];
      }

      rows.add(BulkEmployeeRow.fromMap(map, i));
    }

    return rows;
  }

  /// Parse an Excel file
  Future<List<BulkEmployeeRow>> _parseExcel(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = _sanitizeExcelBytes(await file.readAsBytes());
    final excel = Excel.decodeBytes(bytes);

    // Find a non-empty sheet (prefer "Employees" if it exists)
    Sheet? sheet;

    // First try to find "Employees" sheet
    if (excel.tables.containsKey('Employees')) {
      sheet = excel.tables['Employees'];
    } else {
      // Otherwise find the first non-empty sheet
      for (final name in excel.tables.keys) {
        final s = excel.tables[name];
        if (s != null && s.rows.isNotEmpty) {
          sheet = s;
          break;
        }
      }
    }

    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('The Excel file is empty or has no valid sheets');
    }

    // First row is header
    final headers = sheet.rows[0].map((cell) => cell?.value?.toString() ?? '').toList();
    if (headers.every((h) => h.isEmpty)) {
      throw Exception('No headers found in Excel file');
    }

    final rows = <BulkEmployeeRow>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => cell?.value == null || cell!.value.toString().trim().isEmpty)) {
        continue; // Skip empty rows
      }

      final map = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        final cellValue = row[j]?.value?.toString() ?? '';
        map[headers[j]] = _normalizeCellValue(cellValue);
      }

      rows.add(BulkEmployeeRow.fromMap(map, i));
    }

    return rows;
  }

  /// Parse CSV from bytes (for web platform)
  Future<List<BulkEmployeeRow>> _parseCsvFromBytes(List<int> bytes) async {
    // Try multiple encodings for Arabic text support
    String content;
    try {
      // First try UTF-8
      content = utf8.decode(bytes);
    } catch (e) {
      try {
        // Try Windows-1256 (Arabic)
        content = _decodeWindows1256(bytes);
      } catch (e2) {
        // Fallback to Latin-1
        content = latin1.decode(bytes);
      }
    }

    final lines = _parseCsvLines(content);
    if (lines.isEmpty) {
      throw Exception('The CSV file is empty');
    }

    // First line is header
    final headers = _parseCsvRow(lines[0]);
    if (headers.isEmpty) {
      throw Exception('No headers found in CSV file');
    }

    final rows = <BulkEmployeeRow>[];
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      final values = _parseCsvRow(lines[i]);
      final map = <String, dynamic>{};

      for (var j = 0; j < headers.length && j < values.length; j++) {
        map[headers[j]] = values[j];
      }

      rows.add(BulkEmployeeRow.fromMap(map, i));
    }

    return rows;
  }

  /// Parse Excel from bytes (for web platform)
  Future<List<BulkEmployeeRow>> _parseExcelFromBytes(List<int> bytes) async {
    final excel = Excel.decodeBytes(_sanitizeExcelBytes(bytes));

    // Find a non-empty sheet (prefer "Employees" if it exists)
    Sheet? sheet;

    // First try to find "Employees" sheet
    if (excel.tables.containsKey('Employees')) {
      sheet = excel.tables['Employees'];
    } else {
      // Otherwise find the first non-empty sheet
      for (final name in excel.tables.keys) {
        final s = excel.tables[name];
        if (s != null && s.rows.isNotEmpty) {
          sheet = s;
          break;
        }
      }
    }

    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('The Excel file is empty or has no valid sheets');
    }

    // First row is header
    final headers = sheet.rows[0].map((cell) => cell?.value?.toString() ?? '').toList();
    if (headers.every((h) => h.isEmpty)) {
      throw Exception('No headers found in Excel file');
    }

    final rows = <BulkEmployeeRow>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.every((cell) => cell?.value == null || cell!.value.toString().trim().isEmpty)) {
        continue; // Skip empty rows
      }

      final map = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        final cellValue = row[j]?.value?.toString() ?? '';
        map[headers[j]] = _normalizeCellValue(cellValue);
      }

      rows.add(BulkEmployeeRow.fromMap(map, i));
    }

    return rows;
  }

  /// Parse CSV lines handling quoted values and newlines within quotes
  List<String> _parseCsvLines(String content) {
    final lines = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"') {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (buffer.isNotEmpty) {
          lines.add(buffer.toString());
          buffer.clear();
        }
        // Skip \r\n
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      lines.add(buffer.toString());
    }

    return lines;
  }

  /// Parse a single CSV row
  List<String> _parseCsvRow(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    values.add(buffer.toString().trim());
    return values;
  }

  /// Decode Windows-1256 (Arabic) encoding
  String _decodeWindows1256(List<int> bytes) {
    // Windows-1256 code page mapping for Arabic
    const windows1256 = {
      0x80: '€',
      0x81: 'پ',
      0x82: '‚',
      0x83: 'ƒ',
      0x84: '„',
      0x85: '…',
      0x86: '†',
      0x87: '‡',
      0x88: 'ˆ',
      0x89: '‰',
      0x8A: 'ٹ',
      0x8B: '‹',
      0x8C: 'Œ',
      0x8D: 'چ',
      0x8E: 'ژ',
      0x8F: 'ڈ',
      0x90: 'گ',
      0x91: '‘',
      0x92: '’',
      0x93: '“',
      0x94: '”',
      0x95: '•',
      0x96: '–',
      0x97: '—',
      0x98: 'ک',
      0x99: '™',
      0x9A: 'ڑ',
      0x9B: '›',
      0x9C: 'œ',
      0x9D: 'ں',
      0x9E: '‍',
      0x9F: '،',
      0xA0: ' ',
      0xA1: '،',
      0xA2: '¢',
      0xA3: '£',
      0xA4: '¤',
      0xA5: '¥',
      0xA6: '¦',
      0xA7: '§',
      0xA8: '¨',
      0xA9: '©',
      0xAA: 'ھ',
      0xAB: '«',
      0xAC: '¬',
      0xAD: '­',
      0xAE: '®',
      0xAF: '¯',
      0xB0: '°',
      0xB1: '±',
      0xB2: '²',
      0xB3: '³',
      0xB4: '´',
      0xB5: 'µ',
      0xB6: '¶',
      0xB7: '·',
      0xB8: '¸',
      0xB9: '¹',
      0xBA: '؛',
      0xBB: '»',
      0xBC: '¼',
      0xBD: '½',
      0xBE: '¾',
      0xBF: '؟',
      0xC0: 'ہ',
      0xC1: 'ء',
      0xC2: 'آ',
      0xC3: 'أ',
      0xC4: 'ؤ',
      0xC5: 'إ',
      0xC6: 'ئ',
      0xC7: 'ا',
      0xC8: 'ب',
      0xC9: 'ة',
      0xCA: 'ت',
      0xCB: 'ث',
      0xCC: 'ج',
      0xCD: 'ح',
      0xCE: 'خ',
      0xCF: 'د',
      0xD0: 'ذ',
      0xD1: 'ر',
      0xD2: 'ز',
      0xD3: 'س',
      0xD4: 'ش',
      0xD5: 'ص',
      0xD6: 'ض',
      0xD7: '×',
      0xD8: 'ط',
      0xD9: 'ظ',
      0xDA: 'ع',
      0xDB: 'غ',
      0xDC: 'ـ',
      0xDD: 'ف',
      0xDE: 'ق',
      0xDF: 'ك',
      0xE0: 'à',
      0xE1: 'ل',
      0xE2: 'â',
      0xE3: 'م',
      0xE4: 'ن',
      0xE5: 'ه',
      0xE6: 'و',
      0xE7: 'ç',
      0xE8: 'è',
      0xE9: 'é',
      0xEA: 'ê',
      0xEB: 'ë',
      0xEC: 'ى',
      0xED: 'ي',
      0xEE: 'î',
      0xEF: 'ï',
      0xF0: 'ً',
      0xF1: 'ٌ',
      0xF2: 'ٍ',
      0xF3: 'َ',
      0xF4: 'ُ',
      0xF5: 'ِ',
      0xF6: 'ّ',
      0xF7: '÷',
      0xF8: '°',
      0xF9: 'ù',
      0xFA: 'ْ',
      0xFB: 'û',
      0xFC: 'ü',
      0xFD: '‎',
      0xFE: 'ي',
      0xFF: '‏',
    };

    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte < 128) {
        buffer.write(String.fromCharCode(byte));
      } else {
        buffer.write(windows1256[byte] ?? '?');
      }
    }
    return buffer.toString();
  }

  /// Generate CSV template content
  String generateCsvTemplate() {
    return '''employee_code,english_name,arabic_name,arabic_title,english_title,department_arabic,department_english,hire_date,n1_code,location,cost_center,shift_hours,working_days,leaves_eligibility,email,national_id,english_nickname,arabic_nickname
12345678,John Doe,جون دو,مهندس برمجيات,Software Engineer,إدارة تكنولوجيا المعلومات,IT Department,1-Jan-2024,87654321,RIVERSIDE,RIVERSIDE,8,5,15,john@example.com,12345678901234,John,جون''';
  }

  /// Generate Excel template bytes
  List<int> generateExcelTemplate() {
    final excel = Excel.createExcel();

    // Delete the default "Sheet1" that Excel.createExcel() creates
    excel.delete('Sheet1');

    // Create the Employees sheet
    final sheet = excel['Employees'];

    // Add headers
    final headers = [
      'employee_code',
      'english_name',
      'arabic_name',
      'arabic_title',
      'english_title',
      'department_arabic',
      'department_english',
      'hire_date',
      'n1_code',
      'location',
      'cost_center',
      'shift_hours',
      'working_days',
      'leaves_eligibility',
      'email',
      'national_id',
      'english_nickname',
      'arabic_nickname',
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}1')).value = TextCellValue(headers[i]);
    }

    // Add example row
    final exampleValues = [
      '123456',
      'John Doe',
      'جون دو',
      'مهندس برمجيات',
      'Software Engineer',
      'إدارة تكنولوجيا المعلومات',
      'IT Department',
      '1-Jan-2024',
      '876543',
      'RIVERSIDE',
      'RIVERSIDE',
      '8',
      '5',
      '15',
      'john@example.com',
      '12345678901234',
      'John',
      'جون',
    ];

    for (var i = 0; i < exampleValues.length; i++) {
      sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}2')).value = TextCellValue(exampleValues[i]);
    }

    return excel.encode()!;
  }

  static final _iso8601DatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}');

  String _normalizeCellValue(String value) {
    if (_iso8601DatePattern.hasMatch(value)) {
      return value.substring(0, 10);
    }
    return value;
  }

  /// Workaround for excel package bug: it rejects built-in numFmtId values (< 164).
  /// This strips those entries from xl/styles.xml before decoding.
  List<int> _sanitizeExcelBytes(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final stylesIndex = archive.files.indexWhere(
        (f) => f.name.toLowerCase() == 'xl/styles.xml',
      );
      if (stylesIndex == -1) return bytes;

      final stylesFile = archive.files[stylesIndex];
      final content = utf8.decode(Uint8List.fromList(
        stylesFile.content as List<int>,
      ));
      final document = xml.XmlDocument.parse(content);

      final numFmts = document.findAllElements('numFmt').toList();
      var modified = false;
      for (final numFmt in numFmts) {
        final id = int.tryParse(numFmt.getAttribute('numFmtId') ?? '');
        if (id != null && id < 164) {
          numFmt.parent?.children.remove(numFmt);
          modified = true;
        }
      }

      if (!modified) return bytes;

      // Update or remove the <numFmts> parent count attribute
      for (final numFmtsElement in document.findAllElements('numFmts')) {
        final remaining = numFmtsElement.findElements('numFmt').length;
        if (remaining == 0) {
          numFmtsElement.parent?.children.remove(numFmtsElement);
        } else {
          numFmtsElement.setAttribute('count', remaining.toString());
        }
      }

      final newContent = Uint8List.fromList(utf8.encode(document.toXmlString()));
      archive.addFile(ArchiveFile(
        stylesFile.name,
        newContent.length,
        newContent,
      ));

      return ZipEncoder().encode(archive)!;
    } catch (e) {
      print('Warning: Excel sanitization failed: $e');
      return bytes;
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attendance.dart';

// Workaround untuk web storage
class WebStorageService {
  static final Map<String, dynamic> _storage = {};

  static Future<void> save(String key, String value) async {
    _storage[key] = value;
  }

  static Future<String?> read(String key) async {
    return _storage[key];
  }
}

class LocalStorageService {
  static const String _fileName = 'absensi_data';

  static Future<String> _getFilePath() async {
    if (kIsWeb) {
      return _fileName;
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName.json';
  }

  static Future<void> saveAttendance(Attendance attendance) async {
    try {
      List<Map<String, dynamic>> attendanceList = [];

      // Load existing data
      final existing = await _loadExistingData();
      if (existing.isNotEmpty) {
        attendanceList = existing;
      }

      // Add new data
      attendanceList.add(attendance.toJson());

      // Save to storage
      if (kIsWeb) {
        await WebStorageService.save(_fileName, jsonEncode(attendanceList));
      } else {
        final filePath = await _getFilePath();
        final file = File(filePath);
        await file.writeAsString(jsonEncode(attendanceList));
      }
    } catch (e) {
      throw Exception('Gagal menyimpan data: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _loadExistingData() async {
    try {
      String? contents;

      if (kIsWeb) {
        contents = await WebStorageService.read(_fileName);
      } else {
        final filePath = await _getFilePath();
        final file = File(filePath);
        if (await file.exists()) {
          contents = await file.readAsString();
        }
      }

      if (contents == null || contents.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(contents);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Attendance>> loadAttendance() async {
    try {
      final existingData = await _loadExistingData();

      if (existingData.isEmpty) {
        return [];
      }

      return existingData
          .map((item) => Attendance(
                nama: item['nama'] ?? '',
                nim: item['nim'] ?? '',
                kelas: item['kelas'] ?? '',
                jenisKelamin: item['jenis_kelamin'] ?? '',
                device: item['device'] ?? '',
              ))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat data: $e');
    }
  }
}

import 'dart:convert';
import 'dart:io';

class Utils {
  static Map<String, String> readJson(String fileName) {
    return Map<String, String>.from(jsonDecode(File(fileName).readAsStringSync()));
  }

  static Map<String, String> readJsons(List<String> fileNames) {
    return fileNames.map((fileName) => readJson(fileName)).reduce((a, b) => {...a, ...b});
  }
}

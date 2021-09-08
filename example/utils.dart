import 'dart:convert';
import 'dart:io';

Map<String, String> readJson(String fileName) =>
    (jsonDecode(File(fileName).readAsStringSync()) as Map<String, dynamic>)
        .map<String, String>(
      (key, dynamic value) => MapEntry(
        key,
        value.toString(),
      ),
    );

Map<String, String> readJsons(List<String> fileNames) =>
    fileNames.map(readJson).reduce((a, b) => {...a, ...b});

class Utils {
  static bool isInteger(String target) => int.tryParse(target) != null;
  static bool isNumeric(String target) => double.tryParse(target) != null;
  static bool areNumeric(dynamic first, dynamic second) => Utils.isNumeric(first) && Utils.isNumeric(second);
}

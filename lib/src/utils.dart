import 'package:text_expressions/src/cases.dart';

const charMap = 'abcdefghijklmnopqrstuvwxyz';

class Utils {
  static bool isInteger(String target) => int.tryParse(target) != null;
  static bool isNumeric(String target) => double.tryParse(target) != null;
  static bool areNumeric(dynamic first, dynamic second) => Utils.isNumeric(first) && Utils.isNumeric(second);
  static bool isInRange(String subject, String minimum, String maximum) {
    // If the parameter is in an alphabetical range
    if (!Utils.areNumeric(minimum, maximum)) {
      return subject == minimum || subject == maximum || charMap.split(minimum)[1].split(maximum)[0].contains(subject);
    }

    final subjectNum = double.parse(subject);
    final minimumNum = double.parse(minimum);
    final maximumNum = double.parse(maximum);

    return minimumNum <= subjectNum && subjectNum <= maximumNum;
  }
}

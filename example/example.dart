import 'translation.dart';

final Translation translation = Translation();

void main() {
  translation.load(Language.english);

  print(translation.getString('ageCheck', parameters: {'age': 10}));
  print(translation.getString('ageCheck', parameters: {'age': 17}));
  print(translation.getString('ageCheck', parameters: {'age': 68}));
  print(translation.getString('ageCheck', parameters: {'age': 40}));
  testGreetings();

  translation.load(Language.polish);
  testGreetings();

  translation.load(Language.romanian);
  testGreetings();
}

void testGreetings() {
  print(translation.getString('userGreeting', parameters: {'number': 1}));
  print(translation.getString('userGreeting', parameters: {'number': 4}));
  print(translation.getString('userGreeting', parameters: {'number': 11}));
  print(translation.getString('userGreeting', parameters: {'number': 23}));
}

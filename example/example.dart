import 'translation.dart';

final Translation translation = Translation();

void main() {
  translation.load(Language.english);

  print(translation.translate('ageCheck', named: {'age': 10}));
  print(translation.translate('ageCheck', named: {'age': 17}));
  print(translation.translate('ageCheck', named: {'age': 68}));
  print(translation.translate('ageCheck', named: {'age': 40}));
  testGreetings();

  translation.load(Language.polish);
  testGreetings();

  translation.load(Language.romanian);
  testGreetings();
}

void testGreetings() {
  print(translation.translate('userGreeting', named: {'number': 1}));
  print(translation.translate('userGreeting', named: {'number': 4}));
  print(translation.translate('userGreeting', named: {'number': 11}));
  print(translation.translate('userGreeting', named: {'number': 23}));
}

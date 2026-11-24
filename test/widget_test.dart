import 'package:flutter_test/flutter_test.dart';
import 'package:tomalaga/controllers/auth_controller.dart';

void main() {
  late AuthController controller;

  setUp(() {
    controller = AuthController();
  });

  group('validateUstEmail', () {
    test('returns error when email is empty', () {
      expect(controller.validateUstEmail(''), 'Enter your UST email');
      expect(controller.validateUstEmail(null), 'Enter your UST email');
    });

    test('returns error for non-UST email', () {
      expect(
        controller.validateUstEmail('test@gmail.com'),
        'Must be an official @ust.edu.ph email',
      );
    });

    test('returns error for partial UST domain', () {
      expect(
        controller.validateUstEmail('test@ust.edu'),
        'Must be an official @ust.edu.ph email',
      );
    });

    test('accepts valid UST email', () {
      expect(controller.validateUstEmail('juan.delacruz@ust.edu.ph'), isNull);
    });

    test('accepts UST email with mixed case', () {
      expect(controller.validateUstEmail('Juan.DelaCruz@UST.EDU.PH'), isNull);
    });
  });

  group('validatePassword', () {
    test('returns error when password is null', () {
      expect(controller.validatePassword(null), isNotNull);
    });

    test('returns error when password is too short', () {
      expect(controller.validatePassword('12345'), isNotNull);
    });

    test('accepts password with 6+ characters', () {
      expect(controller.validatePassword('123456'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('returns error when passwords do not match', () {
      expect(
        controller.validateConfirmPassword('abc', '123456'),
        'Passwords do not match',
      );
    });

    test('passes when passwords match', () {
      expect(controller.validateConfirmPassword('123456', '123456'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:regional_news_app/core/failure.dart';

void main() {
  group('ServerFailure.isUnauthorized', () {
    test('401/403 ohne fields gilt als Sitzungsfrage', () {
      expect(const ServerFailure(statusCode: 401).isUnauthorized, isTrue);
      expect(const ServerFailure(statusCode: 403).isUnauthorized, isTrue);
    });

    test('403 mit fields gilt nicht als Sitzungsfrage', () {
      expect(
        const ServerFailure(
          statusCode: 403,
          fields: <String>{'confirmation_code'},
        ).isUnauthorized,
        isFalse,
      );
    });

    test('andere Statuscodes gelten nie als Sitzungsfrage', () {
      expect(const ServerFailure(statusCode: 400).isUnauthorized, isFalse);
      expect(const ServerFailure(statusCode: 500).isUnauthorized, isFalse);
    });
  });

  group('failureFields', () {
    test('liefert die beanstandeten Feldnamen', () {
      expect(
        failureFields(
          const ServerFailure(
            statusCode: 400,
            fields: <String>{'username', 'email'},
          ),
        ),
        <String>{'username', 'email'},
      );
    });

    test('ist leer ohne Fehlerhülle und bei einem fremden Fehler', () {
      expect(failureFields(const ServerFailure(statusCode: 500)), isEmpty);
      expect(failureFields(const ConnectionFailure()), isEmpty);
      expect(failureFields(Exception('irgendetwas')), isEmpty);
    });
  });

  group('failureMessageKeyForField', () {
    test('wählt den spezifischen Text bei passendem Feld', () {
      const ServerFailure error = ServerFailure(
        statusCode: 400,
        fields: <String>{'email'},
      );
      expect(
        failureMessageKeyForField(error, 'email', 'account_email_taken'),
        'account_email_taken',
      );
    });

    test('fällt ohne passendes Feld auf den allgemeinen Text zurück', () {
      const ServerFailure error = ServerFailure(statusCode: 500);
      expect(
        failureMessageKeyForField(error, 'email', 'account_email_taken'),
        'error_server',
      );
    });

    test('fällt bei einem anderen Feld auf den allgemeinen Text zurück', () {
      const ServerFailure error = ServerFailure(
        statusCode: 400,
        fields: <String>{'confirmation_code'},
      );
      expect(
        failureMessageKeyForField(error, 'email', 'account_email_taken'),
        'error_server',
      );
    });

    test(
      'fällt bei einem Nicht-Failure-Fehler auf den allgemeinen Text zurück',
      () {
        expect(
          failureMessageKeyForField(
            Exception('irgendetwas'),
            'email',
            'account_email_taken',
          ),
          'error_server',
        );
      },
    );
  });
}

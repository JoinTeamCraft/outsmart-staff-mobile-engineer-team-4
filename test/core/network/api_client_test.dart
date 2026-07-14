import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/network/api_client.dart';
import 'package:streaklearn/core/network/network_exception.dart';

import '../../helpers/fake_asset_bundle.dart';

ApiClient buildClient({double failureRate = 0.0}) => ApiClient(
      bundle: FakeAssetBundle({
        ApiClient.lessonsAsset: '["lessons"]',
        ApiClient.quizzesAsset: '["quizzes"]',
      }),
      failureRate: failureRate,
      latency: Duration.zero,
    );

void main() {
  group('ApiClient', () {
    test('returns raw asset contents when the network is healthy', () async {
      final client = buildClient();

      expect(await client.getLessonsRaw(), '["lessons"]');
      expect(await client.getQuizzesRaw(), '["quizzes"]');
    });

    test('never fails when failureRate is 0.0', () async {
      final client = buildClient();

      for (var i = 0; i < 25; i++) {
        await client.getLessonsRaw();
      }
    });

    test('throws NetworkException on every request when failureRate is 1.0',
        () async {
      final client = buildClient(failureRate: 1.0);

      await expectLater(
        client.getLessonsRaw(),
        throwsA(isA<NetworkException>()),
      );
      await expectLater(
        client.getQuizzesRaw(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}

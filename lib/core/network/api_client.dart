import 'dart:math';

import 'package:flutter/services.dart';

import 'network_exception.dart';

class ApiClient {
  ApiClient({
    AssetBundle? bundle,
    Random? random,
    this.failureRate = 0.0,
    this.latency = const Duration(milliseconds: 500),
  })  : assert(
          failureRate >= 0.0 && failureRate <= 1.0,
          'failureRate must be within [0.0, 1.0]',
        ),
        _bundle = bundle ?? rootBundle,
        _random = random ?? Random();

  static const String lessonsAsset = 'assets/mock_data/lessons.json';
  static const String quizzesAsset = 'assets/mock_data/quizzes.json';

  final AssetBundle _bundle;
  final Random _random;
  final double failureRate;
  final Duration latency;

  Future<String> getLessonsRaw() => _fetch(lessonsAsset);

  Future<String> getQuizzesRaw() => _fetch(quizzesAsset);

  Future<String> _fetch(String asset) async {
    await Future<void>.delayed(latency);
    if (_random.nextDouble() < failureRate) {
      throw NetworkException('Simulated network failure while loading $asset');
    }
    return _bundle.loadString(asset);
  }
}

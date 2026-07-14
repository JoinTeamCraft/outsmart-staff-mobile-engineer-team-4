import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/result/result.dart';

T successValue<T>(Result<T> result) => switch (result) {
      Success(:final value) => value,
      Failure(:final failure) => fail('Expected Success, got $failure'),
    };

AppFailure failureOf<T>(Result<T> result) => switch (result) {
      Failure(:final failure) => failure,
      Success(:final value) => fail('Expected Failure, got Success($value)'),
    };

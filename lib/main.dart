import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'features/streaks/presentation/streak_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  setupLocator(preferences: preferences);

  // Hydrate streak state from local storage before the first frame.
  await locator<StreakNotifier>().hydrate();

  runApp(const StreakLearnApp());
}

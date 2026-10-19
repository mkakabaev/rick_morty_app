import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:app/di/di.dart';
import 'package:app/di/injectable.dart';
import 'package:app/features/app/app.dart';
import 'package:core/core.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  configureDependencies();

  LoggerObject.outputs = [const DeveloperLogOutput()];
  _installUncaughtErrorLogging();
  Analytics.providers = [const LoggingAnalyticsProvider()];

  unawaited(getIt<StartAppBootstrapUseCase>()());

  runApp(RickMortyApp());
}

void _installUncaughtErrorLogging() {
  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLog.error(details.exception, details.stack ?? StackTrace.current, message: 'Flutter framework error');
    if (previousFlutterOnError != null) {
      previousFlutterOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error(error, stack);
    if (previousPlatformOnError != null) {
      return previousPlatformOnError(error, stack);
    }
    return true;
  };
}

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

  _setupLogsErrorsAndAnalytics();

  configureDependencies();

  unawaited(getIt<StartAppBootstrapUseCase>()());

  runApp(App());
}

void _setupLogsErrorsAndAnalytics() {
  AppLog.addOutput(const DeveloperLogOutput());
  _installErrorLogging();
  Analytics.addProvider(const LoggingAnalyticsProvider());
}

void _installErrorLogging() {
  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLog.error(details.exception, details.stack ?? StackTrace.current, message: 'Flutter framework error');
    if (previousFlutterOnError != null) {
      previousFlutterOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  // Root-isolate errors are not forwarded to [FlutterError.onError], so log them here.
  // An earlier handler still runs; its return value decides the engine fallback.
  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error(error, stack, message: 'Uncaught error');
    if (previousPlatformOnError != null) {
      return previousPlatformOnError(error, stack);
    }
    return true;
  };
}

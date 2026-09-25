import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// ApplyX application entry point.
///
/// Wraps the app in [ProviderScope] for Riverpod state management.
/// No business logic belongs here — this is bootstrap only.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: ApplyXApp(),
    ),
  );
}

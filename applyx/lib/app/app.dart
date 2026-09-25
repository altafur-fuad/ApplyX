import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

/// Root application widget.
///
/// Uses [ProviderScope] for Riverpod state management
/// and [GoRouter] for declarative navigation.
class ApplyXApp extends ConsumerWidget {
  const ApplyXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lock status bar appearance for dark theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp.router(
      title: 'ApplyX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

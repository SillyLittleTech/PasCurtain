import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class PowwowApp extends StatelessWidget {
  const PowwowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      // TODO(rename): Update app title when rebranding from "powwow"
      title: 'powwow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const HomeScreen(),
    );
  }
}

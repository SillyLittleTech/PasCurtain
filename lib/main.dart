import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const PowwowApp(),
    ),
  );
}

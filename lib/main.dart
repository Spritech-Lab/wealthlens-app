/// WealthLens entry point.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait (直式).
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: WealthLensApp()));
}

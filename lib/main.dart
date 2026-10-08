import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled in assets/google_fonts, so never download them.
  GoogleFonts.config.allowRuntimeFetching = false;
  Intl.defaultLocale = 'en_PH';
  await initializeDateFormatting('en_PH');
  runApp(const ProviderScope(child: GncApp()));
}

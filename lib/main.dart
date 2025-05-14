import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/colors.dart';
import 'constants/typography.dart';
import 'providers/router_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');
  runApp(const ProviderScope(child: PlanaryApp()));
}

class PlanaryApp extends ConsumerWidget {
  const PlanaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Planary',
      theme: ThemeData(
        fontFamily: 'GmarketSans',
        textTheme: textTheme,
        primaryColor: kPrimary,
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          foregroundColor: kPrimary,
          elevation: 0,
        ),
      ),
    );
  }
}

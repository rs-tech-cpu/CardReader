import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/transaction_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const CardReaderApp());
}

class CardReaderApp extends StatefulWidget {
  const CardReaderApp({super.key});

  @override
  State<CardReaderApp> createState() => _CardReaderAppState();
}

class _CardReaderAppState extends State<CardReaderApp> {
  /// Lets us push routes in response to deep links that arrive from outside
  /// the widget tree (e.g. the store website's Checkout button).
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Link that launched the app from a cold start.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handleLink(initial);

    // Links received while the app is already running.
    _linkSub = _appLinks.uriLinkStream.listen(_handleLink);
  }

  /// Parses `cardreader://tap?amount=49.99` and opens the transaction screen
  /// with the requested amount already filled in.
  void _handleLink(Uri uri) {
    if (uri.host != 'tap' && uri.path.replaceAll('/', '') != 'tap') return;

    final raw = uri.queryParameters['amount'];
    final amount = double.tryParse(raw ?? '');
    if (amount == null || amount <= 0) return;

    // Defer until the navigator is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navKey.currentState?.push(
        MaterialPageRoute(builder: (_) => TransactionScreen(amount: amount)),
      );
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platinum Reader',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.bgTop,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accent,
          secondary: AppTheme.accentGlow,
          surface: AppTheme.bgMid,
        ),
        splashFactory: InkRipple.splashFactory,
      ),
      home: const HomeScreen(),
    );
  }
}

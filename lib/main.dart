import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Profile/completeRegistrationDataActivity.dart';
import 'Login/login.dart';
import 'Login/needVerificationActivity.dart';
import 'Language/language.dart';

import 'Translation/localizations.dart';
import 'Home/homeActivity.dart';

// Locale contrôlée par un ValueNotifier
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));
String? languageHome;

/// Change la langue à chaud et la persiste
Future<void> setAppLocale(String code) async {
  languageHome = code;
  localeNotifier.value = Locale(code);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', code);
}

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
  FlutterError.dumpErrorToConsole(details);
  debugPrint("❗️Caught error: ${details.exception}");
};

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp().catchError((_) {});

  final prefs = await SharedPreferences.getInstance();
  languageHome = prefs.getString('language');
  localeNotifier.value = Locale(languageHome ?? 'en');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _defaultHome = const LanguageActivity(fromHome: false);

  @override
  void initState() {
    super.initState();
    _decideStart();
  }

  Future<void> _decideStart() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('language')) {
      setState(() => _defaultHome = const LanguageActivity(fromHome: false));
      return;
    }

    final loggedIn = (prefs.getString('userID') ?? '').isNotEmpty;
    if (!loggedIn) {
      setState(() => _defaultHome = LoginActivity());
      return;
    }

    final hasMain = prefs.getBool('hasMainAccount') ?? false;
    final acctType = prefs.getString('accountType') ?? '';
    final validated = prefs.getBool('isValidate') ?? false;

    if (validated) {
      _defaultHome = hasMain
          ? HomeActivity(false)
          : CompleteRegistrationDataActivity(acctType);
    } else {
      _defaultHome = const NeedVerificationActivity();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Délégue custom
    SpecificLocalizationDelegate specificDelegate =
        SpecificLocalizationDelegate(localeNotifier.value);
    helper.onLocaleChanged = (l) => localeNotifier.value = l;

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (_, loc, __) {
        specificDelegate = SpecificLocalizationDelegate(loc);
        return MaterialApp(
          title: 'EGY Copts',
          debugShowCheckedModeBanner: false,
          locale: loc,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            const FallbackCupertinoLocalisationsDelegate(),
            specificDelegate,
          ],
          builder: (ctx, child) {
            return MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: const TextScaler.linear(1.0),
                alwaysUse24HourFormat: false,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: ThemeData(
            fontFamily: 'cocon-next-arabic-regular',
            brightness: Brightness.light,
          ),
          home: _defaultHome,
          routes: {
            '/home': (_) => HomeActivity(false),
            '/login': (_) => LoginActivity(),
            '/language': (_) => const LanguageActivity(fromHome: true),
          },
        );
      },
    );
  }
}

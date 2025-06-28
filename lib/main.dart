import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'SignIn.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.ptSans().fontFamily,
          brightness: Brightness.light,
          primaryColor: Colors.blueAccent,
          iconButtonTheme: const IconButtonThemeData(
            style: ButtonStyle(
              foregroundColor: MaterialStatePropertyAll<Color>(Colors.white),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: MaterialStateProperty.resolveWith((state) {
              if (state.contains(MaterialState.selected)) {
                return const TextStyle(color: Colors.orange);
              }
              return const TextStyle(color: Colors.white);
            }),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        //home: const SignIn()
        home: GlobalLoaderOverlay(
          useDefaultLoading: true,
          overlayColor: Colors.black.withOpacity(0.5),
          overlayWholeScreen:
              false, // Don't overlay the whole screen automatically
          overlayOpacity: 0.7,
          child: const SignIn(),
        ));
  }
}

// Custom loader overlay that doesn't trigger on simple UI state updates
class GlobalLoaderOverlay extends StatelessWidget {
  final Widget child;
  final bool useDefaultLoading;
  final Color overlayColor;
  final bool overlayWholeScreen;
  final double overlayOpacity;

  const GlobalLoaderOverlay({
    super.key,
    required this.child,
    required this.useDefaultLoading,
    required this.overlayColor,
    required this.overlayWholeScreen,
    required this.overlayOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      useDefaultLoading: useDefaultLoading,
      overlayColor: overlayColor,
      overlayWholeScreen: overlayWholeScreen,
      disableBackButton: false,
      child: child,
    );
  }
}

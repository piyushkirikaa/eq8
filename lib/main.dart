import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'SignIn.dart';
import 'Library/RestClient.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
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
    return GlobalLoaderOverlay(
      overlayColor: const Color(0x99000000),
      overlayWidgetBuilder: (progress) {
        return const Center(
          child: SpinKitCubeGrid(
            color: Colors.yellow,
            size: 50.0,
          ),
        );
      },
      child: MaterialApp(
        navigatorKey: RestClient.navigatorKey,
        scaffoldMessengerKey: RestClient.scaffoldMessengerKey,
        scrollBehavior: const MyScrollBehavior(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.ptSans().fontFamily,
          brightness: Brightness.light,
          primaryColor: Colors.blueAccent,
          inputDecorationTheme: const InputDecorationTheme(
            prefixIconColor: Color(0xFFFCB603),
            suffixIconColor: Color(0xFFFCB603),
          ),
          iconButtonTheme: const IconButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((state) {
              if (state.contains(WidgetState.selected)) {
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
        home: const SignIn(),
      ),
    );
  }
}

class MyScrollBehavior extends MaterialScrollBehavior {
  const MyScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

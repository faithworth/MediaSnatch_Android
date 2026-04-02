import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/config.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer edge-to-edge on Android
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF161B22),
  ));

  await AppConfig.init();
  runApp(const MediaSnatchApp());
}

class MediaSnatchApp extends StatelessWidget {
  const MediaSnatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaSnatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}

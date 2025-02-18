import 'package:educo_yoyaku/firebase_options.dart';
import 'package:educo_yoyaku/router/router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Educo 予約',
      theme: ThemeData(
        // ベースとなる明るいテーマ
        brightness: Brightness.light,
        
        // メインカラーをオレンジに設定
        primaryColor: const Color(0xFFFF5722),
        primarySwatch: Colors.deepOrange,
        
        // アクセントカラー
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFFF5722),
          secondary: const Color(0xFFFF8A65),
          surface: Colors.white,
        ),
        
        // 背景色を白に
        scaffoldBackgroundColor: Colors.white,
        
        // AppBarのテーマ
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF5722),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        
        // ボタンのテーマ
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // カードのテーマ
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // テキストのテーマ
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            color: Colors.black87,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
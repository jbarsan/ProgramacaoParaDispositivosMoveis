import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/tela_principal.dart';

/// ============================================================================
/// PONTO DE ENTRADA DO APLICATIVO
/// ============================================================================
void main() {
  // Garante a inicialização correta dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANTE PARA DESKTOP (Linux, Windows, macOS):
  // No Android e iOS, o SqFlite inicializa nativamente.
  // No Linux/Desktop (onde este app está sendo testado), é necessário
  // inicializar o FFI para que o SqFlite acesse o SQLite local.
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Contatos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      home: const TelaPrincipal(),
    );
  }
}

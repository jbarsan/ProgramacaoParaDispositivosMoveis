import 'package:material_ui/material_ui.dart';

// Define a identidade visual institucional do SGP Mobile (CPPT/MPPI).
//
// Segue a paleta de cores definida pelo MPPI:
// - Primária: `#8E1919` (Vermelho Institucional MPPI)
// - Variante Escura: `#6B1212`
// - Fundo Principal: `#FFFFFF` / Cartões: `#F8F9FA`
// - Textos: `#121212` e `#5F6368`
class AppTheme {
  // Impede instanciação direta desta classe utilitária.
  AppTheme._();

  // Vermelho Institucional do Ministério Público do Estado do Piauí (MPPI).
  static const Color primaryColor = Color(0xFF8E1919);

  // Variante escura da cor primária para estados de hover/pressionado.
  static const Color primaryDarkColor = Color(0xFF6B1212);

  // Fundo principal branco puro para alto contraste.
  static const Color backgroundColor = Color(0xFFFFFFFF);

  // Fundo secundário gelo suave para cartões e separadores.
  static const Color surfaceIceColor = Color(0xFFF8F9FA);

  // Cor principal de textos e ícones (preto carvão).
  static const Color textPrimaryColor = Color(0xFF121212);

  // Cor secundária de textos para subtítulos e metadados.
  static const Color textSecondaryColor = Color(0xFF5F6368);

  // Semântica de status: Demanda ou viagem concluída.
  static const Color statusConcluida = Color(0xFF2E7D32);

  // Semântica de status: Demanda pausada com justificativa.
  static const Color statusPausada = Color(0xFFED6C02);

  // Semântica de status: Demanda ou viagem em andamento.
  static const Color statusEmAndamento = Color(0xFF0288D1);

  // Semântica de status: Prioridade alta, atraso ou erro crítico.
  static const Color statusAltaAtrasada = Color(0xFFD32F2F);

  // Retorna o [ThemeData] completo configurado para Material 3.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: primaryDarkColor,
      onSecondary: Colors.white,
      surface: backgroundColor,
      onSurface: textPrimaryColor,
      error: statusAltaAtrasada,
      onError: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceIceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceIceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }
}

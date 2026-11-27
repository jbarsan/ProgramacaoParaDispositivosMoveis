import 'package:material_ui/material_ui.dart';

import '../../utils/app_theme.dart';

// Indicador de carregamento padronizado na identidade visual do MPPI (`#8E1919`).
class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ],
      ),
    );
  }
}

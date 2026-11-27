import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

// Tela de edição de perfil do servidor:
// - Seleção de avatar a partir da lista local em `assets/images/`
// - Edição de dados pessoais (nome, matrícula, cargo)
// - Alteração de senha mediante confirmação da senha atual.
class PerfilEditView extends StatefulWidget {
  const PerfilEditView({super.key});

  @override
  State<PerfilEditView> createState() => _PerfilEditViewState();
}

class _PerfilEditViewState extends State<PerfilEditView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _matriculaController;
  late final TextEditingController _cargoController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedAvatarAsset;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _nomeController = TextEditingController(text: user?.nome ?? '');
    _matriculaController = TextEditingController(text: user?.matricula ?? '');
    _cargoController = TextEditingController(text: user?.cargo ?? '');
    _selectedAvatarAsset = user?.fotoUrl;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    _cargoController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  ImageProvider? _resolveAvatar(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('assets/')) return AssetImage(path);
    return NetworkImage(path);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.updateOwnProfile(
      nome: _nomeController.text,
      matricula: _matriculaController.text,
      cargo: _cargoController.text,
      novaFotoAsset: _selectedAvatarAsset,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Perfil atualizado com sucesso!'
              : (auth.errorMessage ?? 'Erro ao salvar perfil.'),
        ),
        backgroundColor: ok
            ? AppTheme.statusConcluida
            : AppTheme.statusAltaAtrasada,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Senha alterada com sucesso!'
              : (auth.errorMessage ?? 'Não foi possível alterar a senha.'),
        ),
        backgroundColor: ok
            ? AppTheme.statusConcluida
            : AppTheme.statusAltaAtrasada,
      ),
    );
    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final avatarProvider = _resolveAvatar(_selectedAvatarAsset);

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxWebContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.surfaceIceColor,
                        backgroundImage: avatarProvider,
                        child: avatarProvider == null
                            ? const Icon(
                                Icons.person,
                                size: 44,
                                color: AppTheme.primaryColor,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Escolha um avatar do perfil:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: AppConstants.avatarAssets.map((assetPath) {
                          final isSelected = _selectedAvatarAsset == assetPath;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedAvatarAsset = assetPath);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(assetPath),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (user != null)
                        Text(
                          'Lotação: ${AppFormatters.formatLotacao(user.lotacao)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                        ),
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Informe seu nome completo.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _matriculaController,
                        decoration: const InputDecoration(
                          labelText: 'Matrícula',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _cargoController,
                        decoration: const InputDecoration(labelText: 'Cargo'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _saveProfile,
                        child: auth.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Salvar Alterações'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 40),
                const Text(
                  'Alterar Senha',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Form(
                  key: _passwordFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha atual',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Informe sua senha atual.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nova senha (mínimo 6 caracteres)',
                          prefixIcon: Icon(Icons.vpn_key_outlined),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'A nova senha deve ter pelo menos 6 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar nova senha',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        validator: (v) => v != _newPasswordController.text
                            ? 'As senhas não conferem.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: auth.isLoading ? null : _changePassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Atualizar Senha'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/status_badge.dart';

// Tela de Gestão de Usuários exclusiva para Administrador e Coordenação (RF-004).
//
// Apresenta todos os dados preenchidos no cadastro pelo usuário para validação,
// permitindo editá-los apenas se necessário ao aprovar ou atualizar o acesso.
class GestaoUsuariosView extends StatelessWidget {
  const GestaoUsuariosView({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = context.watch<AdminController>();
    final solicitante = context.watch<AuthController>().currentUser;

    if (solicitante == null || !solicitante.isGestor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestão de Usuários')),
        body: const Center(
          child: Text('Acesso restrito à Coordenação e Administração.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Usuários')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxWebContentWidth,
          ),
          child: StreamBuilder<List<UserModel>>(
            stream: adminController.streamTodosPerfis(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator(
                  message: 'Carregando usuários...',
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar usuários: ${snapshot.error}'),
                );
              }
              final usuarios = snapshot.data ?? [];
              if (usuarios.isEmpty) {
                return const Center(child: Text('Nenhum usuário cadastrado.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = usuarios[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        child: Text(
                          usuario.nome.isNotEmpty
                              ? usuario.nome[0].toUpperCase()
                              : 'U',
                        ),
                      ),
                      title: Text(
                        usuario.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario.email),
                          const SizedBox(height: 4),
                          Text(
                            'Mat.: ${usuario.matricula.isNotEmpty ? usuario.matricula : "-"} • Cargo: ${usuario.cargo.isNotEmpty ? usuario.cargo : "-"}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Lotação: ${AppFormatters.formatLotacao(usuario.lotacao)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Cadastro em: ${AppFormatters.formatDateTime(usuario.createdAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              StatusBadge(
                                label: usuario.ativo ? 'Ativo' : 'Pendente',
                                color: usuario.ativo
                                    ? AppTheme.statusConcluida
                                    : AppTheme.statusPausada,
                              ),
                              StatusBadge(
                                label: AppFormatters.formatRole(usuario.role),
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Validar e Configurar Acesso',
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: () => _abrirDialogAprovacao(
                              context,
                              solicitante,
                              usuario,
                            ),
                          ),
                          if (AdminController.validarExclusaoUsuario(
                                solicitante: solicitante,
                                alvo: usuario,
                              ) ==
                              null)
                            IconButton(
                              tooltip: 'Excluir Usuário',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.statusAltaAtrasada,
                              ),
                              onPressed: adminController.isLoading
                                  ? null
                                  : () => _confirmarExclusao(
                                        context,
                                        solicitante,
                                        usuario,
                                      ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDialogAprovacao(
    BuildContext context,
    UserModel solicitante,
    UserModel target,
  ) async {
    String selectedRole = target.role == AppConstants.rolePendente
        ? AppConstants.roleServidor
        : target.role;
    String selectedLotacao =
        AppConstants.lotacoesDisponiveis.contains(target.lotacao)
        ? target.lotacao!
        : AppConstants.lotacoesDisponiveis.first;
    bool ativo = target.ativo || target.role == AppConstants.rolePendente;

    // Permite validar os dados preenchidos no cadastro e editá-los só se necessário.
    bool editarDados = false;
    final nomeCtrl = TextEditingController(text: target.nome);
    final matriculaCtrl = TextEditingController(text: target.matricula);
    final cargoCtrl = TextEditingController(text: target.cargo);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Validar Cadastro • ${target.nome}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apresenta todos os dados preenchidos pelo usuário no cadastro, já pré-preenchidos.
                    TextFormField(
                      controller: nomeCtrl,
                      readOnly: !editarDados,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo (cadastrado)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: target.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'E-mail institucional',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: matriculaCtrl,
                            readOnly: !editarDados,
                            decoration: const InputDecoration(
                              labelText: 'Matrícula',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cargoCtrl,
                            readOnly: !editarDados,
                            decoration: const InputDecoration(
                              labelText: 'Cargo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cadastrado em: ${AppFormatters.formatDateTime(target.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Editar dados cadastrais',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: editarDados,
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: (v) => setState(() => editarDados = v),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Papel'),
                      items: AppConstants.rolesAprovaveis
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(AppFormatters.formatRole(r)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedRole = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLotacao,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lotação / Assessoria',
                      ),
                      items: AppConstants.lotacoesDisponiveis
                          .map(
                            (l) => DropdownMenuItem(
                              value: l,
                              child: Text(
                                AppFormatters.formatLotacao(l),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedLotacao = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Acesso Ativo'),
                      value: ativo,
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: (v) => setState(() => ativo = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final admin = context.read<AdminController>();
                    final ok = await admin.aprovarOuAtualizarUsuario(
                      solicitante: solicitante,
                      targetUid: target.uid,
                      role: selectedRole,
                      ativo: ativo,
                      lotacao: selectedLotacao,
                      nome: editarDados ? nomeCtrl.text : null,
                      matricula: editarDados ? matriculaCtrl.text : null,
                      cargo: editarDados ? cargoCtrl.text : null,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Permissões de ${target.nome} atualizadas!'
                                : (admin.errorMessage ?? 'Falha ao atualizar.'),
                          ),
                          backgroundColor: ok
                              ? AppTheme.statusConcluida
                              : AppTheme.statusAltaAtrasada,
                        ),
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nomeCtrl.dispose();
    matriculaCtrl.dispose();
    cargoCtrl.dispose();
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    UserModel solicitante,
    UserModel alvo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Conta de Usuário'),
        content: Text(
          'Deseja excluir o perfil de ${alvo.nome} (${alvo.email})? O acesso ao sistema será removido imediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusAltaAtrasada,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;
    final admin = context.read<AdminController>();
    final ok = await admin.excluirUsuario(
      solicitante: solicitante,
      alvo: alvo,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Conta de ${alvo.nome} excluída com sucesso!'
              : (admin.errorMessage ?? 'Erro ao excluir usuário.'),
        ),
        backgroundColor:
            ok ? AppTheme.statusConcluida : AppTheme.statusAltaAtrasada,
      ),
    );
  }
}

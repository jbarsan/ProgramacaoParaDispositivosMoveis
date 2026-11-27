import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/demanda_controller.dart';
import '../../controllers/viagem_controller.dart';
import '../../models/comentario_model.dart';
import '../../models/demanda_model.dart';
import '../../models/historico_model.dart';
import '../../models/user_model.dart';
import '../../models/viagem_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../mapa/rota_viagem_view.dart';
import '../widgets/status_badge.dart';
import 'pausa_dialog.dart';

/// Tela de detalhes completos da Demanda Pericial (RF-009, RF-010, RF-011 e RF-012),
/// incluindo início da demanda, alteração/desvínculo de servidor, desvínculo de
/// viagem e exclusão controlada.
class DemandaDetailView extends StatefulWidget {
  final DemandaModel demanda;

  const DemandaDetailView({super.key, required this.demanda});

  @override
  State<DemandaDetailView> createState() => _DemandaDetailViewState();
}

class _DemandaDetailViewState extends State<DemandaDetailView> {
  late DemandaModel _demanda;
  final _comentarioController = TextEditingController();
  List<ViagemModel> _viagensVinculadas = [];

  @override
  void initState() {
    super.initState();
    _demanda = widget.demanda;
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarViagens());
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _carregarViagens() async {
    final lista = await context
        .read<DemandaController>()
        .getViagensPorDemanda(_demanda.id);
    if (mounted) setState(() => _viagensVinculadas = lista);
  }

  Future<void> _iniciar() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    final ok = await context.read<DemandaController>().iniciarDemanda(
          demanda: _demanda,
          usuario: user,
        );
    if (ok && mounted) {
      setState(() {
        _demanda = _demanda.copyWith(status: AppConstants.statusEmAndamento);
      });
    }
  }

  Future<void> _pausar() async {
    final justificativa = await PausaDialog.show(context);
    if (justificativa == null || !mounted) return;
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    final ctrl = context.read<DemandaController>();
    final ok = await ctrl.pausarDemanda(
      demanda: _demanda,
      justificativa: justificativa,
      usuario: user,
    );
    if (ok && mounted) {
      setState(() {
        _demanda = _demanda.copyWith(
          status: AppConstants.statusPausada,
          justificativaPausa: justificativa,
        );
      });
    }
  }

  Future<void> _despausar() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    final ok = await context.read<DemandaController>().despausarDemanda(
          demanda: _demanda,
          usuario: user,
        );
    if (ok && mounted) {
      setState(() {
        _demanda = _demanda.copyWith(
          status: AppConstants.statusEmAndamento,
          clearJustificativa: true,
        );
      });
    }
  }

  Future<void> _concluir() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    final ok = await context.read<DemandaController>().concluirDemanda(
          demanda: _demanda,
          usuario: user,
        );
    if (ok && mounted) {
      setState(() {
        _demanda = _demanda.copyWith(
          status: AppConstants.statusConcluida,
          clearJustificativa: true,
        );
      });
    }
  }

  Future<void> _alterarServidor(UserModel gestor) async {
    final demandaCtrl = context.read<DemandaController>();
    final servidores = await demandaCtrl.getServidoresAprovados();
    if (!mounted) return;

    String selectedId = _demanda.servidorId;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Alterar / Desvincular Servidor'),
              content: DropdownButtonFormField<String>(
                initialValue: servidores.any((s) => s.uid == selectedId)
                    ? selectedId
                    : '',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Servidor Responsável',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text(
                      'Desvincular (Disponível para o setor)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...servidores.map(
                    (s) => DropdownMenuItem(
                      value: s.uid,
                      child: Text(
                        '${s.nome} (${s.lotacao ?? "CPPT"})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedId = v);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmado != true || !mounted) return;

    final escolhido =
        servidores.where((s) => s.uid == selectedId).firstOrNull;
    final novoNome =
        escolhido != null ? escolhido.nome : 'Disponível para o setor';

    final ok = await demandaCtrl.alterarVinculoServidor(
      demanda: _demanda,
      novoServidorId: selectedId,
      novoServidorNome: novoNome,
      gestor: gestor,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _demanda = _demanda.copyWith(
          servidorId: selectedId,
          servidorNome: novoNome,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vínculo atualizado com sucesso!'),
          backgroundColor: AppTheme.statusConcluida,
        ),
      );
    } else if (demandaCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(demandaCtrl.errorMessage!),
          backgroundColor: AppTheme.statusAltaAtrasada,
        ),
      );
    }
  }

  Future<void> _desvincularProprio(UserModel servidor) async {
    final demandaCtrl = context.read<DemandaController>();
    final ok = await demandaCtrl.desvincularPropriaDemanda(
      demanda: _demanda,
      servidor: servidor,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _demanda = _demanda.copyWith(
          servidorId: '',
          servidorNome: 'Disponível para o setor',
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você foi desvinculado desta demanda.'),
          backgroundColor: AppTheme.statusConcluida,
        ),
      );
    } else if (demandaCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(demandaCtrl.errorMessage!),
          backgroundColor: AppTheme.statusAltaAtrasada,
        ),
      );
    }
  }

  Future<void> _excluirDemanda(UserModel gestor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Demanda'),
        content: Text(
          'Deseja excluir a demanda ${_demanda.numeroSgp}? Esta ação só é permitida se ela não tiver sido iniciada e não estiver em nenhuma viagem.',
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
    if (confirmar != true || !mounted) return;

    final demandaCtrl = context.read<DemandaController>();
    final ok = await demandaCtrl.excluirDemanda(
      demanda: _demanda,
      gestor: gestor,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demanda excluída com sucesso!'),
          backgroundColor: AppTheme.statusConcluida,
        ),
      );
    } else if (demandaCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(demandaCtrl.errorMessage!),
          backgroundColor: AppTheme.statusAltaAtrasada,
        ),
      );
    }
  }

  Future<void> _desvincularViagem(ViagemModel viagem, UserModel gestor) async {
    final viagemCtrl = context.read<ViagemController>();
    final atualizada = await viagemCtrl.desvincularDemandaDeViagem(
      viagem: viagem,
      demandaId: _demanda.id,
      gestor: gestor,
    );
    if (!mounted) return;
    if (atualizada != null) {
      await _carregarViagens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demanda desvinculada da viagem!'),
            backgroundColor: AppTheme.statusConcluida,
          ),
        );
      }
    } else if (viagemCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viagemCtrl.errorMessage!),
          backgroundColor: AppTheme.statusAltaAtrasada,
        ),
      );
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty) return;
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    final ok = await context.read<DemandaController>().adicionarComentario(
          demandaId: _demanda.id,
          texto: texto,
          autor: user,
        );
    if (ok && mounted) {
      _comentarioController.clear();
    }
  }

  Future<void> _editarComentario(ComentarioModel c) async {
    final editCtrl = TextEditingController(text: c.texto);
    final novoTexto = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Comentário'),
        content: TextField(controller: editCtrl, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, editCtrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    editCtrl.dispose();
    if (novoTexto == null || novoTexto.isEmpty || !mounted) return;
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    await context.read<DemandaController>().editarComentario(
          demandaId: _demanda.id,
          comentario: c,
          novoTexto: novoTexto,
          usuario: user,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final demandaCtrl = context.watch<DemandaController>();
    final isGestor = user?.isGestor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_demanda.numeroSgp),
        actions: [
          if (isGestor && user != null)
            IconButton(
              tooltip: 'Excluir Demanda',
              icon: const Icon(Icons.delete_outline),
              onPressed:
                  demandaCtrl.isLoading ? null : () => _excluirDemanda(user),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxWebContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cabeçalho de informações principais (RF-009)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusBadge.fromDemandaStatus(_demanda.status),
                          StatusBadge.fromPrioridade(_demanda.prioridade),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _demanda.titulo,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_demanda.descricao.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_demanda.descricao),
                      ],
                      const Divider(height: 24),
                      _infoRow('Solicitante', _demanda.unidadeSolicitante),
                      _infoRow('Número SEI', _demanda.numeroSei),
                      _infoRow('Responsável', _demanda.servidorNome),
                      _infoRow(
                        'Lotação',
                        AppFormatters.formatLotacao(_demanda.lotacao),
                      ),
                      _infoRow(
                        'Recebimento',
                        AppFormatters.formatDate(_demanda.dataRecebimento),
                      ),
                      _infoRow(
                        'Prazo Limite',
                        '${AppFormatters.formatDate(_demanda.dataLimite)} (${_demanda.prazoDias} dias)',
                      ),
                      _infoRow(
                        'Local',
                        '${_demanda.endereco}, ${_demanda.municipio}',
                      ),
                      if (_demanda.justificativaPausa != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.statusPausada.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Motivo da pausa: ${_demanda.justificativaPausa}',
                            style: const TextStyle(
                              color: AppTheme.statusPausada,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Ações operacionais e de vínculo
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Botão "Iniciar" visível apenas para usuário da lotação de destino.
                  if (_demanda.status == AppConstants.statusNaoIniciada &&
                      user != null &&
                      user.lotacao == _demanda.lotacao)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 44),
                        backgroundColor: AppTheme.statusEmAndamento,
                      ),
                      onPressed: demandaCtrl.isLoading ? null : _iniciar,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Iniciar'),
                    ),
                  if (_demanda.status == AppConstants.statusEmAndamento)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 44),
                        backgroundColor: AppTheme.statusPausada,
                      ),
                      onPressed: demandaCtrl.isLoading ? null : _pausar,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pausar'),
                    ),
                  if (_demanda.status == AppConstants.statusPausada)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 44),
                        backgroundColor: AppTheme.statusEmAndamento,
                      ),
                      onPressed: demandaCtrl.isLoading ? null : _despausar,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Retomar'),
                    ),
                  if (_demanda.status != AppConstants.statusConcluida)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 44),
                        backgroundColor: AppTheme.statusConcluida,
                      ),
                      onPressed: demandaCtrl.isLoading ? null : _concluir,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Concluir'),
                    ),
                  if (isGestor && user != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(180, 44),
                      ),
                      onPressed: demandaCtrl.isLoading
                          ? null
                          : () => _alterarServidor(user),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Alterar / Desvincular Servidor'),
                    ),
                  if (!isGestor &&
                      user != null &&
                      _demanda.servidorId == user.uid)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(160, 44),
                        foregroundColor: AppTheme.statusAltaAtrasada,
                      ),
                      onPressed: demandaCtrl.isLoading
                          ? null
                          : () => _desvincularProprio(user),
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Desvincular-me'),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(160, 44),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RotaViagemView(
                            tituloDestino: _demanda.titulo,
                            enderecoDestino:
                                '${_demanda.endereco}, ${_demanda.municipio}',
                            destino: LatLng(
                              _demanda.latitude,
                              _demanda.longitude,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Traçar Rota'),
                  ),
                ],
              ),

              if (_viagensVinculadas.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Viagens Vinculadas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._viagensVinculadas.map(
                  (v) => Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.directions_car,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        'Portaria ${v.numeroPortaria} • ${v.destinoCidade}',
                      ),
                      subtitle: Text(
                        'Situação: ${AppFormatters.formatViagemSituacao(v.situacao)}',
                      ),
                      trailing: (isGestor && user != null)
                          ? IconButton(
                              tooltip: 'Desvincular da Viagem',
                              icon: const Icon(
                                Icons.link_off,
                                color: AppTheme.statusAltaAtrasada,
                              ),
                              onPressed: () => _desvincularViagem(v, user),
                            )
                          : null,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Seção de Comentários (RF-011)
              const Text(
                'Comentários',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comentarioController,
                      decoration: const InputDecoration(
                        hintText: 'Escreva um comentário...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    onPressed: _enviarComentario,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<ComentarioModel>>(
                stream: demandaCtrl.streamComentarios(_demanda.id),
                builder: (context, snapshot) {
                  final comentarios = snapshot.data ?? [];
                  if (comentarios.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum comentário registrado.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    );
                  }
                  return Column(
                    children: comentarios.map((c) {
                      final podeEditar =
                          user != null && c.podeEditarOuExcluir(user);
                      return Card(
                        child: ListTile(
                          title: Text(
                            c.autorNome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(c.texto),
                              const SizedBox(height: 4),
                              Text(
                                AppFormatters.formatDateTime(c.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                          trailing: podeEditar
                              ? PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      _editarComentario(c);
                                    } else if (action == 'delete') {
                                      demandaCtrl.excluirComentario(
                                        demandaId: _demanda.id,
                                        comentario: c,
                                        usuario: user,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Excluir'),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Linha do Tempo Automática (RF-012)
              const Text(
                'Histórico de Movimentações',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<HistoricoModel>>(
                stream: demandaCtrl.streamHistorico(_demanda.id),
                builder: (context, snapshot) {
                  final eventos = snapshot.data ?? [];
                  if (eventos.isEmpty) {
                    return const Text(
                      'Nenhum evento registrado na linha do tempo.',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    );
                  }
                  return Column(
                    children: eventos
                        .map(
                          (e) => ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.timeline,
                              color: AppTheme.primaryColor,
                            ),
                            title: Text(e.descricao),
                            subtitle: Text(
                              '${e.usuarioNome} (${e.unidade}) • ${AppFormatters.formatDateTime(e.createdAt)}',
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : '-'),
          ),
        ],
      ),
    );
  }
}

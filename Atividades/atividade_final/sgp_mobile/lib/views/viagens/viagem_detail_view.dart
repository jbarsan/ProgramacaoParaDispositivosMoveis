import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/viagem_controller.dart';
import '../../models/user_model.dart';
import '../../models/viagem_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../mapa/rota_viagem_view.dart';
import '../widgets/status_badge.dart';
import 'viagem_form_view.dart';

// Tela de detalhes da Viagem exibindo todos os destinos/cidades, desvínculo
// controlado de demandas, exclusão de viagem sem demandas e rota individual (RF-013/016).
class ViagemDetailView extends StatefulWidget {
  final ViagemModel viagem;

  const ViagemDetailView({super.key, required this.viagem});

  @override
  State<ViagemDetailView> createState() => _ViagemDetailViewState();
}

class _ViagemDetailViewState extends State<ViagemDetailView> {
  late ViagemModel _viagem;

  @override
  void initState() {
    super.initState();
    _viagem = widget.viagem;
  }

  Future<void> _desvincularDemanda(String demandaId, UserModel gestor) async {
    final viagemCtrl = context.read<ViagemController>();
    final atualizada = await viagemCtrl.desvincularDemandaDeViagem(
      viagem: _viagem,
      demandaId: demandaId,
      gestor: gestor,
    );
    if (!mounted) return;
    if (atualizada != null) {
      setState(() => _viagem = atualizada);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demanda desvinculada da viagem!'),
          backgroundColor: AppTheme.statusConcluida,
        ),
      );
    } else if (viagemCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viagemCtrl.errorMessage!),
          backgroundColor: AppTheme.statusAltaAtrasada,
        ),
      );
    }
  }

  Future<void> _excluirViagem(UserModel gestor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Viagem'),
        content: Text(
          'Deseja excluir a viagem Portaria ${_viagem.numeroPortaria}? Só é permitido quando não houver nenhuma demanda vinculada.',
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

    final viagemCtrl = context.read<ViagemController>();
    final ok = await viagemCtrl.excluirViagem(viagem: _viagem, gestor: gestor);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem excluída com sucesso!'),
          backgroundColor: AppTheme.statusConcluida,
        ),
      );
    } else if (viagemCtrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viagemCtrl.errorMessage!),
          backgroundColor: AppTheme.statusAltaAtrasada,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final viagemCtrl = context.watch<ViagemController>();
    final isGestor = user?.isGestor ?? false;
    final destinos = _viagem.destinosEfetivos;

    return Scaffold(
      appBar: AppBar(
        title: Text('Viagem • ${_viagem.destinoCidade}'),
        actions: [
          IconButton(
            tooltip: 'Editar Viagem',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ViagemFormView(viagemExistente: _viagem),
                ),
              );
            },
          ),
          if (isGestor && user != null)
            IconButton(
              tooltip: 'Excluir Viagem',
              icon: const Icon(Icons.delete_outline),
              onPressed: viagemCtrl.isLoading
                  ? null
                  : () => _excluirViagem(user),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge.fromViagemSituacao(_viagem.situacao),
                      const SizedBox(height: 12),
                      Text(
                        _viagem.destinoCidade,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _row('Portaria', _viagem.numeroPortaria),
                      _row('SEI Portaria', _viagem.seiPortaria),
                      _row('Solicitante', _viagem.unidadeSolicitante),
                      if (_viagem.servidoresNomes.isNotEmpty)
                        _row('Servidores', _viagem.servidoresNomes.join(', ')),
                      _row(
                        'Período',
                        '${AppFormatters.formatDate(_viagem.dataIda)} até ${AppFormatters.formatDate(_viagem.dataRetorno)}',
                      ),
                      _row('Atividades', _viagem.descricaoAtividades),
                      if (_viagem.seiPrestacaoContas != null)
                        _row('SEI Prest. Contas', _viagem.seiPrestacaoContas!),
                      if (_viagem.observacoes != null)
                        _row('Observações', _viagem.observacoes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Destinos da Viagem',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...destinos.map(
                (dest) => Card(
                  child: ListTile(
                    title: Text(
                      dest.demandaNumeroSgp != null
                          ? '${dest.cidade} (${dest.demandaNumeroSgp})'
                          : dest.cidade,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(dest.endereco),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isGestor && user != null && dest.demandaId != null)
                          IconButton(
                            tooltip: 'Desvincular Demanda',
                            icon: const Icon(
                              Icons.link_off,
                              color: AppTheme.statusAltaAtrasada,
                            ),
                            onPressed: viagemCtrl.isLoading
                                ? null
                                : () => _desvincularDemanda(
                                    dest.demandaId!,
                                    user,
                                  ),
                          ),
                        IconButton.filled(
                          tooltip: 'Traçar Rota',
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RotaViagemView(
                                  tituloDestino: 'Destino: ${dest.cidade}',
                                  enderecoDestino: dest.endereco,
                                  destino: LatLng(
                                    dest.latitude,
                                    dest.longitude,
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.directions,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(child: Text(value.isNotEmpty ? value : '-')),
        ],
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/demanda_controller.dart';
import '../../models/demanda_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/status_badge.dart';
import 'demanda_detail_view.dart';
import 'demanda_form_view.dart';

// Tela de listagem, busca textual e filtros de Demandas Periciais (RF-008).
//
// Inclui a aba/filtro **Demandas do Setor**, que exibe demandas ainda sem
// servidor vinculado para que um servidor da mesma lotação possa assumi-las.
class DemandasListView extends StatefulWidget {
  const DemandasListView({super.key});

  @override
  State<DemandasListView> createState() => _DemandasListViewState();
}

class _DemandasListViewState extends State<DemandasListView> {
  String _statusFilter = 'todas';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final demandaCtrl = context.watch<DemandaController>();

    if (user == null) {
      return const LoadingIndicator();
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por SGP, título ou município...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim().toLowerCase());
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('todas', 'Todas'),
                      const SizedBox(width: 8),
                      _buildFilterChip('setor', 'Demandas do Setor'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        AppConstants.statusNaoIniciada,
                        'Não Iniciadas',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        AppConstants.statusEmAndamento,
                        'Em Andamento',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppConstants.statusPausada, 'Pausadas'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        AppConstants.statusConcluida,
                        'Concluídas',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DemandaModel>>(
              stream: demandaCtrl.streamDemandas(user),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(
                    message: 'Carregando demandas...',
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar demandas: ${snapshot.error}'),
                  );
                }

                final all = snapshot.data ?? [];
                final filtered = all.where((d) {
                  final bool matchesStatus;
                  if (_statusFilter == 'setor') {
                    // Demandas do setor: ainda sem servidor vinculado.
                    matchesStatus =
                        d.servidorId.isEmpty &&
                        (user.isGestor || d.lotacao == user.lotacao);
                  } else {
                    matchesStatus =
                        _statusFilter == 'todas' || d.status == _statusFilter;
                  }
                  final matchesQuery =
                      _searchQuery.isEmpty ||
                      d.numeroSgp.toLowerCase().contains(_searchQuery) ||
                      d.titulo.toLowerCase().contains(_searchQuery) ||
                      d.municipio.toLowerCase().contains(_searchQuery);
                  return matchesStatus && matchesQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _statusFilter == 'setor'
                          ? 'Não há demandas disponíveis sem vínculo no seu setor.'
                          : 'Nenhuma demanda encontrada para os filtros aplicados.',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final d = filtered[index];
                    final semServidor = d.servidorId.isEmpty;

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DemandaDetailView(demanda: d),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    d.numeroSgp,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  StatusBadge.fromDemandaStatus(d.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                d.titulo,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      d.municipio,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  StatusBadge.fromPrioridade(d.prioridade),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Prazo: ${AppFormatters.formatDate(d.dataLimite)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: d.isAtrasada
                                          ? AppTheme.statusAltaAtrasada
                                          : AppTheme.textSecondaryColor,
                                      fontWeight: d.isAtrasada
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (semServidor)
                                    TextButton.icon(
                                      onPressed: demandaCtrl.isLoading
                                          ? null
                                          : () async {
                                              final ok = await demandaCtrl
                                                  .assumirDemanda(
                                                    demanda: d,
                                                    servidor: user,
                                                  );
                                              if (context.mounted && ok) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Demanda vinculada a você com sucesso!',
                                                    ),
                                                    backgroundColor: AppTheme
                                                        .statusConcluida,
                                                  ),
                                                );
                                              }
                                            },
                                      icon: const Icon(
                                        Icons.person_add_alt_1,
                                        size: 16,
                                      ),
                                      label: const Text('Assumir Demanda'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Tanto gestores quanto servidores podem cadastrar novas demandas.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DemandaFormView()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Demanda'),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }
}

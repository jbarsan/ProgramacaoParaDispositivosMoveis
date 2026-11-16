import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/ata_controller.dart';
import '../../models/ata_pncp_model.dart';

class AbaAtasView extends StatefulWidget {
  const AbaAtasView({super.key});

  @override
  State<AbaAtasView> createState() => _AbaAtasViewState();
}

class _AbaAtasViewState extends State<AbaAtasView>
    with AutomaticKeepAliveClientMixin {
  // Parâmetros de teste padrão: CNPJ do MPPI (05805924000189), Ano 2026,
  // Data Inicial 20260101 e Data Final 20261101.
  final TextEditingController _cnpjController = TextEditingController(
    text: '05805924000189',
  );
  final TextEditingController _anoController = TextEditingController(
    text: '2026',
  );
  final TextEditingController _dataInicialController = TextEditingController(
    text: '20260101',
  );
  final TextEditingController _dataFinalController = TextEditingController(
    text: '20261101',
  );
  final TextEditingController _buscaLocalController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _cnpjController.dispose();
    _anoController.dispose();
    _dataInicialController.dispose();
    _dataFinalController.dispose();
    _buscaLocalController.dispose();
    super.dispose();
  }

  void _exibirDetalhesAta(BuildContext context, AtaPncpModel ata) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ata de Registro de Preço Nº ${ata.numeroAtaRegistroPreco}/${ata.anoAta}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text(ata.cancelado ? 'Cancelada' : 'Ativa'),
                        backgroundColor: ata.cancelado
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controle PNCP Ata: ${ata.numeroControlePNCPAta}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                  const Divider(height: 24),
                  _itemDetalhe('Objeto da Contratação', ata.objetoContratacao),
                  _itemDetalhe('Órgão', '${ata.nomeOrgao} (${ata.cnpjOrgao})'),
                  _itemDetalhe(
                    'Unidade Gestora',
                    '${ata.nomeUnidadeOrgao} (${ata.codigoUnidadeOrgao})',
                  ),
                  _itemDetalhe('Data de Assinatura', ata.dataAssinatura),
                  _itemDetalhe(
                    'Período de Vigência',
                    '${ata.vigenciaInicio} até ${ata.vigenciaFim}',
                  ),
                  _itemDetalhe('Data Publicação PNCP', ata.dataPublicacaoPncp),
                  _itemDetalhe(
                    'Possibilidade de Adesão',
                    ata.possibilidadeAdesao == null
                        ? 'Não informado'
                        : (ata.possibilidadeAdesao! ? 'Sim' : 'Não'),
                  ),
                  _itemDetalhe(
                    'Compra Vinculada (PNCP)',
                    ata.numeroControlePNCPCompra,
                  ),
                  if (ata.cancelado && ata.dataCancelamento != null)
                    _itemDetalhe('Data de Cancelamento', ata.dataCancelamento!),
                  if (ata.usuario.isNotEmpty)
                    _itemDetalhe('Sistema / Usuário', ata.usuario),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _itemDetalhe(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AtaController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // 1. Formulário de parâmetros da API (/v1/atas)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _cnpjController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CNPJ do Órgão (cnpj)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _anoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ano',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (ano) {
                            if (ano.trim().length == 4) {
                              _dataInicialController.text = '${ano.trim()}0101';
                              _dataFinalController.text = '${ano.trim()}1101';
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dataInicialController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Data Inicial (AAAAMMDD)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _dataFinalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Data Final (AAAAMMDD)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: controller.isLoading
                            ? null
                            : () {
                                _buscaLocalController.clear();
                                controller.consultarCnpj(
                                  _cnpjController.text,
                                  _anoController.text,
                                  dataInicial: _dataInicialController.text,
                                  dataFinal: _dataFinalController.text,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.search),
                        label: const Text('Consultar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 2. Filtro local da lista de Atas de Registro de Preço
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buscaLocalController,
                      decoration: const InputDecoration(
                        labelText:
                            'Filtrar por objeto, número da ata, ano ou unidade...',
                        prefixIcon: Icon(Icons.filter_list),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: controller.filtrarResultadosLocais,
                    ),
                  ),
                  if (controller.totalCarregadas > 0) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${controller.atas.length}/${controller.totalCarregadas}',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. Exibição da Lista ou Indicador de Carregamento
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : controller.erro.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Atenção:\n${controller.erro}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  : controller.atas.isEmpty
                  ? const Center(
                      child: Text(
                        'Faça uma consulta ou nenhuma ata de registro de preço encontrada.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.atas.length,
                      itemBuilder: (context, index) {
                        final ata = controller.atas[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            onTap: () => _exibirDetalhesAta(context, ata),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Ata Nº ${ata.numeroAtaRegistroPreco}/${ata.anoAta}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ata.cancelado
                                        ? Colors.red.shade100
                                        : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    ata.cancelado ? 'Cancelada' : 'Vigente',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: ata.cancelado
                                          ? Colors.red.shade900
                                          : Colors.green.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  ata.objetoContratacao,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Órgão: ${ata.nomeOrgao}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Vigência: ${ata.vigenciaInicio} a ${ata.vigenciaFim}',
                                ),
                                Text(
                                  'Assinatura: ${ata.dataAssinatura} | Adesão: ${ata.possibilidadeAdesao == null ? "N/I" : (ata.possibilidadeAdesao! ? "Sim" : "Não")}',
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

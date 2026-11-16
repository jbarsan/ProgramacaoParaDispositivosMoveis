import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/contrato_controller.dart';
import '../../models/contrato_pncp_model.dart';

class AbaContratosView extends StatefulWidget {
  const AbaContratosView({super.key});

  @override
  State<AbaContratosView> createState() => _AbaContratosViewState();
}

class _AbaContratosViewState extends State<AbaContratosView>
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

  void _exibirDetalhesContrato(
    BuildContext context,
    ContratoPncpModel contrato,
  ) {
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
                  Text(
                    '${contrato.tipoContratoNome} Nº ${contrato.numeroContrato}/${contrato.anoContrato}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controle PNCP: ${contrato.numeroControlePNCP}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
                  const Divider(height: 24),
                  _itemDetalhe('Objeto do Contrato', contrato.objetoContrato),
                  _itemDetalhe('Fornecedor', contrato.nomeFornecedor),
                  _itemDetalhe(
                    'CNPJ/CPF do Fornecedor (${contrato.tipoPessoa})',
                    contrato.niFornecedor,
                  ),
                  _itemDetalhe(
                    'Valor Inicial',
                    'R\$ ${contrato.valorInicial.toStringAsFixed(2)}',
                  ),
                  _itemDetalhe(
                    'Valor da Parcela',
                    'R\$ ${contrato.valorParcela.toStringAsFixed(2)}',
                  ),
                  _itemDetalhe(
                    'Valor Global',
                    'R\$ ${contrato.valorGlobal.toStringAsFixed(2)}',
                  ),
                  _itemDetalhe('Categoria', contrato.categoriaProcessoNome),
                  _itemDetalhe('Processo', contrato.processo),
                  _itemDetalhe('Data de Assinatura', contrato.dataAssinatura),
                  _itemDetalhe(
                    'Vigência',
                    '${contrato.dataVigenciaInicio} até ${contrato.dataVigenciaFim}',
                  ),
                  _itemDetalhe(
                    'Data Publicação PNCP',
                    contrato.dataPublicacaoPncp,
                  ),
                  _itemDetalhe(
                    'Órgão',
                    '${contrato.razaoSocialOrgao} (${contrato.cnpjOrgao})',
                  ),
                  _itemDetalhe(
                    'Unidade Gestora',
                    '${contrato.nomeUnidadeOrgao} (${contrato.codigoUnidadeOrgao})',
                  ),
                  if (contrato.numeroControlePncpAta != null &&
                      contrato.numeroControlePncpAta!.isNotEmpty)
                    _itemDetalhe(
                      'Ata Vinculada (PNCP)',
                      contrato.numeroControlePncpAta!,
                    ),
                  if (contrato.numeroControlePncpCompra != null &&
                      contrato.numeroControlePncpCompra!.isNotEmpty)
                    _itemDetalhe(
                      'Compra Vinculada (PNCP)',
                      contrato.numeroControlePncpCompra!,
                    ),
                  if (contrato.informacaoComplementar != null &&
                      contrato.informacaoComplementar!.trim().isNotEmpty)
                    _itemDetalhe(
                      'Informação Complementar',
                      contrato.informacaoComplementar!,
                    ),
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
    return Consumer<ContratoController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // 1. Formulário de parâmetros da API (/v1/contratos)
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
                            labelText: 'CNPJ do Órgão (cnpjOrgao)',
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

            // 2. Filtro local da lista de Contratos / Empenhos
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
                            'Filtrar por objeto, fornecedor, número ou processo...',
                        prefixIcon: Icon(Icons.filter_list),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: controller.filtrarResultadosLocais,
                    ),
                  ),
                  if (controller.totalCarregados > 0) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${controller.contratos.length}/${controller.totalCarregados}',
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
                  : controller.contratos.isEmpty
                  ? const Center(
                      child: Text(
                        'Faça uma consulta ou nenhum contrato/empenho encontrado.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.contratos.length,
                      itemBuilder: (context, index) {
                        final contrato = controller.contratos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            onTap: () =>
                                _exibirDetalhesContrato(context, contrato),
                            title: Text(
                              '${contrato.tipoContratoNome} Nº ${contrato.numeroContrato}/${contrato.anoContrato}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  contrato.objetoContrato,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Fornecedor: ${contrato.nomeFornecedor} (${contrato.niFornecedor})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Valor Inicial: R\$ ${contrato.valorInicial.toStringAsFixed(2)} | Global: R\$ ${contrato.valorGlobal.toStringAsFixed(2)}',
                                ),
                                Text(
                                  'Assinatura: ${contrato.dataAssinatura} | Vigência: ${contrato.dataVigenciaInicio} a ${contrato.dataVigenciaFim}',
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

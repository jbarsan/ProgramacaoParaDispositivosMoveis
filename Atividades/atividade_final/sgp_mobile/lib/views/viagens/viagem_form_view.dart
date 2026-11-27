import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/demanda_controller.dart';
import '../../controllers/map_controller.dart';
import '../../controllers/viagem_controller.dart';
import '../../models/demanda_model.dart';
import '../../models/user_model.dart';
import '../../models/viagem_model.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../mapa/map_picker_view.dart';

// Formulário de cadastro e edição de Viagem com vínculo de múltiplas demandas,
// preenchimento automático dos endereços das demandas selecionadas e suporte
// a múltiplos endereços/cidades de destino (RF-013 e RF-015).
class ViagemFormView extends StatefulWidget {
  final ViagemModel? viagemExistente;

  const ViagemFormView({super.key, this.viagemExistente});

  @override
  State<ViagemFormView> createState() => _ViagemFormViewState();
}

class _ViagemFormViewState extends State<ViagemFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _seiPortariaController;
  late final TextEditingController _numeroPortariaController;
  late final TextEditingController _unidadeController;
  late final TextEditingController _atividadesController;
  late final TextEditingController _seiContasController;
  late final TextEditingController _obsController;

  late List<String> _demandasSelecionadas;
  late List<ViagemDestino> _destinos;
  late List<String> _servidoresIdsSelecionados;
  List<UserModel> _servidoresDisponiveis = [];
  late DateTime _dataIda;
  late DateTime _dataRetorno;
  late String _situacao;

  @override
  void initState() {
    super.initState();
    final v = widget.viagemExistente;
    final user = context.read<AuthController>().currentUser;
    _seiPortariaController = TextEditingController(text: v?.seiPortaria ?? '');
    _numeroPortariaController = TextEditingController(
      text: v?.numeroPortaria ?? '',
    );
    _unidadeController = TextEditingController(
      text: v?.unidadeSolicitante ?? '',
    );
    _atividadesController = TextEditingController(
      text: v?.descricaoAtividades ?? '',
    );
    _seiContasController = TextEditingController(
      text: v?.seiPrestacaoContas ?? '',
    );
    _obsController = TextEditingController(text: v?.observacoes ?? '');

    _demandasSelecionadas = List<String>.from(v?.demandasIds ?? []);
    _destinos = v != null
        ? List<ViagemDestino>.from(v.destinosEfetivos)
        : <ViagemDestino>[];
    if (v != null) {
      _servidoresIdsSelecionados = v.servidoresIds.isNotEmpty
          ? List<String>.from(v.servidoresIds)
          : (v.servidorId.isNotEmpty ? [v.servidorId] : <String>[]);
    } else if (user != null && !user.isGestor) {
      // Quando criado por servidor, já vem vinculado a ele (podendo ser alterado).
      _servidoresIdsSelecionados = [user.uid];
    } else {
      _servidoresIdsSelecionados = <String>[];
    }
    _dataIda = v?.dataIda ?? DateTime.now();
    _dataRetorno =
        v?.dataRetorno ?? DateTime.now().add(const Duration(days: 2));
    _situacao = v?.situacao ?? AppConstants.viagemAgendada;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lista =
          await context.read<DemandaController>().getServidoresAprovados();
      if (mounted) setState(() => _servidoresDisponiveis = lista);
    });
  }

  @override
  void dispose() {
    _seiPortariaController.dispose();
    _numeroPortariaController.dispose();
    _unidadeController.dispose();
    _atividadesController.dispose();
    _seiContasController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  // Seleciona ou remove uma demanda, sincronizando automaticamente o seu
  // endereço cadastrado para a lista de destinos da viagem.
  void _toggleDemanda(DemandaModel d, bool selected) {
    setState(() {
      if (selected) {
        if (!_demandasSelecionadas.contains(d.id)) {
          _demandasSelecionadas.add(d.id);
        }
        if (_unidadeController.text.isEmpty) {
          _unidadeController.text = d.unidadeSolicitante;
        }
        final jaExiste = _destinos.any((dest) => dest.demandaId == d.id);
        if (!jaExiste) {
          _destinos.add(ViagemDestino.fromDemanda(d));
        }
      } else {
        _demandasSelecionadas.remove(d.id);
        _destinos.removeWhere((dest) => dest.demandaId == d.id);
      }
    });
  }

  // Abre diálogo para adicionar um endereço manual (ou via mapa) à viagem.
  Future<void> _adicionarEnderecoManual() async {
    final novoDestino = await showDialog<ViagemDestino>(
      context: context,
      builder: (_) => const _AdicionarDestinoDialog(),
    );

    if (novoDestino != null && mounted) {
      setState(() => _destinos.add(novoDestino));
    }
  }

  Future<void> _pickDate({required bool isIda}) async {
    final initial = isIda ? _dataIda : _dataRetorno;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isIda) {
          _dataIda = picked;
          if (_dataRetorno.isBefore(_dataIda)) {
            _dataRetorno = _dataIda;
          }
        } else {
          _dataRetorno = picked;
        }
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_servidoresIdsSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vincule ao menos um servidor à viagem.'),
          backgroundColor: AppTheme.statusPausada,
        ),
      );
      return;
    }
    if (_destinos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione ao menos uma demanda ou adicione um endereço de destino.',
          ),
          backgroundColor: AppTheme.statusPausada,
        ),
      );
      return;
    }

    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    final servidoresNomes = _servidoresDisponiveis
        .where((s) => _servidoresIdsSelecionados.contains(s.uid))
        .map((s) => s.nome)
        .toList();
    if (servidoresNomes.isEmpty && _servidoresIdsSelecionados.contains(user.uid)) {
      servidoresNomes.add(user.nome);
    }

    final principal = _destinos.first;
    final cidadesResumo = _destinos
        .map((d) => d.cidade)
        .where((c) => c.isNotEmpty)
        .toSet()
        .join(' • ');

    final viagem = ViagemModel(
      id: widget.viagemExistente?.id ?? '',
      demandasIds: _demandasSelecionadas,
      unidadeSolicitante: _unidadeController.text.trim(),
      seiPortaria: _seiPortariaController.text.trim(),
      numeroPortaria: _numeroPortariaController.text.trim(),
      descricaoAtividades: _atividadesController.text.trim(),
      destinoCidade: cidadesResumo.isNotEmpty
          ? cidadesResumo
          : principal.cidade,
      destinoEndereco: principal.endereco,
      logradouro: principal.logradouro,
      numero: principal.numero,
      complemento: principal.complemento,
      bairro: principal.bairro,
      estado: principal.estado,
      cep: principal.cep,
      latitude: principal.latitude,
      longitude: principal.longitude,
      destinos: _destinos,
      dataIda: _dataIda,
      dataRetorno: _dataRetorno,
      situacao: _situacao,
      seiPrestacaoContas: _seiContasController.text.trim().isEmpty
          ? null
          : _seiContasController.text.trim(),
      observacoes: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
      servidorId: _servidoresIdsSelecionados.first,
      servidoresIds: _servidoresIdsSelecionados,
      servidoresNomes: servidoresNomes,
    );

    final ctrl = context.read<ViagemController>();
    final ok = widget.viagemExistente == null
        ? await ctrl.criarViagem(viagem: viagem, usuario: user)
        : await ctrl.atualizarViagem(viagem);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem salva com sucesso!'),
          backgroundColor: AppTheme.statusConcluida,
        ),
      );
    } else if (ctrl.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ctrl.errorMessage!),
          backgroundColor: AppTheme.statusAltaAtrasada,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final demandaCtrl = context.watch<DemandaController>();
    final viagemCtrl = context.watch<ViagemController>();
    final anoAtual = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.viagemExistente == null ? 'Nova Viagem' : 'Editar Viagem',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxWebContentWidth,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null)
                    StreamBuilder<List<DemandaModel>>(
                      stream: demandaCtrl.streamDemandas(user),
                      builder: (context, snapshot) {
                        final demandas = snapshot.data ?? [];
                        if (demandas.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demandas Associadas (preenche endereços automaticamente)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: demandas.map((d) {
                                final selected = _demandasSelecionadas.contains(
                                  d.id,
                                );
                                return FilterChip(
                                  label: Text(
                                    '${d.numeroSgp} (${d.municipio})',
                                  ),
                                  selected: selected,
                                  onSelected: (val) => _toggleDemanda(d, val),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  TextFormField(
                    controller: _unidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Unidade Solicitante',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _numeroPortariaController,
                    decoration: const InputDecoration(
                      labelText: 'Número da Portaria',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _seiPortariaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [SeiInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'SEI da Portaria',
                      hintText: '00.00.0000.0000000/$anoAtual-00',
                    ),
                    validator: (v) => AppFormatters.validateSei(v),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Servidores Vinculados à Viagem',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (_servidoresDisponiveis.isEmpty)
                    const Text(
                      'Carregando lista de servidores...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _servidoresDisponiveis.map((srv) {
                        final selected =
                            _servidoresIdsSelecionados.contains(srv.uid);
                        return FilterChip(
                          label: Text(
                            '${srv.nome} (${srv.lotacao ?? "CPPT"})',
                          ),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _servidoresIdsSelecionados.add(srv.uid);
                              } else {
                                _servidoresIdsSelecionados.remove(srv.uid);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Endereços / Cidades de Destino',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _adicionarEnderecoManual,
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Adicionar Endereço'),
                      ),
                    ],
                  ),
                  if (_destinos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Selecione uma demanda acima ou clique em "Adicionar Endereço".',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    )
                  else
                    ..._destinos.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final dest = entry.value;
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            dest.demandaNumeroSgp != null
                                ? '${dest.cidade} (${dest.demandaNumeroSgp})'
                                : dest.cidade,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${dest.endereco}\nCoord.: ${dest.latitude.toStringAsFixed(5)}, ${dest.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: 'Remover destino',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.statusAltaAtrasada,
                            ),
                            onPressed: () {
                              setState(() {
                                if (dest.demandaId != null) {
                                  _demandasSelecionadas.remove(dest.demandaId);
                                }
                                _destinos.removeAt(idx);
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(isIda: true),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            'Ida: ${AppFormatters.formatDate(_dataIda)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(isIda: false),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            'Retorno: ${AppFormatters.formatDate(_dataRetorno)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _situacao,
                    decoration: const InputDecoration(labelText: 'Situação'),
                    items: AppConstants.situacoesViagem
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(AppFormatters.formatViagemSituacao(s)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _situacao = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _atividadesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição das Atividades',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _seiContasController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [SeiInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'SEI da Prestação de Contas (opcional)',
                      hintText: '00.00.0000.0000000/$anoAtual-00',
                    ),
                    validator: (v) => AppFormatters.validateSei(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _obsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observações complementares',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: viagemCtrl.isLoading ? null : _salvar,
                    child: viagemCtrl.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Salvar Viagem'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Diálogo dedicado para adicionar um endereço manual ou via mapa à viagem,
// garantindo ciclo de vida seguro para controladores e navegação ao mapa.
class _AdicionarDestinoDialog extends StatefulWidget {
  const _AdicionarDestinoDialog();

  @override
  State<_AdicionarDestinoDialog> createState() =>
      _AdicionarDestinoDialogState();
}

class _AdicionarDestinoDialogState extends State<_AdicionarDestinoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();

  String _estado = 'PI';
  double _lat = AppConstants.defaultLat;
  double _lng = AppConstants.defaultLng;
  bool _buscando = false;

  @override
  void dispose() {
    _cepCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    super.dispose();
  }

  String _buildAddress() {
    final parts = <String>[];
    if (_logradouroCtrl.text.trim().isNotEmpty) {
      final n = _numeroCtrl.text.trim();
      parts.add(
        n.isNotEmpty
            ? '${_logradouroCtrl.text.trim()}, $n'
            : _logradouroCtrl.text.trim(),
      );
    }
    if (_complementoCtrl.text.trim().isNotEmpty) {
      parts.add(_complementoCtrl.text.trim());
    }
    if (_bairroCtrl.text.trim().isNotEmpty) {
      parts.add(_bairroCtrl.text.trim());
    }
    if (_cidadeCtrl.text.trim().isNotEmpty) {
      parts.add('${_cidadeCtrl.text.trim()} - $_estado');
    }
    if (_cepCtrl.text.trim().isNotEmpty) {
      parts.add('CEP ${_cepCtrl.text.trim()}');
    }
    return parts.join(', ');
  }

  Future<void> _buscarOuSelecionarNoMapa() async {
    setState(() => _buscando = true);
    final mapCtrl = context.read<MapController>();
    final res = await mapCtrl.searchStructuredAddress(
      logradouro: _logradouroCtrl.text,
      numero: _numeroCtrl.text,
      bairro: _bairroCtrl.text,
      cidade: _cidadeCtrl.text,
      estado: _estado,
      cep: _cepCtrl.text,
    );
    if (!mounted) return;
    setState(() => _buscando = false);

    if (res != null) {
      setState(() {
        _lat = res.latitude;
        _lng = res.longitude;
      });
      return;
    }

    final picked = await Navigator.push<GeocodingResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerView(initialPoint: LatLng(_lat, _lng)),
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _lat = picked.latitude;
      _lng = picked.longitude;
      if (picked.logradouro.isNotEmpty) {
        _logradouroCtrl.text = picked.logradouro;
      }
      if (picked.numero.isNotEmpty) {
        _numeroCtrl.text = picked.numero;
      }
      if (picked.bairro.isNotEmpty) {
        _bairroCtrl.text = picked.bairro;
      }
      if (picked.cidade.isNotEmpty) {
        _cidadeCtrl.text = picked.cidade;
      }
      if (AppConstants.estadosBrasileiros.contains(picked.estado)) {
        _estado = picked.estado;
      }
      if (picked.cep.isNotEmpty) {
        _cepCtrl.text = picked.cep;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Endereço de Destino'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cepCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CepInputFormatter()],
                      decoration: const InputDecoration(labelText: 'CEP'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _estado,
                      decoration: const InputDecoration(labelText: 'UF'),
                      items: AppConstants.estadosBrasileiros
                          .map(
                            (uf) =>
                                DropdownMenuItem(value: uf, child: Text(uf)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _estado = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _logradouroCtrl,
                decoration: const InputDecoration(labelText: 'Logradouro'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o logradouro.'
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numeroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Número (opc.)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _complementoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Complemento',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bairroCtrl,
                      decoration: const InputDecoration(labelText: 'Bairro'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o bairro.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cidadeCtrl,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe a cidade.'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _buscando ? null : _buscarOuSelecionarNoMapa,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _buscando ? 'Buscando...' : 'Buscar Coordenadas / Mapa',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Coord.: ${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              ViagemDestino(
                cidade: _cidadeCtrl.text.trim(),
                endereco: _buildAddress(),
                logradouro: _logradouroCtrl.text.trim(),
                numero: _numeroCtrl.text.trim().isEmpty
                    ? null
                    : _numeroCtrl.text.trim(),
                complemento: _complementoCtrl.text.trim().isEmpty
                    ? null
                    : _complementoCtrl.text.trim(),
                bairro: _bairroCtrl.text.trim(),
                estado: _estado,
                cep: _cepCtrl.text.trim(),
                latitude: _lat,
                longitude: _lng,
              ),
            );
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

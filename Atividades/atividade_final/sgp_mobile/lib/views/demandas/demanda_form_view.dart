import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/demanda_controller.dart';
import '../../controllers/map_controller.dart';
import '../../models/demanda_model.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../mapa/map_picker_view.dart';

// Formulário de cadastro de nova demanda pericial com máscara SEI,
// endereço completo e geocodificação automática (RF-015).
class DemandaFormView extends StatefulWidget {
  const DemandaFormView({super.key});

  @override
  State<DemandaFormView> createState() => _DemandaFormViewState();
}

class _DemandaFormViewState extends State<DemandaFormView> {
  final _formKey = GlobalKey<FormState>();
  final _numeroSgpController = TextEditingController();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _unidadeController = TextEditingController();
  final _seiController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _municipioController = TextEditingController(text: 'Teresina');
  final _prazoController = TextEditingController(text: '15');

  String _prioridade = AppConstants.prioridadeNormal;
  String _lotacao = AppConstants.lotacoesDisponiveis.first;
  String _estado = 'PI';
  double _latitude = AppConstants.defaultLat;
  double _longitude = AppConstants.defaultLng;

  List<UserModel> _servidores = [];
  String _servidorIdSelecionado = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    if (user != null) {
      if (user.lotacao != null &&
          AppConstants.lotacoesDisponiveis.contains(user.lotacao)) {
        _lotacao = user.lotacao!;
      }
      if (!user.isGestor) {
        _servidorIdSelecionado = user.uid;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final lista = await context
              .read<DemandaController>()
              .getServidoresAprovados();
          if (mounted) setState(() => _servidores = lista);
        });
      }
    }
  }

  @override
  void dispose() {
    _numeroSgpController.dispose();
    _tituloController.dispose();
    _descricaoController.dispose();
    _unidadeController.dispose();
    _seiController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _municipioController.dispose();
    _prazoController.dispose();
    super.dispose();
  }

  // Monta o endereço completo formatado a partir dos campos individuais.
  String _buildFullAddress() {
    final parts = <String>[];
    if (_logradouroController.text.trim().isNotEmpty) {
      final numTxt = _numeroController.text.trim();
      parts.add(
        numTxt.isNotEmpty
            ? '${_logradouroController.text.trim()}, $numTxt'
            : _logradouroController.text.trim(),
      );
    }
    if (_complementoController.text.trim().isNotEmpty) {
      parts.add(_complementoController.text.trim());
    }
    if (_bairroController.text.trim().isNotEmpty) {
      parts.add(_bairroController.text.trim());
    }
    if (_municipioController.text.trim().isNotEmpty) {
      parts.add('${_municipioController.text.trim()} - $_estado');
    }
    if (_cepController.text.trim().isNotEmpty) {
      parts.add('CEP ${_cepController.text.trim()}');
    }
    return parts.join(', ');
  }

  Future<void> _buscarCoordenadas() async {
    final mapCtrl = context.read<MapController>();
    final result = await mapCtrl.searchStructuredAddress(
      logradouro: _logradouroController.text,
      numero: _numeroController.text,
      bairro: _bairroController.text,
      cidade: _municipioController.text,
      estado: _estado,
      cep: _cepController.text,
    );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coordenadas capturadas: ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
          ),
          backgroundColor: AppTheme.statusConcluida,
        ),
      );
      return;
    }

    // Caso o endereço não seja encontrado, pergunta se deseja buscar no mapa.
    final abrirMapa = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Endereço não encontrado'),
        content: const Text(
          'Não foi possível localizar as coordenadas para este endereço. Deseja buscar e marcar o ponto diretamente no mapa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Não'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Buscar no Mapa'),
          ),
        ],
      ),
    );

    if (abrirMapa == true && mounted) {
      await _abrirSeletorNoMapa();
    }
  }

  // Abre o mapa interativo para marcar um ponto e preencher coordenadas/endereço.
  Future<void> _abrirSeletorNoMapa() async {
    final picked = await Navigator.push<GeocodingResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPickerView(initialPoint: LatLng(_latitude, _longitude)),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _latitude = picked.latitude;
      _longitude = picked.longitude;
      if (picked.logradouro.isNotEmpty) {
        _logradouroController.text = picked.logradouro;
      }
      if (picked.numero.isNotEmpty) {
        _numeroController.text = picked.numero;
      }
      if (picked.bairro.isNotEmpty) {
        _bairroController.text = picked.bairro;
      }
      if (picked.cidade.isNotEmpty) {
        _municipioController.text = picked.cidade;
      }
      if (AppConstants.estadosBrasileiros.contains(picked.estado)) {
        _estado = picked.estado;
      }
      if (picked.cep.isNotEmpty) {
        _cepController.text = picked.cep;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ponto selecionado: ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
        ),
        backgroundColor: AppTheme.statusConcluida,
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;

    String servidorId = '';
    String servidorNome = 'Disponível para o setor';
    if (!user.isGestor) {
      servidorId = user.uid;
      servidorNome = user.nome;
    } else if (_servidorIdSelecionado.isNotEmpty) {
      final encontrado = _servidores
          .where((s) => s.uid == _servidorIdSelecionado)
          .firstOrNull;
      if (encontrado != null) {
        servidorId = encontrado.uid;
        servidorNome = encontrado.nome;
      }
    }

    final lotacaoEfetiva = user.isGestor ? _lotacao : (user.lotacao ?? _lotacao);
    final numeroSgpCompleto = AppFormatters.formatNumeroSgpCompleto(
      _numeroSgpController.text,
      lotacaoEfetiva,
    );

    final demanda = DemandaModel(
      id: '',
      numeroSgp: numeroSgpCompleto,
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      unidadeSolicitante: _unidadeController.text.trim(),
      numeroSei: _seiController.text.trim(),
      status: AppConstants.statusNaoIniciada,
      prioridade: _prioridade,
      servidorId: servidorId,
      servidorNome: servidorNome,
      lotacao: lotacaoEfetiva,
      municipio: _municipioController.text.trim(),
      endereco: _buildFullAddress(),
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim().isEmpty
          ? null
          : _numeroController.text.trim(),
      complemento: _complementoController.text.trim().isEmpty
          ? null
          : _complementoController.text.trim(),
      bairro: _bairroController.text.trim(),
      estado: _estado,
      cep: _cepController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      dataRecebimento: DateTime.now(),
      prazoDias: int.tryParse(_prazoController.text.trim()) ?? 15,
    );

    final ctrl = context.read<DemandaController>();
    final ok = await ctrl.criarDemanda(demanda: demanda, autor: user);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demanda criada com sucesso!'),
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
    final mapCtrl = context.watch<MapController>();
    final anoAtual = DateTime.now().year;
    final isGestor = user?.isGestor ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova Demanda')),
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
                  TextFormField(
                    controller: _numeroSgpController,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [SgpNumeroInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Número SGP (numero/ano)',
                      hintText: '0001234/$anoAtual',
                      helperText: _numeroSgpController.text.contains('/')
                          ? 'Código final: ${AppFormatters.formatNumeroSgpCompleto(_numeroSgpController.text, isGestor ? _lotacao : (user?.lotacao ?? _lotacao))}'
                          : 'Até 7 dígitos / 4 dígitos do ano (ex.: 0001234/$anoAtual)',
                    ),
                    validator: AppFormatters.validateSgpNumero,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descricaoController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Promotoria / Unidade Solicitante',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _seiController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [SeiInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Número SEI',
                      hintText: '00.00.0000.0000000/$anoAtual-00',
                    ),
                    validator: (v) => AppFormatters.validateSei(v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _prioridade,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Prioridade',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'alta',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'normal',
                              child: Text('Normal'),
                            ),
                            DropdownMenuItem(
                              value: 'baixa',
                              child: Text('Baixa'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _prioridade = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _prazoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prazo (dias)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Servidor só cria demanda vinculada ao seu próprio setor;
                  // Coordenador/Administrador escolhe o setor e opcionalmente um servidor.
                  if (isGestor)
                    DropdownButtonFormField<String>(
                      initialValue: _lotacao,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Lotação'),
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
                        if (v != null) setState(() => _lotacao = v);
                      },
                    )
                  else
                    TextFormField(
                      initialValue: AppFormatters.formatLotacao(_lotacao),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Lotação (Setor do Servidor)',
                      ),
                    ),
                  if (isGestor) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _servidorIdSelecionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Servidor Responsável (opcional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text(
                            'Não vincular agora (Demanda do Setor)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ..._servidores.map(
                          (s) => DropdownMenuItem(
                            value: s.uid,
                            child: Text(
                              '${s.nome} (${s.lotacao ?? "Sem lotação"})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _servidorIdSelecionado = v);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Endereço Completo do Local da Perícia',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _cepController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CepInputFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'CEP',
                            hintText: '64000-000',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _estado,
                          decoration: const InputDecoration(labelText: 'UF'),
                          items: AppConstants.estadosBrasileiros
                              .map(
                                (uf) => DropdownMenuItem(
                                  value: uf,
                                  child: Text(uf),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _estado = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _logradouroController,
                    decoration: const InputDecoration(
                      labelText: 'Logradouro (Rua / Avenida)',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o logradouro.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _numeroController,
                          decoration: const InputDecoration(
                            labelText: 'Número (opcional)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _complementoController,
                          decoration: const InputDecoration(
                            labelText: 'Complemento (opcional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bairroController,
                          decoration: const InputDecoration(
                            labelText: 'Bairro',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o bairro.'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _municipioController,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe a cidade.'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: mapCtrl.isLoading ? null : _buscarCoordenadas,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Buscar Coordenadas pelo Endereço'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Coordenadas: ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: demandaCtrl.isLoading ? null : _salvar,
                    child: demandaCtrl.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Cadastrar Demanda'),
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

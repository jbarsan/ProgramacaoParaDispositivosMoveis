import 'package:flutter/material.dart';
import '../database/banco_helper.dart';
import '../models/contato.dart';

/// ============================================================================
/// ABA 2: TELA DE CONSULTA / LISTAGEM (Consultar, Alterar e Excluir)
/// ============================================================================
class AbaConsulta extends StatefulWidget {
  const AbaConsulta({super.key});

  @override
  State<AbaConsulta> createState() => AbaConsultaState();
}

class AbaConsultaState extends State<AbaConsulta> {
  // Lista de contatos carregados da base de dados SQLite
  List<Contato> _contatos = [];
  bool _carregando = true;

  // Controlador para o campo de busca
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    recarregarContatos();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  /// Método público para recarregar a lista (usado também após salvar na outra aba)
  Future<void> recarregarContatos({String? filtro}) async {
    setState(() => _carregando = true);
    final textoBusca = filtro ?? _buscaController.text;
    final resultado = await BancoHelper.consultarContatos(filtro: textoBusca);
    setState(() {
      _contatos = resultado;
      _carregando = false;
    });
  }

  // --------------------------------------------------------------------------
  // EXCLUSÃO COM MENSAGEM DE CONFIRMAÇÃO
  // --------------------------------------------------------------------------
  /// Exibe um AlertDialog para confirmar se o usuário deseja mesmo apagar o contato
  Future<void> _confirmarExclusao(Contato contato) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o contato "${contato.nome}"?\nEsta ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    // Se o usuário confirmou no diálogo, remove do banco e avisa com SnackBar
    if (confirmar == true && contato.id != null) {
      await BancoHelper.excluirContato(contato.id!);
      await recarregarContatos();

      // MENSAGEM DE CONFIRMAÇÃO DE EXCLUSÃO (SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_forever, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Contato "${contato.nome}" foi excluído!')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // ALTERAÇÃO (EDIÇÃO) COM DIÁLOGO E FEEDBACK
  // --------------------------------------------------------------------------
  /// Abre uma caixa modal com campos preenchidos para alterar o contato
  Future<void> _abrirDialogoEdicao(Contato contato) async {
    final TextEditingController editNomeController =
        TextEditingController(text: contato.nome);
    final TextEditingController editEmailController =
        TextEditingController(text: contato.email);
    final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.edit, color: Colors.teal),
              SizedBox(width: 8),
              Text('Alterar Contato'),
            ],
          ),
          content: Form(
            key: editFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: editNomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: editEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe o e-mail';
                      }
                      if (!valor.contains('@')) {
                        return 'Informe um e-mail válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (editFormKey.currentState!.validate()) {
                  // Cria o contato atualizado mantendo o mesmo id
                  final contatoAtualizado = Contato(
                    id: contato.id,
                    nome: editNomeController.text.trim(),
                    email: editEmailController.text.trim(),
                  );

                  // Atualiza no banco
                  await BancoHelper.atualizarContato(contatoAtualizado);
                  await recarregarContatos();

                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();

                  // Mensagem de confirmação de alteração
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.update, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Contato atualizado com sucesso!'),
                          ],
                        ),
                        backgroundColor: Colors.teal.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar Alterações'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de Pesquisa
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _buscaController,
            decoration: InputDecoration(
              hintText: 'Pesquisar por nome...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _buscaController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _buscaController.clear();
                        recarregarContatos();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (texto) {
              recarregarContatos(filtro: texto);
            },
          ),
        ),

        // Lista de Contatos
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _contatos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.contact_page_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _buscaController.text.isEmpty
                                ? 'Nenhum contato cadastrado ainda.\nUse a aba "Cadastrar" para adicionar!'
                                : 'Nenhum contato encontrado com esse nome.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => recarregarContatos(),
                      child: ListView.builder(
                        itemCount: _contatos.length,
                        itemBuilder: (context, index) {
                          final Contato contato = _contatos[index];
                          final String inicial = contato.nome.isNotEmpty
                              ? contato.nome[0].toUpperCase()
                              : '?';

                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade400,
                                foregroundColor: Colors.white,
                                child: Text(
                                  inicial,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                contato.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(contato.email),
                                  Text(
                                    'ID: ${contato.id}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botão Alterar
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Alterar Contato',
                                    onPressed: () => _abrirDialogoEdicao(contato),
                                  ),
                                  // Botão Excluir
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Excluir Contato',
                                    onPressed: () => _confirmarExclusao(contato),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

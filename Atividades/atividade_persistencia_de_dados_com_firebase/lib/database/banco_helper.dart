import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/contato.dart';

/// ============================================================================
/// GERENCIADOR DO BANCO DE DADOS (Cloud Firestore)
/// ============================================================================
/// Esta classe centraliza todas as operações de banco de dados (CRUD) no
/// Cloud Firestore, separando os contatos por usuário autenticado:
/// caminho no Firestore -> usuarios/{uid}/contatos/{contatoId}
///
/// - C (Create) -> Inserir / Armazenar
/// - R (Read)   -> Consultar / Listar
/// - U (Update) -> Alterar / Atualizar
/// - D (Delete) -> Excluir / Deletar
class BancoHelper {
  // Instância do Cloud Firestore
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instância do FirebaseAuth para identificar o usuário atualmente logado
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Nomes das coleções utilizadas no Cloud Firestore
  static const String colecaoUsuarios = 'usuarios';
  static const String colecaoContatos = 'contatos';

  /// Retorna a referência da subcoleção 'contatos' pertencente ao usuário logado.
  /// Caso não haja usuário autenticado, lança uma exceção.
  static CollectionReference<Map<String, dynamic>> get _colecaoContatosUsuario {
    final User? usuario = _auth.currentUser;
    if (usuario == null) {
      throw StateError(
        'Usuário não autenticado. Faça login para acessar seus contatos.',
      );
    }

    return _firestore
        .collection(colecaoUsuarios)
        .doc(usuario.uid)
        .collection(colecaoContatos);
  }

  // --------------------------------------------------------------------------
  // 1. CREATE: INSERIR (Armazenar)
  // --------------------------------------------------------------------------
  /// Insere um novo documento de contato na coleção do usuário logado
  /// e retorna o 'id' (String) gerado automaticamente pelo Firestore.
  static Future<String> inserirContato(Contato contato) async {
    final DocumentReference<Map<String, dynamic>> docRef =
        await _colecaoContatosUsuario.add(contato.toMap());
    return docRef.id;
  }

  // --------------------------------------------------------------------------
  // 2. READ: CONSULTAR (Listar com suporte a filtro)
  // --------------------------------------------------------------------------
  /// Consulta todos os contatos do usuário logado ordenados por nome.
  /// Se passar um [filtro], filtra os contatos que contenham o texto no nome.
  static Future<List<Contato>> consultarContatos({String filtro = ''}) async {
    // Busca os documentos ordenados alfabeticamente pelo campo 'nome'
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _colecaoContatosUsuario.orderBy('nome').get();

    // Converte cada documento do Firestore em um objeto Contato
    final List<Contato> contatos = snapshot.docs
        .map((doc) => Contato.fromMap(doc.data(), id: doc.id))
        .toList();

    // Se houver texto de busca, aplica o filtro (sem diferenciar maiúsculas/minúsculas)
    final String termo = filtro.trim().toLowerCase();
    if (termo.isEmpty) {
      return contatos;
    }

    return contatos
        .where((contato) => contato.nome.toLowerCase().contains(termo))
        .toList();
  }

  // --------------------------------------------------------------------------
  // 3. UPDATE: ALTERAR (Atualizar)
  // --------------------------------------------------------------------------
  /// Atualiza os dados de um contato existente no Firestore com base no seu 'id'.
  static Future<void> atualizarContato(Contato contato) async {
    if (contato.id == null || contato.id!.isEmpty) {
      throw ArgumentError('O contato precisa ter um id para ser atualizado.');
    }

    await _colecaoContatosUsuario.doc(contato.id).update(contato.toMap());
  }

  // --------------------------------------------------------------------------
  // 4. DELETE: EXCLUIR (Deletar)
  // --------------------------------------------------------------------------
  /// Remove um documento de contato do Firestore através do seu 'id'.
  static Future<void> excluirContato(String id) async {
    await _colecaoContatosUsuario.doc(id).delete();
  }

  // --------------------------------------------------------------------------
  // 5. STREAM: QUANTIDADE DE CONTATOS SALVOS (Tempo Real)
  // --------------------------------------------------------------------------
  /// Retorna um [Stream] com a quantidade atual de contatos do usuário logado.
  /// Atualiza automaticamente sempre que um contato é adicionado ou excluído.
  static Stream<int> observarQuantidadeContatos() {
    return _colecaoContatosUsuario
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/contato.dart';

/// ============================================================================
/// GERENCIADOR DO BANCO DE DADOS (SQLite com SqFlite)
/// ============================================================================
/// Esta classe centraliza todas as operações de banco de dados (CRUD):
/// - C (Create) -> Inserir / Armazenar
/// - R (Read)   -> Consultar / Listar
/// - U (Update) -> Alterar / Atualizar
/// - D (Delete) -> Excluir / Deletar
class BancoHelper {
  // Nome do arquivo onde os dados serão salvos no aparelho
  static const String _nomeBanco = 'banco.db';

  // Nome da tabela de contatos
  static const String tabelaContatos = 'contatos';

  // Guarda uma única conexão aberta com o banco na memória (Singleton)
  static Database? _banco;

  /// Retorna a conexão com o banco. Se ainda não estiver aberto, abre automaticamente.
  static Future<Database> get banco async {
    if (_banco != null) return _banco!;
    _banco = await _abrirBanco();
    return _banco!;
  }

  /// Método privado para criar e abrir o banco de dados.
  static Future<Database> _abrirBanco() async {
    // 1. Obtém o caminho padrão seguro para salvar bancos no dispositivo
    final String caminhoPasta = await getDatabasesPath();

    // 2. Junta o caminho da pasta com o nome do arquivo 'banco.db'
    final String caminhoCompleto = p.join(caminhoPasta, _nomeBanco);

    // 3. Abre o banco na versão 1.
    // O onCreate só executa na primeira vez que o banco é criado.
    return await openDatabase(
      caminhoCompleto,
      version: 1,
      onCreate: (Database db, int versao) async {
        // Comando SQL DDL para criar a tabela com os 3 campos exigidos:
        // 1. id (inteiro, chave primária e autoincremento)
        // 2. nome (texto obrigatório)
        // 3. email (texto obrigatório)
        const String sql = '''
          CREATE TABLE $tabelaContatos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            email TEXT NOT NULL
          )
        ''';
        await db.execute(sql);
      },
    );
  }

  // --------------------------------------------------------------------------
  // 1. CREATE: INSERIR (Armazenar)
  // --------------------------------------------------------------------------
  /// Insere um novo contato no banco e retorna o 'id' gerado.
  static Future<int> inserirContato(Contato contato) async {
    final Database db = await banco;

    // Como o id é autoincremento, passamos apenas nome e email
    final Map<String, dynamic> dados = {
      'nome': contato.nome,
      'email': contato.email,
    };

    return await db.insert(tabelaContatos, dados);
  }

  // --------------------------------------------------------------------------
  // 2. READ: CONSULTAR (Listar com suporte a filtro)
  // --------------------------------------------------------------------------
  /// Consulta todos os contatos. Se passar um [filtro], busca contatos que
  /// contenham aquele texto no nome.
  static Future<List<Contato>> consultarContatos({String filtro = ''}) async {
    final Database db = await banco;
    List<Map<String, dynamic>> resultado;

    if (filtro.trim().isEmpty) {
      // Retorna todos os contatos em ordem alfabética por nome
      resultado = await db.query(tabelaContatos, orderBy: 'nome ASC');
    } else {
      // Retorna apenas contatos que contenham o texto pesquisado
      resultado = await db.query(
        tabelaContatos,
        where: 'nome LIKE ?',
        whereArgs: ['%$filtro%'], // Parâmetro seguro contra SQL Injection
        orderBy: 'nome ASC',
      );
    }

    // Converte a lista de Maps do SQLite em uma lista de objetos Contato
    return resultado.map((map) => Contato.fromMap(map)).toList();
  }

  // --------------------------------------------------------------------------
  // 3. UPDATE: ALTERAR (Atualizar)
  // --------------------------------------------------------------------------
  /// Atualiza os dados de um contato existente com base no seu 'id'.
  /// Retorna a quantidade de registros alterados.
  static Future<int> atualizarContato(Contato contato) async {
    final Database db = await banco;

    return await db.update(
      tabelaContatos,
      contato.toMap(),
      where: 'id = ?',
      whereArgs: [contato.id],
    );
  }

  // --------------------------------------------------------------------------
  // 4. DELETE: EXCLUIR (Deletar)
  // --------------------------------------------------------------------------
  /// Remove um contato do banco através do seu 'id'.
  /// Retorna a quantidade de registros removidos.
  static Future<int> excluirContato(int id) async {
    final Database db = await banco;

    return await db.delete(
      tabelaContatos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

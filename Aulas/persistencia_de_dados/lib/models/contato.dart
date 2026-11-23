/// ============================================================================
/// MODELO DE DADOS: CONTATO
/// ============================================================================
/// Esta classe representa a estrutura da tabela 'contatos' no banco de dados SQLite:
/// 1. id: Identificador único gerado automaticamente pelo banco (chave primária)
/// 2. nome: Nome do contato (Texto)
/// 3. email: E-mail do contato (Texto)
class Contato {
  final int? id;
  final String nome;
  final String email;

  Contato({
    this.id,
    required this.nome,
    required this.email,
  });

  /// Converte o objeto [Contato] para um [Map] (formato chave/valor).
  /// O SqFlite exige esse formato para inserir e atualizar registros no SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
    };
  }

  /// Construtor que cria um objeto [Contato] a partir de um [Map] vindo do banco.
  /// Quando o SQLite faz um SELECT, ele retorna linhas no formato Map.
  factory Contato.fromMap(Map<String, dynamic> map) {
    return Contato(
      id: map['id'] as int?,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }
}

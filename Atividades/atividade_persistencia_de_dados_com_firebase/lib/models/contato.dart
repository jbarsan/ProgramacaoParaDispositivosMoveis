// ============================================================================
// MODELO DE DADOS: CONTATO
// ============================================================================
// Esta classe representa a estrutura de um documento na coleção 'contatos'
// (usuarios/{uid}/contatos) no Cloud Firestore:
// 1. id: Identificador único do documento gerado automaticamente pelo Firestore
// 2. nome: Nome do contato (Texto)
// 3. email: E-mail do contato (Texto)
class Contato {
  // No Cloud Firestore, o ID do documento é uma String (opcional antes de salvar)
  final String? id;
  final String nome;
  final String email;

  Contato({this.id, required this.nome, required this.email});

  // Converte o objeto [Contato] para um [Map] (formato chave/valor).
  // O Cloud Firestore utiliza esse formato para gravar e atualizar documentos.
  // O campo 'id' não precisa ser enviado no corpo porque já é o ID do documento.
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'email': email};
  }

  // Construtor que cria um objeto [Contato] a partir de um [Map] vindo do Firestore.
  // Recebe opcionalmente o [id] do documento retornado pelo snapshot (`doc.id`).
  factory Contato.fromMap(Map<String, dynamic> map, {String? id}) {
    return Contato(
      id: id ?? map['id'] as String?,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }
}

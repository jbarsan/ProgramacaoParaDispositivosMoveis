import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('Test SQLite FFI', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE contatos (id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT, email TEXT);');
    final id = await db.insert('contatos', {'nome': 'Carlos', 'email': 'carlos@email.com'});
    expect(id, 1);
    final lista = await db.query('contatos');
    expect(lista.length, 1);
    expect(lista.first['nome'], 'Carlos');
    await db.close();
  });
}

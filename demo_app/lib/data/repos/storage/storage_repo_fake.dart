// In-memory stand-in for StorageRepo.
//
// Production persists the session to the platform secure store. The demo keeps
// it in a plain map: nothing here is sensitive, and a page reload is expected
// to start the demo over from its seeded state.

import 'package:hrms_demo/data/repos/storage/storage_repo.dart';

class FakeStorageRepo implements StorageRepo {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  Future<void> write(String key, dynamic value) async {
    _values[key] = value;
  }

  @override
  Future<dynamic> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

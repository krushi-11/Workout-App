import 'package:hive/hive.dart';

//A mock implementation for hive box class for testing purpose
//making it useful for unit tests without requiring actual disk storage
class CustomMockBox<T> implements Box<T> {
  //Internal storage using a map to verify hive's key-value storage
  final Map<dynamic, T> _store = {};

  //returns all values stored in the mock box
  @override
  Iterable<T> get values => _store.values;

  //adds a value to the mock box with an auto generated key
  @override
  Future<int> add(T value) async {
    final key = _store.length;
    _store[key] = value;
    return key;
  }

  //stores the value with key
  @override
  Future<void> put(dynamic key, T value) async {
    _store[key] = value;
  }

  //retrieves a value by its key
  @override
  T? get(dynamic key, {T? defaultValue}) => _store[key] ?? defaultValue;

  //remove a single entry from mock box by its key
  @override
  Future<void> delete(dynamic key) async {
    _store.remove(key);
  }

  //remove multiple entries from the mock box with provided keys
  @override
  Future<void> deleteAll(Iterable keys) async {
    for (var key in keys) {
      _store.remove(key);
    }
  }

  //check if the key exists in mock box
  @override
  bool containsKey(dynamic key) => _store.containsKey(key);

  //return the number of entries in the box
  @override
  int get length => _store.length;

  //returns true if there are no entries in box
  @override
  bool get isEmpty => _store.isEmpty;

  //returns true if the box contains at least one entry
  @override
  bool get isNotEmpty => _store.isNotEmpty;

  //return all the keys in the mock box
  @override
  Iterable<dynamic> get keys => _store.keys;

  // handles unimplemented methods from the box interface
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
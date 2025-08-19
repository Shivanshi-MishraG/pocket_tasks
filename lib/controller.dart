import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'storage.dart';

enum TaskFilter { all, active, done }

class TasksController extends ChangeNotifier {
  final TaskStorage storage;
  final _uuid = const Uuid();

  List<Task> _tasks = [];
  String _query = '';
  TaskFilter _filter = TaskFilter.all;

  // for undo
  List<Task>? _snapshotBeforeAction;

  TasksController(this.storage);

  List<Task> get tasks => List.unmodifiable(_tasks);
  String get query => _query;
  TaskFilter get filter => _filter;

  int get totalCount => _tasks.length;
  int get doneCount => _tasks.where((t) => t.done).length;

  List<Task> get filtered {
    var list = _tasks;
    if (_query.isNotEmpty) {
      list = list.where((t) => t.title.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    if (_filter == TaskFilter.active) {
      list = list.where((t) => !t.done).toList();
    } else if (_filter == TaskFilter.done) {
      list = list.where((t) => t.done).toList();
    }
    return list;
  }

  Future<void> init() async {
    _tasks = await storage.load();
    notifyListeners();
  }

  Future<void> persist() async {
    await storage.save(_tasks);
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(TaskFilter f) {
    _filter = f;
    notifyListeners();
  }

  void addTask(String title) {
    final t = Task(
      id: _uuid.v4(),
      title: title.trim(),
      done: false,
      createdAt: DateTime.now(),
    );
    _snapshot();
    _tasks.insert(0, t);
    notifyListeners();
    persist();
  }

  void toggleTask(String id) {
    _snapshot();
    _tasks = _tasks
        .map((t) => t.id == id ? t.copyWith(done: !t.done) : t)
        .toList(growable: false);
    notifyListeners();
    persist();
  }

  void deleteTask(String id) {
    _snapshot();
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    persist();
  }

  void clearDone() {
    _snapshot();
    _tasks.removeWhere((t) => t.done);
    notifyListeners();
    persist();
  }

  // Undo last change (if any)
  bool undo() {
    if (_snapshotBeforeAction == null) return false;
    _tasks = _snapshotBeforeAction!;
    _snapshotBeforeAction = null;
    notifyListeners();
    return true;
  }

  void _snapshot() {
    _snapshotBeforeAction = List<Task>.from(_tasks);
  }
}

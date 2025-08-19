import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_tasks/controller.dart';
import 'package:pocket_tasks/models.dart';
import 'package:pocket_tasks/storage.dart';

class _FakeStorage extends TaskStorage {
  List<Task> _db = [];
  @override
  Future<List<Task>> load() async => _db;
  @override
  Future<void> save(List<Task> tasks) async {
    _db = tasks;
  }
}

void main() {
  test('search + filter pipeline', () async {
    final ctrl = TasksController(_FakeStorage());
    ctrl
      ..addListener(() {})
      ..addTask('Buy milk')
      ..addTask('Read book')
      ..addTask('Milk chocolate')
      ..toggleTask(ctrl.tasks[0].id); // mark the latest as done

    // All + query "milk"
    ctrl.setFilter(TaskFilter.all);
    ctrl.setQuery('milk');
    expect(ctrl.filtered.map((t) => t.title).toList(), ['Milk chocolate', 'Buy milk']);

    // Active + query "milk"
    ctrl.setFilter(TaskFilter.active);
    expect(ctrl.filtered.map((t) => t.title).toList(), ['Buy milk']);

    // Done only
    ctrl.setFilter(TaskFilter.done);
    ctrl.setQuery(''); // clear query
    expect(ctrl.filtered.length, 1);

    // Undo restores previous state
    final before = ctrl.tasks.length;
    ctrl.deleteTask(ctrl.tasks.first.id);
    expect(ctrl.tasks.length, before - 1);
    final ok = ctrl.undo();
    expect(ok, true);
    expect(ctrl.tasks.length, before);
  });
}

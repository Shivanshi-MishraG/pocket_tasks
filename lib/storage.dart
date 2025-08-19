import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class TaskStorage {
  static const _key = 'pocket_tasks_v1';

  Future<List<Task>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null || s.isEmpty) return [];
    try {
      return Task.listFromJsonString(s);
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Task.listToJsonString(tasks).isEmpty ? _key : _key, Task.listToJsonString(tasks));
  }
}

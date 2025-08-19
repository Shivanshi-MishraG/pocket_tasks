import 'package:flutter/material.dart';
import 'controller.dart';
import 'debouncer.dart';
import 'progress_ring.dart';
import 'storage.dart';
import 'task_item.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PocketTasksApp());
}

class PocketTasksApp extends StatefulWidget {
  const PocketTasksApp({super.key});
  @override
  State<PocketTasksApp> createState() => _PocketTasksAppState();
}

class _PocketTasksAppState extends State<PocketTasksApp> {
  final controller = TasksController(TaskStorage());

  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketTasks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8A5BFF),
          surface: Colors.transparent,
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => HomePage(controller: controller),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final TasksController controller;
  const HomePage({super.key, required this.controller});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(const Duration(milliseconds: 300));
    _searchCtrl.addListener(() {
      _debouncer(() => widget.controller.setQuery(_searchCtrl.text));
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _titleCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action:
        onUndo == null ? null : SnackBarAction(label: 'UNDO', onPressed: onUndo),
      ),
    ).closed.whenComplete(() => widget.controller.persist());
  }

  void _addTask() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      widget.controller.addTask(_titleCtrl.text.trim());
      print("Task added: ${_titleCtrl.text.trim()}");
      print("Total tasks: ${widget.controller.filtered.length}");
      _titleCtrl.clear();
    });
    _snack('Task added', onUndo: () {
      if (widget.controller.undo()) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Undone')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final tasks = c.filtered;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C003E), Color(0xFF160028)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProgressRing(done: c.doneCount, total: c.totalCount, size: 52),
                    const SizedBox(width: 12),
                    const Text(
                      'PocketTasks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Clear done',
                      icon: const Icon(Icons.cleaning_services_outlined,
                          color: Colors.white70),
                      onPressed: c.doneCount == 0
                          ? null
                          : () {
                        c.clearDone();
                        _snack('Cleared completed', onUndo: () {
                          if (c.undo()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Undone')));
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                //Add task row
                Row(
                  children: [
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _titleCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'Add Task'),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _addTask(),
                          validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A5BFF),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Searchbar
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter chips
                Wrap(
                  spacing: 10,
                  children: [
                    _chip('All', c.filter == TaskFilter.all,
                            () => c.setFilter(TaskFilter.all)),
                    _chip('Active', c.filter == TaskFilter.active,
                            () => c.setFilter(TaskFilter.active)),
                    _chip('Done', c.filter == TaskFilter.done,
                            () => c.setFilter(TaskFilter.done)),
                  ],
                ),
                const SizedBox(height: 12),

                // list
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                      child:
                      Text('No tasks', style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return TaskItem(
                        task: t,
                        onToggle: () {
                          c.toggleTask(t.id);
                          _snack(t.done ? 'Marked active' : 'Marked done',
                              onUndo: () {
                                if (c.undo()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Undone')));
                                }
                              });
                        },
                        onDismissed: (_) {
                          c.deleteTask(t.id);
                          _snack('Task deleted', onUndo: () {
                            if (c.undo()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Undone')));
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF8A5BFF),
      backgroundColor: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

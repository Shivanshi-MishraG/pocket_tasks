import 'package:flutter/material.dart';
import 'models.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final DismissDirectionCallback onDismissed;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.white10,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white70),
      ),
      onDismissed: onDismissed,
      child: ListTile(
        onTap: onToggle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Checkbox(
          value: task.done,
          onChanged: (_) => onToggle(),
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.white54, width: 1.5),
          activeColor: Colors.greenAccent,
          checkColor: Colors.black,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: Colors.white,
            decoration: task.done ? TextDecoration.lineThrough : null,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

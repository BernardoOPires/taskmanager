import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';

enum TaskFilter { all, completed, pending }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _titleController = TextEditingController();

  List<Task> _tasks = [];
  String _newPriority = 'medium';
  TaskFilter _filter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseService.instance.readAll();
    setState(() => _tasks = tasks);
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final task = Task(title: title, priority: _newPriority);
    await DatabaseService.instance.create(task);
    _titleController.clear();
    await _loadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    await _loadTasks();
  }

  Future<void> _deleteTask(String id) async {
    await DatabaseService.instance.delete(id);
    await _loadTasks();
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      case 'medium':
      default:
        return Colors.orange;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'high':
        return 'Alta';
      case 'low':
        return 'Baixa';
      case 'medium':
      default:
        return 'Média';
    }
  }

  List<Task> get _filtered {
    switch (_filter) {
      case TaskFilter.completed:
        return _tasks.where((t) => t.completed).toList();
      case TaskFilter.pending:
        return _tasks.where((t) => !t.completed).toList();
      case TaskFilter.all:
      default:
        return _tasks;
    }
  }

  String get _filterLabel {
    switch (_filter) {
      case TaskFilter.completed:
        return 'Completas';
      case TaskFilter.pending:
        return 'Pendentes';
      case TaskFilter.all:
      default:
        return 'Todas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksToShow = _filtered;

    final total = _tasks.length;
    final done = _tasks.where((t) => t.completed).length;
    final pending = total - done;

    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Tarefas — $_filterLabel'),
        actions: [
          PopupMenuButton<TaskFilter>(
            initialValue: _filter,
            onSelected: (f) => setState(() => _filter = f),
            itemBuilder: (context) => const [
              PopupMenuItem(value: TaskFilter.all, child: Text('Todas')),
              PopupMenuItem(
                value: TaskFilter.completed,
                child: Text('Completas'),
              ),
              PopupMenuItem(
                value: TaskFilter.pending,
                child: Text('Pendentes'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _CounterChip(
                  label: 'Total',
                  value: total,
                  selected: _filter == TaskFilter.all,
                  onTap: () => setState(() => _filter = TaskFilter.all),
                ),
                _CounterChip(
                  label: 'Completas',
                  value: done,
                  selected: _filter == TaskFilter.completed,
                  onTap: () => setState(() => _filter = TaskFilter.completed),
                ),
                _CounterChip(
                  label: 'Pendentes',
                  value: pending,
                  selected: _filter == TaskFilter.pending,
                  onTap: () => setState(() => _filter = TaskFilter.pending),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Nova tarefa...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _newPriority,
                    isDense: true,
                    borderRadius: BorderRadius.circular(10),
                    onChanged: (v) {
                      if (v != null) setState(() => _newPriority = v);
                    },
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Baixa')),
                      DropdownMenuItem(value: 'medium', child: Text('Média')),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: tasksToShow.isEmpty
                ? const Center(child: Text('Nenhuma tarefa'))
                : ListView.builder(
                    itemCount: tasksToShow.length,
                    itemBuilder: (context, index) {
                      final task = tasksToShow[index];
                      final color = _priorityColor(task.priority);

                      return ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -2,
                        ),
                        leading: Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: task.completed,
                            onChanged: (_) => _toggleTask(task),
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: color.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                _priorityLabel(task.priority),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Criada em ${task.createdAt.toLocal().toString().substring(0, 16)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTask(task.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _CounterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
        : null;
    final border = selected
        ? BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          )
        : BorderSide(color: Colors.grey.withOpacity(0.4));

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.fromBorderSide(border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.countertops, size: 14),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

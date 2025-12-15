import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_repository.dart';
import '../services/sensor_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import 'task_form_screen.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initConnectivity();
    _setupShakeDetection();
  }

  void _initConnectivity() {
    ConnectivityService.instance.stream.listen((online) async {
      if (!mounted) return;

      if (online) {
        await SyncService.instance.sync();

        final freshTasks = await TaskRepository().readAll();

        setState(() {
          _isOnline = true;
          _tasks = freshTasks.map((t) => t.copyWith(isSynced: true)).toList();
        });

        return;
      }

      final tasks = await TaskRepository().readAll();

      setState(() {
        _isOnline = false;
        _tasks = tasks;
      });
    });
  }

  void _setupShakeDetection() {
    SensorService.instance.startShakeDetection(_showShakeDialog);
  }

  @override
  void dispose() {
    SensorService.instance.stop();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await TaskRepository().readAll();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _toggle(Task task) async {
    final updated = task.copyWith(
      completed: !task.completed,
      completedAt: !task.completed ? DateTime.now() : null,
      completedBy: !task.completed ? 'manual' : null,
      isSynced: false,
    );

    await TaskRepository().update(updated);
    await _loadTasks();
  }

  void _showShakeDialog() {
    final pending = _tasks.where((t) => !t.completed).toList();
    if (pending.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Shake detectado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: pending.take(3).map((t) {
            return ListTile(
              title: Text(t.title),
              trailing: IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () async {
                  final updated = t.copyWith(
                    completed: true,
                    completedAt: DateTime.now(),
                    completedBy: 'shake',
                    isSynced: false,
                  );
                  await TaskRepository().update(updated);
                  Navigator.pop(context);
                  await _loadTasks();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _toggleOnlineManually() async {
    final newStatus = !_isOnline;

    setState(() {
      _isOnline = newStatus;
    });

    if (newStatus) {
      await SyncService.instance.sync();
      final tasks = await TaskRepository().readAll();
      if (!mounted) return;

      setState(() {
        _tasks = tasks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOnline ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: _toggleOnlineManually,
              icon: Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
              ),
              label: Text(
                _isOnline ? 'Online' : 'Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: _tasks.isEmpty
                        ? const Center(child: Text('Nenhuma tarefa'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _tasks.length,
                            itemBuilder: (_, i) {
                              final t = _tasks[i];
                              return TaskCard(
                                task: t,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskFormScreen(task: t),
                                    ),
                                  );
                                  if (result == true) await _loadTasks();
                                },
                                onDelete: () async {
                                  await TaskRepository().delete(t);
                                  await _loadTasks();
                                },
                                onCheckboxChanged: (_) => _toggle(t),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          if (result == true) await _loadTasks();
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
      ),
    );
  }
}

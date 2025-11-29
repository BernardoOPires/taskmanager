import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_repository.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../services/camera_service.dart';
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
  String _filter = 'all';
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadTasks();
    _setupShakeDetection();
  }

  void _initConnectivity() async {
    _isOnline = await ConnectivityService.instance.check();
    setState(() {});

    ConnectivityService.instance.onStatusChange.listen((online) async {
      if (!mounted) return;

      setState(() => _isOnline = online);

      if (online) {
        await SyncService.instance.sync();
        await _loadTasks();
      }
    });
  }

  @override
  void dispose() {
    SensorService.instance.stop();
    super.dispose();
  }

  void _setupShakeDetection() {
    SensorService.instance.startShakeDetection(() {
      _showShakeDialog();
    });
  }

  void _showShakeDialog() {
    final pending = _tasks.where((t) => !t.completed).toList();

    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma tarefa pendente'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

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
                onPressed: () => _completeShake(t),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeShake(Task task) async {
    final updated = task.copyWith(
      completed: true,
      completedAt: DateTime.now(),
      completedBy: 'shake',
      isSynced: false,
    );

    await TaskRepository().update(updated);
    Navigator.pop(context);
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await TaskRepository().readAll();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  List<Task> get _filtered {
    switch (_filter) {
      case 'pending':
        return _tasks.where((t) => !t.completed).toList();
      case 'completed':
        return _tasks.where((t) => t.completed).toList();
      case 'nearby':
        return _tasks;
      default:
        return _tasks;
    }
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: _isOnline ? Colors.green : Colors.red,
            child: Text(
              _isOnline ? 'Online' : 'Offline',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: filtered.isEmpty
                        ? const Center(child: Text('Nenhuma tarefa'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
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

import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/task.dart';
import 'api_service.dart';
import 'database_service.dart';

class TaskRepository {
  final db = DatabaseService.instance;
  final api = ApiService.instance;

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi);
  }

  Future<List<Task>> readAll() async {
    return await db.readAll();
  }

  Future<Task> create(Task task) async {
    final local = await db.createLocal(task);
    await db.enqueue('create', local);

    if (await _isOnline()) {
      final newId = await api.createRemote(local.toMap());
      await db.replaceLocalIdWithServerId(local.id!, newId);
    }

    return local;
  }

  Future<void> update(Task task) async {
    await db.updateLocal(task);
    await db.enqueue('update', task);

    if (await _isOnline() && task.isSynced) {
      await api.upsertRemote(task.toMap());
    }
  }

  Future<void> delete(Task task) async {
    await db.deleteLocal(task.id!);
    await db.enqueue('delete', task);

    if (await _isOnline() && task.isSynced) {
      await api.deleteRemote(task.id!);
    }
  }

  Future<List<Task>> getTasksNearLocation({
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    return await db.getTasksNearLocation(
      latitude: latitude,
      longitude: longitude,
      radiusInMeters: radiusInMeters,
    );
  }
}

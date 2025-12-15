import '../models/task.dart';
import 'database_service.dart';

class TaskRepository {
  final db = DatabaseService.instance;

  Future<List<Task>> readAll() async {
    return await db.readAll();
  }

  Future<Task> create(Task task) async {
    final local = await db.createLocal(task);
    await db.enqueue('create', local);
    return local;
  }

  Future<void> update(Task task) async {
    final updated = task.copyWith(
      lastModifiedAt: DateTime.now(),
      isSynced: false,
    );

    await db.updateLocal(updated);
    await db.enqueue('update', updated);
  }

  Future<void> delete(Task task) async {
    await db.deleteLocal(task.id!);
    await db.enqueue('delete', task);
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

import '../models/task.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  bool _running = false;

  Future<void> sync() async {
    if (_running) return;
    _running = true;

    try {
      final queue = await DatabaseService.instance.getQueue();

      for (final item in queue) {
        final queueId = item['id'] as int;
        final taskId = item['task_id'] as int;
        final operation = item['operation'] as String;

        if (operation == 'delete') {
          await ApiService.instance.deleteRemote(taskId);
          await DatabaseService.instance.removeFromQueue(queueId);
          continue;
        }

        final localTasks = await DatabaseService.instance.readAll();
        final localTask = localTasks.firstWhere((t) => t.id == taskId);

        final remote = await ApiService.instance.fetchRemote(taskId);

        if (remote == null) {
          final created = await ApiService.instance.upsertRemote(
            localTask.toMap()..remove('id'),
          );

          final serverId = created['id'] as int;

          await DatabaseService.instance.replaceLocalIdWithServerId(
            localTask.id!,
            serverId,
          );

          await DatabaseService.instance.removeFromQueue(queueId);
          continue;
        }

        final remoteModified = remote['last_modified_at'] as int;
        final localModified = localTask.lastModifiedAt.millisecondsSinceEpoch;

        if (remoteModified > localModified) {
          final taskFromServer = Task.fromMap(remote).copyWith(isSynced: true);

          await DatabaseService.instance.updateLocal(taskFromServer);
        } else {
          await ApiService.instance.upsertRemote(localTask.toMap());

          await DatabaseService.instance.updateLocal(
            localTask.copyWith(isSynced: true, lastModifiedAt: DateTime.now()),
          );
        }

        await DatabaseService.instance.removeFromQueue(queueId);
      }
    } finally {
      _running = false;
    }
  }
}

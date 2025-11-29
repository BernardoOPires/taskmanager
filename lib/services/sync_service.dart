import 'dart:convert';
import 'package:task_manager/services/api_service.dart';
import 'package:task_manager/services/database_service.dart';
import '../models/task.dart';

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
        final id = item['id'];
        final taskId = item['task_id'];
        final op = item['operation'];
        final payloadString = item['payload'];
        final payload = jsonDecode(payloadString);

        if (op == 'delete') {
          await ApiService.instance.deleteRemote(taskId);
          await DatabaseService.instance.removeFromQueue(id);
          continue;
        }

        final localModified =
            payload['last_modified_at'] ??
            DateTime.now().millisecondsSinceEpoch;

        final remote = await ApiService.instance.fetchRemote(taskId);

        if (remote == null) {
          await ApiService.instance.upsertRemote(payload);
          await DatabaseService.instance.markAsSynced(taskId);
          await DatabaseService.instance.removeFromQueue(id);
          continue;
        }

        final remoteModified = remote['last_modified_at'];

        if (remoteModified > localModified) {
          final task = Task.fromMap(remote);
          await DatabaseService.instance.updateLocal(task);
          await DatabaseService.instance.markAsSynced(taskId);
          await DatabaseService.instance.removeFromQueue(id);
        } else {
          await ApiService.instance.upsertRemote(payload);
          await DatabaseService.instance.markAsSynced(taskId);
          await DatabaseService.instance.removeFromQueue(id);
        }
      }
    } finally {
      _running = false;
    }
  }
}

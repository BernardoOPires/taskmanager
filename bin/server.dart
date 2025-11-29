import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

void main() async {
  final tasks = <int, Map<String, dynamic>>{};
  var nextId = 1;

  final router = Router();

  router.get('/tasks', (Request req) {
    return Response.ok(
      jsonEncode(tasks.values.toList()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/tasks/<id>', (Request req, String id) {
    final taskId = int.tryParse(id);
    if (taskId == null || !tasks.containsKey(taskId)) {
      return Response.notFound('Not found');
    }
    return Response.ok(
      jsonEncode(tasks[taskId]),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.post('/tasks', (Request req) async {
    final data = jsonDecode(await req.readAsString());
    data['id'] = nextId++;
    tasks[data['id']] = data;
    return Response.ok(
      jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.put('/tasks/<id>', (Request req, String id) async {
    final taskId = int.tryParse(id);
    if (taskId == null) return Response.notFound('Not found');

    final data = jsonDecode(await req.readAsString());
    data['id'] = taskId;
    tasks[taskId] = data;

    return Response.ok(
      jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.delete('/tasks/<id>', (Request req, String id) {
    final taskId = int.tryParse(id);
    if (taskId == null || !tasks.containsKey(taskId)) {
      return Response.notFound('Not found');
    }
    tasks.remove(taskId);
    return Response.ok('Deleted');
  });

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 3000);
  print('Server running at http://${server.address.host}:${server.port}');
}

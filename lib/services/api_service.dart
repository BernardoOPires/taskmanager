import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = 'http://10.0.2.2:3000/tasks';

  Future<Map<String, dynamic>?> fetchRemote(int id) async {
    final uri = Uri.parse('$baseUrl/$id');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 404) return null;
    throw Exception('Erro buscando remoto');
  }

  Future<Map<String, dynamic>> upsertRemote(
    Map<String, dynamic> payload,
  ) async {
    final id = payload['id'];
    http.Response response;

    if (id == null) {
      response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } else {
      response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Erro sincronizando remoto');
  }

  Future<void> deleteRemote(int id) async {
    final uri = Uri.parse('$baseUrl/$id');
    final response = await http.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro deletando remoto');
    }
  }
}

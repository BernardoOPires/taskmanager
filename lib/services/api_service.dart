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
    return null;
  }

  Future<int> createRemote(Map<String, dynamic> payload) async {
    final uri = Uri.parse(baseUrl);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] as int;
    }

    throw Exception('Erro criando remoto');
  }

  Future<void> upsertRemote(Map<String, dynamic> payload) async {
    final id = payload['id'];
    final uri = Uri.parse('$baseUrl/$id');

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro sincronizando remoto');
    }
  }

  Future<void> deleteRemote(int id) async {
    final uri = Uri.parse('$baseUrl/$id');
    final response = await http.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro deletando remoto');
    }
  }
}

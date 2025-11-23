import 'dart:convert';
import 'package:dart_amqp/dart_amqp.dart';

class RabbitMQService {
  RabbitMQService._();
  static final RabbitMQService instance = RabbitMQService._();

  Client? _client;
  Exchange? _exchange;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;

    final settings = ConnectionSettings(
      host: 'kebnekaise.lmq.cloudamqp.com',
      port: 5672,
      virtualHost: 'adhaedye',
      authProvider: const PlainAuthenticator(
        'adhaedye',
        '15I1N8Mt5uIkc9TU0eTDX4PW1mPNO5LB',
      ),
    );

    _client = Client(settings: settings);

    final channel = await _client!.channel();
    _exchange = await channel.exchange(
      'shopping_events',
      ExchangeType.TOPIC,
      durable: true,
    );

    _initialized = true;
  }

  Future<void> publishCheckout({
    required String listId,
    required String userEmail,
  }) async {
    await _init();

    final payload = jsonEncode({
      'type': 'list.checkout.completed',
      'occurredAt': DateTime.now().toIso8601String(),
      'data': {
        'listId': listId,
        'userEmail': userEmail,
        'items': [
          {'name': 'Item A', 'qty': 1, 'price': 10.0},
          {'name': 'Item B', 'qty': 2, 'price': 5.5},
        ],
      },
    });

    _exchange!.publish(
      payload,
      'list.checkout.completed',
      properties: MessageProperties.persistentMessage(),
    );
  }

  Future<void> dispose() async {
    await _client?.close();
    _client = null;
    _exchange = null;
    _initialized = false;
  }
}

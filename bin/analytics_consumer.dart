import 'dart:async';
import 'package:dart_amqp/dart_amqp.dart';

const String amqpHost = 'kebnekaise.lmq.cloudamqp.com';
const int amqpPort = 5672;
const String amqpUser = 'adhaedye';
const String amqpPassword = '15I1N8Mt5uIkc9TU0eTDX4PW1mPNO5LB';
const String amqpVHost = 'adhaedye';

ConnectionSettings buildSettings() {
  return ConnectionSettings(
    host: amqpHost,
    port: amqpPort,
    virtualHost: amqpVHost,
    authProvider: const PlainAuthenticator(amqpUser, amqpPassword),
  );
}

Future<void> main() async {
  final client = Client(settings: buildSettings());

  final channel = await client.channel();
  final exchange = await channel.exchange(
    'shopping_events',
    ExchangeType.TOPIC,
    durable: true,
  );

  final queue = await channel.queue('task_analytics_queue', durable: true);

  await queue.bind(exchange, 'list.checkout.#');

  final consumer = await queue.consume(noAck: true);

  print('[*] Consumer B (analytics) ouvindo queue task_analytics_queue...');
  print('[*] CTRL+C para sair.\n');

  StreamSubscription? sub;
  sub = consumer.listen(
    (AmqpMessage message) {
      dynamic payload;
      try {
        payload = message.payloadAsJson;
      } catch (_) {
        payload = {'raw': message.payloadAsString};
      }

      final id =
          payload['listId'] ??
          payload['taskId'] ??
          payload['id'] ??
          'desconhecida';

      final total =
          payload['totalValue'] ?? payload['total'] ?? payload['amount'] ?? 0;

      final items =
          payload['itemsCount'] ??
          (payload['items'] is List ? payload['items'].length : null);

      print(
        '📊 Atualizando dashboard: lista $id, total gasto = $total, itens = ${items ?? "?"} (Consumer B)',
      );
    },
    onError: (e, st) {
      print('Erro no consumer B: $e');
    },
    onDone: () {
      print('Consumer B encerrado.');
      sub?.cancel();
      client.close();
    },
  );
}

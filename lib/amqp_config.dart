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

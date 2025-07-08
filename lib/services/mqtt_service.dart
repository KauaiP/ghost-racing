import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  final String broker = 'test.mosquitto.org'; // Servidor MQTT público
  final String clientId;
  final String topic;

  late MqttServerClient _client;

  Function(String)? onMessage;

  MQTTService({required this.clientId, required this.topic});

  Future<void> connect() async {
    _client = MqttServerClient(broker, clientId);
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client.connectionMessage = connMessage;

    try {
      await _client.connect();
      _subscribeToTopic();
    } catch (e) {
      print('Erro ao conectar ao MQTT: $e');
      _client.disconnect();
    }
  }

  void _subscribeToTopic() {
    _client.subscribe(topic, MqttQos.atLeastOnce);
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      if (onMessage != null) {
        onMessage!(payload);
      }
    });
  }

  void publish(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _onDisconnected() {
    print('MQTT desconectado');
  }

  void disconnect() {
    _client.disconnect();
  }
}

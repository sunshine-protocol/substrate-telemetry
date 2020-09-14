library substrate_telemetry;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

class Telemetry {
  Telemetry({int port = 9900}) : _port = port;

  final int _port;
  HttpServer _server;
  WebSocket _socket;
  StreamController<TelemetryEvent> _controller = StreamController();

  Stream<TelemetryEvent> get events => _controller.stream;

  /// Run Telemetry Server in the background.
  /// it will be running as long as the application is running or until calling `stop` method.
  void run() async {
    _server = await HttpServer.bind('0.0.0.0', _port);
    _server.listen((req) async {
      _socket = await WebSocketTransformer.upgrade(req);
      _socket.map(_toTelemtryEvent).pipe(_controller);
    });
  }

  /// Permanently stops this [Telemetry] from listening for new events.
  /// This closes the [Stream] of [HttpRequest]s with a done event.
  /// The returned future completes when the server is stopped.
  /// If [force] is true, active connections will be closed immediately.
  void stop({bool force = true}) async {
    await _controller.close();
    await _socket.close(WebSocketStatus.noStatusReceived);
    await _server.close(force: force);
  }

  /// Convert the websocket message from `Bytes` into UTF8 Text, then parse that text as JSON.
  /// and then Convert it to a [`TelemetryEvent`]
  TelemetryEvent _toTelemtryEvent(dynamic message) {
    var text = utf8.decode(message);
    var payload = json.decode(text) as Map<String, dynamic>;
    var tag = payload.remove('msg') as String;
    var level = _logLevelfromString(payload.remove('level') as String);
    var ts = DateTime.parse(payload.remove('ts'));
    return TelemetryEvent(level: level, tag: tag, ts: ts, payload: payload);
  }
}

/// A [TelemetryEvent] is a basic class that got decoded from the Websocket Stream.
/// it contians the `Message` tag of that event, `LogLevel`, `Timestamp` and the `Payload` of that Event.
class TelemetryEvent {
  final String tag;
  final LogLevel level;
  final DateTime ts;
  final Map<String, dynamic> payload;

  TelemetryEvent({this.tag, this.level, this.ts, this.payload});

  @override
  String toString() {
    return '${ts.toIso8601String()} ${_logLevelToString(level)} $tag: $payload';
  }
}

enum LogLevel {
  trace,
  debug,
  info,
  warn,
  error,
}

LogLevel _logLevelfromString(String level) {
  switch (level) {
    case "TRACE":
      return LogLevel.trace;
    case "DEBUG":
      return LogLevel.debug;
    case "INFO":
      return LogLevel.info;
    case "WARN":
      return LogLevel.warn;
    case "ERROR":
      return LogLevel.error;
    default:
      return LogLevel.trace;
  }
}

String _logLevelToString(LogLevel level) {
  switch (level) {
    case LogLevel.trace:
      return "TRACE";
    case LogLevel.debug:
      return "DEBUG";
    case LogLevel.info:
      return "INFO";
    case LogLevel.warn:
      return "WARN";
    case LogLevel.error:
      return "ERROR";
    default:
      return "TRACE";
  }
}

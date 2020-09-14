import 'package:substrate_telemetry/substrate_telemetry.dart';

void main() async {
  var telemetry = Telemetry(port: 9900);
  telemetry.events.forEach(print);
  print("Server Started !");
  await telemetry.run();
  await Future.delayed(Duration(days: 365));
}

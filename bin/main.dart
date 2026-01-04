import 'package:axon/blueprints/blueprint.dart';
import 'package:axon/axon.dart';
import 'package:axon/routes/root_route.dart';
// Import validator to ensure it's loaded by the mirror system

void main(List<String> args) {
  Axon.server.start(Server());
}

class Server extends ServerRoot {
  @override
  List<Route> routes = [Root()];
}

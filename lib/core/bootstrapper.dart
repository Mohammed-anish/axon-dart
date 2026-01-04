import 'package:axon/blueprints/blueprint.dart';
import 'package:axon/core/context.dart';
import 'package:axon/core/server/server.dart';
import 'package:axon/core/url_parser.dart';

final Context ctx = Context();

class BootStrapper {
  void start(ServerRoot root) async {
    CoreServer coreServer = (CoreServer(
      address: root.configuration.address,
      port: root.configuration.port,
    ));

    ctx.routes = .unmodifiable(root.routes);

    coreServer.setRoutes(root.routes);
    coreServer.setUrlParser(URLParser());
    coreServer.start();
  }
}

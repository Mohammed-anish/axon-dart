import 'dart:io';

import 'package:axon/blueprints/blueprint.dart';
import 'package:axon/core/bootstrapper.dart';
import 'package:axon/core/request_handler.dart';
import 'package:axon/core/route_provider.dart';
import 'package:axon/core/server/server_configuration.dart';
import 'package:axon/core/url_parser.dart';

class CoreServer {
  final InternetAddress address;
  final int port;
  CoreServer({required this.address, required this.port});
  factory CoreServer.fromConfiguration([ServerConfiguration? configuration]) {
    final config = configuration ?? defaultServerConfiguration;
    return CoreServer(address: config.address, port: config.port);
  }

  URLParser? _urlParser;
  List<Route> routes = [];

  void setUrlParser(URLParser parser) {
    _urlParser = parser;
  }

  void setRoutes(List<Route> routes) {
    this.routes = routes;
  }

  RequestHandler handler = RequestHandler();

  Future start() async {
    HttpServer httpServer = await HttpServer.bind(address, port);

    print('Server started on: http://localhost:${httpServer.port}');

    httpServer.listen((HttpRequest request) async {
      ctx.requestUrl = request.uri;

      final RouteProvider routeProvider = RouteProvider(_urlParser!);
      ({Route? route, Variables variables}) provide = routeProvider.provide();
      final route = provide.route;
      print('routessss ${Platform.script} $route');

      if (route != null) {
        handler.handle(route, request, provide.variables);
      } else {
        handler.fallback(request);
      }
    });
  }
}

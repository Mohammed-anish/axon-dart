import 'dart:async';
import 'dart:io';

import 'package:axon/core/body_parser.dart';
import 'package:axon/core/response.dart';
import 'package:axon/core/route_provider.dart';
import 'package:axon/core/server/server_configuration.dart';
import 'package:axon/core/session_manager.dart';

abstract class Route {
  String get target;
  bool get socketEnabled;

  FutureOr<Response> get(Request request) {
    return UnSupportedMethod();
  }

  FutureOr<Response> put(Request request) {
    return UnSupportedMethod();
  }

  FutureOr<Response> post(Request request) {
    return UnSupportedMethod();
  }

  FutureOr<Response> patch(Request request) {
    return UnSupportedMethod();
  }

  FutureOr<Response> delete(Request request) {
    return UnSupportedMethod();
  }

  FutureOr<Response> custom(String method, Request request) {
    return UnSupportedMethod();
  }

  void socket(WebSocket socket, List<WebSocket> clients) {}
}

abstract class Server {}

abstract class ServerRoot {
  ServerConfiguration configuration = defaultServerConfiguration;
  abstract List<Route> routes;
}

class Request {
  final String method;
  final String url;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> queryParameters;
  final Variables variables;
  final Variables body;
  final List<UploadedFile> files;
  final Session session;

  Request({
    required this.method,
    required this.url,
    required this.headers,
    required this.queryParameters,
    required this.variables,
    required this.body,
    required this.files,
    required this.session,
  });

  static Future<Request> fromHttpRequest(
    HttpRequest request,
    Variables variables,
  ) async {
    Map<String, dynamic> headers = {};
    request.headers.forEach((name, values) => headers.addAll({name: values}));
    BodyParseResult parse = await BodyParser.parse(request, tempDir: 'tmp');
    Session session = await SessionManager.instance.handle(request);

    return Request(
      method: request.method,
      url: request.uri.toString(),
      headers: headers,
      queryParameters: request.uri.queryParameters,
      variables: variables,
      body: Variables(parse.fields),
      files: parse.files,
      session: session,
    );
  }
}

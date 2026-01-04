import 'dart:async';
import 'dart:io';

import 'package:axon/blueprints/blueprint.dart';
import 'package:axon/core/response.dart';
import 'package:axon/core/route_provider.dart';
import 'package:axon/axon.dart';

void main(List<String> args) {
  Axon.server.start(Server());
}

class Server extends ServerRoot {
  @override
  List<Route> routes = [Root()];
}

class Root extends Route {
  @override
  String get target => '/';
  @override
  bool get socketEnabled => false;

  @override
  FutureOr<Response> get(Request request) async {
    return File('bin/demo.html', variables: Variables({'yo': false}));
  }

  // @override
  @override
  FutureOr<Response<dynamic>> post(Request request) {
    print('yoooo ${request.files.first.saveTo('public/changelog.md')}');

    return Json({
      'error': false,
      'message': "Done!",
      'var': request.variables,
      // 'head': request.headers,
      "data": request.body.values,
    });
  }
}



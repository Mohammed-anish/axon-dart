import 'dart:async';

import 'package:axon/blueprints/blueprint.dart';
import 'package:axon/core/response.dart';
import 'package:axon/core/route_provider.dart';

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
    if (request.files.isNotEmpty) {
      print('yoooo ${request.files.first.saveTo('public/changelog.md')}');
    }

    return Json({
      'error': false,
      'message': "Done!",
      'var': request.variables,
      // 'head': request.headers,
      "data": request.body.values,
    });
  }
}

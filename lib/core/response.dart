import 'dart:convert';
import 'dart:io' as io;

import 'package:axon/core/bootstrapper.dart';
import 'package:axon/core/route_provider.dart';
import 'package:axon/core/template_engine.dart';

abstract class Response<T> {
  T? value;
  String contentType = 'plain/text';

  Response();
}

final class UnSupportedMethod extends Response {
  UnSupportedMethod();
}

final class StringResponse extends Response<String> {
  StringResponse(String value) {
    super.value = value;
    super.contentType = 'plain/text';
  }
}

class Html extends Response {
  Html(String value) {
    super.contentType = 'text/html';
    super.value = value;
  }
}

class Json extends Response {
  Json(Map<String, dynamic> value) {
    super.contentType = 'application/json';
    super.value = json.encode(value);
  }
}

class File extends Response {
  File(String path, {Variables? variables}) {
    HydroTemplateEngine engine = HydroTemplateEngine({
      ...variables?.values ?? {},
      'query': ctx.requestUrl.queryParameters,
    });

    print('${io.File(path).existsSync()}');
    super.contentType = 'text/html';
    super.value = engine.render(io.File(path).readAsStringSync());
  }
}

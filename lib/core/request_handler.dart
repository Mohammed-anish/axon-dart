import 'dart:async';
import 'dart:io';
import 'package:axon/blueprints/blueprint.dart';
import 'package:axon/core/response.dart' hide File;
import 'package:axon/core/route_provider.dart';
import 'package:axon/core/template_engine.dart';

class RequestHandler {
  List<WebSocket> socketClients = [];
  void handle(Route route, HttpRequest request, Variables variables) async {
    try {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        if (route.socketEnabled) {
          await handleSocketRequest(request, route);
        } else {
          request.response.write('Socket endpoint is not available!');
          request.response.close();
        }
        return;
      }
      Request req = await Request.fromHttpRequest(request, variables);
      Response? response =
          await (handleMethod(route, request.method)?.call(req) ??
              route.custom(request.method, req));
      if (response is UnSupportedMethod) {
        request.response.write('Unsupported method : ${request.method}');
        request.response.close();
      }
      request.response.headers.set('Content-Type', response.contentType);
      request.response.write(response.value.toString());
      request.response.close();
    } catch (e) {
      print('>>>>>>>>> $e');
    }
  }

  FutureOr<Response<dynamic>> Function(Request request)? handleMethod<T>(
    Route route,
    String method,
  ) {
    Map<String, FutureOr<Response<dynamic>> Function(Request request)>
    methodMap = {
      'GET': route.get,
      'POST': route.post,
      'PUT': route.put,
      'PATCH': route.patch,
      'DELETE': route.delete,
    };
    if (methodMap.containsKey(method)) {
      return methodMap[method];
    }
    return null;
  }

  Future<void> handleSocketRequest(HttpRequest request, Route route) async {
    final WebSocket socket = await WebSocketTransformer.upgrade(request);

    socketClients.add(socket);

    route.socket(socket, socketClients);
  }

  void fallback(HttpRequest request) {
    request.response.headers.add('Content-Type', 'text/html');

    request.response.write(
      HydroTemplateEngine({
        'route': request.requestedUri.path,
      }).render(File('lib/core/syspages/not-found.html').readAsStringSync()),
    );
    request.response.close();
  }
}

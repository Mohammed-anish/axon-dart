import 'package:axon/blueprints/blueprint.dart';
import 'package:axon/core/bootstrapper.dart';
import 'package:axon/core/url_parser.dart';

extension type Variables(Map<String, dynamic> values) {
  T? get<T>(String key) {
    if (values.containsKey(key)) {
      return values[key] as T;
    }
    return null;
  }
}

class RouteProvider {
  final URLParser urlParser;

  RouteProvider(this.urlParser);

  ({Route? route, Variables variables}) provide() {
    Variables variables = Variables({});
    Route? route = ctx.routes.where((route) {
      UrlParserResult result = urlParser.parse(route);
      variables = result.variables;
      return result.didMatch;
    }).firstOrNull;
    return (route: route, variables: variables);
  }
}

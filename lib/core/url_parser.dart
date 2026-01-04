

import 'package:axon/blueprints/blueprint.dart';
import 'package:axon/core/bootstrapper.dart';
import 'package:axon/core/route_provider.dart';

class URLParser {
  UrlParserResult parse(Route route) {
    ({bool didMatch, Variables variables}) match = _didMatchedPath(
      route.target,
      ctx.requestUrl.path.toString(),
    );

    return UrlParserResult(
      didMatch: match.didMatch,
      variables: match.variables,
    );
  }

  List<int> _variableIndicesFinder(String target) {
    List<String> splited = target.split('/')
      ..removeWhere((element) => element.isEmpty);
    List<int> indices = [];
    for (var i = 0; i < splited.length; i++) {
      var current = splited[i];
      if (current.startsWith(':')) {
        indices.add(i);
      }
    }
    return indices;
  }

  ({bool didMatch, Variables variables}) _didMatchedPath(
    String target,
    String urlPath,
  ) {
    var indices = _variableIndicesFinder(target);

    List<String> splitedUrlPath = urlPath.split('/')
      ..removeWhere((element) => element.isEmpty);
    List<String> splitedTarget = target.split('/')
      ..removeWhere((element) => element.isEmpty);
    int matchRate = 0;
    Map<String, dynamic> variables = {};
    print('>SDASD $splitedTarget $splitedUrlPath $indices');

    if (splitedTarget.length != splitedUrlPath.length) {
      return (didMatch: false, variables: Variables({}));
    }
    for (var i = 0; i < splitedTarget.length; i++) {
      var current = splitedTarget[i];
      var pathCurrent = splitedUrlPath[i];

      if (current == pathCurrent) {
        matchRate++;
      } else if (indices.contains(i)) {
        variables.addAll({current.replaceAll(':', ''): pathCurrent});
        matchRate++;
      }
    }
    print('ASDASD $matchRate ${splitedTarget.length}');
    return (
      didMatch: matchRate >= splitedTarget.length,
      variables: Variables(variables),
    );
  }
}

class UrlParserResult {
  final bool didMatch;
  final Variables variables;
  UrlParserResult({required this.didMatch, required this.variables});
}

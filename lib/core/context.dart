import 'package:axon/blueprints/blueprint.dart';

class Context {
  static Map<dynamic, dynamic> dependencies = {};
  List<Route> routes = [];
  late Uri requestUrl;
  void put<T>(T value, String? tag) {
    if (tag != null) {
      dependencies.addAll({'${T}_$tag': value});
      return;
    }
    dependencies.addAll({T: value});
  }

  T? get<T>(String? tag) {
    if (tag != null) {
      return dependencies['${T}_$tag'] as T?;
    }
    return dependencies[T] as T?;
  }

  void destroy<T>() {
    dependencies.remove(T);
  }
}

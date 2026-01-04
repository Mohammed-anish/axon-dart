# Hydro Framework - Current Features

Hydro is a lightweight web framework for Dart that provides a simple, elegant way to build web servers with routing, request handling, and templating capabilities.

## Core Features

### 1. **HTTP Server**
- Built-in HTTP server using Dart's `dart:io` library
- Configurable address and port binding
- Asynchronous request handling with futures support
- Server startup and lifecycle management via `Bootstrapper`

### 2. **Routing System**
- Route-based architecture for organizing endpoints
- Support for multiple HTTP methods:
  - **GET** - Retrieve data
  - **POST** - Create data
  - **PUT** - Update data (full)
  - **PATCH** - Update data (partial)
  - **DELETE** - Remove data
  - **Custom Methods** - Handle any HTTP method
- Route targeting with pattern matching
- Dynamic URL parsing with variable extraction

### 3. **Request & Response Handling**
- **Request Object** - Encapsulates HTTP request data including:
  - HTTP method
  - URL and query parameters
  - Headers
  - Route variables
- **Response Object** - Simplified response creation with:
  - Custom content types
  - Dynamic value support

### 4. **URL Parsing & Route Variables**
- URL pattern matching using `URLParser`
- Dynamic variable extraction from URLs (e.g., `/users/{id}`)
- Type-safe variable access through `Variables` extension type
- Generic getter for type-specific value retrieval

### 5. **Template Engine**
The `HydroTemplateEngine` provides server-side template rendering with support for:

#### Variable Interpolation
```
{{ variableName }}
{{ nested.object.property }}
```

#### Conditional Rendering
```
{{if condition}}
  Content shown when true
{{else}}
  Content shown when false
{{end}}
```

#### Loops
```
{{for item in list}}
  {{ item }}
{{end}}
```

### 6. **Request Method Handling**
- Automatic HTTP method routing
- Handler methods return `FutureOr<Response>` for async support
- Fallback mechanism for unsupported methods
- Custom method handling for non-standard HTTP verbs

### 7. **Error Handling & Fallback**
- 404 Not Found page for unmatched routes
- Customizable error pages using templates
- Graceful error handling with fallback responses
- System pages stored in `/core/syspages/`

### 8. **Server Configuration**
- Configurable server settings via `ServerConfiguration`
- Default configuration support
- Customizable address binding
- Customizable port configuration
- Optional logging capability

### 9. **Context Management**
- Global `Context` object for application state
- Request URL tracking
- Route registry
- Immutable route collections

## Architecture Components

### Main Classes

| Component | Purpose |
|-----------|---------|
| `Hydro` | Main entry point, provides static access to `BootStrapper` |
| `BootStrapper` | Initializes and starts the server with routes |
| `CoreServer` | Low-level HTTP server implementation |
| `Route` | Abstract base for defining route handlers |
| `ServerRoot` | Abstract base for server configuration |
| `RequestHandler` | Processes incoming HTTP requests |
| `RouteProvider` | Matches URLs to routes and extracts variables |
| `URLParser` | Parses and matches URL patterns |
| `HydroTemplateEngine` | Renders HTML templates with dynamic data |
| `Request` | Encapsulates incoming HTTP request data |
| `Response` | Encapsulates HTTP response data |
| `Context` | Manages application-wide state |

## Usage Pattern

```dart
void main() {
  Hydro.server.start(MyServerRoot());
}

class MyServerRoot extends ServerRoot {
  ServerConfiguration configuration = ServerConfiguration(
    address: InternetAddress.loopbackIPv4,
    port: 8080,
  );

  @override
  List<Route> routes = [
    HomeRoute(),
    UserRoute(),
  ];
}

class HomeRoute extends Route {
  @override
  String get target => '/';

  @override
  FutureOr<Response> get(Request request) {
    return Response(value: 'Hello, Hydro!', contentType: 'text/plain');
  }
}
```

## Key Features Summary

✅ **Lightweight** - Minimal dependencies, focused framework  
✅ **Fast** - Async/await support for high performance  
✅ **Type-Safe** - Dart's type system with custom extensions  
✅ **Templating** - Built-in server-side template engine  
✅ **RESTful** - Full HTTP method support  
✅ **Modular** - Clean separation of concerns  
✅ **Extensible** - Custom route handlers and methods  
✅ **Developer-Friendly** - Simple, intuitive API  

## Status

- ✅ Core server and routing functional
- ✅ HTTP method handling implemented
- ✅ URL parsing with variables
- ✅ Template engine with conditionals and loops
- ✅ Request/Response objects
- ✅ Error handling and 404 pages
- 🔄 WebSocket support (planned in `socket.dart`)
- 🔄 Middleware system (future enhancement)
- 🔄 Session management (future enhancement)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Result of parsing a request body.
class BodyParseResult {
  /// Map of non-file form fields or parsed JSON body.
  final Map<String, dynamic> fields;

  /// List of uploaded files (if any).
  final List<UploadedFile> files;

  BodyParseResult({Map<String, dynamic>? fields, List<UploadedFile>? files})
    : fields = fields ?? {},
      files = files ?? [];
}

/// Represents a file uploaded in a multipart/form-data request.
class UploadedFile {
  final String name; // form field name
  final String filename;
  final String? contentType;
  final File tempFile;

  UploadedFile({
    required this.name,
    required this.filename,
    required this.tempFile,
    this.contentType,
  });

  /// Size in bytes of the saved temporary file.
  Future<int> get size async => await tempFile.length();

  /// Read entire file as bytes.
  Future<List<int>> readAsBytes() => tempFile.readAsBytes();

  /// Save uploaded file to [destinationPath]. Returns the new File.
  Future<File> saveTo(
    String destinationPath, {
    bool preserveTemp = false,
  }) async {
    final dest = File(destinationPath);
    await dest.create(recursive: true);
    var ref = tempFile.copy(destinationPath);
    if (!preserveTemp) {
      await tempFile.delete();
    }

    return ref;
  }

  /// Removes the temporary file.
  Future<void> delete() async {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}

/// Utility to parse HTTP request bodies including JSON, urlencoded and multipart.
///
/// Example usage:
///
/// ```dart
/// final result = await BodyParser.parse(request);
/// // result.fields -> Map of values
/// // result.files -> List<UploadedFile>
/// ```
class BodyParser {
  /// Parse the incoming [request] and return a [BodyParseResult].
  ///
  /// If [tempDir] is provided, uploaded files are stored there; otherwise
  /// the system temporary directory is used.
  static Future<BodyParseResult> parse(
    HttpRequest request, {
    String? tempDir,
  }) async {
    final contentTypeHeader = request.headers.contentType;

    final mime = contentTypeHeader == null
        ? ''
        : '${contentTypeHeader.primaryType}/${contentTypeHeader.subType}';

    tempDir ??= Directory.systemTemp.path;

    if (mime == 'application/json') {
      final bodyString = await utf8.decoder.bind(request).join();
      dynamic jsonBody;
      try {
        jsonBody = jsonDecode(bodyString);
      } catch (e) {
        jsonBody = null;
      }

      if (jsonBody is Map<String, dynamic>) {
        return BodyParseResult(fields: Map.from(jsonBody));
      }

      return BodyParseResult(fields: {'_raw': jsonBody});
    }

    if (mime == 'application/x-www-form-urlencoded') {
      final bodyString = await utf8.decoder.bind(request).join();
      final parsed = Uri.splitQueryString(bodyString, encoding: utf8);
      return BodyParseResult(fields: Map<String, dynamic>.from(parsed));
    }

    if (mime == 'multipart/form-data') {
      final boundary = contentTypeHeader?.parameters['boundary'];
      if (boundary == null || boundary.isEmpty) {
        throw ArgumentError('Missing multipart boundary');
      }

      final bodyBytes = await consolidateHttpClientResponseBytes(request);
      final bodyText = latin1.decode(bodyBytes);
      final boundaryMarker = '--$boundary';

      final fields = <String, dynamic>{};
      final files = <UploadedFile>[];

      // Split by boundary marker
      final rawParts = bodyText.split(boundaryMarker);

      for (var rawPart in rawParts) {
        rawPart = rawPart.trim();
        if (rawPart.isEmpty || rawPart == '--')
          continue; // skip preamble and closing

        // Remove leading CRLF if present
        if (rawPart.startsWith('\r\n')) rawPart = rawPart.substring(2);

        final headerBodySep = rawPart.indexOf('\r\n\r\n');
        if (headerBodySep == -1) continue;

        final headerText = rawPart.substring(0, headerBodySep);
        var partBodyText = rawPart.substring(headerBodySep + 4);

        // Remove possible trailing CRLF
        if (partBodyText.endsWith('\r\n')) {
          partBodyText = partBodyText.substring(0, partBodyText.length - 2);
        }

        // Parse headers
        final headers = <String, String>{};
        for (final line in headerText.split('\r\n')) {
          final idx = line.indexOf(':');
          if (idx == -1) continue;
          final key = line.substring(0, idx).trim().toLowerCase();
          final value = line.substring(idx + 1).trim();
          headers[key] = value;
        }

        final contentDisposition = headers['content-disposition'] ?? '';
        final nameMatch = RegExp(
          r'name="([^"]+)"',
        ).firstMatch(contentDisposition);
        final filenameMatch = RegExp(
          r'filename="([^"]+)"',
        ).firstMatch(contentDisposition);

        final name = nameMatch?.group(1) ?? 'unknown';
        final filename = filenameMatch?.group(1);

        if (filename == null) {
          // regular field
          final value = partBodyText;
          if (fields.containsKey(name)) {
            final existing = fields[name];
            if (existing is List) {
              existing.add(value);
            } else {
              fields[name] = [existing, value];
            }
          } else {
            fields[name] = value;
          }
        } else {
          // file field -> save to temp file
          final safeFileName = filename.replaceAll(
            RegExp(r'[\\/:*?"<>|]'),
            '_',
          );
          final tempPath =
              '${tempDir.replaceAll(RegExp(r'\\'), '/')}/upload_${DateTime.now().microsecondsSinceEpoch}_$safeFileName';
          final tempFile = File(tempPath);
          await tempFile.create(recursive: true);

          final fileBytes = latin1.encode(partBodyText);
          await tempFile.writeAsBytes(fileBytes);

          files.add(
            UploadedFile(
              name: name,
              filename: filename,
              tempFile: tempFile,
              contentType: headers['content-type'],
            ),
          );
        }
      }

      return BodyParseResult(fields: fields, files: files);
    }

    // Unknown or empty content type: return raw body as bytes and string
    final rawBytes = await consolidateHttpClientResponseBytes(request);

    return BodyParseResult(
      fields: {
        '_rawBytes': rawBytes,
        '_rawString': utf8.decode(rawBytes, allowMalformed: true),
      },
    );
  }
}

// Helper to consume request body when content type is unknown.
Future<List<int>> consolidateHttpClientResponseBytes(
  HttpRequest request,
) async {
  final chunks = <int>[];
  await for (final chunk in request) {
    chunks.addAll(chunk);
  }
  return chunks;
}

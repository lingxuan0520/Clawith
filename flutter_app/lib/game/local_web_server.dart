import 'dart:io';

import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import 'package:mime/mime.dart';

/// A local HTTP server that serves the bundled agent-town static files.
///
/// The files are bundled as a zip asset, extracted to a temp directory on
/// first use, then served via a localhost HTTP server. The WebView loads
/// from this server. Users don't interact with or see this server at all.
class LocalWebServer {
  HttpServer? _server;
  String? _baseUrl;
  static Directory? _extractDir;

  String? get baseUrl => _baseUrl;

  /// Start the local server. Returns the base URL (e.g., "http://127.0.0.1:54321").
  Future<String> start() async {
    // Extract zip to temp if not already done
    final dir = await _ensureExtracted();

    // Bind to loopback on a random available port
    _server = await HttpServer.bind('127.0.0.1', 0);
    _baseUrl = 'http://127.0.0.1:${_server!.port}';

    _server!.listen((HttpRequest request) async {
      try {
        var path = Uri.decodeFull(request.uri.path);
        if (path == '/') path = '/index.html';

        final file = File('${dir.path}$path');
        if (await file.exists()) {
          final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
          request.response
            ..headers.set('Content-Type', mimeType)
            ..headers.set('Access-Control-Allow-Origin', '*');
          await request.response.addStream(file.openRead());
        } else {
          // Try index.html for SPA routing
          final indexFile = File('${dir.path}/index.html');
          if (await indexFile.exists()) {
            request.response
              ..headers.set('Content-Type', 'text/html')
              ..headers.set('Access-Control-Allow-Origin', '*');
            await request.response.addStream(indexFile.openRead());
          } else {
            request.response.statusCode = 404;
            request.response.write('Not found');
          }
        }
      } catch (_) {
        request.response.statusCode = 500;
      } finally {
        await request.response.close();
      }
    });

    return _baseUrl!;
  }

  /// Stop the server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _baseUrl = null;
  }

  /// Extract the zip asset to a temp directory (cached across calls).
  static Future<Directory> _ensureExtracted() async {
    if (_extractDir != null && await _extractDir!.exists()) {
      return _extractDir!;
    }

    // Load zip from Flutter assets
    final ByteData data = await rootBundle.load('assets/agent_town_web.zip');
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode zip
    final archive = ZipDecoder().decodeBytes(bytes);

    // Create temp directory
    _extractDir = await Directory.systemTemp.createTemp('agent_town_');

    // Extract all files
    for (final file in archive) {
      final filePath = '${_extractDir!.path}/${file.name}';
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }

    return _extractDir!;
  }
}

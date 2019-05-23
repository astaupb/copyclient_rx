import 'dart:async';

import 'package:blocs_copyclient/backend.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

export 'package:blocs_copyclient/src/models/backend.dart';

class BackendShiva implements Backend {
  final String host = 'astaprint.upb.de';
  final String basePath = '/api/v1';
  final Client _innerClient;

  Logger _log = Logger('BackendShiva');

  BackendShiva(this._innerClient) {
    _log.fine('Creating Backend with ${_innerClient.toString()} as innerClient');
  }

  @override
  void close() {
    _log.fine('Closing Client: $_innerClient');
    _innerClient.close();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    Request modRequest = Request(request.method, request.url);

    modRequest.persistentConnection = true;

    /// copy over headers from [request]
    for (String key in request.headers.keys) {
      modRequest.headers[key] = request.headers[key];
    }

    modRequest.headers['Connection'] = 'keep-alive';

    /// copy over body from [request]
    if (request is Request) {
      modRequest.bodyBytes = request.bodyBytes;
    }

    /// send finalized request through [_innerClient] and return [StreamedResponse]
    return _innerClient.send(modRequest);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map();
    map['host'] = host;
    map['basePath'] = basePath;
    return map;
  }

  @override
  String toStringDeep() => toMap().toString();
}

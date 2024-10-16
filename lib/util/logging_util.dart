import 'dart:io';

import 'package:http/http.dart' as http;

void logHttpResponse(final http.Response response) {
  stdout.writeln('${response.request?.method} ${response.statusCode} '
      '${Uri.decodeQueryComponent(response.request?.url.toString() ?? '')}'
      '\n${response.body}');
}

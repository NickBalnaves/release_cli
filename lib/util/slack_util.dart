import 'dart:convert';

import 'package:http/http.dart' as http;

import 'git_util.dart';
import 'logging_util.dart';

abstract final class SlackUtil {
  static Future<void> postWarningMessage({
    required final String slackWebhookUrl,
    required final String message,
  }) async {
    final branch = await GitUtil.gitBranch();
    final commit = await GitUtil.gitCommit();
    final payload = {
      'blocks': [
        {
          'type': 'header',
          'text': {
            'type': 'plain_text',
            'text': '🚨 CI/CD Pipeline Failed',
            'emoji': true,
          },
        },
        {
          'type': 'section',
          'fields': [
            {'type': 'mrkdwn', 'text': '*Branch:*\n$branch'},
            {'type': 'mrkdwn', 'text': '*Commit:*\n$commit'},
            {'type': 'mrkdwn', 'text': '*Error:*\n$message'},
          ],
        },
        {
          'type': 'context',
          'elements': [
            {
              'type': 'mrkdwn',
              'text': '🕒 ${DateTime.now().toUtc().toIso8601String()} UTC',
            }
          ],
        }
      ],
    };

    final response = await http.post(
      Uri.parse(slackWebhookUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      logHttpResponse(response);
      throw Exception('Error posting warning message to Slack.');
    }
  }
}

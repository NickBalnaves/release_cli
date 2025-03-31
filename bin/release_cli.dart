import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:release_cli/commands/android_command.dart';
import 'package:release_cli/commands/ios_command.dart';
import 'package:release_cli/commands/web_command.dart';
import 'package:release_cli/util/slack_util.dart';

Future<void> main(final List<String> arguments) async {
  final runner =
      CommandRunner<void>('release_cli', 'Release Command Line Interface')
        ..addCommand(AndroidCommand())
        ..addCommand(IOSCommand())
        ..addCommand(WebCommand());

  final slackWebhookUrlError = Platform.environment['SLACK_WEBHOOK_URL_ERROR'];
  try {
    await runner.run(arguments);
  } on UsageException catch (error) {
    stderr.writeln(error);
    if (slackWebhookUrlError != null) {
      await SlackUtil.postWarningMessage(
        slackWebhookUrl: slackWebhookUrlError,
        message: error.toString(),
      );
    }
    exit(64);
  } catch (error) {
    final errorString = error.toString();
    stderr.writeln(errorString);
    if (slackWebhookUrlError != null) {
      await SlackUtil.postWarningMessage(
        slackWebhookUrl: slackWebhookUrlError,
        message: error.toString(),
      );
    }
    exit(1);
  }
}

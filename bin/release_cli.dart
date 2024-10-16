import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:release_cli/commands/android_command.dart';
import 'package:release_cli/commands/ios_command.dart';

Future<void> main(final List<String> arguments) async {
  final runner = CommandRunner('release_cli', 'Release Command Line Interface')
    ..addCommand(AndroidCommand())
    ..addCommand(IOSCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (error) {
    stdout.writeln(error);
    exit(64);
  } catch (error) {
    stdout.writeln('$error');
    exit(1);
  }
}

import 'dart:io';

abstract final class GitUtil {
  static Future<bool> hasPubspecVersionChanged() async {
    final result = await Process.run(
      'git',
      ['show', 'HEAD', '--', 'pubspec.yaml'],
    );

    if (result.exitCode == 0) {
      return RegExp('^[-+].*version:').hasMatch(result.stdout);
    } else {
      stderr.writeln('Error running git command: ${result.stderr}');
      exit(1);
    }
  }
}

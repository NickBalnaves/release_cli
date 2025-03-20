import 'dart:convert';
import 'dart:io';

abstract final class GitUtil {
  static Future<String?> pubspecVersionChange() async {
    final result = await Process.run(
      'git',
      ['show', 'HEAD', '--', 'pubspec.yaml'],
    );

    if (result.exitCode != 0) {
      throw Exception('Error running git command: ${result.stderr}');
    }

    final lines = LineSplitter.split(result.stdout);
    final versionRegex = RegExp(r'^\+version:\s*(.*)');

    for (final line in lines) {
      final match = versionRegex.firstMatch(line);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  static Future<String> gitBranch() async {
    final result =
        await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);

    if (result.exitCode != 0) {
      throw Exception('Error running git command: ${result.stderr}');
    }

    return (result.stdout as String).trim();
  }

  static Future<String> gitCommit() async {
    final result = await Process.run('git', ['rev-parse', 'HEAD']);

    if (result.exitCode != 0) {
      throw Exception('Error running git command: ${result.stderr}');
    }

    return (result.stdout as String).trim();
  }
}

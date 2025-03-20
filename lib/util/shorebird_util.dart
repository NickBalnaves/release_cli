import 'dart:io';

abstract final class ShorebirdUtil {
  static Future<void> patch({
    required final String buildName,
    required final int buildNumber,
    required final String platform,
    required final String buildOptions,
    required final String flutterVersion,
    required final bool allowAssetDiffs,
  }) async {
    stdout.writeln('Starting shorebird patch for $buildName+$buildNumber...');
    final shorebirdPatchProcess = await Process.run(
      'shorebird',
      [
        'patch',
        '--platforms=$platform',
        '--build-name=$buildName',
        '--build-number=$buildNumber',
        '--release-version=$buildName+$buildNumber',
        if (allowAssetDiffs) '--allow-asset-diffs',
        '--',
        if (platform.contains('ios'))
          '--export-options-plist=ios/exportOptions.plist',
        ...buildOptions.split(' '),
      ],
    );

    final shorebirdPatchProcessExitCode = shorebirdPatchProcess.exitCode;
    stdout.writeln(shorebirdPatchProcess.stdout);
    if (shorebirdPatchProcessExitCode != 0) {
      throw Exception(
        'Error running shorebird patch: ${shorebirdPatchProcess.stderr}',
      );
    }
  }

  static Future<List<String>> release({
    required final String buildName,
    required final int buildNumber,
    required final String platform,
    required final String buildOptions,
    required final String flutterVersion,
  }) async {
    stdout.writeln(
      'Starting shorebird build for $buildName+${buildNumber + 1}...',
    );

    final shorebirdReleaseProcess = await Process.start(
      'shorebird',
      [
        'release',
        '--platforms=$platform',
        '--build-name=$buildName',
        '--build-number=${buildNumber + 1}',
        '--flutter-version=$flutterVersion',
        '--',
        if (platform.contains('ios'))
          '--export-options-plist=ios/exportOptions.plist',
        ...buildOptions.split(' '),
      ],
    );

    shorebirdReleaseProcess.stdout
        .transform(const SystemEncoding().decoder)
        .listen((final data) {
      stdout.write(data);
    });
    shorebirdReleaseProcess.stderr
        .transform(const SystemEncoding().decoder)
        .listen((final data) => stderr.write(data));

    final shorebirdReleaseProcessExitCode =
        await shorebirdReleaseProcess.exitCode;
    if (shorebirdReleaseProcessExitCode != 0) {
      throw Exception(
        'Error running shorebird release: ${shorebirdReleaseProcess.stderr}',
      );
    }

    final buildFiles = Directory('build').listSync(recursive: true).where(
          (final file) =>
              (platform.contains('ios') && file.path.contains('.ipa')) ||
              (platform.contains('android') &&
                  file.path.contains('.aab') &&
                  !file.path.contains('intermediary')),
        );
    if (buildFiles.isEmpty) {
      throw Exception('No build files found in build folder.');
    }
    stdout.writeln(
      'Found build files ${buildFiles.map((final file) => file.path)}',
    );

    return [for (final file in buildFiles) file.path];
  }
}

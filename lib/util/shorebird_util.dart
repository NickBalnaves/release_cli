import 'dart:io';

abstract final class ShorebirdUtil {
  static Future<List<String>> patchOrBuildPaths({
    required final String buildName,
    required final int buildNumber,
    required final String platform,
    required final String buildOptions,
    required final String flutterVersion,
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
        '--',
        if (platform.contains('ios'))
          '--export-options-plist=ios/exportOptions.plist',
        ...buildOptions.split(' '),
      ],
    );

    final shorebirdPatchProcessExitCode = shorebirdPatchProcess.exitCode;
    final buildLocations = <String>[];
    if (shorebirdPatchProcessExitCode != 0) {
      stdout.writeln(
        "Couldn't patch shorebird build. Building a new one...",
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
        final matches = RegExp(r'(/[\w/.-]+\.(aab|ipa))')
            .allMatches(data)
            .map((final match) => match.group(1));
        for (final match in matches) {
          if (match != null) {
            buildLocations.add(match);
          }
        }
      });
      shorebirdReleaseProcess.stderr
          .transform(const SystemEncoding().decoder)
          .listen((final data) => stdout.write(data));

      final shorebirdReleaseProcessExitCode =
          await shorebirdReleaseProcess.exitCode;
      if (shorebirdReleaseProcessExitCode != 0) {
        exit(1);
      }
      if (buildLocations.isEmpty) {
        stdout.writeln(
          'No build location in output. Looking for it in build folder...',
        );
        final buildFiles = Directory('build').listSync(recursive: true).where(
              (final file) =>
                  (platform.contains('ios') && file.path.contains('.ipa')) ||
                  (platform.contains('android') && file.path.contains('.aab')),
            );
        if (buildFiles.isEmpty) {
          stdout.writeln('No build files found in build folder.');
          exit(1);
        }
        stdout.writeln(
          'Found build files ${buildFiles.map((final file) => file.path)}',
        );
        buildLocations.addAll(buildFiles.map((final file) => file.path));
      }
    }
    stdout.writeln(shorebirdPatchProcess.stdout);

    return buildLocations;
  }
}
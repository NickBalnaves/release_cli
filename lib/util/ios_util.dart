import 'dart:io';

import 'package:xml/xml.dart';

abstract final class IOSUtil {
  static Future<String?> createBuild({
    required final int buildNumber,
    required final String buildOptions,
    final String? buildName,
  }) async {
    String? buildLocation;

    stdout.writeln(
      'Starting flutter build for '
      '${buildName != null ? '$buildName+' : ''}'
      '${buildNumber + 1}...',
    );
    final process = await Process.start(
      'flutter',
      [
        'build',
        'ipa',
        if (buildName != null) '--build-name=$buildName',
        '--build-number=${buildNumber + 1}',
        '--export-options-plist=ios/exportOptions-adhoc.plist',
        ...buildOptions.split(' '),
      ],
    );

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((final data) {
      stdout.write(data);
      final match = RegExp(r' ([\w/.-]+/ios/ipa)').firstMatch(data)?.group(1);
      if (match != null) {
        stdout.writeln('Build location: $match');
        final plistPath =
            match.replaceFirst('build/ios/ipa', 'ios/Runner/Info.plist');

        final plistContent = File(plistPath).readAsStringSync();
        final xmlDocument = XmlDocument.parse(plistContent);
        String? bundleName;
        final elements = xmlDocument.findAllElements('key');
        for (final element in elements) {
          if (element.innerText == 'CFBundleName') {
            final valueElement = element.nextElementSibling;
            if (valueElement != null &&
                valueElement.name.toString() == 'string') {
              bundleName = valueElement.innerText;
              break;
            }
          }
        }

        if (bundleName != null) {
          stdout.writeln('CFBundleName: $bundleName');
        } else {
          stdout.writeln('CFBundleName not found in Info.plist.');
        }
        buildLocation = '$match/$bundleName.ipa';
      }
    });
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((final data) => stderr.write(data));

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      exit(1);
    }

    if (buildLocation == null) {
      stderr.writeln('Build location not found.');
      exit(1);
    }

    return buildLocation;
  }
}

import 'dart:io';

abstract final class AndroidUtil {
  static Future<void> configureSigning({
    required final String storePassword,
    required final String keyPassword,
    required final String keyAlias,
    required final String storeFile,
  }) async {
    final file = File('android/key.properties');
    await file.create();
    await file.writeAsString(
      '''
  storePassword=$storePassword
  keyPassword=$keyPassword
  keyAlias=$keyAlias
  storeFile=$storeFile
  ''',
    );
    stdout.writeln('Updated ${file.uri} file');
  }

  static Future<String?> createBuild({
    required final String buildName,
    required final int buildNumber,
    required final String buildOptions,
  }) async {
    stdout
        .writeln('Starting flutter build for $buildName+${buildNumber + 1}...');
    String? buildLocation;

    final process = await Process.start(
      'flutter',
      [
        'build',
        'appbundle',
        '--build-name=$buildName',
        '--build-number=${buildNumber + 1}',
        ...buildOptions.split(' '),
      ],
    );

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((final data) {
      stdout.write(data);
      final match = RegExp(r' ([\w/.-]+\.aab)').firstMatch(data)?.group(1);
      if (match != null) {
        buildLocation = match;
      }
    });
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((final data) => stdout.write(data));

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      exit(1);
    }

    if (buildLocation == null) {
      stdout.writeln('Build location not found.');
      exit(1);
    }

    return buildLocation;
  }
}

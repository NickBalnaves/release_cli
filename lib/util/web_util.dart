import 'dart:io';

abstract final class WebUtil {
  static Future<String?> createBuild({
    required final String buildOptions,
  }) async {
    stdout.writeln('Starting flutter build...');

    final process = await Process.start(
      'flutter',
      [
        'build',
        'web',
        ...buildOptions.split(' '),
      ],
    );

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((final data) {
      stdout.write(data);
    });
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((final data) => stderr.write(data));

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Error running flutter build. ${process.stderr}');
    }

    return 'build/web';
  }
}

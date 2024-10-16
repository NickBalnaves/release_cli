import 'dart:io';

import 'package:args/command_runner.dart';

import '../util/android_util.dart';
import '../util/google_play_store_util.dart';
import '../util/shorebird_util.dart';

class AndroidGooglePlayCommand extends Command {
  AndroidGooglePlayCommand() {
    argParser
      ..addOption(
        'serviceAccount',
        help: 'Google Play service account JSON',
        mandatory: true,
      )
      ..addOption(
        'buildOptions',
        help: 'Build options',
        mandatory: true,
      )
      ..addOption(
        'storePassword',
        help: 'Store password',
        mandatory: true,
      )
      ..addOption(
        'keyPassword',
        help: 'Key password',
        mandatory: true,
      )
      ..addOption(
        'keyAlias',
        help: 'Key alias',
        mandatory: true,
      )
      ..addOption(
        'storeFile',
        help: 'Store file',
        mandatory: true,
      )
      ..addOption(
        'flutterVersion',
        help: 'Flutter version',
        mandatory: true,
      );
  }

  @override
  final name = 'google_play';

  @override
  final description = 'Deploy to Google Play Store';

  @override
  Future<void> run() async {
    final results = argResults!;

    final serviceAccount = results['serviceAccount'] as String;
    final storePassword = results['storePassword'] as String;
    final keyPassword = results['keyPassword'] as String;
    final keyAlias = results['keyAlias'] as String;
    final storeFile = results['storeFile'] as String;
    final buildOptions = results['buildOptions'] as String;
    final flutterVersion = results['flutterVersion'] as String;

    await AndroidUtil.configureSigning(
      storePassword: storePassword,
      keyPassword: keyPassword,
      keyAlias: keyAlias,
      storeFile: storeFile,
    );

    final googlePlayStoreUtil = GooglePlayStoreUtil(
      serviceAccount: serviceAccount,
    );

    final release = await googlePlayStoreUtil.latestRelease(track: 'internal');
    final buildName = release.buildName;
    final buildNumber = release.buildNumber;

    final newBuildPaths = await ShorebirdUtil.patchOrBuildPaths(
      buildName: buildName,
      buildNumber: buildNumber,
      platform: 'android',
      buildOptions: buildOptions,
      flutterVersion: flutterVersion,
    );
    for (final buildPath in newBuildPaths) {
      stdout.writeln(
        'Uploading shorebird build from $buildPath to Google Play...',
      );
      await googlePlayStoreUtil.uploadBuild(
        track: 'internal',
        filePath: buildPath,
      );
    }
  }
}

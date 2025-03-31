import 'dart:io';

import 'package:args/command_runner.dart';

import '../util/apple_appstore_util.dart';
import '../util/git_util.dart';
import '../util/shorebird_util.dart';

class IOSAppStoreCommand extends Command<void> {
  IOSAppStoreCommand() {
    argParser
      ..addOption(
        'appId',
        help: 'App ID',
      )
      ..addOption(
        'issuerId',
        help: 'Issuer ID',
        mandatory: true,
      )
      ..addOption(
        'keyId',
        help: 'Key ID',
        mandatory: true,
      )
      ..addOption(
        'privateKey',
        help: 'Private Key',
        mandatory: true,
      )
      ..addOption(
        'gitUrl',
        help: 'Git URL',
        mandatory: true,
      )
      ..addOption(
        'buildOptions',
        help: 'Build options',
        mandatory: true,
      )
      ..addOption(
        'flutterVersion',
        help: 'Flutter version',
        mandatory: true,
      )
      ..addFlag(
        'allowAssetDiffs',
        help: 'Allow asset diffs',
      );
  }

  @override
  final name = 'app_store';

  @override
  final description = 'Deploy to Apple AppStore';

  @override
  Future<void> run() async {
    final results = argResults!;

    final appId = results['appId'] as String;
    final issuerId = results['issuerId'] as String;
    final keyId = results['keyId'] as String;
    final privateKey =
        (results['privateKey'] as String).replaceAll(r'\n', '\n');
    final gitUrl = results['gitUrl'] as String;
    final buildOptions = results['buildOptions'] as String;
    final flutterVersion = results['flutterVersion'] as String;
    final allowAssetDiffs = results['allowAssetDiffs'] as bool;

    final appleAppStoreUtil = AppleAppStoreUtil(
      issuerId: issuerId,
      keyId: keyId,
      privateKey: privateKey,
      appId: appId,
    );

    await appleAppStoreUtil.configureSigning(gitUrl: gitUrl);

    final release = await appleAppStoreUtil.latestRelease();
    final buildName = release.buildName;
    final buildNumber = release.buildNumber;

    final pubspecVersionChange = await GitUtil.pubspecVersionChange();

    if (pubspecVersionChange == null) {
      await ShorebirdUtil.patch(
        buildName: buildName,
        buildNumber: buildNumber,
        platform: 'ios',
        buildOptions: buildOptions,
        flutterVersion: flutterVersion,
        allowAssetDiffs: allowAssetDiffs,
      );

      return;
    }

    final newBuildPaths = await ShorebirdUtil.release(
      buildName: pubspecVersionChange,
      buildNumber: buildNumber,
      platform: 'ios',
      buildOptions: buildOptions,
      flutterVersion: flutterVersion,
    );
    for (final buildPath in newBuildPaths) {
      stdout.writeln(
        'Uploading shorebird build from $buildPath to TestFlight...',
      );
      await appleAppStoreUtil.uploadBuild(
        filePath: buildPath,
        keyId: keyId,
        issuerId: issuerId,
        privateKey: privateKey,
      );
    }
  }
}

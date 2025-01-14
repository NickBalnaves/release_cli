import 'dart:io';

import 'package:args/command_runner.dart';

import '../util/apple_appstore_util.dart';
import '../util/git_util.dart';
import '../util/shorebird_util.dart';

class IOSAppStoreCommand extends Command {
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

    final latestCommitResult = await Process.run(
      'git',
      ["show HEAD -- pubspec.yaml | grep '^+version: '"],
    );

    if (latestCommitResult.exitCode == 0) {
      stdout.writeln('Latest commit message: ${latestCommitResult.stdout}');
    } else {
      stdout.writeln(
        'Error fetching commit message: ${latestCommitResult.stderr}',
      );
    }
    if (!await GitUtil.hasPubspecVersionChanged()) {
      await ShorebirdUtil.patch(
        buildName: buildName,
        buildNumber: buildNumber,
        platform: 'ios',
        buildOptions: buildOptions,
        flutterVersion: flutterVersion,
      );

      return;
    }

    final newBuildPaths = await ShorebirdUtil.release(
      buildName: buildName,
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

import 'dart:io';

import 'package:args/command_runner.dart';

import '../util/apple_appstore_util.dart';
import '../util/firebase_app_distribution_util.dart';
import '../util/ios_util.dart';

class IOSFirebaseAppDistributionCommand extends Command<void> {
  IOSFirebaseAppDistributionCommand() {
    argParser
      ..addOption(
        'firebaseAppId',
        help: 'Firebase app ID',
        mandatory: true,
      )
      ..addOption(
        'serviceAccount',
        help: 'Firebase service account',
        mandatory: true,
      )
      ..addOption(
        'appId',
        help: 'App ID',
        mandatory: true,
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
        'testerGroups',
        help: 'Tester groups',
        mandatory: true,
      );
  }

  @override
  final name = 'firebase_app_distribution';

  @override
  final description = 'Deploy to Firebase App Distribution';

  @override
  Future<void> run() async {
    final results = argResults!;

    final firebaseAppId = results['firebaseAppId'] as String;
    final serviceAccount = results['serviceAccount'] as String;
    final appId = results['appId'] as String;
    final issuerId = results['issuerId'] as String;
    final keyId = results['keyId'] as String;
    final privateKey =
        (results['privateKey'] as String).replaceAll(r'\n', '\n');
    final gitUrl = results['gitUrl'] as String;
    final buildOptions = results['buildOptions'] as String;
    final testerGroups = results['testerGroups'] as String;

    final appleAppStoreUtil = AppleAppStoreUtil(
      issuerId: issuerId,
      keyId: keyId,
      privateKey: privateKey,
      appId: appId,
    );

    await appleAppStoreUtil.configureSigning(gitUrl: gitUrl, isAdhoc: true);

    final firebaseAppDistributionUtil = FirebaseAppDistributionUtil(
      serviceAccount: serviceAccount,
      appId: firebaseAppId,
    );

    final authClient = await firebaseAppDistributionUtil.initializeAuthClient();

    final release =
        await firebaseAppDistributionUtil.latestRelease(authClient: authClient);
    final buildNumber = release.buildNumber;

    final newBuildPath = await IOSUtil.createBuild(
      buildNumber: buildNumber,
      buildOptions: buildOptions,
    );
    if (newBuildPath != null) {
      stdout.writeln(
        'Uploading flutter build from $newBuildPath to Firebase App '
        'Distribution...',
      );
      await firebaseAppDistributionUtil.uploadBuild(
        authClient: authClient,
        filePath: newBuildPath,
        testerGroups: testerGroups.split(','),
      );
    }
  }
}

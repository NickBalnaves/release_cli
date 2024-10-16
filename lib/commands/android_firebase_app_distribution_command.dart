import 'dart:io';

import 'package:args/command_runner.dart';

import '../util/android_util.dart';
import '../util/firebase_app_distribution_util.dart';

class AndroidFirebaseAppDistributionCommand extends Command {
  AndroidFirebaseAppDistributionCommand() {
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
    final storePassword = results['storePassword'] as String;
    final keyPassword = results['keyPassword'] as String;
    final keyAlias = results['keyAlias'] as String;
    final storeFile = results['storeFile'] as String;
    final testerGroups = results['testerGroups'] as String;
    final buildOptions = results['buildOptions'] as String;

    await AndroidUtil.configureSigning(
      storePassword: storePassword,
      keyPassword: keyPassword,
      keyAlias: keyAlias,
      storeFile: storeFile,
    );

    final firebaseAppDistributionUtil = FirebaseAppDistributionUtil(
      serviceAccount: serviceAccount,
      appId: firebaseAppId,
    );

    final authClient = await firebaseAppDistributionUtil.initializeAuthClient();

    final release =
        await firebaseAppDistributionUtil.latestRelease(authClient: authClient);
    final buildName = release.buildName;
    final buildNumber = release.buildNumber;

    final newBuildPath = await AndroidUtil.createBuild(
      buildName: buildName,
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

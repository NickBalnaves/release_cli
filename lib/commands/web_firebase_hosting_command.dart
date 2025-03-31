import 'dart:io';

import 'package:args/command_runner.dart';

import '../util/firebase_hosting_util.dart';
import '../util/web_util.dart';

class WebFirebaseHostingCommand extends Command<void> {
  WebFirebaseHostingCommand() {
    argParser
      ..addOption(
        'projectId',
        help: 'Firebase project ID',
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
      );
  }

  @override
  final name = 'firebase_hosting';

  @override
  final description = 'Deploy to Firebase Hosting';

  @override
  Future<void> run() async {
    final results = argResults!;

    final projectId = results['projectId'] as String;
    final serviceAccount = results['serviceAccount'] as String;
    final buildOptions = results['buildOptions'] as String;

    final firebaseHostingUtil = FirebaseHostingUtil(
      serviceAccount: serviceAccount,
      projectId: projectId,
    );

    final authClient = await firebaseHostingUtil.initializeAuthClient();

    final buildLocation = await WebUtil.createBuild(
      buildOptions: buildOptions,
    );
    if (buildLocation != null) {
      stdout.writeln(
        'Uploading flutter build to Firebase Hosting...',
      );
      await firebaseHostingUtil.uploadBuild(
        authClient: authClient,
        buildLocation: buildLocation,
      );
    }
  }
}

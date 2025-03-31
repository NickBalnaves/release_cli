import 'package:args/command_runner.dart';

import 'android_firebase_app_distribution_command.dart';
import 'android_google_play_command.dart';

class AndroidCommand extends Command<void> {
  AndroidCommand() {
    addSubcommand(AndroidGooglePlayCommand());
    addSubcommand(AndroidFirebaseAppDistributionCommand());
  }
  @override
  final String name = 'android';

  @override
  final String description = 'Deployments for Android';
}

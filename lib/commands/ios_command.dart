import 'package:args/command_runner.dart';

import 'ios_app_store_command.dart';
import 'ios_firebase_app_distribution_command.dart';

class IOSCommand extends Command<void> {
  IOSCommand() {
    addSubcommand(IOSAppStoreCommand());
    addSubcommand(IOSFirebaseAppDistributionCommand());
  }
  @override
  final String name = 'ios';

  @override
  final String description = 'Deployments for iOS';
}

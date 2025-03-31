import 'package:args/command_runner.dart';

import 'web_firebase_hosting_command.dart';

class WebCommand extends Command<void> {
  WebCommand() {
    addSubcommand(WebFirebaseHostingCommand());
  }
  @override
  final String name = 'web';

  @override
  final String description = 'Deployments for Web';
}

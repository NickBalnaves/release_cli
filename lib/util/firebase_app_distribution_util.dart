import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../models/release.dart';
import 'logging_util.dart';

class FirebaseAppDistributionUtil {
  FirebaseAppDistributionUtil({
    required final String serviceAccount,
    required final String appId,
  })  : _appId = appId,
        _projectId = appId.split(':')[1],
        _serviceAccount = ServiceAccountCredentials.fromJson(
          jsonDecode(serviceAccount) as Map,
        );

  final ServiceAccountCredentials _serviceAccount;
  final String _appId;
  final String _projectId;

  Future<AutoRefreshingAuthClient> initializeAuthClient() async =>
      clientViaServiceAccount(
        _serviceAccount,
        ['https://www.googleapis.com/auth/cloud-platform'],
      );

  Future<Release> latestRelease({
    required final AutoRefreshingAuthClient authClient,
  }) async {
    final response = await authClient.get(
      Uri.parse(
        'https://firebaseappdistribution.googleapis.com/v1/projects/$_projectId/apps/$_appId/releases',
      ),
    );

    if (response.statusCode != 200) {
      logHttpResponse(response);
      exit(1);
    }
    final data = json.decode(response.body) as Map<String, dynamic>?;
    final releases = data?['releases'] as List?;
    final firstRelease = releases?.firstOrNull as Map?;
    final displayVersion = firstRelease?['displayVersion'] as String?;

    return Release(
      buildName: displayVersion ?? '1.0.0',
      buildNumber:
          int.tryParse(firstRelease?['buildVersion'] as String? ?? '') ?? 0,
    );
  }

  Future<void> uploadBuild({
    required final AutoRefreshingAuthClient authClient,
    required final String filePath,
    required final List<String> testerGroups,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://firebaseappdistribution.googleapis.com/upload/v1/projects/$_projectId/apps/$_appId/releases:upload',
      ),
    )..files.add(await http.MultipartFile.fromPath('file', filePath));

    final uploadResponse =
        await http.Response.fromStream(await authClient.send(request));

    if (uploadResponse.statusCode != 200) {
      logHttpResponse(uploadResponse);
      exit(1);
    }
    final operationUrl =
        (jsonDecode(uploadResponse.body) as Map?)?['name'] as String?;
    String? releaseId;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final uploadBuildUrl = await authClient.get(
        Uri.parse(
          'https://firebaseappdistribution.googleapis.com/v1/$operationUrl',
        ),
      );
      if (uploadBuildUrl.statusCode == 200) {
        final data = jsonDecode(uploadBuildUrl.body) as Map<String, dynamic>?;
        final done = data?['done'] as bool?;
        final error = data?['error'] as Map<String, dynamic>?;
        final release = (data?['response'] as Map<String, dynamic>?)?['release']
            as Map<String, dynamic>?;
        if (done != null && done) {
          if (release != null) {
            releaseId = (release['name'] as String?)?.split('/').last;
            stdout.writeln('Release completed successfully');
            if (releaseId == null) {
              stdout.writeln('Release ID not found.');
              exit(1);
            }
            stdout.writeln('Release ID: $releaseId');
          } else if (error != null) {
            stdout.writeln('Error: ${error['message']}');
          }
          break;
        }
        stdout.writeln('Polling... Operation still in progress.');
      } else {
        logHttpResponse(uploadBuildUrl);
        exit(1);
      }
    }
    stdout.writeln('Uploaded to firebase app distribution successfully.');

    final latestCommitResult =
        await Process.run('git', ['log', '-1', '--pretty=%B']);

    if (latestCommitResult.exitCode == 0) {
      stdout.writeln('Latest commit message: ${latestCommitResult.stdout}');
    } else {
      stdout.writeln(
        'Error fetching commit message: ${latestCommitResult.stderr}',
      );
    }

    final updateReleaseResponse = await authClient.patch(
      Uri.parse(
        'https://firebaseappdistribution.googleapis.com/v1/projects/$_projectId/apps/$_appId/releases/$releaseId',
      ),
      body: jsonEncode({
        'releaseNotes': {'text': latestCommitResult.stdout},
      }),
    );

    if (updateReleaseResponse.statusCode != 200) {
      logHttpResponse(updateReleaseResponse);
      exit(1);
    }
    stdout.writeln('Updated release notes successfully.');

    final distributeReleaseResponse = await authClient.post(
      Uri.parse(
        'https://firebaseappdistribution.googleapis.com/v1/projects/$_projectId/apps/$_appId/releases/$releaseId:distribute',
      ),
      body: jsonEncode({'groupAliases': testerGroups}),
    );

    if (distributeReleaseResponse.statusCode != 200) {
      logHttpResponse(distributeReleaseResponse);
      exit(1);
    }
    stdout.writeln('Distributed release successfully.');
  }
}

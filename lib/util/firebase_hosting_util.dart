import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'logging_util.dart';

class FirebaseHostingUtil {
  FirebaseHostingUtil({
    required final String serviceAccount,
    required final String projectId,
  })  : _projectId = projectId,
        _serviceAccount = ServiceAccountCredentials.fromJson(
          jsonDecode(serviceAccount) as Map,
        );

  final ServiceAccountCredentials _serviceAccount;
  final String _projectId;

  Future<AutoRefreshingAuthClient> initializeAuthClient() async =>
      clientViaServiceAccount(
        _serviceAccount,
        [
          'https://www.googleapis.com/auth/cloud-platform',
        ],
      );

  Future<void> uploadBuild({
    required final AutoRefreshingAuthClient authClient,
    required final String buildLocation,
  }) async {
    stdout.writeln('Creating version...');
    final versionResponse = await authClient.post(
      Uri(
        scheme: 'https',
        host: 'firebasehosting.googleapis.com',
        path: 'v1beta1/sites/$_projectId/versions',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (versionResponse.statusCode != 200) {
      logHttpResponse(versionResponse);
      exit(1);
    }
    final versionData =
        json.decode(versionResponse.body) as Map<String, dynamic>;
    final versionName = versionData['name'] as String;

    stdout.writeln('Populating release...');
    final fileMap = <String, String>{};

    await for (final file
        in Directory('build/web').list(recursive: true, followLinks: false)) {
      if (file is File) {
        final fileBytes = await file.readAsBytes();
        final compressedBytes = GZipCodec().encode(fileBytes);
        final compressedHash = sha256.convert(compressedBytes).toString();
        final relativePath = file.path.replaceFirst('build/web/', '');
        final filePath = '/$relativePath';

        fileMap[filePath] = compressedHash;
      }
    }

    final populateResponse = await authClient.post(
      Uri.parse(
        'https://firebasehosting.googleapis.com/v1beta1/$versionName:populateFiles',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'files': fileMap}),
    );

    if (populateResponse.statusCode != 200) {
      logHttpResponse(populateResponse);
      exit(1);
    }

    final releaseData =
        json.decode(populateResponse.body) as Map<String, dynamic>;
    final uploadUrl = releaseData['uploadUrl'];
    final uploadRequiredHashes = releaseData['uploadRequiredHashes'];

    stdout.writeln('Uploading files...');
    final uploadTasks = <Future>[];

    for (final hash in uploadRequiredHashes) {
      final filePath =
          fileMap.entries.firstWhere((final entry) => entry.value == hash).key;
      final file = File('build/web$filePath');
      final fileBytes = await file.readAsBytes();

      final compressedBytes = GZipCodec().encode(fileBytes);

      final uploadTask = authClient
          .put(
        Uri.parse('$uploadUrl/$hash'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: compressedBytes,
      )
          .then((final response) {
        if (response.statusCode == 200) {
          stdout.writeln('File $filePath uploaded successfully.');
        } else {
          logHttpResponse(response);
        }
      });

      uploadTasks.add(uploadTask);
    }

    await Future.wait(uploadTasks);

    stdout.writeln('All files uploaded. Finalizing deployment...');
    final finalizeResponse = await authClient.patch(
      Uri.parse(
        'https://firebasehosting.googleapis.com/v1beta1/$versionName?update_mask=status',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'status': 'FINALIZED',
      }),
    );

    if (finalizeResponse.statusCode != 200) {
      logHttpResponse(finalizeResponse);
      exit(1);
    }

    stdout.writeln('Releasing...');
    final releaseResponse = await authClient.post(
      Uri(
        scheme: 'https',
        host: 'firebasehosting.googleapis.com',
        path: 'v1beta1/sites/$_projectId/releases',
        queryParameters: {
          'versionName': versionName,
        },
      ),
      headers: {'Content-Type': 'application/json'},
    );

    if (releaseResponse.statusCode != 200) {
      logHttpResponse(releaseResponse);
      exit(1);
    }

    stdout.writeln('🎉 Deployment completed successfully!\n'
        'Deployed to: https://$_projectId.web.app');
  }
}

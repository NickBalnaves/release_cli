import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

import '../models/release.dart';
import 'logging_util.dart';

class AppleAppStoreUtil {
  AppleAppStoreUtil({
    required final String issuerId,
    required final String keyId,
    required final String privateKey,
    required final String appId,
  })  : _issuerId = issuerId,
        _keyId = keyId,
        _privateKey = privateKey,
        _appId = appId,
        _token = JWT(
          {
            'aud': 'appstoreconnect-v1',
            'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 1200,
            'iss': issuerId,
          },
          header: {'alg': 'ES256', 'kid': keyId},
        ).sign(ECPrivateKey(privateKey), algorithm: JWTAlgorithm.ES256);

  final String _token;
  final String _issuerId;
  final String _keyId;
  final String _privateKey;
  final String _appId;

  Future<void> configureSigning({
    required final String gitUrl,
    final bool isAdhoc = false,
  }) async {
    final bundleId = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync()
        .split('\n')
        .firstWhere(
          (final line) => line.contains('PRODUCT_BUNDLE_IDENTIFIER'),
        )
        .split(' = ')[1]
        .replaceAll(';', '')
        .trim();
    final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
    projectFile.writeAsStringSync(
      projectFile
          .readAsStringSync()
          .replaceAll(
            'CODE_SIGN_IDENTITY = "Apple Development";',
            'CODE_SIGN_IDENTITY = "iPhone Distribution";',
          )
          .replaceAll(
            'CODE_SIGN_STYLE = Automatic;',
            'CODE_SIGN_STYLE = Manual;',
          )
          .replaceAll(
            'PROVISIONING_PROFILE_SPECIFIER = "";',
            'PROVISIONING_PROFILE_SPECIFIER = "match '
                '${isAdhoc ? 'AdHoc' : 'AppStore'} '
                '$bundleId";',
          ),
    );

    final apiKey = '{"key_id": "$_keyId", '
        '"issuer_id": "$_issuerId", '
        '"key": "${_privateKey.replaceAll('\n', r'\n')}", '
        '"in_house": false }';
    final fastlaneMatchProcess = await Process.start(
      'fastlane',
      [
        'match',
        if (isAdhoc) 'adhoc' else 'appstore',
        '--app_identifier',
        bundleId,
        '--git_url',
        gitUrl,
        '--api_key',
        apiKey,
        '--force_for_new_devices',
        'true',
        '--keychain_password',
        'default',
      ],
      mode: ProcessStartMode.inheritStdio,
      environment: Platform.environment,
    );

    final exitCode = await fastlaneMatchProcess.exitCode;
    if (exitCode != 0) {
      exit(1);
    }
  }

  Future<Release> latestRelease() async {
    final response = await http.get(
      Uri.parse(
        'https://api.appstoreconnect.apple.com/v1/builds?filter[app]=$_appId&sort=-version,-uploadedDate&limit=1&fields[builds]=version&include=preReleaseVersion',
      ),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map?;
      final buildNumber = int.tryParse(
        (((body?['data'] as List?)?.firstOrNull as Map?)?['attributes']
                as Map?)?['version'] as String? ??
            '',
      );
      final buildName = (((body?['included'] as List?)?.firstOrNull
          as Map?)?['attributes'] as Map?)?['version'] as String?;

      return Release(
        buildName: buildName ?? '1.0.0',
        buildNumber: buildNumber ?? 0,
      );
    }

    logHttpResponse(response);
    exit(1);
  }

  Future<void> uploadBuild({
    required final String filePath,
    required final String keyId,
    required final String issuerId,
    required final String privateKey,
  }) async {
    final file = File(
      '${Platform.environment['HOME']}/.appstoreconnect/private_keys/AuthKey_$keyId.p8',
    );
    stdout.writeln('Checking if private key exists in ${file.path}...');
    if (!file.existsSync()) {
      stdout.writeln('Private key not found. Creating one...');
      await file.create(recursive: true);
      await file.writeAsString(privateKey);
    }
    final result = await Process.run('xcrun', [
      'altool',
      '--upload-app',
      '-f',
      filePath,
      '-t',
      'ios',
      '--apiKey',
      keyId,
      '--apiIssuer',
      issuerId,
    ]);

    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      exit(1);
    }
    stdout.writeln('Uploaded to TestFlight successfully.');
  }
}

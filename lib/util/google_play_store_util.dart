import 'dart:io';

import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../models/release.dart';

class GooglePlayStoreUtil {
  GooglePlayStoreUtil({required final String serviceAccount})
      : _serviceAccountCredentials = ServiceAccountCredentials.fromJson(
          serviceAccount,
        );

  final ServiceAccountCredentials _serviceAccountCredentials;

  Future<String> _packageName() async {
    final file = File('android/app/build.gradle');

    if (!file.existsSync()) {
      stdout.writeln('build.gradle file not found!');
      exit(1);
    }

    final content = await file.readAsString();
    final regex = RegExp(r'applicationId\s+"(.+?)"');
    final match = regex.firstMatch(content);

    final packageName = match?.group(1);
    if (packageName == null) {
      stdout.writeln('Application ID not found in build.gradle');
      exit(1);
    }

    return packageName;
  }

  Future<Release> latestRelease({required final String track}) async {
    final packageName = await _packageName();

    final scopes = [AndroidPublisherApi.androidpublisherScope];
    final client = await clientViaServiceAccount(
      _serviceAccountCredentials,
      scopes,
    );
    final androidPublisher = AndroidPublisherApi(client);

    try {
      final edit = await androidPublisher.edits.insert(AppEdit(), packageName);

      final tracks =
          await androidPublisher.edits.tracks.list(packageName, edit.id ?? '');
      final releases = tracks.tracks
          ?.firstWhere((final playStoreTrack) => playStoreTrack.track == track)
          .releases;

      if (releases != null && releases.isNotEmpty) {
        final latestRelease = releases.firstWhere(
          (final release) => release.status == 'completed',
          orElse: () => releases.first,
        );
        final name = latestRelease.name;
        final versionCode =
            int.tryParse(latestRelease.versionCodes?.firstOrNull ?? '');
        if (name == null || versionCode == null) {
          stdout.writeln('No releases found for the $track track.');

          return Release(
            buildName: name ?? '1.0.0',
            buildNumber: versionCode ?? 0,
          );
        }

        return Release(buildName: name, buildNumber: versionCode);
      }
      stdout.writeln('No releases found for the $track track.');

      return const Release(buildName: '1.0.0', buildNumber: 0);
    } catch (error) {
      stdout.writeln(error);
      exit(1);
    } finally {
      client.close();
    }
  }

  Future<void> uploadBuild({
    required final String track,
    required final String filePath,
  }) async {
    final packageName = await _packageName();
    final client = await clientViaServiceAccount(
      _serviceAccountCredentials,
      [AndroidPublisherApi.androidpublisherScope],
    );

    final androidPublisher = AndroidPublisherApi(client);

    try {
      final edit = await androidPublisher.edits.insert(AppEdit(), packageName);
      final editId = edit.id;
      if (editId == null) {
        stdout.writeln('Edit ID not found.');
        exit(1);
      }

      final file = File(filePath);
      final uploadResponse = await androidPublisher.edits.bundles.upload(
        packageName,
        editId,
        uploadMedia: Media(file.openRead(), file.lengthSync()),
      );

      stdout.writeln('Uploaded version code: ${uploadResponse.versionCode}');

      await androidPublisher.edits.tracks.update(
        Track()
          ..track = track
          ..releases = [
            TrackRelease()
              ..versionCodes = [uploadResponse.versionCode?.toString() ?? '']
              ..status = 'completed',
          ],
        packageName,
        editId,
        track,
      );

      await androidPublisher.edits.commit(packageName, editId);
      stdout.writeln('Edit committed successfully');
    } catch (error) {
      stdout.writeln(error);
      exit(1);
    } finally {
      client.close();
    }
  }
}

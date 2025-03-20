# Release CLI

A command-line interface (CLI) for managing and automating app deployments.

## Features

- **Android Deployments**
  - Deploy Android apps to **Google Play Store**.
  - Deploy Android apps to **Firebase App Distribution**.

- **iOS Deployments**
  - Deploy iOS apps to **Apple App Store**.
  - Deploy iOS apps to **Firebase App Distribution**.

- **Web Deployments**
  - Deploy web apps to **Firebase Hosting**.

## Usage

To use the CLI, run the following command:

```sh
release_cli <command> [options]
```

## Commands

### Android

#### `android`

This is the parent command for Android-specific deployments. It includes the following subcommands:

##### 1. `android google_play`

Deploy an Android app to the Google Play Store.

**Prerequisites:**

- `SHOREBIRD_TOKEN` environment variable exported for shorebird releases.

**Required Options:**

- `--serviceAccount`: Service account JSON.
- `--buildOptions`: Build options for the app.
- `--storePassword`: Password for the keystore.
- `--keyPassword`: Password for the key in the keystore.
- `--keyAlias`: Alias for the key in the keystore.
- `--storeFile`: Path to the keystore file.
- `--flutterVersion`: Version of Flutter to use.
- `--allowAssetDiffs`: Allow asset diffs.

##### 2. `android firebase_app_distribution`

Deploy an Android app to Firebase App Distribution.

**Required Options:**

- `--firebaseAppId`: Firebase app ID.
- `--serviceAccount`: Firebase service account.
- `--buildOptions`: Build options for the app.
- `--storePassword`: Password for the keystore.
- `--keyPassword`: Password for the key in the keystore.
- `--keyAlias`: Alias for the key in the keystore.
- `--storeFile`: Path to the keystore file.
- `--testerGroups`: Tester groups to invite for app testing.

### iOS

#### `ios`

This is the parent command for iOS-specific deployments. It includes the following subcommands:

**Prerequisites:**

- Automatic signing enabled.
- `fastlane` installed.
- `MATCH_PASSWORD` environment variable exported for fastlane match.

##### 1. `ios app_store`

Deploy an iOS app to the Apple App Store.

**Prerequisites:**

- Filled in `exportOptions.plist` file in the ios folder.
- `SHOREBIRD_TOKEN` environment variable exported for shorebird releases.

**Required Options:**

- `--appId`: The iOS app ID.
- `--issuerId`: Apple Developer Issuer ID.
- `--keyId`: Apple Developer Key ID.
- `--privateKey`: Apple Developer private key.
- `--gitUrl`: URL to the app's Git repository.
- `--buildOptions`: Build options for the app.
- `--flutterVersion`: Version of Flutter to use.
- `--allowAssetDiffs`: Allow asset diffs.

##### 2. `ios firebase_app_distribution`

Deploy an iOS app to Firebase App Distribution.

**Prerequisites:**

- Filled in `exportOptions-adhoc.plist` file in the ios folder.

**Required Options:**

- `--firebaseAppId`: Firebase app ID.
- `--serviceAccount`: Firebase service account.
- `--appId`: The iOS app ID.
- `--issuerId`: Apple Developer Issuer ID.
- `--keyId`: Apple Developer Key ID.
- `--privateKey`: Apple Developer private key.
- `--gitUrl`: URL to the app's Git repository.
- `--buildOptions`: Build options for the app.
- `--testerGroups`: Tester groups to invite for app testing.

### Web

#### `web`

This is the parent command for Web-specific deployments. It includes the following subcommands:

##### 1. `web firebase_hosting`

Deploy a web app to Firebase Hosting.

**Required Options:**

- `--projectId`: Firebase project ID.
- `--serviceAccount`: Path to the Firebase service account.
- `--buildOptions`: Build options for the app.

## Environment Variables

You can expose the following environment variable to enable additional functionality:

- `SLACK_WEBHOOK_URL_ERROR`: Set this to a Slack Incoming Webhook URL to send error notifications to a Slack channel.

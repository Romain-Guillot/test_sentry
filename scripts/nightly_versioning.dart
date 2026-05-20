import 'dart:io';

/// Update the application's version for nightly builds.
/// Based on Codemagic environment variables:
/// https://docs.codemagic.io/yaml-basic-configuration/environment-variables/
///
/// The version format is: SHORT_YEAR.MONTH.DAY (e.g. 26.5.20).
/// We use the last two digits of the year because MSI installers don't
/// support version number components above 256.
///
/// When the build is triggered by a git tag (CM_TAG is set), the pubspec
/// version is left untouched so tagged releases keep their declared version.
Future<void> main() async {
  final gitTag = Platform.environment['CM_TAG'];
  if (gitTag != null && gitTag.isNotEmpty) {
    stdout.writeln('Git tag is defined: $gitTag');
    stdout.writeln('Nightly build version is skipped');
    return;
  }

  final now = DateTime.now();
  final shortYear = now.year.toString().substring(2);
  final version = '$shortYear.${now.month}.${now.day}';
  stdout.writeln('Nightly build version 👉 $version');

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('pubspec.yaml not found in ${Directory.current.path}');
    exit(1);
  }

  final lines = pubspec.readAsLinesSync();
  final versionLine = RegExp(r'^version:\s*([^\s+]+)(\+(\d+))?');
  var updated = false;
  for (var i = 0; i < lines.length; i++) {
    final match = versionLine.firstMatch(lines[i]);
    if (match != null) {
      final buildSuffix = match.group(2) ?? '';
      lines[i] = 'version: $version$buildSuffix';
      updated = true;
      break;
    }
  }

  if (!updated) {
    stderr.writeln('Could not find version line in pubspec.yaml');
    exit(1);
  }

  pubspec.writeAsStringSync('${lines.join('\n')}\n');
  stdout.writeln('pubspec.yaml version updated to $version');
}

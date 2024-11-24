import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const String version = '0.0.1';

class PubspecModifier {
  final String filePath;
  final String username;
  final String token;

  PubspecModifier(this.filePath, this.username, this.token);

  void updateDependency(String dependencyName) {
    final file = File(filePath);

    if (!file.existsSync()) {
      print('Error: pubspec.yaml not found at $filePath');
      return;
    }

    final content = file.readAsStringSync();
    final yamlDoc = loadYaml(content);
    final yamlEditor = YamlEditor(content);

    final dependencies = yamlDoc['dependencies'];
    if (dependencies == null || dependencies is! Map) {
      print('No dependencies found in pubspec.yaml');
      return;
    }

    bool updated = false;

    dependencies.forEach((key, value) {
      if (value is Map && value.containsKey('path')) {
        final localPath = value['path'];
        final lastPart = localPath.split(Platform.pathSeparator).last;

        final gitUrl = 'https://$username:$token@github.com/$username/$lastPart.git';
        final gitDependency = {
          'git': {'url': gitUrl, 'ref': 'main'}
        };

        yamlEditor.update(['dependencies', key], gitDependency);
        print('Updated $key to use git dependency: $gitUrl');
        updated = true;
      }
    });

    if (!updated) {
      print('No dependencies with local paths found.');
      return;
    }

    file.writeAsStringSync(yamlEditor.toString());
    print('pubspec.yaml updated successfully!');
  }
}

ArgParser buildParser() {
  return ArgParser()
    ..addOption(
      'file',
      abbr: 'f',
      help: 'Path to the pubspec.yaml file to modify.',
    )
    ..addOption(
      'username',
      abbr: 'u',
      help: 'GitHub username for git dependency replacement.',
    )
    ..addOption(
      'token',
      abbr: 't',
      help: 'GitHub personal access token for git dependency replacement.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
        'version',
        negatable: false,
        help: 'Print the tool version.');
}

void printUsage(ArgParser argParser) {
  print('Usage: dart dart_actions_util.dart --file <path> --username <user> --token <token>');
  print(argParser.usage);
}

void main(List<String> arguments) {
  final argParser = buildParser();

  try {
    final results = argParser.parse(arguments);

    if (results.wasParsed('help')) {
      printUsage(argParser);
      return;
    }

    if (results.wasParsed('version')) {
      print('dart_actions_util version: $version');
      return;
    }

    final filePath = results['file'];
    final username = results['username'];
    final token = results['token'];

    if (filePath == null || username == null || token == null) {
      print('Error: Missing required arguments.');
      printUsage(argParser);
      return;
    }

    final modifier = PubspecModifier(filePath, username, token);
    modifier.updateDependency(filePath);
  } on FormatException catch (e) {
    print('Error: ${e.message}');
    print('');
    printUsage(argParser);
  }
}

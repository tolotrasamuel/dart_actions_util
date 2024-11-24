import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as path;

const String version = '0.0.1';

class PubspecModifier {
  final String filePath;
  final String? rootLocalLibrary;

  static Map<String, dynamic> castAsMap(dynamic value) {
    if (value == null) return {};
    return Map<String, dynamic>.from(value);
  }

  PubspecModifier(
    this.filePath,
    this.rootLocalLibrary,
  );

  void updateDependency(String dependencyName) {
    final file = File(filePath);

    if (!file.existsSync()) {
      print('Error: pubspec.yaml not found at $filePath');
      return;
    }

    final content = file.readAsStringSync();
    final yamlDoc = loadYaml(content);
    final yamlEditor = YamlEditor(content);

    final dependencies = castAsMap(yamlDoc['dependencies']);
    final remoteDependencies = castAsMap(yamlDoc['remote_dependencies']);

    bool updated = false;

    final rootLocalLibrary = this.rootLocalLibrary;
    dependencies.forEach((key, value) {
      // final isPath = value is Map && value.containsKey('path');
      // if (!isPath) {
      //   return;
      // }

      final remoteDependency = remoteDependencies[key];

      if (remoteDependency == null) {
        print('No remote dependency found for $key');
        return;
      }

      // final localPath = value['path'];
      // final lastPart = localPath.split(Platform.pathSeparator).last;

      late Map<String, dynamic> gitDependency;

      if (rootLocalLibrary == null) {
        gitDependency = castAsMap(remoteDependency);
      } else {
        final localPath = path.join(rootLocalLibrary, key);
        gitDependency = {
          'path': localPath,
        };
      }

      yamlEditor.update(['dependencies', key], gitDependency);
      print('Updated $key to git dependency');
      updated = true;
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
      mandatory: true,
      help: 'Path to the pubspec.yaml file to modify.',
    )
    ..addOption(
      'root',
      abbr: 'r',
      help: 'Root local library name for git dependency replacement.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.');
}

void printUsage(ArgParser argParser) {
  print(
      'Usage: dart dart_actions_util.dart --file <path> --username <user> --token <token>');
  print(argParser.usage);
}

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    /// dart run debug
    arguments = [...arguments];
    arguments.addAll(["--file", "pubspec.test.yaml"]);
    // arguments.addAll(["--root", "./"]);

  }
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
    // results['file'] = 'pubspec.yaml';

    final filePath = results['file'];
    final rootLocalLibrary = results['root'];
    // final token = results['token'];

    if (filePath == null) {
      print('Error: Missing required arguments.');
      printUsage(argParser);
      return;
    }

    final modifier = PubspecModifier(filePath, rootLocalLibrary);
    modifier.updateDependency(filePath);
  } on FormatException catch (e) {
    print('Error: ${e.message}');
    print('');
    printUsage(argParser);
  }
}

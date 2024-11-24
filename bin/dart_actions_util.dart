import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

const String version = '0.0.1';

class PubspecModifier {
  final String filePath;
  final String? mapFile;

  static Map<String, dynamic> castAsMap(dynamic value) {
    if (value == null) return {};
    return Map<String, dynamic>.from(value);
  }

  PubspecModifier(
    this.filePath,
    this.mapFile,
  );

  void updateDependency(String dependencyName) {
    final file = File(filePath);

    if (!file.existsSync()) {
      print('Error: pubspec.yaml not found at $filePath');
      return;
    }

    final content = file.readAsStringSync();
    final yamlDoc = loadYaml(content);
    final mapToLocalFile = mapFile;

    Map<String, dynamic> localDependencies = {};
    if (mapToLocalFile != null) {
      final mapFileContent = File(mapToLocalFile).readAsStringSync();
      final mapDocYaml = loadYaml(mapFileContent);
      localDependencies = castAsMap(mapDocYaml['local_dependencies']);
    }

    final yamlEditor = YamlEditor(content);

    final dependencies = castAsMap(yamlDoc['dependencies']);
    final remoteDependencies = castAsMap(yamlDoc['remote_dependencies']);

    bool updated = false;

    dependencies.forEach((key, value) {
      final remoteDependency = remoteDependencies[key];
      final localDependency = localDependencies[key];

      late Map<String, dynamic> gitDependency;

      if (localDependency != null) {
        gitDependency = castAsMap(localDependency);
        print('Updated $key to local dependency');
      } else if (remoteDependency != null) {
        gitDependency = castAsMap(remoteDependency);
        print('Updated $key to git dependency');
      } else {
        print('No remote or local dependency found for $key');
        return;
      }

      yamlEditor.update(['dependencies', key], gitDependency);
      updated = true;
    });

    if (!updated) {
      print('No dependencies with local paths found.');
      return;
    }

    file.writeAsStringSync(yamlEditor.toString());
    print('$filePath updated successfully!');
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
      'mapFile',
      abbr: 'm',
      help:
          'Path to the map file to use for updating the pubspec.yaml file to local paths.',
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
    arguments.addAll([
      "--mapFile",
      "/Users/samuel/StudioProjects/shared_frontend_tools/pubspec.local.yaml"
    ]);
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
    final mapFile = results['mapFile'];
    // final token = results['token'];

    if (filePath == null) {
      print('Error: Missing required arguments.');
      printUsage(argParser);
      return;
    }

    print("filePath: $filePath and mapFile: $mapFile");
    final modifier = PubspecModifier(filePath, mapFile);
    modifier.updateDependency(filePath);
  } on FormatException catch (e) {
    print('Error: ${e.message}');
    print('');
    printUsage(argParser);
  }
}

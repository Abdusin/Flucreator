import 'dart:convert';
import 'dart:io';
import 'package:flucreator/flucreator.dart';
import 'package:process_run/shell_run.dart';

void main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    help();
  }
  var index = args.indexWhere((arg) => arg.startsWith('--create='));
  if (index == -1) {
    return createProject(args);
  } else {
    if (args.length - 1 > index) {
      var type = args[index];
      if (type.contains('project')) {
        return createProject(args);
      } else if (type.contains('screen')) {
        return createScreen(args);
      } else {
        print('type not found');
        help();
      }
    }
  }
}

void help() {
  print('Create project: flucreator --org com.example app_name');
  print('Create screen: flucreator --create=screen screen_name');
  print('Create screen without controller: flucreator --create=screen --no-controller screen_name');
  exit(0);
}

void createScreen(List<String> args) async {
  String name;
  var noController = args.contains('--no-controller');
  if (args.last.isNotEmpty && !args.last.contains('--create=')) {
    name = args.last;
  } else {
    stdout.write('Screen Name:');
    name = stdin.readLineSync(encoding: utf8);
  }
  name = name[0].toUpperCase() + name.substring(1);
  var packageName;
  var lines = File('pubspec.yaml').readAsLinesSync();
  for (var element in lines) {
    if (element.contains('name')) {
      packageName = element.split(':')[1].trim();
      break;
    }
  }
  var screenFile = await File('lib/screens/$name.dart').create(recursive: true);
  screenSetter(screenFile, packageName, name, noController);

  if (!noController) {
    var controllerFile = await File('lib/controllers/$name' 'Controller.dart').create(recursive: true);
    screenControllerSetter(controllerFile, name + 'Controller');
  }

  exit(0);
}

void createProject(List<String> args) async {
  var shell = Shell();
  String name;
  String org;
  String extraArgment;
  for (var i = 0; i < args.length; i++) {
    var element = args[i];
    if (element.isNotEmpty) {
      if (i > 0 && args[i - 1] == '--org') {
        org = element;
      }
      if (i == args.length - 1) {
        name = element;
      }
    }
  }

  while (name == null || name.isEmpty) {
    stdout.write('Project Name:');
    name = stdin.readLineSync(encoding: utf8);
  }
  while (org == null || org.isEmpty) {
    stdout.write('org:');
    org = stdin.readLineSync(encoding: utf8);
  }
  stdout.write('extraArgment:');
  extraArgment = stdin.readLineSync(encoding: utf8);

  var code = 'flutter create --org $org $extraArgment $name';
  var results = await shell.run(code);
  if (results.isEmpty) return print('Project Not Created');
  var text = results.first.stdout.toString();
  if (!text.contains('Creat')) return print('Project Not Created');

  Directory('$name/lib/screens').createSync(recursive: true);
  Directory('$name/lib/controllers').createSync(recursive: true);
  Directory('$name/lib/models').createSync(recursive: true);
  Directory('$name/lib/widgets').createSync(recursive: true);
  Directory('$name/lib/utils').createSync(recursive: true);

  pubSpecSetter(name);
  mainFileSetter(name);
  homeControllerSetter(name);
  homeScreenSetter(name);
  appSpacesSetter(name);
}

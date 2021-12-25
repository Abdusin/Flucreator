import 'dart:convert';
import 'dart:io';
import 'package:flucreator/flucreator.dart';
import 'package:process_run/shell_run.dart';

void main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    return help();
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
  String fileNameFormatter(String raw) {
    var name = '';
    if (raw.toUpperCase() == raw) {
      return raw.toLowerCase();
    }
    name = raw.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
      return '_' + match.group(0).toLowerCase();
    });
    if (name.startsWith('_')) {
      name = name.substring(1);
    }
    return name;
  }

  String classNameFormatter(String raw) {
    var name = '';
    name = raw.replaceAllMapped(RegExp(r'_[a-z]'), (match) {
      return match.group(0).substring(1, 2).toUpperCase() + match.group(0).substring(2);
    });
    return name;
  }

  var noController = args.contains('--no-controller');
  if (args.last.isNotEmpty && !args.last.contains('--create=')) {
    name = fileNameFormatter(args.last);
  } else {
    stdout.write('Screen Name:');
    name = fileNameFormatter(stdin.readLineSync(encoding: utf8));
  }

  var packageName;
  var lines = File('pubspec.yaml').readAsLinesSync();
  for (var element in lines) {
    if (element.contains('name')) {
      packageName = element.split(':')[1].trim();
      break;
    }
  }
  if (name.contains('screen')) {
    name = name.replaceAll('screen', '');
  }
  var screenName = classNameFormatter(name) + 'Screen';
  var screenFile = await File('lib/screens/${name}_screen.dart').create(recursive: true);
  if (!noController) {
    var controllerName = classNameFormatter(name) + 'ScreenController';
    var controllerFile = await File('lib/controllers/$name' '_controller.dart').create(recursive: true);
    screenControllerSetter(controllerFile, controllerName);
    screenSetter(screenFile, packageName, screenName, controllerName);
  } else {
    screenSetter(screenFile, packageName, screenName);
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
  return exit(0);
}

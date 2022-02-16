import 'dart:convert';
import 'dart:io';
import 'package:flucreator/flucreator.dart';
import 'package:flucreator/console.dart';
import 'package:process_run/shell_run.dart';
import 'package:change_case/change_case.dart';

void main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    return help();
  }
  var index = args.indexWhere((arg) => arg.startsWith('--create='));
  if (index == -1) {
    return createProject(args);
  } else {
    if (!File('pubspec.yaml').existsSync()) {
      printRed('You need to be in a flutter project to run this command');
      return help();
    }
    var type = args[index];
    if (args.length - 1 > index) {
      if (type.contains('project')) {
        return createProject(args);
      } else if (type.contains('screen')) {
        return createScreen(args);
      } else if (type.contains('assets')) {
        return createAssets(args);
      } else {
        printRed('type not found');
        help();
      }
    } else if (type.contains('route')) {
      return createRoute();
    } else {
      printRed('type error');
      help();
    }
  }
}

void help() {
  printBlue('Create project: flucreator --org com.example app_name');
  printBlue('Create route: flucreator --create=route');
  printBlue('Create assets: flucreator --create=assets <folder_name ex:assets>');
  printBlue('Create screen: flucreator --create=screen screen_name');
  printBlue('Create screen without controller: flucreator --create=screen --no-controller screen_name');
  exit(0);
}

String firstLetterUpperCase(String raw) {
  return raw.substring(0, 1).toUpperCase() + raw.substring(1);
}

void createScreen(List<String> args) async {
  String name;
  var path = '';

  var noController = args.contains('--no-controller');
  if (args.last.isNotEmpty && !args.last.contains('--create=')) {
    var splittedData = args.last.replaceAll('\\', '/').split('/');
    if (splittedData.length > 1) {
      path = splittedData.sublist(0, splittedData.length - 1).join('/') + '/';
      name = splittedData.last;
    } else {
      name = args.last.toSnakeCase();
    }
  } else {
    stdout.write('Screen Name (HomeScreen | Home | home_screen):');
    name = (stdin.readLineSync(encoding: utf8) ?? '').toSnakeCase();
  }

  name = name.replaceAll('_screen', '');

  var screenFile = await File('lib/screens/$path${name}_screen.dart').create(recursive: true);
  if (!noController) {
    var controllerName = name.toPascalCase() + 'ScreenController';
    var controllerFile = await File('lib/controllers/$path$name' '_screen_controller.dart').create(recursive: true);
    screenControllerSetter(controllerFile, controllerName);
    screenSetter(screenFile, packageName, name.toPascalCase(), controllerName: controllerName, path: path);
  } else {
    screenSetter(screenFile, packageName, name.toPascalCase());
  }

  exit(0);
}

String get packageName {
  var lines = File('pubspec.yaml').readAsLinesSync();
  for (var element in lines) {
    if (element.contains('name')) {
      return element.split(':')[1].trim();
    }
  }
  return '';
}

void createAssets(List<String> args) async {
  printMagenta('Reading assets...');
  var dir = Directory(args.last);
  var filePaths = <String>[];

  void checkFiles(List<FileSystemEntity> list) {
    for (var item in list) {
      if (item is File) {
        filePaths.add(item.path.split(args.last).last.replaceAll('\\', '/'));
      } else if (item is Directory) {
        checkFiles(item.listSync());
      }
    }
  }

  checkFiles(dir.listSync());

  String variableNameCreator(String raw) =>
      raw.split('/').last.split('.').first.replaceAll('-', '_').toLowerCase().toCamelCase();

  var assetFile = await File('lib/utils/assets.dart').create(recursive: true);
  assetFile.writeAsStringSync('''
class AppAssets {
  ${filePaths.map((path) => 'static const String ${variableNameCreator(path)} = \'$path\';').join('\n\t')}  
}
''');
  exit(0);
}

void createProject(List<String> args) async {
  var shell = Shell();
  String? name;
  String? org;
  String? extraArgment;
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
  extraArgment = stdin.readLineSync(encoding: utf8) ?? '';

  var code = 'flutter create --org $org $extraArgment $name';
  var results = await shell.run(code);
  if (results.isEmpty) return printRed('Project Not Created');
  var text = results.first.stdout.toString();
  if (!text.contains('Creat')) return printRed('Project Not Created');

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
  exit(0);
}

void createRoute() async {
  List<String> getDirTree(String dirPath) {
    var dir = Directory(dirPath);
    var files = dir.listSync();
    var paths = <String>[];
    for (var i = 0; i < files.length; i++) {
      var f = files[i];
      if (f is Directory) {
        paths.addAll(getDirTree(f.path));
      } else {
        paths.add(f.path.split('screens/').last.replaceAll('\\', '/'));
      }
    }
    return paths;
  }

  var screens = getDirTree('lib/screens/');
  appRouteSetter(screens);
  exit(0);
}

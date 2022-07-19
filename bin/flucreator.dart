import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:flucreator/flucreator.dart';
import 'package:flucreator/console.dart';
import 'package:process_run/shell_run.dart';
import 'package:change_case/change_case.dart';

void main(List<String> args) async {
  var parser = ArgParser();
  parser.addFlag('no-controller', help: 'Do not generate controller');
  parser.addFlag('help', abbr: 'h', help: 'show help', defaultsTo: false);
  parser.addOption('create', abbr: 'c', help: 'create a new flutter project');
  parser.addOption('org', help: 'organization name');
  parser.addOption('skip', help: 'skip the directories');

  var argResult = parser.parse(args);
  if (argResult['help'] == true) {
    return help();
  }
  if (argResult['create'] == null) {
    return createProject(argResult);
  } else {
    if (!File('pubspec.yaml').existsSync()) {
      printRed('You need to be in a flutter project to run this command');
      return help();
    }
    var type = argResult['create'].toString();
    if (type == 'route') {
      return createRoute(argResult);
    }
    if (argResult.rest.isNotEmpty) {
      if (type.contains('project')) {
        return createProject(argResult);
      } else if (type.contains('screen')) {
        return createScreen(argResult);
      } else if (type.contains('assets')) {
        return createAssets(argResult);
      } else {
        printRed('type not found');
        help();
      }
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
  printBlue('Create screen: flucreator --create=screen <screen_name ex:screen || screen_name || folder/screen_name>');
  printBlue('Create screen without controller: flucreator --create=screen --no-controller screen_name');
  exit(0);
}

String firstLetterUpperCase(String raw) {
  return raw.substring(0, 1).toUpperCase() + raw.substring(1);
}

void createScreen(ArgResults args) async {
  String name;
  var path = '';

  var noController = args['--no-controller'] == true;
  if (args.rest.isNotEmpty && args.rest.first.isNotEmpty && args['create'] != null) {
    var splittedData = args.rest.first.replaceAll('\\', '/').split('/');
    if (splittedData.length > 1) {
      path = splittedData.sublist(0, splittedData.length - 1).join('/') + '/';
      name = splittedData.last.toSnakeCase();
    } else {
      name = args.rest.first.toSnakeCase();
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
    screenSetter(screenFile, packageName, name.toPascalCase(),
        controllerName: controllerName, path: '/controllers/$path$name' '_screen_controller.dart');
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

void createAssets(ArgResults args) async {
  printMagenta('Reading assets...');
  var dir = Directory(args.rest.first);
  var filePaths = <String>[];

  void checkFiles(List<FileSystemEntity> list) {
    for (var item in list) {
      if (item is File) {
        filePaths.add(item.path.split(args.rest.first).last.replaceAll('\\', '/'));
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

void createProject(ArgResults args) async {
  var shell = Shell(verbose: false);
  var name = args.rest.isNotEmpty ? args.rest.first : null;
  String? org = args['org'];
  String? extraArgment;

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

  var code = 'flutter create --org $org --platforms=ios,android,web $extraArgment $name';
  printBlue('Creating project...');
  var results = await shell.run(code);
  if (results.isEmpty) return printRed('Project Not Created');
  var text = results.first.stdout.toString();
  if (!text.contains('Creat')) return printRed('Project Not Created');
  printBlue('Creating Directories...');
  Directory('$name/lib/screens').createSync(recursive: true);
  Directory('$name/lib/controllers').createSync(recursive: true);
  Directory('$name/lib/models').createSync(recursive: true);
  Directory('$name/lib/widgets').createSync(recursive: true);
  Directory('$name/lib/utils').createSync(recursive: true);
  printMagenta('Creating files...');
  mainFileSetter(name);
  homeControllerSetter(name);
  homeScreenSetter(name);
  appSpacesSetter(name);
  await pubSpecSetter(name);
  exit(0);
}

void createRoute(ArgResults argResults) async {
  var skipList = <String>[];
  if (argResults['skip'] != null) {
    skipList = argResults['skip'].split(',');
    skipList.removeWhere((element) => element.isEmpty);
  }
  List<String> getDirTree(String dirPath) {
    var dir = Directory(dirPath);
    var files = dir.listSync();
    var paths = <String>[];
    for (var i = 0; i < files.length; i++) {
      var f = files[i];
      if (f is Directory) {
        var _paths = f.path.split('screens/').last.replaceAll('\\', '/').split('/');
        _paths.removeWhere((element) => element.isEmpty);
        if (skipList.any((element) => _paths.contains(element))) continue;
        paths.addAll(getDirTree(f.path));
      } else {
        paths.add(f.path.split('screens/').last.replaceAll('\\', '/'));
      }
    }
    return paths;
  }

  var screens = getDirTree('lib/screens/');
  appRouteSetter(packageName, screens);
  exit(0);
}

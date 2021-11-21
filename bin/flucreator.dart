import 'dart:convert';
import 'dart:io';
import 'package:flucreator/flucreator.dart';
import 'package:process_run/shell_run.dart';

void main(List<String> args) async {
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

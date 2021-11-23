import 'dart:io';

void screenControllerSetter(File file, String name) {
  file.writeAsStringSync('''import 'package:get/get.dart';
    
class $name extends GetxController {

}
''');
}

void screenSetter(File file, String packageName, String name, [bool noController = false]) {
  var scaffold = '''return Scaffold(
      body:Center(
        child:Text('$name'),
      ),
    );''';

  var getController = '''return GetBuilder<${name}Controller>(
      init: ${name}Controller(),
      builder: (controller) {
        return Scaffold(
          body:Center(
            child:Text('$name'),
          ),
        );
      },
    );''';

  file.writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:get/get.dart';
${noController ? "" : "import 'package:" + packageName + "/controllers/" + name + "Controller.dart';\n"}
class $name extends StatelessWidget {
  const $name({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ${noController ? scaffold : getController}
  }
}
''');
}

void homeControllerSetter(String name) {
  var homeController = File('$name/lib/controllers/HomeScreenController.dart');
  screenControllerSetter(homeController, 'HomeScreenController');
}

void homeScreenSetter(String name) {
  var homeScreen = File('$name/lib/screens/HomeScreen.dart');
  screenSetter(homeScreen, '$name', 'HomeScreen');
}

void appSpacesSetter(String name) {
  var appSpaces = File('$name/lib/utils/AppSpaces.dart');
  appSpaces.writeAsStringSync('''import 'package:flutter/material.dart' show SizedBox;

class AppSpaces {
  static const vertical5 = const SizedBox(height: 5);
  static const vertical10 = const SizedBox(height: 10);
  static const vertical15 = const SizedBox(height: 15);
  static const vertical20 = const SizedBox(height: 20);
  static const vertical25 = const SizedBox(height: 25);
  static const vertical30 = const SizedBox(height: 30);
  static const vertical40 = const SizedBox(height: 40);
  static const vertical50 = const SizedBox(height: 50);
  static const horizontal5 = const SizedBox(width: 5);
  static const horizontal10 = const SizedBox(width: 10);
  static const horizontal15 = const SizedBox(width: 15);
  static const horizontal20 = const SizedBox(width: 20);
  static const horizontal25 = const SizedBox(width: 25);
  static const horizontal30 = const SizedBox(width: 30);
  static const horizontal40 = const SizedBox(width: 40);
  static const horizontal50 = const SizedBox(width: 50);
}
''');
}

void pubSpecSetter(String name) {
  var pubSpec = File('$name/pubspec.yaml');
  var pubLines = pubSpec.readAsLinesSync();
  pubLines.removeWhere((element) => element.trim().startsWith('#'));
  var index = pubLines.indexWhere((element) => element.contains('cupertino'));
  if (index != -1) {
    pubLines.removeAt(index);
    pubLines.insertAll(index, [
      '#State Management & Utils',
      '  get: ^4.3.8',
      '  get_storage: ^2.0.3',
      '',
      '#Fonts & Icons',
      '  cupertino_icons: ^1.0.3',
      '  google_fonts: ^2.1.0',
      '',
    ]);
  }
  pubSpec.writeAsStringSync(pubLines.join('\n'));
}

void mainFileSetter(String name) {
  var mainFile = File('$name/lib/main.dart');
  mainFile.writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:$name/screens/HomeScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: '$name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
''');
}

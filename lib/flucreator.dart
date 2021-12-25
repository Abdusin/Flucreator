import 'dart:io';

void screenControllerSetter(File file, String name) {
  file.writeAsStringSync('''import 'package:get/get.dart';
    
class $name extends GetxController {

}
''');
}

void screenSetter(File file, String packageName, String name, [String controllerName]) {
  var scaffold = '''return Scaffold(
      body:Center(
        child:Text('$name'),
      ),
    );''';

  var getController = '''return GetBuilder<$controllerName>(
      init: $controllerName(),
      builder: (controller) {
        return const Scaffold(
          body:Center(
            child:Text('$name'),
          ),
        );
      },
    );''';

  file.writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:get/get.dart';
${controllerName == null ? "" : "import 'package:" + packageName + "/controllers/" + name + "_screen_controller.dart';\n"}
class ${name}Screen extends StatelessWidget {
  const ${name}Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ${controllerName == null ? scaffold : getController}
  }
}
''');
}

void homeControllerSetter(String name) {
  var homeController = File('$name/lib/controllers/home_screen_controller.dart');
  screenControllerSetter(homeController, 'HomeScreenController');
}

void homeScreenSetter(String name) {
  var homeScreen = File('$name/lib/screens/home_screen.dart');
  screenSetter(homeScreen, '$name', 'home_screen', 'HomeScreenController');
}

void appSpacesSetter(String name) {
  var appSpaces = File('$name/lib/utils/app_spaces.dart');
  appSpaces.writeAsStringSync('''import 'package:flutter/material.dart' show SizedBox;

class AppSpaces {
  static const vertical5 = SizedBox(height: 5);
  static const vertical10 = SizedBox(height: 10);
  static const vertical15 = SizedBox(height: 15);
  static const vertical20 = SizedBox(height: 20);
  static const vertical25 = SizedBox(height: 25);
  static const vertical30 = SizedBox(height: 30);
  static const vertical40 = SizedBox(height: 40);
  static const vertical50 = SizedBox(height: 50);
  static const horizontal5 = SizedBox(width: 5);
  static const horizontal10 = SizedBox(width: 10);
  static const horizontal15 = SizedBox(width: 15);
  static const horizontal20 = SizedBox(width: 20);
  static const horizontal25 = SizedBox(width: 25);
  static const horizontal30 = SizedBox(width: 30);
  static const horizontal40 = SizedBox(width: 40);
  static const horizontal50 = SizedBox(width: 50);
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
import 'package:$name/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
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

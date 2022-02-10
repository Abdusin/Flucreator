import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

final formatter = DartFormatter();
void screenControllerSetter(File file, String name) {
  var getxController = Class((b) => b
    ..name = name
    ..extend = refer('GetxController'));
  var lib = Library((b) => b
    ..directives.add(Directive.import('package:get/get.dart'))
    ..body.add(getxController));
  file.writeAsStringSync(formatter.format(DartEmitter.scoped(useNullSafetySyntax: true).visitLibrary(lib).toString()));
}

void screenSetter(File file, String packageName, String name, [String? controllerName]) {
  var scaffold = '''return const Scaffold(
      body:Center(
        child:Text('$name'),
      ),
    );''';

  final hasController = controllerName != null;

  if (hasController) {
    scaffold = '''return GetBuilder<$controllerName>(
      init: $controllerName(),
      builder: (controller) {
        $scaffold
      },
    );''';
  }

  var directives = [
    Directive.import('package:get/get.dart'),
    Directive.import('package:flutter/material.dart'),
    if (hasController) ...[
      Directive.import('package:' + packageName + '/controllers/' + name.toLowerCase() + '_screen_controller.dart'),
    ]
  ];

  var lib = Library((b) => b
    ..directives.addAll(directives)
    ..body.add(statelessWidgetGenerator('${name}Screen', scaffold)));
  file.writeAsStringSync(formatter.format(DartEmitter.scoped(useNullSafetySyntax: true).visitLibrary(lib).toString()));
}

void homeControllerSetter(String packageName) {
  var homeController = File('$packageName/lib/controllers/home_screen_controller.dart');
  screenControllerSetter(homeController, 'HomeScreenController');
}

void homeScreenSetter(String packageName) {
  var homeScreen = File('$packageName/lib/screens/home_screen.dart');
  screenSetter(homeScreen, '$packageName', 'Home', 'HomeScreenController');
}

enum Axis { horizontal, vertical }
void appSpacesSetter(String name) {
  Field fieldGenerator(Axis axis, num count) {
    return Field(
      (b) => b
        ..name = '${axis.name}$count'
        ..modifier = FieldModifier.constant
        ..static = true
        ..assignment = Code('SizedBox(${axis == Axis.horizontal ? 'width' : 'height'}: $count)'),
    );
  }

  var lib = Library(
    (lib) => lib
      ..directives.add(Directive.import('package:flutter/material.dart', show: ['SizedBox']))
      ..body.addAll([
        Class(
          (c) => c
            ..name = 'AppSpaces'
            ..fields.addAll(
              [
                ...List.generate(10, (index) => fieldGenerator(Axis.horizontal, (index + 1) * 5)),
                ...List.generate(10, (index) => fieldGenerator(Axis.vertical, (index + 1) * 5)),
              ],
            ),
        ),
      ]),
  );
  File('app_spaces.dart')
      .writeAsStringSync(formatter.format(DartEmitter.scoped(useNullSafetySyntax: true).visitLibrary(lib).toString()));
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
      '  get: ^4.6.1',
      '  get_storage: ^2.0.3',
      '',
      '#Fonts & Icons',
      '  cupertino_icons: ^1.0.4',
      '  google_fonts: ^2.3.1',
      '',
    ]);
  }
  pubSpec.writeAsStringSync(pubLines.join('\n'));
}

void mainFileSetter(String name) {
  var mainFunction = Method((m) => m
    ..name = 'main'
    ..body = Code('''
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
'''));
  var lib = Library(
    (lib) => lib
      ..directives.addAll([
        Directive.import('package:flutter/material.dart'),
        Directive.import('package:flutter/services.dart'),
        Directive.import('package:get/get.dart'),
        Directive.import('package:$name/screens/home_screen.dart'),
      ])
      ..body.addAll([
        mainFunction,
        statelessWidgetGenerator('MyApp', '''return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: '$name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );''')
      ]),
  );
  File('$name/lib/main.dart')
      .writeAsStringSync(formatter.format(DartEmitter.scoped(useNullSafetySyntax: true).visitLibrary(lib).toString()));
}

Class statelessWidgetGenerator(String name, String code) {
  return Class(
    (b) => b
      ..name = name
      ..extend = refer('StatelessWidget')
      ..constructors.add(
        Constructor(
          (b) => b
            ..optionalParameters.add(
              Parameter(
                (b) => b
                  ..name = 'key'
                  ..type = refer('Key'),
              ),
            )
            ..initializers.add(
              Code('super(key:key)'),
            ),
        ),
      )
      ..methods.add(
        Method(
          (b) => b
            ..name = 'build'
            ..returns = refer('Widget')
            ..requiredParameters.add(
              Parameter(
                (b) => b
                  ..name = 'context'
                  ..type = refer('BuildContext'),
              ),
            )
            ..annotations.add(CodeExpression(Code('override')))
            ..body = Code(code),
        ),
      ),
  );
}

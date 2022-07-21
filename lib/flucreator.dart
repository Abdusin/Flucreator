import 'dart:async';
import 'dart:io';
import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flucreator/console.dart';
import 'package:process_run/shell.dart';

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

void screenSetter(File file, String packageName, String name,
    {String? controllerName, String path = '', bool noRoute = false}) {
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
      Directive.import('package:$packageName$path'),
    ],
    if (!noRoute) ...[
      Directive.import('package:$packageName/utils/route_type.dart'),
    ]
  ];

  var lib = Library(
    (b) => b
      ..directives.addAll(directives)
      ..body.add(
        statelessWidgetGenerator(
          '${name}Screen',
          scaffold,
          annonations: [
            if (!noRoute)
              refer('RouteType').call([
                literalString(file.path.split('lib/screens/').last.replaceAll('_screen.dart', '')),
                literalString(name),
              ]),
          ],
        ),
      ),
  );
  file.writeAsStringSync(formatter.format(DartEmitter.scoped(useNullSafetySyntax: true).visitLibrary(lib).toString()));
}

void homeControllerSetter(String packageName) {
  var homeController = File('$packageName/lib/controllers/home_screen_controller.dart');
  screenControllerSetter(homeController, 'HomeScreenController');
}

void homeScreenSetter(String packageName) {
  var homeScreen = File('$packageName/lib/screens/home_screen.dart');
  screenSetter(
    homeScreen,
    '$packageName',
    'Home',
    controllerName: 'HomeScreenController',
    path: '/controllers/home_screen_controller.dart',
  );
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

  Field spacerFieldGenerator(num flex) {
    return Field(
      (b) => b
        ..name = 'space${flex > 1 ? flex : ''}'
        ..modifier = FieldModifier.constant
        ..static = true
        ..assignment = Code('Spacer(flex:$flex)'),
    );
  }

  var lib = Library(
    (lib) => lib
      ..directives.add(Directive.import('package:flutter/material.dart', show: ['SizedBox', 'Spacer']))
      ..body.addAll([
        Class(
          (c) => c
            ..name = 'AppSpaces'
            ..fields.addAll(
              [
                ...List.generate(10, (index) => spacerFieldGenerator((index + 1))),
                ...List.generate(10, (index) => fieldGenerator(Axis.horizontal, (index + 1) * 5)),
                ...List.generate(10, (index) => fieldGenerator(Axis.vertical, (index + 1) * 5)),
              ],
            ),
        ),
      ]),
  );
  File('$name/lib/utils/app_spaces.dart')
      .writeAsStringSync(formatter.format(DartEmitter.scoped(useNullSafetySyntax: true).visitLibrary(lib).toString()));
}

void appRouteSetter(
  String packageName, {
  List<String> screens = const [],
  List<Map> routes = const [],
}) {
  String fieldGenerator(String fieldName, String className) {
    return 'GetPage(name: AppRoutes.${fieldName.toCamelCase()}, page: () => const $className())';
  }

  var lib = Library(
    (lib) => lib
      ..directives.add(Directive.import('package:get/get.dart'))
      ..directives.addAll(
          routes.map((e) => Directive.import('package:$packageName/screens/${e['filePath']!.split('lib/').last}')))
      ..directives.addAll(screens.map((e) => Directive.import('package:$packageName/screens/$e')))
      ..body.addAll(
        [
          Class((c) => c
            ..name = 'AppRoutes'
            ..methods.addAll(
              screens.map(
                (e) {
                  var name = e.split('/').last.split('.').first.toCamelCase();
                  return Method(
                    (p0) => p0
                      ..static = true
                      ..lambda = true
                      ..name = 'navigateTo${name.toUpperFirstCase()}'
                      ..returns = refer('Future?')
                      ..body = Code('Get.toNamed($name)'),
                  );
                },
              ),
            )
            ..fields.addAll(
              [
                ...screens.map((e) => Field((f) => f
                  ..static = true
                  ..name = e.split('/').last.split('.').first.toCamelCase()
                  ..assignment = Code('"/${e.split('.').first}"'))),
                ...routes.map(
                  (e) => Field(
                    (f) => f
                      ..static = true
                      ..name = e['fieldName'].toString().toCamelCase()
                      ..assignment = Code('"${e['path']}"'),
                  ),
                ),
                Field(
                  (b) => b
                    ..name = 'routes'
                    ..modifier = FieldModifier.final$
                    ..static = true
                    ..assignment = Code('''[
                      ${screens.map((screen) {
                      var name = screen.split('.').first.split('/').last.toPascalCase();
                      return fieldGenerator(name, name);
                    }).join(',\n')}
                      ${routes.map((route) => fieldGenerator(route['fieldName']!, route['className']!)).join(',\n')}
                    ]'''),
                ),
              ],
            )
            ..methods.addAll(
              routes.map(
                (route) {
                  var name = route['fieldName']!.toString();
                  return Method(
                    (p0) => p0
                      ..static = true
                      ..lambda = true
                      ..name = 'navigateTo${name.toPascalCase()}'
                      ..returns = refer('Future?')
                      ..body = Code('Get.toNamed(${name.toCamelCase()})'),
                  );
                },
              ),
            )),
        ],
      ),
  );
  File('lib/utils/routes.dart')
      .writeAsStringSync(formatter.format(DartEmitter.scoped(useNullSafetySyntax: true).visitLibrary(lib).toString()));
}

Future pubSpecSetter(String name) async {
  var shell = Shell(
    workingDirectory: Directory('./$name').path,
    verbose: false,
    throwOnError: false,
    commandVerbose: false,
    commentVerbose: false,
  );
  var packages = [
    'get',
    'get_storage',
    'cupertino_icons',
    'google_fonts',
  ];
  for (var package in packages) {
    try {
      await shell.run('flutter pub add $package');
    } catch (e) {
      printRed('$package installation failed');
    }
  }
}

void routeTypeClassSetter([String filePath = './lib/utils/route_type.dart']) {
  if (File(filePath).existsSync()) return;
  var lib = Library(
    (lib) => lib
      ..body.addAll([
        Class(
          (c) => c
            ..name = 'RouteType'
            ..fields.addAll([
              Field(
                (b) => b
                  ..name = 'path'
                  ..type = refer('String')
                  ..modifier = FieldModifier.final$,
              ),
              Field(
                (b) => b
                  ..name = 'fieldName'
                  ..type = refer('String')
                  ..modifier = FieldModifier.final$,
              ),
            ])
            ..constructors.add(Constructor(
              (c) => c
                ..constant = true
                ..requiredParameters.addAll([
                  Parameter(
                    (p) => p
                      ..name = 'path'
                      ..toThis = true,
                  ),
                  Parameter(
                    (p) => p
                      ..name = 'fieldName'
                      ..toThis = true,
                  ),
                ]),
            )),
        ),
      ]),
  );
  var file = formatter.format(DartEmitter.scoped(useNullSafetySyntax: true).visitLibrary(lib).toString());
  File(filePath).writeAsStringSync(file);
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

Class statelessWidgetGenerator(String name, String code, {List<Expression> annonations = const []}) {
  return Class(
    (b) => b
      ..name = name
      ..extend = refer('StatelessWidget')
      ..annotations.addAll(annonations)
      ..constructors.add(
        Constructor(
          (b) => b
            ..constant = true
            ..optionalParameters.add(
              Parameter(
                (b) => b
                  ..named = true
                  ..name = 'key'
                  ..type = refer('Key?'),
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

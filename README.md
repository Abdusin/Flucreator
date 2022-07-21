<!-- DO NOT REMOVE - contributor_list:data:start:["Matt-Gleich", "lig", "bartekpacia", "ImgBotApp", "jlnrrg", "vHanda"]:end -->

## Flucreator

    You can use Flucreator to create a new Flutter project.
    Automatically create a new Flutter project with Getx & Directories. 

####  💻  Usage ~ Project Create
```
// You Can Activate Flucreator With This Command Line 
pub global activate --source git https://github.com/Abdusin/Flucreator.git
// You can run like this
fluecretor --org com.abdusin myapp
// Also you can run with command too 
// If run without arguments console will ask details
flucreator
```
####  💻  Usage ~ Screen Create
```
fluecretor --create=screen ExampleScreen
fluecretor --create=screen Folder/ExampleScreen
fluecretor --create=screen --no-controller ExampleScreen
```

`$flucreator`             |  `$flutter --create`
:-------------------------:|:-------------------------:
![](https://github.com/Abdusin/Flucreator/blob/main/flucreator.png?raw=true)  |  ![](https://github.com/Abdusin/Flucreator/blob/main/flutter.png?raw=true)

####  💻  Usage ~ Route Create
```
flucreator --create=route
flucreator --create-annonation --create=route
// --create-annonation on BETA
// this flag for only old project update if u create new project u dont need use this
```

####  💻  Usage ~ Assets Create
```
flucreator --create=assets assets
flucreator --create=assets <Folder>
```

####  🚀 Advance
```
// Only If U wanna create again (for updates)
dart compile aot-snapshot bin/flucreator.dart
// You need to run this for global calling
pub global activate --source path .
```
![code](https://github.com/Abdusin/Flucreator/blob/main/code.png?raw=true)

# 🏃‍♂️ Path
 * Controllers
    * home_screen_controller.dart
 * Models
 * Screens
    * home_screen.dart
 * Utils
    * app_spaces.dart
 * Widgets
 * main.dart

## 🙋‍♀️🙋‍♂️ Contributing

All contributions are welcome! Just make sure that it's not an already existing issue or pull request.

<!-- DO NOT REMOVE - contributor_list:start -->

## 👥 Contributors

- **[@Abdusin](https://github.com/abdusin)**

<!-- DO NOT REMOVE - contributor_list:end -->
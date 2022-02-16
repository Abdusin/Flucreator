## Flucreator

    You can use Flucreator to create a new Flutter project.
    Automatically create a new Flutter project with Getx & Directories. 

#### Normal Usage (Project Create)
```
// You Can Activate Flucreator With This Command Line 
pub global activate --source git https://github.com/Abdusin/Flucreator.git
// You can run like this
fluecretor --org com.abdusin myapp
// Also you can run with command too 
// If run without arguments console will ask details
flucreator
```
#### Normal Usage (Screen Create)
```
fluecretor --create=screen ExampleScreen
fluecretor --create=screen Folder/ExampleScreen
fluecretor --create=screen --no-controller ExampleScreen
```

`$flucreator`             |  `$flutter --create`
:-------------------------:|:-------------------------:
![](flucreator.png)  |  ![](flutter.png)

#### Advance
```
// Only If U wanna create again (for updates)
dart compile aot-snapshot bin/flucreator.dart
// You need to run this for global calling
pub global activate --source path .
```
![code](code.png)

# Path
 * Controllers
    * home_screen_controller.dart
 * Models
 * Screens
    * home_screen.dart
 * Utils
    * app_spaces.dart
 * Widgets
 * main.dart

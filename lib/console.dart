void printMagenta(String text) {
  print('\x1B[35m$text\x1B[0m');
}

void printBlue(String text) {
  print('\x1B[35m[FLUCREATOR-WORKER]\x1B[0m\x1B[36m $text\x1B[0m');
}

void printRed(String text) {
  print('\x1B[35m[FLUCREATOR-WORKER]\x1B[0m\x1B[91m $text\x1B[0m');
}

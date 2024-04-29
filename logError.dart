import 'dart:developer';

void logQuery({required String message, required String name}) {
  log("\x1B[32m$message\x1B[0m", name: "\x1B[32m$name\x1B[0m");
}

void logError({required String message, required String name}) {
  log("\x1B[31m$message\x1B[0m", name: "\x1B[31m$name\x1B[0m");
}

void logWarning({required String message, required String name}) {
  log("\x1B[35m$message\x1B[0m", name: "\x1B[35m$name\x1B[0m");
}

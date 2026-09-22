class GlobalErrorTrap {
  static final List<String> caughtErrors = [];
  static void record(String error) {
    if (!caughtErrors.contains(error)) {
      caughtErrors.add(error);
    }
  }
}

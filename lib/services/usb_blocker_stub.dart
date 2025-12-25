abstract class UsbBlocker {
  static Future<bool> blockAllUsbStorage() async => false;
  static Future<bool> unblockAllUsbStorage() async => false;
  static Future<int?> getUsbStorStartValue() async => null;
  static bool isRunningAsAdmin() => false;
}

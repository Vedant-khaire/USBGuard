import 'dart:io';
import 'package:win32_registry/win32_registry.dart';

class UsbBlocker {
  static const _usbStorPath = r'SYSTEM\CurrentControlSet\Services\USBSTOR';
  static const _usbStorValue = 'Start';

  ///  Block USB storage by setting Start = 4
  static Future<bool> blockAllUsbStorage() async {
    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: _usbStorPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.createValue(RegistryValue(
        _usbStorValue,
        RegistryValueType.int32,
        4,
      ));
      key.close();
      return true;
    } catch (e) {
      stderr.writeln(" Failed to block USB storage: $e");
      return false;
    }
  }

  ///  Unblock USB storage by setting Start = 3
  static Future<bool> unblockAllUsbStorage() async {
    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: _usbStorPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.createValue(RegistryValue(
        _usbStorValue,
        RegistryValueType.int32,
        3,
      ));
      key.close();
      return true;
    } catch (e) {
      stderr.writeln(" Failed to unblock USB storage: $e");
      return false;
    }
  }

///  Get current USBSTOR Start value (3 = enabled, 4 = disabled)
static Future<int?> getUsbStorStartValue() async {
  try {
    final key = Registry.openPath(
      RegistryHive.localMachine,
      path: _usbStorPath,
      desiredAccessRights: AccessRights.readOnly, //  FIXED
    );
    final value = key.getValue(_usbStorValue) as RegistryValue?;
    key.close();
    if (value != null && value.data is int) {
      return value.data as int;
    }
    return null;
  } catch (e) {
    stderr.writeln(" Failed to read USBSTOR value: $e");
    return null;
  }
}

///  Check if the app is running with Admin rights
static bool isRunningAsAdmin() {
  try {
    final result = Process.runSync('net', ['session']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

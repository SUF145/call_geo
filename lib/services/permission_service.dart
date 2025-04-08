import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  
  factory PermissionService() {
    return _instance;
  }
  
  PermissionService._internal();
  
  // Check and request call recording permissions
  Future<Map<Permission, PermissionStatus>> requestCallRecordingPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.microphone,
      Permission.storage,
    ].request();
    
    return statuses;
  }
  
  // Check if all call recording permissions are granted
  Future<bool> checkCallRecordingPermissions() async {
    bool phoneStatus = await Permission.phone.isGranted;
    bool microphoneStatus = await Permission.microphone.isGranted;
    bool storageStatus = await Permission.storage.isGranted;
    
    return phoneStatus && microphoneStatus && storageStatus;
  }
  
  // Check and request location permissions
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }
  
  // Check if location permission is granted
  Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted;
  }
  
  // Check if background location permission is granted
  Future<bool> checkBackgroundLocationPermission() async {
    return await Permission.locationAlways.isGranted;
  }
  
  // Request background location permission
  Future<PermissionStatus> requestBackgroundLocationPermission() async {
    return await Permission.locationAlways.request();
  }
}

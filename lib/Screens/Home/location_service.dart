// lib/services/location_service.dart
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final loc.Location _location = loc.Location();

  static Future<String> getCurrentAddress() async {
    try {
      // Check if service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return "Dịch vụ vị trí không khả dụng";
        }
      }

      // Check permission
      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          return "Chưa cấp quyền vị trí";
        }
      }

      // Get current location
      loc.LocationData locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        // Convert to address using geocoding
        List<Placemark> placemarks = await placemarkFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = _buildAddressString(place);
          return address;
        }
      }

      return "Không thể lấy địa chỉ";
    } catch (e) {
      print('Error getting location: $e');
      return "Lỗi khi lấy vị trí: ${e.toString()}";
    }
  }

  static String _buildAddressString(Placemark place) {
    List<String> addressParts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      addressParts.add(place.subAdministrativeArea!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    
    return addressParts.isNotEmpty 
        ? addressParts.join(', ') 
        : "Địa chỉ không xác định";
  }

  static Future<bool> requestLocationPermission() async {
    try {
      PermissionStatus permission = await Permission.location.request();
      return permission == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  static Future<Map<String, double>?> getCurrentCoordinates() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return null;
      }

      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return null;
      }

      loc.LocationData locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        return {
          'latitude': locationData.latitude!,
          'longitude': locationData.longitude!,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return _buildAddressString(place);
      }
      
      return "Không thể lấy địa chỉ";
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return "Lỗi khi lấy địa chỉ";
    }
  }
}

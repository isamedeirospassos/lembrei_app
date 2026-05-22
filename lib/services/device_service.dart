import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _deviceIdKey = 'device_id';

  /// Pega o device_id salvo ou cria um novo se não existir
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    // Se ainda não tem device_id, cria um novo
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      print('🆔 Novo device_id criado: $deviceId');
    } else {
      print('🆔 Device_id existente: $deviceId');
    }

    return deviceId;
  }

  /// (Opcional) Resetar o device_id - útil pra testes
  static Future<void> resetDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    print('🆔 Device_id resetado');
  }
}
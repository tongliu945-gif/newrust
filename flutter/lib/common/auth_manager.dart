import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/utils/http_service.dart' as http;
import 'dart:convert';

class AuthManager {
  static final AuthManager instance = AuthManager._();
  AuthManager._();

  final RxBool isActivated = false.obs;
  final RxString authCode = "".obs;
  final RxString expiryDate = "".obs;

  // Placeholder for OSS URL - User needs to provide this
  // In a real scenario, this would be a fixed URL pointing to an OSS bucket.
  // For development/demo, we can set this to point to a local file or just skip it 
  // and default to the management server directly.
  final String _ossUrl = "http://localhost:8080/oss_config.json"; // Example
  // Default Management Server if OSS fails or for testing
  final String _defaultManagerUrl = "http://localhost:8080";

  Future<void> init() async {
    String code = await bind.mainGetLocalOption(key: 'custom-auth-code');
    if (code.isNotEmpty) {
      // Validate locally or re-fetch
      await _validateAndFetchConfig(code);
    }
  }

  Future<String> _fetchManagerUrl() async {
      // 1. Try to fetch from OSS
      try {
        // We use a shorter timeout for OSS fetch if possible, or just try catch
        final response = await http.get(Uri.parse(_ossUrl));
        if (response.statusCode == 200) {
          final config = jsonDecode(response.body);
          if (config['manager_url'] != null) {
            return config['manager_url'];
          }
        }
      } catch (e) {
        debugPrint("Failed to fetch OSS config: $e");
      }
      return _defaultManagerUrl;
  }

  Future<void> _validateAndFetchConfig(String code) async {
    try {
        final managerUrl = await _fetchManagerUrl();
        final deviceId = await bind.mainGetMyId();
        
        final response = await http.post(
            Uri.parse('$managerUrl/api/license/verify'),
            body: jsonEncode({"code": code, "device_id": deviceId})
        );

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            // Valid
            authCode.value = code;
            isActivated.value = true;
            expiryDate.value = data['expiration'] ?? "";
            
            // Also fetch server config
            await _fetchServerConfig(managerUrl);
        } else {
             debugPrint("License invalid: ${response.body}");
             // Optional: Unbind locally if server says invalid?
             // unbind(); 
        }
    } catch (e) {
        debugPrint("Error validating license: $e");
    }
  }

  Future<void> _fetchServerConfig(String managerUrl) async {
      try {
          final response = await http.get(Uri.parse('$managerUrl/api/config'));
          if (response.statusCode == 200) {
              final config = jsonDecode(response.body);
              await bind.mainSetOption(key: 'custom-rendezvous-server', value: config['id_server']);
              await bind.mainSetOption(key: 'key', value: config['key']);
              
              // Voice SDK Config
              if (config['voice_provider'] != null) {
                  await bind.mainSetOption(key: 'voice-provider', value: config['voice_provider']);
              }
              if (config['voice_app_id'] != null) {
                  await bind.mainSetOption(key: 'voice-app-id', value: config['voice_app_id']);
              }
              if (config['voice_app_key'] != null) {
                  await bind.mainSetOption(key: 'voice-app-key', value: config['voice_app_key']);
              }
          }
      } catch (e) {
          debugPrint("Error fetching server config: $e");
      }
  }

  Future<bool> bindCode(String code) async {
    if (code.isEmpty) return false;

    try {
        final managerUrl = await _fetchManagerUrl();
        final deviceId = await bind.mainGetMyId();

        final response = await http.post(
            Uri.parse('$managerUrl/api/license/bind'),
            body: jsonEncode({"code": code, "device_id": deviceId})
        );

        if (response.statusCode == 200) {
             // Success
             await bind.mainSetLocalOption(key: 'custom-auth-code', value: code);
             authCode.value = code;
             isActivated.value = true;
             
             // Verify to get expiration
             await _validateAndFetchConfig(code);
             
             return true;
        } else {
             debugPrint("Bind failed: ${response.body}");
             return false;
        }
    } catch (e) {
        debugPrint("Error binding code: $e");
        return false;
    }
  }

  Future<void> unbind() async {
    final code = authCode.value;
    if (code.isNotEmpty) {
        try {
            final managerUrl = await _fetchManagerUrl();
            final deviceId = await bind.mainGetMyId();
            await http.post(
                Uri.parse('$managerUrl/api/license/unbind'),
                body: jsonEncode({"code": code, "device_id": deviceId})
            );
        } catch (e) {
            debugPrint("Error unbinding: $e");
        }
    }

    await bind.mainSetLocalOption(key: 'custom-auth-code', value: '');
    authCode.value = "";
    isActivated.value = false;
    expiryDate.value = "";
  }

  bool canConnect() {
    return isActivated.value;
  }
}

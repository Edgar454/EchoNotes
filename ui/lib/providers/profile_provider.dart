import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? _profile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get profile => _profile;

  /// Fetch current user profile
  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '${ApiService.baseUrl}/auth/profile';
      final res = await ApiService.httpGet(url, token: token);

      _profile = Map<String, dynamic>.from(res);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update profile fields (partial updates supported)
  Future<bool> updateProfile({
    String? fullName,
    String? role,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = '${ApiService.baseUrl}/auth/profile';
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (role != null) body['role'] = role;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;

      if (body.isEmpty) throw Exception('No fields to update');

      final res = await ApiService.httpPost(url, body: body, token: token);

      // Update local profile cache
      _profile = _profile ?? {};
      _profile!.addAll(body);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

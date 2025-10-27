import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  
  // Initialize - check if user is already authenticated
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _isAuthenticated = await ApiService.isAuthenticated();
    } catch (e) {
      print('Error initializing auth: $e');
      _isAuthenticated = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Sign in
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await ApiService.signIn(email, password);
      
      if (result['success']) {
        _isAuthenticated = true;
        _userData = result['data'];
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Sign up
  Future<bool> signUp(String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await ApiService.signUp(email, password, fullName);
      
      if (result['success']) {
        _isAuthenticated = true;
        _userData = result['data'];
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await ApiService.removeToken();
      _isAuthenticated = false;
      _userData = null;
      _errorMessage = null;
    } catch (e) {
      print('Error signing out: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
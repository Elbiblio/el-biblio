import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Network connectivity status and monitoring service
class ConnectivityService {
  ConnectivityService(this._logger) {
    _initializeConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectivityStatus);
  }

  final Logger _logger;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // Connectivity state
  ValueListenable<bool> get isConnected => _isConnected;
  final _isConnected = ValueNotifier<bool>(true);
  
  ValueListenable<ConnectivityResult> get connectionType => _connectionType;
  final _connectionType = ValueNotifier<ConnectivityResult>(ConnectivityResult.other);

  bool get hasInternetConnection => _isConnected.value;
  ConnectivityResult get currentConnectionType => _connectionType.value;

  // Stream for connectivity changes
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;
  final _connectivityStreamController = StreamController<bool>.broadcast();

  Future<void> _initializeConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e) {
      _logger.e('Failed to initialize connectivity check: $e');
      // Assume connected on initialization failure
      _isConnected.value = true;
    }
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      _logger.w('No connectivity results received');
      return;
    }

    final previousConnectionType = _connectionType.value;
    final previousIsConnected = _isConnected.value;

    // Determine the primary connection type (prioritize WiFi over mobile)
    ConnectivityResult primaryResult = ConnectivityResult.other;
    for (final result in results) {
      if (result == ConnectivityResult.wifi) {
        primaryResult = ConnectivityResult.wifi;
        break;
      } else if (result == ConnectivityResult.mobile) {
        primaryResult = ConnectivityResult.mobile;
      } else if (result == ConnectivityResult.ethernet) {
        primaryResult = ConnectivityResult.ethernet;
      } else if (result != ConnectivityResult.none) {
        primaryResult = result;
      }
    }

    final isNowConnected = primaryResult != ConnectivityResult.none;

    _connectionType.value = primaryResult;
    _isConnected.value = isNowConnected;

    // Log connectivity changes
    if (previousIsConnected != isNowConnected || previousConnectionType != primaryResult) {
      _logger.i('Connectivity changed: ${isNowConnected ? "CONNECTED" : "DISCONNECTED"} ($primaryResult)');
      
      // Emit connectivity change event
      _connectivityStreamController.add(isNowConnected);
    }
  }

  /// Check if currently connected with optional validation
  Future<bool> checkConnectivity({bool validateInternet = false}) async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);

      if (!validateInternet) {
        return _isConnected.value;
      }

      // Additional internet validation if requested
      if (_isConnected.value) {
        return await _validateInternetConnection();
      }

      return false;
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      return false;
    }
  }

  /// Validate actual internet connectivity by making a simple request
  Future<bool> _validateInternetConnection() async {
    try {
      // Try to connect to a reliable endpoint
      final addresses = [
        'google.com',
        'cloudflare.com',
        'api.elbiblio.com',
      ];

      for (final address in addresses) {
        try {
          final result = await InternetAddress.lookup(address);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            _logger.d('Internet validation successful via $address');
            return true;
          }
        } catch (e) {
          _logger.d('Failed to resolve $address: $e');
          continue;
        }
      }

      _logger.w('Internet validation failed - no DNS resolution');
      return false;
    } catch (e) {
      _logger.e('Internet validation error: $e');
      return false;
    }
  }

  /// Wait for connectivity to be restored
  Future<bool> waitForConnectivity({Duration timeout = const Duration(seconds: 30)}) async {
    if (_isConnected.value) {
      return true;
    }

    _logger.i('Waiting for connectivity restoration...');
    
    final completer = Completer<bool>();
    late StreamSubscription<bool> subscription;
    Timer? timeoutTimer;

    subscription = connectivityStream.listen((isConnected) {
      if (isConnected) {
        timeoutTimer?.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          _logger.i('Connectivity restored');
          completer.complete(true);
        }
      }
    });

    timeoutTimer = Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        _logger.w('Connectivity wait timeout');
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Get human-readable connection type description
  String getConnectionTypeDescription() {
    switch (_connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.none:
        return 'Offline';
      case ConnectivityResult.other:
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  /// Check if connection is suitable for large downloads
  bool isSuitableForDownloads() {
    return _isConnected.value && 
           (_connectionType.value == ConnectivityResult.wifi || 
            _connectionType.value == ConnectivityResult.ethernet);
  }

  /// Check if connection is metered (mobile data)
  bool isMeteredConnection() {
    return _isConnected.value && _connectionType.value == ConnectivityResult.mobile;
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _connectivityStreamController.close();
    _isConnected.dispose();
    _connectionType.dispose();
  }

  @override
  String toString() => 
      'ConnectivityService(connected: $_isConnected, type: $_connectionType)';
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import 'notifications_api.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationsApiService _apiService = NotificationsApiService();

  final List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  final StreamController<Map<String, dynamic>> _presenceStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get presenceStream => _presenceStreamController.stream;

  HttpClient? _sseHttpClient;
  StreamSubscription? _sseSubscription;
  bool _isConnected = false;
  bool _disposed = false;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  // Initialize and load initial data
  Future<void> init() async {
    await fetchNotifications(refresh: true);
    _connectSSE();
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
      _hasMore = true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.fetchNotifications(page: _currentPage);
      final data = response['data'] as List?;
      final pagination = response['pagination'];

      if (data != null) {
        _notifications.addAll(data);
        _updateUnreadCount();
      }

      if (pagination != null) {
        _hasMore = pagination['next'] != null;
        if (_hasMore) _currentPage++;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsSeen(int notificationId) async {
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index == -1 || _notifications[index]['seen'] == true) return;

    // Optimistic update
    _notifications[index]['seen'] = true;
    _updateUnreadCount();
    notifyListeners();

    try {
      await _apiService.markAsSeen(notificationId);
    } catch (e) {
      // Revert on failure
      _notifications[index]['seen'] = false;
      _updateUnreadCount();
      notifyListeners();
      debugPrint("Error marking notification as seen: $e");
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => n['seen'] == false).length;
  }

  // ─── SSE using dart:io for true streaming ────────────────────────────────
  void _connectSSE() async {
    if (_isConnected || _disposed) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    _isConnected = true;
    debugPrint("🔌 SSE: Connecting...");

    try {
      _sseHttpClient = HttpClient();
      // No idle timeout — SSE connection must stay open indefinitely
      _sseHttpClient!.idleTimeout = Duration.zero;

      final uri = Uri.parse("${AppConfig.baseUrl}/sse/stream");
      final request = await _sseHttpClient!.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      // Prevent gzip compression — compressed SSE breaks streaming
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');

      final response = await request.close();
      debugPrint("🔌 SSE: Status ${response.statusCode}");

      if (response.statusCode == 200) {
        final StringBuffer eventBuffer = StringBuffer();

        _sseSubscription = response
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (String line) {
            debugPrint("RAW SSE LINE: $line"); // DEBUG PRINT
            if (line.startsWith('data: ')) {
              eventBuffer.write(line.substring(6));
            } else if (line.isEmpty && eventBuffer.isNotEmpty) {
              // Empty line = end of SSE event block
              final dataStr = eventBuffer.toString().trim();
              eventBuffer.clear();

              if (dataStr.isNotEmpty) {
                try {
                  final eventData = jsonDecode(dataStr);
                  debugPrint("📩 SSE event parsed, type: ${eventData['type']}");
                  
                  // Handle both wrapped format and direct unwrapped format
                  if (eventData['type'] == 'notification' && eventData['data'] != null) {
                    _handleNewNotification(
                      Map<String, dynamic>.from(eventData['data']),
                    );
                  } else if (eventData['type'] == 'presence' && eventData['data'] != null) {
                    _presenceStreamController.add(Map<String, dynamic>.from(eventData['data']));
                  } else if (eventData['type'] == 'presence_change' && eventData['data'] != null) {
                    _presenceStreamController.add(Map<String, dynamic>.from(eventData['data']));
                  } else if (eventData['type'] == 'presence') {
                    _presenceStreamController.add(Map<String, dynamic>.from(eventData));
                  } else if (eventData.containsKey('id') || eventData.containsKey('code')) {
                    _handleNewNotification(
                      Map<String, dynamic>.from(eventData),
                    );
                  }
                } catch (e) {
                  debugPrint("SSE parse error: $e | data: $dataStr");
                }
              }
            }
          },
          onError: (error) {
            debugPrint("❌ SSE stream error: $error");
            _reconnectSSE();
          },
          onDone: () {
            debugPrint("🔌 SSE stream closed — will reconnect");
            _reconnectSSE();
          },
          cancelOnError: false,
        );
      } else {
        debugPrint("❌ SSE connection failed: ${response.statusCode}");
        _sseHttpClient?.close(force: true);
        _sseHttpClient = null;
        _isConnected = false;
        _reconnectSSE();
      }
    } catch (e) {
      debugPrint("❌ SSE exception: $e");
      _sseHttpClient?.close(force: true);
      _sseHttpClient = null;
      _isConnected = false;
      _reconnectSSE();
    }
  }

  void _handleNewNotification(Map<String, dynamic> notification) {
    if (_disposed) return;
    final exists = _notifications.any((n) => n['id'] == notification['id']);
    if (!exists) {
      _notifications.insert(0, notification);
      _updateUnreadCount();
      notifyListeners();
      debugPrint("🔔 New notification: ${notification['code']}");
    }
  }

  void _reconnectSSE() {
    if (_disposed) return;
    _disconnectSSE();
    Future.delayed(const Duration(seconds: 5), () {
      if (_disposed || _isConnected) return;
      debugPrint("🔄 SSE: Reconnecting...");
      _connectSSE();
    });
  }

  void _disconnectSSE() {
    _isConnected = false;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseHttpClient?.close(force: true);
    _sseHttpClient = null;
  }

  void logout() {
    _disconnectSSE();
    _notifications.clear();
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _disconnectSSE();
    _presenceStreamController.close();
    super.dispose();
  }
}

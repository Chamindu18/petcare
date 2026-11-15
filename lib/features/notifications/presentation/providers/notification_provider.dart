import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required this.repository});
  final NotificationRepository repository;

  StreamSubscription<List<Notification>>? _subscription;

  List<Notification> _notifications = const [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;
  bool _markAllInProgress = false;
  final Set<String> _readUpdatesInProgress = {};

  List<Notification> get notifications => _notifications;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get unreadCount =>
      _notifications.where((notification) => !notification.read).length;

  void startListening() {
    _subscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = repository.watchNotifications().listen(
      (notifications) {
        if (_disposed) return;
        _notifications = notifications;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_disposed) return;
        _isLoading = false;
        _errorMessage = _errorMessageFrom(error);
        notifyListeners();
      },
    );
  }

  Future<bool> markAsRead(String notificationId) async {
    if (_disposed || !_readUpdatesInProgress.add(notificationId)) return false;
    try {
      await repository.markAsRead(notificationId: notificationId);
      return true;
    } catch (error) {
      return false;
    } finally {
      _readUpdatesInProgress.remove(notificationId);
    }
  }

  Future<bool> markAllAsRead() async {
    if (_disposed || _markAllInProgress) return false;
    _markAllInProgress = true;
    try {
      await repository.markAllAsRead();
      return true;
    } catch (error) {
      return false;
    } finally {
      _markAllInProgress = false;
    }
  }

  String _errorMessageFrom(Object error) {
    return 'Unable to load notifications. Please try again.';
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

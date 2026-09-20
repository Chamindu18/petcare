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
        _notifications = notifications;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = _errorMessageFrom(error);
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await repository.markAsRead(notificationId: notificationId);
    } catch (error) {
      _errorMessage = _errorMessageFrom(error);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await repository.markAllAsRead();
    } catch (error) {
      _errorMessage = _errorMessageFrom(error);
      notifyListeners();
    }
  }

  String _errorMessageFrom(Object error) {
    return 'Unable to load notifications. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

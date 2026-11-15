import 'package:flutter/foundation.dart';

import '../../domain/entities/queue.dart';
import '../../domain/repositories/queue_repository.dart';

/// Loads one owner's appointment queue and its server-calculated position.
///
/// The queue itself remains the source of truth for queue number and status.
/// The stored position field is not treated as authoritative because staff
/// transitions may make it stale.
class OwnerQueueProvider extends ChangeNotifier {
  OwnerQueueProvider({
    required this._queueRepository,
    required this.appointmentId,
    this._ownerQueueRepository,
    Queue? initialQueue,
  }) : _queue = initialQueue;

  final QueueRepository _queueRepository;
  final OwnerQueueRepository? _ownerQueueRepository;
  final String appointmentId;

  Queue? _queue;
  int? _position;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  Queue? get queue => _queue;

  /// Waiting position including this entry, or null when it is unavailable.
  int? get position => _position;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_disposed || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queue = await _queueRepository.getQueueByAppointment(appointmentId);
      if (_disposed) return;
      _queue = queue;
      _position = null;

      if (queue != null &&
          queue.queueStatus == QueueStatus.waiting &&
          _ownerQueueRepository != null) {
        try {
          final position = await _ownerQueueRepository.getOwnerQueuePosition(
            queueId: queue.queueId,
          );
          if (!_disposed) _position = position;
        } catch (error) {
          // Position is optional. Never substitute the stale stored field.
          debugPrint('Owner queue position unavailable: $error');
        }
      }
    } catch (error) {
      if (!_disposed) {
        debugPrint('Owner queue loading error: $error');
        // Do not keep displaying an unverified initial or previously loaded
        // record after authorization or connectivity fails.
        _queue = null;
        _position = null;
        _errorMessage = 'Unable to load queue details. Please try again.';
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_router.dart';

/// Keeps a protected route tied to the account that opened it.
class ProtectedSessionGate extends StatefulWidget {
  const ProtectedSessionGate({
    super.key,
    required this.auth,
    required this.sessionUid,
    required this.childBuilder,
  });

  final FirebaseAuth auth;
  final String sessionUid;
  final WidgetBuilder childBuilder;

  @override
  State<ProtectedSessionGate> createState() => _ProtectedSessionGateState();
}

class _ProtectedSessionGateState extends State<ProtectedSessionGate> {
  StreamSubscription<User?>? _authSubscription;
  String? _observedUid;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _observedUid = widget.auth.currentUser?.uid;
    _authSubscription = widget.auth.authStateChanges().listen((user) {
      if (mounted) setState(() => _observedUid = user?.uid);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _redirectIfCurrent() {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectScheduled = false;
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final target = _observedUid == null || widget.auth.currentUser == null
          ? AppRouter.login
          : AppRouter.home;
      Navigator.of(context).pushNamedAndRemoveUntil(target, (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_observedUid != widget.sessionUid ||
        widget.auth.currentUser?.uid != widget.sessionUid) {
      _redirectIfCurrent();
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.childBuilder(context);
  }
}

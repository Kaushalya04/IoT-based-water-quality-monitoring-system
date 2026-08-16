import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryService {
  static bool _started = false;

  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<DatabaseEvent>? _sensorSubscription;

  static String? _activeUid;

  static String? _lastStatus;
  static String? _lastValve;

  // Ensures sensor events are handled one by one.
  static Future<void> _eventQueue = Future.value();

  static void start() {
    if (_started) return;

    _started = true;

    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        _switchUser(user);
      },
    );
  }

  static Future<void> _switchUser(User? user) async {
    await _sensorSubscription?.cancel();

    _sensorSubscription = null;

    _lastStatus = null;
    _lastValve = null;

    _activeUid = user?.uid;

    _eventQueue = Future.value();

    if (user == null) {
      return;
    }

    final String uid = user.uid;

    final FirebaseDatabase database =
        FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    final DatabaseReference sensorRef =
        database.ref(
      'users/$uid/sensor',
    );

    final DatabaseReference historyRef =
        database.ref(
      'users/$uid/history',
    );

    _sensorSubscription =
        sensorRef.onValue.listen(
      (DatabaseEvent event) {
        // Add every event to a queue.
        // This prevents overlapping async handlers.
        _eventQueue = _eventQueue.then(
          (_) async {
            if (_activeUid != uid) {
              return;
            }

            await _handleSensorEvent(
              event: event,
              sensorRef: sensorRef,
              historyRef: historyRef,
              uid: uid,
            );
          },
        ).catchError(
          (error) {
            print(
              "HistoryService error: $error",
            );
          },
        );
      },
    );
  }

  static Future<void> _handleSensorEvent({
    required DatabaseEvent event,
    required DatabaseReference sensorRef,
    required DatabaseReference historyRef,
    required String uid,
  }) async {
    if (_activeUid != uid) {
      return;
    }

    final value = event.snapshot.value;

    if (value is! Map) {
      return;
    }

    final data =
        Map<dynamic, dynamic>.from(value);

    final rawTurbidity =
        data['turbidity'];

    double turbidity = 0;

    if (rawTurbidity is num) {
      turbidity =
          rawTurbidity.toDouble();
    } else {
      turbidity =
          double.tryParse(
            rawTurbidity.toString(),
          ) ??
          0;
    }

    final String status =
        turbidity < 300
            ? 'CLEAR'
            : 'DIRTY';

    final bool manualOverride =
        data['manualOverride'] == true;

    String currentValve =
        data['valve']
                ?.toString()
                .toUpperCase() ??
            'UNKNOWN';

    final String currentStatus =
        data['waterStatus']
                ?.toString()
                .toUpperCase() ??
            'UNKNOWN';

    String desiredValve;

    if (status == 'CLEAR') {
      desiredValve = 'OPEN';
    } else {
      desiredValve =
          manualOverride
              ? 'OPEN'
              : 'CLOSED';
    }

    // Initial sensor state:
    // save as baseline only.
    if (_lastStatus == null &&
        _lastValve == null) {
      final Map<String, Object?> updates = {};

      if (currentStatus != status) {
        updates['waterStatus'] = status;
      }

      if (currentValve != desiredValve) {
        updates['valve'] = desiredValve;
      }

      if (status == 'CLEAR' &&
          manualOverride) {
        updates['manualOverride'] = false;
      }

      if (updates.isNotEmpty) {
        await sensorRef.update(updates);
      }

      _lastStatus = status;
      _lastValve = desiredValve;

      return;
    }

    final Map<String, Object?> updates = {};

    if (currentStatus != status) {
      updates['waterStatus'] = status;
    }

    if (currentValve != desiredValve) {
      updates['valve'] = desiredValve;
      currentValve = desiredValve;
    }

    if (status == 'CLEAR' &&
        manualOverride) {
      updates['manualOverride'] = false;
    }

    // Do one Firebase update instead of multiple set() calls.
    if (updates.isNotEmpty) {
      await sensorRef.update(updates);
    }

    if (_activeUid != uid) {
      return;
    }

    // Record only when final system state actually changed.
    if (_lastStatus != status ||
        _lastValve != desiredValve) {
      await historyRef.push().set({
        'waterStatus': status,
        'turbidity':
            turbidity.toInt(),
        'valve': desiredValve,
        'timestamp':
            DateTime.now()
                .millisecondsSinceEpoch,
      });

      _lastStatus = status;
      _lastValve = desiredValve;
    }
  }

  static Future<void> stop() async {
    await _sensorSubscription?.cancel();
    await _authSubscription?.cancel();

    _sensorSubscription = null;
    _authSubscription = null;

    _activeUid = null;

    _lastStatus = null;
    _lastValve = null;

    _eventQueue = Future.value();

    _started = false;
  }
}
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryService {
  static bool _started = false;

  static StreamSubscription<User?>?
      _authSubscription;

  static StreamSubscription<DatabaseEvent>?
      _sensorSubscription;

  static String? _activeUid;

  static String? _lastWaterStatus;
  static String? _lastValve;

  static Future<void> _eventQueue =
      Future.value();

  static late final FirebaseDatabase _database =
      FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );

  // ====================================================
  // Start Service
  // ====================================================

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

  // ====================================================
  // Switch Firebase User
  // ====================================================

  static Future<void> _switchUser(
    User? user,
  ) async {
    await _sensorSubscription?.cancel();

    _sensorSubscription = null;

    _activeUid = null;

    _lastWaterStatus = null;
    _lastValve = null;

    _eventQueue = Future.value();

    if (user == null) {
      return;
    }

    final String uid = user.uid;

    _activeUid = uid;

    final DatabaseReference sensorRef =
        _database.ref(
      'users/$uid/sensor',
    );

    final DatabaseReference historyRef =
        _database.ref(
      'users/$uid/history',
    );

    _sensorSubscription =
        sensorRef.onValue.listen(
      (DatabaseEvent event) {
        _eventQueue = _eventQueue
            .then(
          (_) async {
            if (_activeUid != uid) {
              return;
            }

            await _handleSensorEvent(
              event: event,
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
      onError: (Object error) {
        print(
          "HistoryService sensor error: $error",
        );
      },
    );
  }

  // ====================================================
  // Handle Sensor Data
  // ====================================================

  static Future<void> _handleSensorEvent({
    required DatabaseEvent event,
    required DatabaseReference historyRef,
    required String uid,
  }) async {
    if (_activeUid != uid) {
      return;
    }

    final dynamic value =
        event.snapshot.value;

    if (value == null ||
        value is! Map) {
      return;
    }

    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(
      value,
    );

    // --------------------------------------------------
    // Read ESP8266 final values
    // --------------------------------------------------

    final String waterStatus =
        data['waterStatus']
                ?.toString()
                .trim()
                .toUpperCase() ??
            'UNKNOWN';

    final String valve =
        data['valve']
                ?.toString()
                .trim()
                .toUpperCase() ??
            'UNKNOWN';

    final double turbidity =
        _toDouble(
      data['turbidity'],
    );

    final String deviceStatus =
        data['deviceStatus']
                ?.toString()
                .trim()
                .toUpperCase() ??
            'UNKNOWN';

    final bool manualOverride =
        data['manualOverride'] == true;

    final bool manualButton =
        data['manualButton'] == true;

    final String controlMode =
        data['controlMode']
                ?.toString()
                .trim()
                .toUpperCase() ??
            'AUTO';

    // --------------------------------------------------
    // Ignore incomplete sensor state
    // --------------------------------------------------

    if (waterStatus == 'UNKNOWN' ||
        valve == 'UNKNOWN') {
      return;
    }

    // --------------------------------------------------
    // First Firebase event = baseline only
    //
    // Don't create history simply because app opened.
    // --------------------------------------------------

    if (_lastWaterStatus == null &&
        _lastValve == null) {
      _lastWaterStatus =
          waterStatus;

      _lastValve =
          valve;

      return;
    }

    // --------------------------------------------------
    // Create history only if water status OR valve changed
    // --------------------------------------------------

    final bool statusChanged =
        _lastWaterStatus !=
            waterStatus;

    final bool valveChanged =
        _lastValve != valve;

    if (!statusChanged &&
        !valveChanged) {
      return;
    }

    // --------------------------------------------------
    // Update local state BEFORE async push
    // Prevent duplicate events
    // --------------------------------------------------

    _lastWaterStatus =
        waterStatus;

    _lastValve =
        valve;

    // --------------------------------------------------
    // Push history
    // --------------------------------------------------

    await historyRef.push().set({
      'waterStatus':
          waterStatus,

      'turbidity':
          turbidity,

      'valve':
          valve,

      'deviceStatus':
          deviceStatus,

      'manualOverride':
          manualOverride,

      'manualButton':
          manualButton,

      'controlMode':
          controlMode,

      'timestamp':
          ServerValue.timestamp,
    });

    print(
      "History added: "
      "$waterStatus | "
      "$valve | "
      "$turbidity",
    );
  }

  // ====================================================
  // Convert Firebase value to double
  // ====================================================

  static double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ====================================================
  // Stop Service
  // ====================================================

  static Future<void> stop() async {
    await _sensorSubscription?.cancel();
    await _authSubscription?.cancel();

    _sensorSubscription = null;
    _authSubscription = null;

    _activeUid = null;

    _lastWaterStatus = null;
    _lastValve = null;

    _eventQueue =
        Future.value();

    _started = false;
  }
}
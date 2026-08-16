import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryService {
  static bool _started = false;

  static String? _lastStatus;
  static String? _lastValve;

  static void start() {
    if (_started) return;
    _started = true;

    final FirebaseDatabase database =
        FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://water-quality-monitoring-94502-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );

    final DatabaseReference sensorRef =
        database.ref('sensor');

    final DatabaseReference historyRef =
        database.ref('history');

    sensorRef.onValue.listen((event) async {
      final value = event.snapshot.value;

      if (value is! Map) return;

      final data =
          Map<dynamic, dynamic>.from(value);

      final rawTurbidity = data['turbidity'];

      double turbidity = 0;

      if (rawTurbidity is num) {
        turbidity = rawTurbidity.toDouble();
      } else {
        turbidity =
            double.tryParse(
                  rawTurbidity.toString(),
                ) ??
                0;
      }

      // -------------------------------
      // WATER QUALITY
      // -------------------------------

      final String status =
          turbidity < 300
              ? 'CLEAR'
              : 'DIRTY';

      // -------------------------------
      // MANUAL OVERRIDE
      // -------------------------------

      bool manualOverride =
          data['manualOverride'] == true;

      String currentValve =
          data['valve']
                  ?.toString()
                  .toUpperCase() ??
              'UNKNOWN';

      String desiredValve;

      // Clean water
      if (status == 'CLEAR') {
        desiredValve = 'OPEN';

        // Clear manual override
        if (manualOverride) {
          await sensorRef
              .child('manualOverride')
              .set(false);

          manualOverride = false;
        }
      }

      // Dirty water
      else {
        // User manually opened valve
        if (manualOverride) {
          desiredValve = 'OPEN';
        } else {
          desiredValve = 'CLOSED';
        }
      }

      // -------------------------------
      // UPDATE WATER STATUS
      // -------------------------------

      if (data['waterStatus']
              ?.toString()
              .toUpperCase() !=
          status) {
        await sensorRef
            .child('waterStatus')
            .set(status);
      }

      // -------------------------------
      // UPDATE VALVE AUTOMATICALLY
      // -------------------------------

      if (currentValve != desiredValve) {
        await sensorRef
            .child('valve')
            .set(desiredValve);

        currentValve = desiredValve;
      }

      // -------------------------------
      // HISTORY
      // -------------------------------

      if (_lastStatus == null &&
          _lastValve == null) {
        _lastStatus = status;
        _lastValve = currentValve;
        return;
      }

      if (_lastStatus != status ||
          _lastValve != currentValve) {
        await historyRef.push().set({
          'waterStatus': status,
          'turbidity':
              turbidity.toInt(),
          'valve': currentValve,
          'timestamp':
              DateTime.now()
                  .millisecondsSinceEpoch,
        });

        _lastStatus = status;
        _lastValve = currentValve;
      }
    });
  }
}
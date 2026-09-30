enum PickupPoint {
  mainGate,
  hostelGate,
}

extension PickupPointX on PickupPoint {
  String get label {
    switch (this) {
      case PickupPoint.mainGate:
        return 'Main Gate';
      case PickupPoint.hostelGate:
        return 'Hostel Gate';
    }
  }

  String get subtitle {
    switch (this) {
      case PickupPoint.mainGate:
        return 'Near admin block / main entrance';
      case PickupPoint.hostelGate:
        return 'Near hostel complex entrance';
    }
  }

  String get storageKey {
    switch (this) {
      case PickupPoint.mainGate:
        return 'main_gate';
      case PickupPoint.hostelGate:
        return 'hostel_gate';
    }
  }

  static PickupPoint fromStorage(String? key) {
    if (key == PickupPoint.hostelGate.storageKey) {
      return PickupPoint.hostelGate;
    }
    return PickupPoint.mainGate;
  }
}

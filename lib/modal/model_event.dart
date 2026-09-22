/// Current user's registration on an event (`my_registration` from event GET).
class MyRegistration {
  final String? role;
  final String? paymentStatus;

  const MyRegistration({this.role, this.paymentStatus});

  factory MyRegistration.fromJson(Map json) {
    return MyRegistration(
      role: json['role']?.toString().trim(),
      paymentStatus: json['payment_status']?.toString().trim().toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'payment_status': paymentStatus,
      };

  bool get isPaid => paymentStatus == 'paid';
}

class ModelEvent {
  String? id;
  String? title;
  String? description;
  String? category;
  String? venue;
  String? eventDate;
  String? eventEndDate;
  List<String>? banners;
  String? hostId;
  String? hostName;
  int? attendees;
  bool? isFavorite;
  String? status;
  DateTime? createdAt;
  String? userRole; // 'attendee', 'volunteer', 'host', or null
  DateTime? registrationDeadline;
  bool? canClose;
  dynamic closeBlockers;
  /// Present when GET includes `user_id` and the user is registered.
  MyRegistration? myRegistration;

  ModelEvent({
    this.id,
    this.title,
    this.description,
    this.category,
    this.venue,
    this.eventDate,
    this.eventEndDate,
    this.banners,
    this.hostId,
    this.hostName,
    this.attendees,
    this.isFavorite,
    this.status,
    this.createdAt,
    this.userRole,
    this.registrationDeadline,
    this.canClose,
    this.closeBlockers,
    this.myRegistration,
  });

  // Maps JSON from API to Dart object
  ModelEvent.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    title = json['title'];
    description = json['description'];
    category = json['category'];
    venue = json['venue'];
    eventDate = json['event_date'] ?? json['date'];
    final rawEnd = json['event_end_date']?.toString();
    eventEndDate = (rawEnd != null && rawEnd.isNotEmpty && rawEnd != '0000-00-00 00:00:00') ? rawEnd : null;
    banners = List<String>.from(json['banners'] ?? []);
    hostId = json['host_id']?.toString();
    hostName = json['host_name'] ?? json['created_by'];
    attendees = int.tryParse(json['attendees']?.toString() ?? '0');
    isFavorite = json['is_favorite'] ?? false;
    status = json['status'] ?? 'pending';
    createdAt = json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null;
    userRole = json['user_role'] ?? json['role'];
    final rawDeadline = json['registration_deadline']?.toString();
    if (rawDeadline != null &&
        rawDeadline.isNotEmpty &&
        rawDeadline != 'null' &&
        rawDeadline != '0000-00-00 00:00:00') {
      registrationDeadline = DateTime.tryParse(rawDeadline.replaceAll(' ', 'T'));
    }
    final rawCanClose = json['can_close'];
    if (rawCanClose is bool) {
      canClose = rawCanClose;
    } else if (rawCanClose != null) {
      final s = rawCanClose.toString().toLowerCase();
      canClose = s == '1' || s == 'true';
    }
    closeBlockers = json['close_blockers'];
    myRegistration = parseMyRegistration(json['my_registration']);
  }

  /// Parses `my_registration: { role, payment_status }` from event GET.
  static MyRegistration? parseMyRegistration(dynamic raw) {
    if (raw is! Map) return null;
    final reg = MyRegistration.fromJson(Map<String, dynamic>.from(
      raw.map((k, v) => MapEntry(k.toString(), v)),
    ));
    if ((reg.role == null || reg.role!.isEmpty) &&
        (reg.paymentStatus == null || reg.paymentStatus!.isEmpty)) {
      return null;
    }
    return reg;
  }

  /// Whether Leave/Switch for [wantRole] (`attend` / `participate`) is paid-locked.
  static bool isPaidLockedForRole(MyRegistration? reg, String wantRole) {
    if (reg == null || !reg.isPaid) return false;
    final regRole = (reg.role ?? '').toLowerCase();
    final want = wantRole.trim().toLowerCase();
    if (want == 'attend') {
      return regRole == 'attend' ||
          regRole == 'attendee' ||
          regRole == 'viewer' ||
          regRole.isEmpty;
    }
    if (want == 'participate') {
      return regRole == 'participate' || regRole == 'participant';
    }
    return false;
  }

  // Convert object to JSON for API requests
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['category'] = category;
    data['venue'] = venue;
    data['event_date'] = eventDate;
    data['event_end_date'] = eventEndDate;
    data['banners'] = banners;
    data['host_id'] = hostId;
    data['host_name'] = hostName;
    data['attendees'] = attendees;
    data['is_favorite'] = isFavorite;
    data['status'] = status;
    data['created_at'] = createdAt?.toIso8601String();
    data['user_role'] = userRole;
    data['registration_deadline'] = registrationDeadline?.toIso8601String();
    data['can_close'] = canClose;
    data['close_blockers'] = closeBlockers;
    if (myRegistration != null) {
      data['my_registration'] = myRegistration!.toJson();
    }
    return data;
  }
}

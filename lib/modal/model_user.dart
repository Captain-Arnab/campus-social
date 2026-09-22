class ModelUserLink {
  final int? id;
  final String url;
  final String label;

  const ModelUserLink({this.id, required this.url, required this.label});

  factory ModelUserLink.fromJson(Map json) {
    return ModelUserLink(
      id: int.tryParse(json['id']?.toString() ?? ''),
      url: (json['url'] ?? '').toString().trim(),
      label: (json['label'] ?? '').toString().trim(),
    );
  }

  /// Chip text: label, else host from URL.
  String get displayLabel {
    if (label.isNotEmpty) return label;
    try {
      final u = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return u.host.isNotEmpty ? u.host : url;
    } catch (_) {
      return url;
    }
  }
}

class ModelUser {
  String? id;
  String? fullName;
  String? email;
  String? phone;
  String? image;
  String? bio;
  String? interests;
  String? departmentClass;
  String? institutionId;
  String? institutionName;
  bool? isAdmin;
  /// From API `is_student` (1 = student).
  bool? isStudent;
  String? rollNumber;
  String? empNumber;
  String? linkedSubadminId;
  List<String> adminPrivileges;
  bool canApproveEvents;
  List<ModelUserLink> links;

  ModelUser({
    this.id,
    this.fullName,
    this.email,
    this.phone,
    this.image,
    this.bio,
    this.interests,
    this.departmentClass,
    this.institutionId,
    this.institutionName,
    this.isAdmin,
    this.isStudent,
    this.rollNumber,
    this.empNumber,
    this.linkedSubadminId,
    this.adminPrivileges = const [],
    this.canApproveEvents = false,
    this.links = const [],
  });

  ModelUser.fromJson(Map<String, dynamic> json)
      : adminPrivileges = const [],
        canApproveEvents = false,
        links = const [] {
    id = json['id']?.toString();
    fullName = json['full_name'];
    email = json['email'];
    phone = json['phone'];
    image = json['profile_pic'] ?? json['image'];
    bio = json['bio'];
    interests = json['interests'];
    departmentClass = json['department_class']?.toString();
    final idRaw = json['institution_id']?.toString().trim();
    institutionId = (idRaw != null && idRaw.isNotEmpty) ? idRaw : null;
    final nestedInst = json['institution'];
    if (institutionId == null && nestedInst is Map) {
      final nestedId = nestedInst['id']?.toString().trim();
      if (nestedId != null && nestedId.isNotEmpty) {
        institutionId = nestedId;
      }
    }
    institutionName = _parseInstitutionName(json);
    isAdmin = json['is_admin'] == 1 || json['is_admin'] == true;
    final isStudRaw = json['is_student'];
    isStudent = isStudRaw == 1 || isStudRaw == true || isStudRaw == '1';
    rollNumber = json['roll_number']?.toString();
    empNumber = json['emp_number']?.toString();

    final linked = json['linked_subadmin_id']?.toString().trim();
    linkedSubadminId =
        (linked != null && linked.isNotEmpty && linked != 'null') ? linked : null;

    final priv = json['admin_privileges'];
    if (priv is List) {
      adminPrivileges = priv.map((e) => e.toString()).toList();
    }

    final can = json['can_approve_events'];
    canApproveEvents =
        can == true || can == 1 || can?.toString() == '1';

    final rawLinks = json['links'];
    if (rawLinks is List) {
      links = rawLinks
          .whereType<Map>()
          .map((e) => ModelUserLink.fromJson(e))
          .where((l) => l.url.isNotEmpty)
          .toList();
    }
  }

  static String? _parseInstitutionName(Map<String, dynamic> json) {
    final direct = json['institution_name']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final inst = json['institution'];
    if (inst is Map) {
      final name = inst['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    } else if (inst is String) {
      final name = inst.trim();
      if (name.isNotEmpty) return name;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['full_name'] = fullName;
    data['email'] = email;
    data['phone'] = phone;
    data['image'] = image;
    data['bio'] = bio;
    data['interests'] = interests;
    data['department_class'] = departmentClass;
    data['institution_id'] = institutionId;
    data['institution_name'] = institutionName;
    data['is_admin'] = isAdmin;
    if (isStudent != null) {
      data['is_student'] = isStudent! ? 1 : 0;
    }
    data['roll_number'] = rollNumber;
    data['emp_number'] = empNumber;
    data['linked_subadmin_id'] = linkedSubadminId;
    data['admin_privileges'] = adminPrivileges;
    data['can_approve_events'] = canApproveEvents;
    data['links'] = links
        .map((l) => {'id': l.id, 'url': l.url, 'label': l.label})
        .toList();
    return data;
  }
}

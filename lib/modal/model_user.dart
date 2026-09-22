class ModelUser {
  String? id;
  String? fullName;
  String? email;
  String? phone;
  String? image;
  String? bio; // Added for Profile/About section
  String? interests; // Added for Interests section
  String? departmentClass;
  String? institutionId;
  String? institutionName;
  bool? isAdmin; // Admin can grant edit permissions, upload certificates
  /// From API `is_student` (1 = student).
  bool? isStudent;
  String? rollNumber;
  String? empNumber;

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
  });

  // Maps the JSON keys from your PHP API to Dart properties
  ModelUser.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    fullName = json['full_name'];
    email = json['email'];
    phone = json['phone'];
    // API returns 'profile_pic', model uses 'image'
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

  // Converts the object back to JSON for API requests like updateProfile
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
    return data;
  }
}
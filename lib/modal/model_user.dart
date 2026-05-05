class ModelUser {
  String? id;
  String? fullName;
  String? email;
  String? phone;
  String? image;
  String? bio; // Added for Profile/About section
  String? interests; // Added for Interests section
  String? departmentClass;
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
    isAdmin = json['is_admin'] == 1 || json['is_admin'] == true;
    final isStudRaw = json['is_student'];
    isStudent = isStudRaw == 1 || isStudRaw == true || isStudRaw == '1';
    rollNumber = json['roll_number']?.toString();
    empNumber = json['emp_number']?.toString();
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
    data['is_admin'] = isAdmin;
    if (isStudent != null) {
      data['is_student'] = isStudent! ? 1 : 0;
    }
    data['roll_number'] = rollNumber;
    data['emp_number'] = empNumber;
    return data;
  }
}
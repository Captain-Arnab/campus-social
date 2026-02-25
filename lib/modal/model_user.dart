class ModelUser {
  String? id;
  String? fullName;
  String? email;
  String? phone;
  String? image;
  String? bio; // Added for Profile/About section
  String? interests; // Added for Interests section

  ModelUser({
    this.id,
    this.fullName,
    this.email,
    this.phone,
    this.image,
    this.bio,
    this.interests,
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
    return data;
  }
}
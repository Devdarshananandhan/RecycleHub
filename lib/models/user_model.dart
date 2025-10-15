class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String city;
  final String profileImage;
  final double rating;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.city,
    required this.profileImage,
    required this.rating,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      city: json['city'],
      profileImage: json['profileImage'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'city': city,
      'profileImage': profileImage,
      'rating': rating,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? city,
    String? profileImage,
    double? rating,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      city: city ?? this.city,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
    );
  }
}
class UserAddress {
  final String id;
  final String userId;
  final String fullName;
  final String streetAddress;
  final String city;
  final String phone;
  final String? deliveryInstructions;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAddress({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.streetAddress,
    required this.city,
    required this.phone,
    this.deliveryInstructions,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      streetAddress: json['streetAddress'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      deliveryInstructions: json['deliveryInstructions'],
      isDefault: json['isDefault'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'streetAddress': streetAddress,
      'city': city,
      'phone': phone,
      'deliveryInstructions': deliveryInstructions,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserAddress copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? streetAddress,
    String? city,
    String? phone,
    String? deliveryInstructions,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

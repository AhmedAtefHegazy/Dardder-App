class Address {
  final String id;
  final String userId;
  final String fullName;
  final String streetAddress;
  final String city;
  final String phone;
  final String? deliveryInstructions;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.streetAddress,
    required this.city,
    required this.phone,
    this.deliveryInstructions,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      streetAddress: json['streetAddress'] as String,
      city: json['city'] as String,
      phone: json['phone'] as String,
      deliveryInstructions: json['deliveryInstructions'] as String?,
      isDefault: json['isDefault'] as bool,
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
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? streetAddress,
    String? city,
    String? phone,
    String? deliveryInstructions,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

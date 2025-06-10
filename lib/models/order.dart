enum OrderStatus {
  Pending,
  Processing,
  Shipped,
  Delivered,
  Cancelled;

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => OrderStatus.Pending,
    );
  }

  String toJson() => index.toString();
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final List<OrderItem> items;
  final double totalAmount;
  final String shippingAddress;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      items: ((json['items'] ?? json['orderItems']) as List? ?? [])
          .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      status: json['status'] is int
          ? OrderStatus.values[json['status']]
          : OrderStatus.fromString(json['status']?.toString() ?? 'Pending'),
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
      'userName': userName,
      'userEmail': userEmail,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    List<OrderItem>? items,
    double? totalAmount,
    String? shippingAddress,
    String? paymentMethod,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: (json['quantity'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
    };
  }
}

import 'enums.dart';

class PaymentModel {
  final String id;
  final String userId;
  final String? bookingId;
  final String? subscriptionId;
  final PaymentType paymentType;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String paystackReference;
  final String? paystackAccessCode;
  final String? paymentMethod;
  final DateTime? verifiedAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.userId,
    this.bookingId,
    this.subscriptionId,
    required this.paymentType,
    required this.amount,
    this.currency = 'NGN',
    this.status = PaymentStatus.pending,
    required this.paystackReference,
    this.paystackAccessCode,
    this.paymentMethod,
    this.verifiedAt,
    this.metadata,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookingId: json['booking_id'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      paymentType:
          PaymentType.fromString(json['payment_type'] as String?),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'NGN',
      status: PaymentStatus.fromString(json['status'] as String?),
      paystackReference: json['paystack_reference'] as String,
      paystackAccessCode: json['paystack_access_code'] as String?,
      paymentMethod: json['payment_method'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'subscription_id': subscriptionId,
      'payment_type': paymentType.toJsonValue(),
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'paystack_reference': paystackReference,
      'paystack_access_code': paystackAccessCode,
      'payment_method': paymentMethod,
      'verified_at': verifiedAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? bookingId,
    String? subscriptionId,
    PaymentType? paymentType,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? paystackReference,
    String? paystackAccessCode,
    String? paymentMethod,
    DateTime? verifiedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      paymentType: paymentType ?? this.paymentType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paystackReference: paystackReference ?? this.paystackReference,
      paystackAccessCode: paystackAccessCode ?? this.paystackAccessCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PaymentModel(id: $id, amount: $amount, status: $status)';
}

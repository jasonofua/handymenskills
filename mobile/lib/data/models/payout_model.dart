import 'enums.dart';

class PayoutModel {
  final String id;
  final String workerId;
  final String? bookingId;
  final double amount;
  final PayoutStatus status;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String? paystackTransferCode;
  final String? paystackRecipientCode;
  final DateTime createdAt;
  final DateTime? processedAt;

  const PayoutModel({
    required this.id,
    required this.workerId,
    this.bookingId,
    required this.amount,
    this.status = PayoutStatus.pending,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.paystackTransferCode,
    this.paystackRecipientCode,
    required this.createdAt,
    this.processedAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      bookingId: json['booking_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: PayoutStatus.fromString(json['status'] as String?),
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      accountName: json['account_name'] as String,
      paystackTransferCode: json['paystack_transfer_code'] as String?,
      paystackRecipientCode: json['paystack_recipient_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'booking_id': bookingId,
      'amount': amount,
      'status': status.name,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'paystack_transfer_code': paystackTransferCode,
      'paystack_recipient_code': paystackRecipientCode,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  PayoutModel copyWith({
    String? id,
    String? workerId,
    String? bookingId,
    double? amount,
    PayoutStatus? status,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? paystackTransferCode,
    String? paystackRecipientCode,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return PayoutModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      paystackTransferCode:
          paystackTransferCode ?? this.paystackTransferCode,
      paystackRecipientCode:
          paystackRecipientCode ?? this.paystackRecipientCode,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayoutModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PayoutModel(id: $id, amount: $amount, status: $status)';
}

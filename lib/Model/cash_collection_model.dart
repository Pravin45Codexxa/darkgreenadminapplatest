class CashCollectionModel {
  String? id,
      name,
      mobile,
      orderId,
      cashReceived,
      type,
      amount,
      message,
      transactionDate,
      date;

  CashCollectionModel({
    this.id,
    this.name,
    this.mobile,
    this.orderId,
    this.cashReceived,
    this.type,
    this.amount,
    this.message,
    this.transactionDate,
    this.date,
  });

  factory CashCollectionModel.fromJson(Map<String, dynamic> json) =>
      CashCollectionModel(
        id: json["id"],
        name: json["name"],
        mobile: json["mobile"],
        orderId: json["order_id"] ?? "",
        cashReceived: json["cash_received"],
        type: json["type"],
        amount: json["amount"],
        message: json["message"],
        transactionDate: json["transaction_date"],
        date: json["date"],
      );
}

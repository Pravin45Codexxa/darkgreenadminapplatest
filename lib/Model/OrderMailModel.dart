import 'package:admin_eshop/Helper/String.dart';

class OrderMailModel {
  String? id, orderId, orderItemId, subject, message, fileUrl, dateAdded;

  OrderMailModel({
    this.id,
    this.orderId,
    this.orderItemId,
    this.subject,
    this.message,
    this.fileUrl,
    this.dateAdded,
  });

  factory OrderMailModel.fromJson(Map<String, dynamic> json) {
    return OrderMailModel(
        id: json[ID],
        orderId: json[ORDER_ID],
        orderItemId: json[ORDER_ITEM_ID],
        subject: json[SUBJECT],
        message: json[MESSAGE],
        fileUrl: json[FILE_URL],
        dateAdded: json[DATE_ADDED]);
  }
}

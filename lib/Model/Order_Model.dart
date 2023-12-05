import 'package:intl/intl.dart';
import 'package:admin_eshop/Helper/String.dart';

class Order {
  Order({
    this.id,
    this.orderId,
    this.courierAgency,
    this.trackingId,
    this.url,
    this.orderDetails,
  });

  String? id;
  String? orderId;
  String? courierAgency;
  String? trackingId;
  String? url;
  Order_Model? orderDetails;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json["id"],
        orderId: json["order_id"],
        courierAgency: json["courier_agency"],
        trackingId: json["tracking_id"],
        url: json["url"],
        orderDetails: json["order_details"] == ""
            ? null
            : Order_Model.fromJson(json["order_details"]),
      );
}

class Order_Model {
  String? id,
      user_id,
      name,
      email,
      userName,
      mobile,
      notes,
      latitude,
      longitude,
      delCharge,
      walBal,
      promo,
      promoDis,
      payMethod,
      total,
      subTotal,
      payable,
      address,
      taxAmt,
      taxPer,
      orderDate,
      dateTime,
      isCancleable,
      isReturnable,
      isAlrCancelled,
      isAlrReturned,
      rtnReqSubmitted,
      activeStatus,
      otp,
      deliveryBoyId,
      invoice,
      delDate,
      delTime,
      countryCode,
      tracking_id,
      courier_agency,
      url,
      isLocalPickUp;
  List<Attachment>? attachList = [];

  List<OrderItem>? itemList;
  List<String?>? listStatus = [];
  List<String?>? listDate = [];

  Order_Model(
      {this.id,
      this.user_id,
      this.name,
      this.mobile,
      this.notes,
      this.delCharge,
      this.walBal,
      this.promo,
      this.promoDis,
      this.payMethod,
      this.total,
      this.subTotal,
      this.payable,
      this.address,
      this.taxPer,
      this.taxAmt,
      this.orderDate,
      this.dateTime,
      this.itemList,
      this.listStatus,
      this.listDate,
      this.isReturnable,
      this.isCancleable,
      this.isAlrCancelled,
      this.isAlrReturned,
      this.rtnReqSubmitted,
      this.activeStatus,
      this.otp,
      this.invoice,
      this.latitude,
      this.longitude,
      this.delDate,
      this.delTime,
      this.countryCode,
      this.deliveryBoyId,
      this.attachList,
      this.tracking_id,
      this.url,
      this.courier_agency,
      this.isLocalPickUp,
      this.userName,
      this.email});

  factory Order_Model.fromJson(Map<String, dynamic> parsedJson) {
    List<OrderItem> itemList = [];
    List<Attachment> attachmentList = [];
    var order = (parsedJson[ORDER_ITEMS] as List?);
    if (order == "" || order!.isEmpty) {
      itemList = [];
    } else {
      itemList = order.map((data) => OrderItem.fromJson(data)).toList();
    }
    String date = parsedJson[DATE_ADDED];
    date = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
    List<String?> lStatus = [];
    List<String?> lDate = [];

    var attachments = (parsedJson[ATTACHMENTS] as List?);

    if (attachments == "" || attachments!.isEmpty) {
      attachmentList = [];
    } else {
      attachmentList =
          attachments.map((data) => Attachment.fromJson(data)).toList();
    }

    var allSttus = parsedJson[STATUS];
    for (var curStatus in allSttus) {
      lStatus.add(curStatus[0]);
      lDate.add(curStatus[1]);
    }
    return Order_Model(
        user_id: parsedJson[USER_ID],
        id: parsedJson[ID],
        name: parsedJson[USERNAME] ?? "",
        mobile: parsedJson[MOBILE],
        notes: parsedJson[NOTES],
        invoice: parsedJson[INVOICE],
        delCharge: parsedJson[DEL_CHARGE],
        walBal: parsedJson[WAL_BAL],
        promo: parsedJson[PROMOCODE],
        promoDis: parsedJson[PROMO_DIS],
        payMethod: parsedJson[PAYMENT_METHOD],
        total: parsedJson[FINAL_TOTAL],
        subTotal: parsedJson[TOTAL],
        payable: parsedJson[TOTAL_PAYABLE],
        address: parsedJson[ADDRESS],
        taxAmt: parsedJson[TOTAL_TAX_AMT],
        taxPer: parsedJson[TOTAL_TAX_PER],
        dateTime: parsedJson[DATE_ADDED],
        isCancleable: parsedJson[ISCANCLEABLE],
        isReturnable: parsedJson[ISRETURNABLE],
        isAlrCancelled: parsedJson[ISALRCANCLE],
        isAlrReturned: parsedJson[ISALRRETURN],
        rtnReqSubmitted: parsedJson[ISRTNREQSUBMITTED],
        orderDate: date,
        itemList: itemList,
        listStatus: lStatus,
        listDate: lDate,
        activeStatus: parsedJson[ACTIVE_STATUS],
        otp: parsedJson[OTP],
        latitude: parsedJson[LATITUDE],
        countryCode: parsedJson[COUNTRY_CODE],
        longitude: parsedJson[LONGITUDE],
        delDate: parsedJson[DEL_DATE] != ""
            ? DateFormat('dd-MM-yyyy')
                .format(DateTime.parse(parsedJson[DEL_DATE]))
            : '',
        delTime: parsedJson[DEL_TIME] != "" ? parsedJson[DEL_TIME] : '',
        attachList: attachmentList,
        deliveryBoyId: parsedJson[DELIVERY_BOY_ID],
        courier_agency: parsedJson[COURIER_AGENCY],
        tracking_id: parsedJson[TRACKING_ID],
        isLocalPickUp: parsedJson[IS_LOCAL_PICKUP],
        url: parsedJson[URL],
        userName: parsedJson[USERNAME],
        email: parsedJson[EMAIL]);
  }
}

class OrderItem {
  String? id,
      name,
      qty,
      price,
      subTotal,
      status,
      image,
      varientId,
      isCancle,
      isReturn,
      isAlrCancelled,
      isAlrReturned,
      rtnReqSubmitted,
      varient_values,
      attr_name,
      productId,
      curSelected,
      productType,
      downloadAllow,
      isSent;

  List<String?>? listStatus = [];
  List<String?>? listDate = [];

  OrderItem(
      {this.qty,
      this.id,
      this.name,
      this.price,
      this.subTotal,
      this.status,
      this.image,
      this.varientId,
      this.listDate,
      this.listStatus,
      this.isCancle,
      this.isReturn,
      this.isAlrReturned,
      this.isAlrCancelled,
      this.rtnReqSubmitted,
      this.attr_name,
      this.productId,
      this.varient_values,
      this.curSelected,
      this.productType,
      this.downloadAllow,
      this.isSent});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    List<String?> lStatus = [];
    List<String?> lDate = [];

    var allSttus = json[STATUS];
    for (var curStatus in allSttus) {
      lStatus.add(curStatus[0]);
      lDate.add(curStatus[1]);
    }
    return OrderItem(
      id: json[ID],
      qty: json[QUANTITY],
      name: json[NAME],
      image: json[IMAGE],
      price: json[PRICE],
      subTotal: json[SUB_TOTAL],
      varientId: json[PRODUCT_VARIENT_ID],
      listStatus: lStatus,
      status: json[ACTIVE_STATUS],
      curSelected: json[ACTIVE_STATUS],
      listDate: lDate,
      isCancle: json[ISCANCLEABLE],
      isReturn: json[ISRETURNABLE],
      isAlrCancelled: json[ISALRCANCLE],
      isAlrReturned: json[ISALRRETURN],
      rtnReqSubmitted: json[ISRTNREQSUBMITTED],
      attr_name: json[ATTR_NAME],
      productId: json[PRODUCT_ID],
      varient_values: json[VARIENT_VALUE],
      productType: json[TYPE],
      downloadAllow: json[DOWNLOAD_ALLOW],
      isSent: json[IS_SENT],
    );
  }
}

class Attachment {
  String? id, attachment, bankTransferStatus;

  Attachment({this.id, this.attachment, this.bankTransferStatus});

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
        id: json[ID],
        attachment: json[ATTACHMENT],
        bankTransferStatus: json["banktransfer_status"]);
  }
}

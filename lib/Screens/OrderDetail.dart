import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:admin_eshop/Model/OrderMailModel.dart';
import 'package:admin_eshop/Model/Person_Model.dart';
import 'package:admin_eshop/Screens/OrderMailDetailsScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:http/http.dart';
import 'package:open_filex/open_filex.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'EmailSend.dart';
import 'Home.dart';
import '../Model/Order_Model.dart';

class OrderDetail extends StatefulWidget {
  final Order_Model? model;
  final Function? updateHome;

  const OrderDetail({
    Key? key,
    this.model,
    this.updateHome,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateOrder();
  }
}

class StateOrder extends State<OrderDetail> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  ScrollController controller = ScrollController();
  List<OrderMailModel> digitalMailList = [];

  // Future<List<Directory>?>? _externalStorageDirectories;

  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;

  List<String> statusList = [
    PLACED,
    PROCESSED,
    SHIPED,
    DELIVERD,
    CANCLED,
    RETURNED,
    WAITING,
    READYTOPICKUP
  ];
  List<String> digitalList = [
    WAITING,
    PLACED,
    DELIVERD,
  ];
  List<String> digitalMailSendList = [MAIL_SENT];

  List<String> statusListOfBankTransfer = ["Pending", "Rejected", "Accepted"];
  bool? _isCancleable, _isReturnable, _isLoading = true;
  bool _isProgress = false, isNoteVisible = true;
  String? curStatus;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController? otpC,
      courierAgencyController,
      trackingIdController,
      urlController;
  final List<DropdownMenuItem> items = [];
  List<PersonModel> searchList = [];
  String? selectedValue, courierAgency, trackingId, url;
  int? selectedDelBoy = -1;
  final TextEditingController _controller = TextEditingController();
  late StateSetter delBoyState;

  bool fabIsVisible = true;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < widget.model!.itemList!.length; i++) {
      widget.model!.itemList![i].curSelected =
          widget.model!.itemList![i].status;
    }

    searchList.addAll(delBoyList);

    if (widget.model!.deliveryBoyId != "") {
      selectedDelBoy =
          delBoyList.indexWhere((f) => f.id == widget.model!.deliveryBoyId);
    }

    if (selectedDelBoy == -1) selectedDelBoy = -1;

    if (widget.model!.payMethod == "Bank Transfer") {
      statusList.removeWhere((element) => element == PLACED);
    }
    if (widget.model!.isLocalPickUp == "0") {
      statusList.removeWhere((element) => element == READYTOPICKUP);
    }

    controller = ScrollController();
    controller.addListener(
      () {
        setState(
          () {
            fabIsVisible = controller.position.userScrollDirection ==
                ScrollDirection.forward;
          },
        );
      },
    );
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
    curStatus = widget.model!.activeStatus;

    _controller.addListener(
      () {
        searchOperation(_controller.text);
      },
    );
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            noIntImage(),
            noIntText(context),
            noIntDec(context),
            AppBtn(
              title: getTranslated(context, TRY_AGAIN_INT_LBL)!,
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();

                Future.delayed(const Duration(seconds: 2)).then(
                  (_) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                          builder: (BuildContext context) => super.widget,
                        ),
                      );
                    } else {
                      await buttonController!.reverse();
                      setState(
                        () {},
                      );
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    Order_Model model = widget.model!;
    String? pDate, prDate, sDate, dDate, cDate, rDate;

    if (model.listStatus!.contains(PLACED)) {
      pDate = model.listDate![model.listStatus!.indexOf(PLACED)];

      if (pDate != "") {
        List d = pDate!.split(" ");
        pDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(PROCESSED)) {
      prDate = model.listDate![model.listStatus!.indexOf(PROCESSED)];
      if (prDate != "") {
        List d = prDate!.split(" ");
        prDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(SHIPED)) {
      sDate = model.listDate![model.listStatus!.indexOf(SHIPED)];
      if (sDate != "") {
        List d = sDate!.split(" ");
        sDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(DELIVERD)) {
      dDate = model.listDate![model.listStatus!.indexOf(DELIVERD)];
      if (dDate != "") {
        List d = dDate!.split(" ");
        dDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(CANCLED)) {
      cDate = model.listDate![model.listStatus!.indexOf(CANCLED)];
      if (cDate != "") {
        List d = cDate!.split(" ");
        cDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(RETURNED)) {
      rDate = model.listDate![model.listStatus!.indexOf(RETURNED)];
      if (rDate != "") {
        List d = rDate!.split(" ");
        rDate = d[0] + "\n" + d[1];
      }
    }

    _isCancleable = model.isCancleable == "1" ? true : false;
    _isReturnable = model.isReturnable == "1" ? true : false;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: lightWhite,
      appBar: getAppBar(ORDER_DETAIL, context),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: fabIsVisible ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 108.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (model.itemList!.length == 1)
                model.itemList![0].productType == 'digital_product' &&
                        model.itemList![0].isSent == "1"
                    ? FloatingActionButton(
                        backgroundColor: lightWhite,
                        onPressed: () async {
                          getDigitalOrderMailData(
                              model.id!, model.itemList![0].id!);
                        },
                        heroTag: null,
                        child: const Icon(
                          Icons.mark_email_read,
                          size: 25,
                          color: fontColor,
                        ),
                      )
                    : const SizedBox.shrink(),
              if (model.itemList!.length == 1)
                model.itemList![0].productType == 'digital_product' &&
                        model.itemList![0].isSent != "1" &&
                        model.itemList![0].downloadAllow == "0"
                    ? FloatingActionButton(
                        backgroundColor: lightWhite,
                        /*Image.asset(
                          'assets/images/google.png',
                          width: 25,
                          height: 25,
                          color: fontColor,
                        ),*/
                        onPressed: () async {
                          _launchCaller("mailto:${model.email}");
                        },
                        heroTag: null,
                        child: const Icon(
                          Icons.mail,
                          size: 25,
                        ),
                      )
                    : const SizedBox.shrink(),
              const SizedBox(
                height: 10,
              ),
              FloatingActionButton(
                backgroundColor: lightWhite,
                onPressed: () async {
                  String text =
                      '${getTranslated(context, hello)!} ${model.name},\n${getTranslated(context, yourOrderWithId)!} : ${model.id} ${getTranslated(context, isText)!} ${model.activeStatus}. ${getTranslated(context, thankyouText)!}';
                  await launchUrlString(
                      "https://wa.me/${"${model.countryCode!}${model.mobile!}"}?text=$text",
                      mode: LaunchMode.externalApplication);
                },
                heroTag: null,
                child: Image.asset(
                  'assets/images/whatsapp.png',
                  width: 25,
                  height: 25,
                  color: fontColor,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              FloatingActionButton(
                backgroundColor: lightWhite,
                onPressed: () async {
                  String text =
                      '${getTranslated(context, hello)!} ${model.name},\n${getTranslated(context, yourOrderWithId)!} : ${model.id} ${getTranslated(context, isText)!} ${model.activeStatus}. ${getTranslated(context, thankyouText)!}';

                  var uri = 'sms:${model.mobile}?body=$text';
                  await launchUrlString(uri);
                },
                heroTag: null,
                child: const Icon(
                  Icons.message,
                  color: fontColor,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isNetworkAvail
          ? Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              model.notes != ""
                                  ? Visibility(
                                      visible: isNoteVisible,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          decoration: BoxDecoration(
                                            color: Colors.yellow.shade200,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(3.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  style: BorderStyle.solid,
                                                  width: 2,
                                                  color: fontColor
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          "${getTranslated(context, noteText)!}:",
                                                          style: const TextStyle(
                                                              color: fontColor),
                                                        ),
                                                        InkWell(
                                                          onTap: () {
                                                            if (mounted) {
                                                              setState(
                                                                () {
                                                                  isNoteVisible =
                                                                      false;
                                                                },
                                                              );
                                                            }
                                                          },
                                                          child: const Icon(
                                                            Icons.close,
                                                            size: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(model.notes!),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(),
                              Card(
                                elevation: 0,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${getTranslated(context, ORDER_ID_LBL)!} - ${model.id!}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              color: lightBlack2,
                                            ),
                                      ),
                                      Text(
                                        "${getTranslated(context, ORDER_DATE)!} - ${model.orderDate!}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              color: lightBlack2,
                                            ),
                                      ),
                                      Text(
                                        "${getTranslated(context, PAYMENT_MTHD)!} - ${model.payMethod!}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(color: lightBlack2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              model.delDate != "" && model.delDate!.isNotEmpty
                                  ? Card(
                                      elevation: 0,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(
                                          "${getTranslated(context, PREFER_DATE_TIME)!}: ${model.delDate!} - ${model.delTime!}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                                color: lightBlack2,
                                              ),
                                        ),
                                      ),
                                    )
                                  : Container(),
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: model.itemList!.length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, i) {
                                  print(
                                      "itemlist len****${model.itemList!.length}");
                                  OrderItem orderItem = model.itemList![i];
                                  return productItem(orderItem, model, i);
                                },
                              ),
                              model.payMethod == "Bank Transfer"
                                  ? bankProof(model)
                                  : Container(),
                              shippingDetails(),
                              (widget.model!.courier_agency != "" &&
                                      widget.model!.tracking_id != "" &&
                                      widget.model!.url != "")
                                  ? trackingDetails(model)
                                  : Container(),
                              dwnInvoice(),
                              priceDetails(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.model!.itemList!.length == 1)
                      widget.model!.itemList![0].productType ==
                              'digital_product'
                          ? model.itemList![0].isSent != "1" &&
                                  widget.model!.itemList![0].downloadAllow ==
                                      "0"
                              ? Padding(
                                  padding: const EdgeInsetsDirectional.all(13),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) => SendMail(
                                            email: model.email ?? '',
                                            productName: widget
                                                    .model!.itemList![0].name ??
                                                '',
                                            orderId: model.id ?? '',
                                            orderIteamId:
                                                widget.model!.itemList![0].id ??
                                                    '',
                                            userName: model.userName ?? '',
                                          ),
                                        ),
                                      );
                                      // emailSendButtomSheet(context,
                                      //     setState, orderItem.name);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: primary,
                                        ),
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(5),
                                        ),
                                      ),
                                      height: 40,
                                      width: MediaQuery.of(context).size.width,
                                      child: Center(
                                        child: Text(
                                          getTranslated(context, SendMailText)!,
                                          style: const TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink()
                          : const SizedBox.shrink(),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(start: 13, end: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.model!.itemList![0].productType ==
                                  'digital_product'
                              ? Expanded(
                                  child: model.itemList![0].isSent == "0" &&
                                          widget.model!.itemList![0]
                                                  .downloadAllow ==
                                              "0"
                                      ? DropdownButtonFormField(
                                          isExpanded: true,
                                          dropdownColor: lightWhite,
                                          isDense: true,
                                          iconEnabledColor: fontColor,
                                          hint: Text(
                                            getTranslated(
                                                context, updateStatus)!,
                                            style: Theme.of(this.context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                  color: fontColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          decoration: const InputDecoration(
                                            filled: true,
                                            isDense: true,
                                            fillColor: lightWhite,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 10,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: fontColor,
                                              ),
                                            ),
                                          ),
                                          value: MAIL_SENT,
                                          onChanged: (dynamic newValue) {
                                            setState(
                                              () {
                                                curStatus = newValue;
                                              },
                                            );
                                          },
                                          items: digitalMailSendList.map(
                                            (String st) {
                                              return DropdownMenuItem<String>(
                                                value: st,
                                                child: Text(
                                                  () {
                                                    return capitalize(st);
                                                  }(),
                                                  // capitalize(st),
                                                  style: Theme.of(this.context)
                                                      .textTheme
                                                      .titleSmall!
                                                      .copyWith(
                                                        color: fontColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              );
                                            },
                                          ).toList(),
                                        )
                                      : DropdownButtonFormField(
                                          isExpanded: true,
                                          dropdownColor: lightWhite,
                                          isDense: true,
                                          iconEnabledColor: fontColor,
                                          hint: Text(
                                            getTranslated(
                                                context, updateStatus)!,
                                            style: Theme.of(this.context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                  color: fontColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          decoration: const InputDecoration(
                                            filled: true,
                                            isDense: true,
                                            fillColor: lightWhite,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 10,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: fontColor,
                                              ),
                                            ),
                                          ),
                                          value: widget.model!.activeStatus,
                                          onChanged: (dynamic newValue) {
                                            setState(
                                              () {
                                                curStatus = newValue;
                                              },
                                            );
                                          },
                                          items: digitalList.map(
                                            (String st) {
                                              return DropdownMenuItem<String>(
                                                value: st,
                                                child: Text(
                                                  () {
                                                    if (capitalize(st) ==
                                                        "Received") {
                                                      return getTranslated(
                                                          context,
                                                          RECEIVED_LBL)!;
                                                    } else if (capitalize(st) ==
                                                        "Delivered") {
                                                      return getTranslated(
                                                          context,
                                                          DELIVERED_LBL)!;
                                                    } else if (capitalize(st) ==
                                                        "awaiting") {
                                                      return getTranslated(
                                                          context,
                                                          RECEIVED_LBL)!;
                                                    }
                                                    return capitalize(st);
                                                  }(),
                                                  // capitalize(st),
                                                  style: Theme.of(this.context)
                                                      .textTheme
                                                      .titleSmall!
                                                      .copyWith(
                                                        color: fontColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              );
                                            },
                                          ).toList(),
                                        ),
                                )
                              : Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: DropdownButtonFormField(
                                      isExpanded: true,
                                      dropdownColor: lightWhite,
                                      isDense: true,
                                      iconEnabledColor: fontColor,
                                      hint: Text(
                                        getTranslated(context, updateStatus)!,
                                        style: Theme.of(this.context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              color: fontColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      decoration: const InputDecoration(
                                        filled: true,
                                        isDense: true,
                                        fillColor: lightWhite,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 10,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: fontColor,
                                          ),
                                        ),
                                      ),
                                      value: widget.model!.activeStatus,
                                      onChanged: (dynamic newValue) {
                                        setState(
                                          () {
                                            curStatus = newValue;
                                          },
                                        );
                                      },
                                      items: statusList.map(
                                        (String st) {
                                          return DropdownMenuItem<String>(
                                            value: st,
                                            child: Text(
                                              () {
                                                // print("status****$st");
                                                if (capitalize(st) ==
                                                    "Received") {
                                                  return getTranslated(
                                                      context, RECEIVED_LBL)!;
                                                } else if (capitalize(st) ==
                                                    "Processed") {
                                                  return getTranslated(
                                                      context, PROCESSED_LBL)!;
                                                } else if (capitalize(st) ==
                                                    "Shipped") {
                                                  return getTranslated(
                                                      context, SHIPED_LBL)!;
                                                } else if (capitalize(st) ==
                                                    "Delivered") {
                                                  return getTranslated(
                                                      context, DELIVERED_LBL)!;
                                                } else if (capitalize(st) ==
                                                    "Awaiting") {
                                                  return getTranslated(
                                                      context, AWAITING_LBL)!;
                                                } else if (capitalize(st) ==
                                                    "Returned") {
                                                  return getTranslated(
                                                      context, RETURNED_LBL)!;
                                                } else if (capitalize(st) ==
                                                    "Cancelled") {
                                                  return getTranslated(
                                                      context, CANCELLED_LBL)!;
                                                } else if (capitalize(st) ==
                                                    "Ready_to_pickup") {
                                                  return getTranslated(context,
                                                      READY_TO_PICK_UP_LBL)!;
                                                }
                                                return capitalize(st);
                                              }(),
                                              // capitalize(st),
                                              style: Theme.of(this.context)
                                                  .textTheme
                                                  .titleSmall!
                                                  .copyWith(
                                                    color: fontColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ),
                                ),
                          if (widget.model!.itemList![0].productType !=
                              'digital_product')
                            Expanded(
                              child: InkWell(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: lightWhite,
                                    border: Border.all(
                                      color: fontColor,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedDelBoy != -1
                                              ? searchList[selectedDelBoy!]
                                                  .name!
                                              : getTranslated(
                                                  context, Del_LBL)!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(this.context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                                color: fontColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: fontColor,
                                      )
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  delboyDialog();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      width: double.maxFinite,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primary,
                          disabledForegroundColor:
                              Colors.grey.withOpacity(0.38),
                          disabledBackgroundColor:
                              Colors.grey.withOpacity(0.12),
                        ),
                        onPressed: () async {
                          _isNetworkAvail = await isNetworkAvailable();
                          if (_isNetworkAvail) {
                            if (widget.model!.itemList![0].productType ==
                                    'digital_product' &&
                                model.itemList![0].isSent == "0" &&
                                widget.model!.itemList![0].downloadAllow ==
                                    "0") {
                              updateOrder(
                                  '', updateOrderApi, model.id, true, 0, true);
                            } else {
                              if (model.otp != "" &&
                                  model.otp!.isNotEmpty &&
                                  model.otp != "0" &&
                                  curStatus == DELIVERD) {
                                otpDialog(
                                    curStatus, model.otp, model.id, false, 0);
                              } else {
                                updateOrder(curStatus, updateOrderApi, model.id,
                                    false, 0, false);
                              }
                            }
                          } else {
                            await buttonController!.reverse();
                            setState(
                              () {},
                            );
                          }
                        },
                        child: Text(
                          getTranslated(context, UPDATE_ORDER)!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                showCircularProgress(_isProgress, primary),
              ],
            )
          : noInternet(context),
    );
  }

  Future<void> searchOperation(String searchText) async {
    searchList.clear();
    for (int i = 0; i < delBoyList.length; i++) {
      PersonModel map = delBoyList[i];

      if (map.name!.toLowerCase().contains(searchText)) {
        searchList.add(map);
      }
    }

    if (mounted) delBoyState(() {});
  }

  delboyDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            delBoyState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                    child: Text(
                      getTranslated(context, selectDeliveryBoy)!,
                      style: Theme.of(this.context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: fontColor),
                    ),
                  ),
                  TextField(
                    controller: _controller,
                    autofocus: false,
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                      prefixIcon:
                          const Icon(Icons.search, color: primary, size: 17),
                      hintText: getTranslated(context, search)!,
                      hintStyle: TextStyle(
                        color: primary.withOpacity(0.5),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: white),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: white),
                      ),
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: getLngList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> getLngList() {
    return searchList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  setState(
                    () {
                      selectedDelBoy = index;
                      Navigator.of(context).pop();
                    },
                  );
                }
              },
              child: SizedBox(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    searchList[index].name!,
                  ),
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  otpDialog(
    String? curSelected,
    String? otp,
    String? id,
    bool item,
    int index,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                      child: Text(
                        getTranslated(context, OTP_LBL)!,
                        style: Theme.of(this.context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: fontColor),
                      ),
                    ),
                    const Divider(color: lightBlack),
                    Form(
                      key: _formkey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              validator: (String? value) {
                                if (value!.isEmpty) {
                                  return FIELD_REQUIRED;
                                } else if (value.trim() != otp) {
                                  return OTPERROR;
                                } else {
                                  return null;
                                }
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: OTP_ENTER,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: lightBlack,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: otpC,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    getTranslated(context, CANCEL)!,
                    style:
                        Theme.of(this.context).textTheme.titleSmall!.copyWith(
                              color: lightBlack,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(
                    getTranslated(context, SEND_LBL)!,
                    style:
                        Theme.of(this.context).textTheme.titleSmall!.copyWith(
                              color: fontColor,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  onPressed: () {
                    final form = _formkey.currentState!;
                    if (form.validate()) {
                      form.save();
                      setState(
                        () {
                          Navigator.pop(context);
                        },
                      );
                      updateOrder(
                          curSelected, updateOrderApi, id, item, index, false);
                    }
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  _launchMap(lat, lng) async {
    var url = '';

    if (Platform.isAndroid) {
      url =
          "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving&dir_action=navigate";
    } else {
      url =
          "http://maps.apple.com/?saddr=&daddr=$lat,$lng&directionsmode=driving&dir_action=navigate";
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  priceDetails() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: Text(PRICE_DETAIL,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: fontColor, fontWeight: FontWeight.bold))),
            const Divider(
              color: lightBlack,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${getTranslated(context, PRICE_LBL)!} :",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: lightBlack2),
                  ),
                  Text(
                    "${CUR_CURRENCY!} ${widget.model!.subTotal!}",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: lightBlack2),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${getTranslated(context, DELIVERY_CHARGE)!} :",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "+ ${CUR_CURRENCY!} ${widget.model!.delCharge!}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack2,
                        ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${getTranslated(context, TAXPER)!} (${widget.model!.taxPer!}) :",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "+ ${CUR_CURRENCY!} ${widget.model!.taxAmt!}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack2,
                        ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${getTranslated(context, PROMO_CODE_DIS_LBL)!} :",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "- ${CUR_CURRENCY!} ${widget.model!.promoDis!}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack2,
                        ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${getTranslated(context, WALLET_BAL)!} :",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "- ${CUR_CURRENCY!} ${widget.model!.walBal!}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack2,
                        ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${getTranslated(context, PAYABLE)!} :",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    "${CUR_CURRENCY!} ${widget.model!.payable!}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: lightBlack,
                          fontWeight: FontWeight.bold,
                        ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  shippingDetails() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                children: [
                  Text(
                    getTranslated(context, SHIPPING_DETAIL)!,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: fontColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 30,
                    child: IconButton(
                      icon: const Icon(
                        Icons.location_on,
                        color: fontColor,
                      ),
                      onPressed: () {
                        _launchMap(
                            widget.model!.latitude, widget.model!.longitude);
                      },
                    ),
                  )
                ],
              ),
            ),
            const Divider(
              color: lightBlack,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Text(
                widget.model!.name != "" && widget.model!.name!.isNotEmpty
                    ? " ${capitalize(widget.model!.name!)}"
                    : " ",
              ),
            ),
            if (widget.model!.address != "")
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 3),
                child: Text(
                  capitalize(widget.model!.address!),
                  style: const TextStyle(
                    color: lightBlack2,
                  ),
                ),
              ),
            if (widget.model!.mobile != "")
              InkWell(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.call,
                        size: 15,
                        color: fontColor,
                      ),
                      Text(
                        " ${widget.model!.mobile!}",
                        style: const TextStyle(
                          color: fontColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  _launchCaller("tel:${widget.model!.mobile}");
                },
              ),
          ],
        ),
      ),
    );
  }

  _filterRow(Order_Model model, OrderItem orderItem) {
    return orderItem.productType == 'digital_product'
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (model.itemList!.length > 1)
                orderItem.isSent != "1" && orderItem.downloadAllow == "0"
                    ? Card(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                        child: SizedBox(
                          //margin: EdgeInsets.all(10),
                          width: MediaQuery.of(context).size.width * .25,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: lightWhite,
                              backgroundColor: fontColor,
                              side: const BorderSide(color: fontColor),
                              disabledForegroundColor:
                                  fontColor.withOpacity(0.38),
                              disabledBackgroundColor:
                                  fontColor.withOpacity(0.12),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => SendMail(
                                    email: model.email ?? '',
                                    productName: orderItem.name ?? '',
                                    orderId: model.id ?? '',
                                    orderIteamId: orderItem.id ?? '',
                                    userName: model.userName ?? '',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              getTranslated(context, SendMailText)!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              Row(
                children: [
                  if (model.itemList!.length > 1)
                    orderItem.isSent != "1" && orderItem.downloadAllow == "0"
                        ? InkWell(
                            onTap: () {
                              _launchCaller("mailto:${model.email}");
                            },
                            child: Container(
                                alignment: Alignment.center,
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(7),
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4.0),
                                  color: fontColor,
                                ),
                                width: MediaQuery.of(context).size.width * .1,
                                child: const Icon(
                                  Icons.mail,
                                  size: 25,
                                ) /*Image.asset(
                                  "assets/images/google.png",
                                  color: Colors.white,
                                )*/
                                ),
                          )
                        : const SizedBox.shrink(),
                  orderItem.isSent == "1"
                      ? Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.all(5),
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: fontColor,
                          ),
                          width: MediaQuery.of(context).size.width * .1,
                          child: IconButton(
                            alignment: Alignment.center,
                            icon: const Icon(
                              Icons.mark_email_read,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              getDigitalOrderMailData(model.id!, orderItem.id!);
                            },
                          ))
                      : Container(),
                ],
              )
            ],
          )
        : const SizedBox.shrink();
  }

  Future<void> getDigitalOrderMailData(
      String orderId, String orderItemId) async {
    var param = {ORDER_ID: orderId, ORDER_ITEM_ID: orderItemId};
    apiBaseHelper.postAPICall(getDigitalOrderMailApi, param).then(
      (getdata) async {
        print("getdata***$getdata");
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          digitalMailList.clear();
          var data = getdata["data"]["rows"];
          print("data***$data");
          digitalMailList = (data as List)
              .map((data) => OrderMailModel.fromJson(data))
              .toList();
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => OrderMailDetails(
                model: digitalMailList[0],
              ),
            ),
          );
        } else {
          setsnackbar(
            msg!,
            context,
          );
        }
      },
      onError: (error) {
        setsnackbar(
          error.toString(),
          context,
        );
      },
    );
  }

  productItem(OrderItem orderItem, Order_Model model, int i) {
    List att = [], val = [];
    if (orderItem.attr_name!.isNotEmpty) {
      att = orderItem.attr_name!.split(',');
      val = orderItem.varient_values!.split(',');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                    fadeInDuration: const Duration(milliseconds: 150),
                    image: NetworkImage(orderItem.image!),
                    height: 90.0,
                    width: 90.0,
                    imageErrorBuilder: ((context, error, stackTrace) {
                      return erroWidget(90);
                    }),
                    placeholder: placeHolder(90),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderItem.name ?? '',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: lightBlack,
                                    fontWeight: FontWeight.normal,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        orderItem.attr_name!.isNotEmpty
                            ? ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: att.length,
                                itemBuilder: (context, index) {
                                  return Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          att[index].trim() + ":",
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                                color: lightBlack2,
                                              ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 5.0),
                                        child: Text(
                                          val[index],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                                color: lightBlack,
                                              ),
                                        ),
                                      )
                                    ],
                                  );
                                },
                              )
                            : Container(),
                        Row(
                          children: [
                            Text(
                              "${getTranslated(context, QUANTITY_LBL)!}:",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    color: lightBlack2,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                orderItem.qty!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(color: lightBlack),
                              ),
                            )
                          ],
                        ),
                        Text(
                          "${CUR_CURRENCY!} ${orderItem.price!}",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                        if (model.itemList!.length > 1)
                          _filterRow(model, orderItem),
                        /* if (model.itemList!.length > 1)
                          orderItem.productType == 'digital_product'
                              ? orderItem.downloadAllow == "0"
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: 15.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                              builder: (context) => SendMail(
                                                email: model.email ?? '',
                                                productName:
                                                    orderItem.name ?? '',
                                                orderId: model.id ?? '',
                                                orderIteamId:
                                                    orderItem.id ?? '',
                                                userName: model.userName ?? '',
                                              ),
                                            ),
                                          );
                                          // emailSendButtomSheet(context,
                                          //     setState, orderItem.name);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: primary,
                                            ),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(5),
                                            ),
                                          ),
                                          height: 40,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Center(
                                            child: Text(
                                              getTranslated(
                                                  context, SendMailText)!,
                                              style: TextStyle(
                                                color: primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container()
                              : Container(),*/
                        widget.model!.itemList!.length > 1
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  children: [
//==============================================================================
//============================ Status of Order =================================

                                    orderItem.productType == 'digital_product'
                                        ? Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: orderItem.isSent == "0" &&
                                                      orderItem.downloadAllow ==
                                                          "0"
                                                  ? DropdownButtonFormField(
                                                      isExpanded: true,
                                                      dropdownColor: lightWhite,
                                                      isDense: true,
                                                      iconEnabledColor:
                                                          fontColor,
                                                      hint: Text(
                                                        getTranslated(context,
                                                            updateStatus)!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleSmall!
                                                            .copyWith(
                                                              color: fontColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      decoration:
                                                          const InputDecoration(
                                                        filled: true,
                                                        isDense: true,
                                                        fillColor: lightWhite,
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 10,
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: fontColor,
                                                          ),
                                                        ),
                                                      ),
                                                      value: MAIL_SENT,
                                                      onChanged:
                                                          (dynamic newValue) {
                                                        setState(
                                                          () {
                                                            curStatus =
                                                                newValue;
                                                          },
                                                        );
                                                      },
                                                      items: digitalMailSendList
                                                          .map(
                                                        (String st) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: st,
                                                            child: Text(
                                                              () {
                                                                return capitalize(
                                                                    st);
                                                              }(),
                                                              // capitalize(st),
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .titleSmall!
                                                                  .copyWith(
                                                                    color:
                                                                        fontColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ).toList(),
                                                    )
                                                  : DropdownButtonFormField(
                                                      dropdownColor: lightWhite,
                                                      isDense: true,
                                                      iconEnabledColor:
                                                          fontColor,
                                                      hint: Text(
                                                        getTranslated(context,
                                                            updateStatus)!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleSmall!
                                                            .copyWith(
                                                              color: fontColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      decoration:
                                                          const InputDecoration(
                                                        filled: true,
                                                        isDense: true,
                                                        fillColor: lightWhite,
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 10,
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: fontColor),
                                                        ),
                                                      ),
                                                      value: orderItem.status,
                                                      onChanged:
                                                          (dynamic newValue) {
                                                        setState(
                                                          () {
                                                            orderItem
                                                                    .curSelected =
                                                                newValue;
                                                          },
                                                        );
                                                      },
                                                      items: digitalList.map(
                                                        (String st) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: st,
                                                            child: Text(
                                                              capitalize(st),
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .titleSmall!
                                                                  .copyWith(
                                                                    color:
                                                                        fontColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ).toList(),
                                                    ),
                                            ),
                                          )
                                        : Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              child: DropdownButtonFormField(
                                                dropdownColor: lightWhite,
                                                isDense: true,
                                                iconEnabledColor: fontColor,
                                                hint: Text(
                                                  getTranslated(
                                                      context, updateStatus)!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall!
                                                      .copyWith(
                                                        color: fontColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  filled: true,
                                                  isDense: true,
                                                  fillColor: lightWhite,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 10,
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: fontColor),
                                                  ),
                                                ),
                                                value: orderItem.status,
                                                onChanged: (dynamic newValue) {
                                                  setState(
                                                    () {
                                                      orderItem.curSelected =
                                                          newValue;
                                                    },
                                                  );
                                                },
                                                items: statusList.map(
                                                  (String st) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: st,
                                                      child: Text(
                                                        capitalize(st),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleSmall!
                                                            .copyWith(
                                                              color: fontColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ).toList(),
                                              ),
                                            ),
                                          ),
                                    RawMaterialButton(
                                      constraints: const BoxConstraints.expand(
                                          width: 42, height: 42),
                                      onPressed: () {
                                        if (orderItem.productType ==
                                                'digital_product' &&
                                            orderItem.isSent == "0" &&
                                            orderItem.downloadAllow == "0") {
                                          updateOrder('', updateOrderApi,
                                              model.id, true, i, true);
                                        } else {
                                          if (model.otp != "" &&
                                              model.otp!.isNotEmpty &&
                                              model.otp != "0" &&
                                              orderItem.curSelected ==
                                                  DELIVERD) {
                                            otpDialog(orderItem.curSelected,
                                                model.otp, model.id, true, i);
                                          } else {
                                            updateOrder(
                                                orderItem.curSelected,
                                                updateOrderApi,
                                                model.id,
                                                true,
                                                i,
                                                false);
                                          }
                                        }
                                      },
                                      elevation: 2.0,
                                      fillColor: fontColor,
                                      padding: const EdgeInsets.only(left: 5),
                                      shape: const CircleBorder(),
                                      child: const Align(
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.send,
                                          size: 20,
                                          color: white,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : Container()
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateOrder(String? status, Uri api, String? id, bool item,
      int index, bool isSent) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (editOrder) {
      if (_isNetworkAvail) {
        try {
          setState(
            () {
              _isProgress = true;
            },
          );
          var parameter = {
            ORDERID: id,
          };

          if (status != '') {
            parameter[STATUS] = status;
          }

          if (isSent) {
            parameter[IS_SENT] = "1";
          }
          if (item) parameter[ORDERITEMID] = widget.model!.itemList![index].id;
          print("selectedDElBoy****$selectedDelBoy");
          if (selectedDelBoy != -1) {
            parameter[DEL_BOY_ID] = searchList[selectedDelBoy!].id;
          }
          print("paramter update status***$parameter");
          Response response = await post(
                  item ? updateOrderItemApi : updateOrderApi,
                  body: parameter,
                  headers: headers)
              .timeout(
            const Duration(seconds: timeOut),
          );
          var getdata = json.decode(response.body);

          print("order status getdata***$getdata");
          bool error = getdata["error"];
          String msg = getdata["message"];
          setsnackbar(msg, context);
          if (!error) {
            if (item) {
              widget.model!.itemList![index].status = status;
            } else {
              widget.model!.activeStatus = status;
            }
            if (selectedDelBoy != -1) {
              widget.model!.deliveryBoyId = searchList[selectedDelBoy!].id;
            }
          }

          setState(
            () {
              _isProgress = false;
            },
          );
        } on TimeoutException catch (_) {
          setsnackbar(somethingMSg, context);
        }
      } else {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    } else {
      setsnackbar(getTranslated(context, authoritypermissionText)!, context);
    }
  }

  _launchCaller(String URL) async {
    var url = URL.trim();

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      setsnackbar(getTranslated(context, couldnotlaunch)! + url, context);
    }
  }

  bankProof(Order_Model model) {
    int currentStatus = 0;
    if (model.attachList!.isNotEmpty) {
      currentStatus = int.parse(model.attachList![0].bankTransferStatus!);
    }
    return Card(
      elevation: 0,
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: model.attachList!.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      child: Text(
                        "${getTranslated(context, attachmentText)!} ${i + 1}",
                        style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: fontColor),
                      ),
                      onTap: () {
                        _launchURL(model.attachList![i].attachment!);
                      },
                    ),
                    InkWell(
                      child: const Icon(
                        Icons.delete,
                        color: fontColor,
                      ),
                      onTap: () {
                        deleteBankProof(i, model);
                      },
                    )
                  ],
                ),
              );
            },
          ),
          model.attachList!.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 5.0),
                  child: DropdownButtonFormField(
                    isExpanded: true,
                    dropdownColor: lightWhite,
                    isDense: true,
                    iconEnabledColor: fontColor,
                    //iconSize: 40,
                    hint: Text(
                      getTranslated(context, PENDING)!,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: fontColor, fontWeight: FontWeight.bold),
                    ),
                    decoration: const InputDecoration(
                      filled: true,
                      isDense: true,
                      fillColor: lightWhite,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: fontColor),
                      ),
                    ),

                    value: statusListOfBankTransfer[currentStatus],
                    onChanged: (dynamic newValue) {
                      setState(
                        () {
                          curStatus = newValue;
                        },
                      );
                      if (curStatus == "Accepted") {
                        changeBankTransferStatus("2", model);
                      } else if (curStatus == "Rejected") {
                        changeBankTransferStatus("1", model);
                      }
                    },
                    items: statusListOfBankTransfer.map((String st) {
                      return DropdownMenuItem<String>(
                        value: st,
                        child: Text(
                          capitalize(st),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color: fontColor,
                                  fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  void _launchURL(String url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  Future<void> deleteBankProof(int i, Order_Model model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (editOrder) {
      if (_isNetworkAvail) {
        try {
          setState(() {
            _isProgress = true;
          });

          var parameter = {
            ID: model.attachList![i].id,
          };

          Response response =
              await post(deleteBankProofApi, body: parameter, headers: headers)
                  .timeout(const Duration(seconds: timeOut));

          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String msg = getdata["message"];
          setsnackbar(msg, context);
          if (!error) {
            model.attachList!
                .removeWhere((item) => item.id == model.attachList![i].id);
          }

          setState(() {
            _isProgress = false;
          });
        } on TimeoutException catch (_) {
          setsnackbar(getTranslated(context, somethingMSg)!, context);
        }
      } else {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    } else {
      setsnackbar(getTranslated(context, authoritypermissionText)!, context);
    }
  }

  Future<void> changeBankTransferStatus(
      String status, Order_Model model) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        setState(() {
          _isProgress = true;
        });

        var parameter = {
          ORDER_ID: model.id,
          USER_ID: model.user_id,
          STATUS: status.toString(),
        };

        Response response = await post(changeBankTransferStatusApi,
                body: parameter, headers: headers)
            .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        String msg = getdata["message"];
        setsnackbar(msg, context);

        setState(() {
          _isProgress = false;
        });
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, somethingMSg)!, context);
      }
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }
  }

  trackingDetails(Order_Model model) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                children: [
                  Text(
                    getTranslated(context, TRACKING_DETAIL)!,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: fontColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(
              color: lightBlack,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
              child: Row(
                children: [
                  Text("${getTranslated(context, courierAgencyText)!}: "),
                  Text(
                    "${widget.model!.courier_agency}",
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
              child: Row(
                children: [
                  Text("${getTranslated(context, trackingIDText)!}: "),
                  Text(
                    "${widget.model!.tracking_id}",
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            InkWell(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
                child: Row(
                  children: [
                    const Text("$URL: "),
                    Text(
                      "${widget.model!.url}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: fontColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                _launchCaller("${widget.model!.url}");
              },
            ),
          ],
        ),
      ),
    );
  }

  void getTrackingDetails() {
    if (widget.model!.courier_agency != "" &&
        widget.model!.tracking_id != "" &&
        widget.model!.url != "") {
      if (mounted) {
        setState(
          () {
            trackingId = widget.model!.tracking_id;
            url = widget.model!.url;
            courierAgency = widget.model!.courier_agency;
          },
        );
      }
    }
  }

  dwnInvoice() {
    return widget.model!.invoice != ""
        ? Card(
            elevation: 0,
            child: InkWell(
              child: ListTile(
                dense: true,
                trailing: const Icon(
                  Icons.keyboard_arrow_right,
                  color: fontColor,
                ),
                leading: const Icon(
                  Icons.receipt,
                  color: fontColor,
                ),
                title: Text(
                  getTranslated(context, DWNLD_INVOICE)!,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: fontColor),
                ),
              ),
              onTap: () async {
                final status = await Permission.storage.request();

                if (status == PermissionStatus.granted) {
                  if (mounted) {
                    setState(
                      () {
                        _isProgress = true;
                      },
                    );
                  }
                  var targetPath;

                  if (Platform.isIOS) {
                    var target = await getApplicationDocumentsDirectory();
                    targetPath = target.path.toString();
                  } else {
                    targetPath = '/storage/emulated/0/Download';
                    if (!await Directory(targetPath).exists()) {
                      targetPath = await getExternalStorageDirectory();
                    }
                  }

                  var targetFileName = "Invoice_${widget.model!.id}";
                  var generatedPdfFile, filePath;
                  try {
                    generatedPdfFile =
                        await FlutterHtmlToPdf.convertFromHtmlContent(
                            widget.model!.invoice!, targetPath, targetFileName);
                    filePath = generatedPdfFile.path;

                    File fileDef = File(filePath);
                    await fileDef.create(recursive: true);
                    Uint8List bytes = await generatedPdfFile.readAsBytes();
                    await fileDef.writeAsBytes(bytes);
                  } catch (e) {
                    if (mounted) {
                      setState(
                        () {
                          _isProgress = false;
                        },
                      );
                      setsnackbar(
                          getTranslated(context, somethingMSg)!, context);
                    }
                    return;
                  }

                  if (mounted) {
                    setState(
                      () {
                        _isProgress = false;
                      },
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${getTranslated(context, checkFolderText)!} - $targetFileName",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: fontColor),
                      ),
                      action: SnackBarAction(
                        label: getTranslated(context, ViewLbl)!,
                        onPressed: () async {
                          await OpenFilex.open(filePath);
                        },
                      ),
                      backgroundColor: Colors.white,
                      elevation: 1.0,
                    ),
                  );
                }
              },
            ),
          )
        : Container();
  }
}

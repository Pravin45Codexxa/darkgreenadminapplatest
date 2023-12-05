import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Order_Model.dart';
import 'OrderDetail.dart';

class OrderList extends StatefulWidget {
  const OrderList({Key? key}) : super(key: key);

  @override
  _OrderListState createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  String _searchText = "", _lastsearch = "", whichAPICalledRecently = "";
  bool? isSearching;
  int scrollOffset = 0;
  ScrollController? scrollController;
  bool scrollLoadmore = true,
      scrollGettingData = false,
      scrollNodata = false,
      isLoading = false;
  final TextEditingController _controller = TextEditingController();
  List<Order_Model> orderList = [];
  Icon iconSearch = const Icon(
    Icons.search,
    color: primary,
  );
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  Widget? appBarTitle;
  List<Order_Model> tempList = [];
  String? activeStatus;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String? start, end;
  String? all,
      received,
      orderTrackingTotal,
      processed,
      shipped,
      delivered,
      cancelled,
      returned,
      awaiting;
  String? courierAgency, trackingId, url;
  TextEditingController? courierAgencyController,
      trackingIdController,
      urlController;
  List<String> statusList = [
    ALL,
    PLACED,
    PROCESSED,
    SHIPED,
    DELIVERD,
    CANCLED,
    RETURNED,
    awaitingPayment
  ];
  Timer? _debounce;
  String? productType;

  @override
  void initState() {
    appBarTitle = const Text(
      ORDER,
      style: TextStyle(color: primary),
    );
    scrollOffset = 0;
    getTotalOrderTrackingNumber();
    Future.delayed(Duration.zero, getOrder);
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    scrollController = ScrollController();
    scrollController!.addListener(_transactionscrollListener);

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

    _controller.addListener(
      () {
        if (_controller.text.isEmpty) {
          if (mounted) {
            setState(
              () {
                _searchText = "";
              },
            );
          }
        } else {
          if (mounted) {
            setState(
              () {
                _searchText = _controller.text;
              },
            );
          }
        }

        if (_lastsearch != _searchText &&
            (_searchText == '' || (_searchText.length > 2))) {
          _lastsearch = _searchText;
          scrollLoadmore = true;
          scrollOffset = 0;

          getOrder();
        }
      },
    );

    super.initState();
  }

  Future<void> editTrackingDetails(Order_Model model, String? courierAgency,
      String? trackingId, String? url) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        var parameter = {
          ORDER_ID: model.id,
          COURIER_AGENCY: courierAgency,
          TRACKING_ID: trackingId,
          URL: url,
        };

        Response response =
            await post(editOrderTrackingApi, body: parameter, headers: headers)
                .timeout(
          const Duration(
            seconds: timeOut,
          ),
        );

        var getdata = json.decode(response.body);
        String msg = getdata["message"];
        setsnackbar(msg, context);
      } on TimeoutException catch (_) {
        setsnackbar(
            getTranslated(
              context,
              somethingMSg,
            )!,
            context);
      }
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }
  }

  _transactionscrollListener() {
    if (scrollController!.offset >=
            scrollController!.position.maxScrollExtent &&
        !scrollController!.position.outOfRange) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 500),
        () {
          if (scrollLoadmore) {
            setState(
              () {
                scrollLoadmore = true;
                if (whichAPICalledRecently == "OrderTracking") {
                  getOrderTracking();
                } else {
                  getOrder();
                }
              },
            );
          }
        },
      );
    }
  }

  commanDesing(
    String title,
    IconData icon,
    int index,
    String? onTapAction,
  ) {
    return Expanded(
      flex: 1,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Card(
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
            child: SizedBox(
              height: 100,
              width: deviceWidth * 0.4,
              child: InkWell(
                onTap: () {
                  if (!scrollGettingData) {
                    setState(
                      () {
                        activeStatus = onTapAction;
                        scrollLoadmore = true;
                        scrollOffset = 0;
                      },
                    );
                    if (index == 0) {
                      getOrderTracking();
                    } else {
                      getOrder();
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    bottom: 20.0,
                    left: 10.0,
                    right: 10.0,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        color: fontColor,
                        size: 30,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: fontColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 90.0),
            child: Container(
              height: 36,
              width: 56,
              decoration: const BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    10.0,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  () {
                    if (index == 0) {
                      return orderTrackingTotal ?? "";
                    } else if (index == 1) {
                      return received ?? '';
                    } else if (index == 2) {
                      return processed ?? "";
                    } else if (index == 3) {
                      return shipped ?? "";
                    } else if (index == 4) {
                      return delivered ?? "";
                    } else if (index == 5) {
                      return awaiting ?? '';
                    } else if (index == 6) {
                      return cancelled ?? "";
                    } else if (index == 7) {
                      return returned ?? "";
                    } else {
                      return "";
                    }
                  }(),
                  // orderTrackingTotal ?? "",
                  style: const TextStyle(
                    color: white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightWhite,
      appBar: getAppbar(),
      body: _isNetworkAvail ? _showContent() : noInternet(context),
    );
  }

  void _handleSearchStart() {
    if (!mounted) return;
    setState(
      () {
        isSearching = true;
      },
    );
  }

  Future<void> _startDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
        () {
          startDate = picked;
          start = DateFormat('dd-MM-yyyy').format(startDate);

          if (start != "" && end != "") {
            scrollLoadmore = true;
            scrollOffset = 0;
            getOrder();
          }
        },
      );
    }
  }

  Future<void> _endDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
        () {
          endDate = picked;
          end = DateFormat('dd-MM-yyyy').format(endDate);
          if (start != "" && end != "") {
            scrollLoadmore = true;
            scrollOffset = 0;
            getOrder();
          }
        },
      );
    }
  }

  void _handleSearchEnd() {
    if (!mounted) return;
    setState(
      () {
        iconSearch = const Icon(
          Icons.search,
          color: primary,
        );
        appBarTitle = Text(
          getTranslated(context, ORDER)!,
          style: const TextStyle(color: primary),
        );
        isSearching = false;
        _controller.clear();
      },
    );
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
              title: getTranslated(context, NO_INTERNET)!,
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
                            builder: (BuildContext context) => super.widget),
                      );
                    } else {
                      await buttonController!.reverse();
                      if (mounted) {
                        setState(
                          () {},
                        );
                      }
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

  AppBar getAppbar() {
    return AppBar(
      title: appBarTitle,
      backgroundColor: white,
      leading: Builder(
        builder: (BuildContext context) {
          return Container(
            margin: const EdgeInsets.all(10),
            decoration: shadow(),
            child: Card(
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => Navigator.of(context).pop(),
                child: const Center(
                  child: Icon(
                    Icons.keyboard_arrow_left,
                    color: primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: <Widget>[
        InkWell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: iconSearch,
          ),
          onTap: () {
            if (!mounted) return;
            setState(
              () {
                if (iconSearch.icon == Icons.search) {
                  iconSearch = const Icon(
                    Icons.close,
                    color: primary,
                  );
                  appBarTitle = TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(
                      color: primary,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: primary),
                      hintText: '${getTranslated(context, search)!}...',
                      hintStyle: const TextStyle(color: primary),
                    ),
                  );
                  _handleSearchStart();
                } else {
                  _handleSearchEnd();
                }
              },
            );
          },
        ),
        InkWell(
          onTap: filterDialog,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.filter_alt_outlined,
              color: primary,
            ),
          ),
        )
      ],
    );
  }

  _showContent() {
    return scrollNodata
        ? getNoItem()
        : Stack(
            children: [
              Stack(
                children: [
                  SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: <Widget>[
                        _detailHeader(),
                        detailHeader2(),
                        detailHeader3(),
                        _detailHeader2(),
                        _filterRow(),
                        ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsetsDirectional.only(
                              bottom: 5, start: 10, end: 10),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orderList.length,
                          itemBuilder: (context, index) {
                            Order_Model? item;
                            try {
                              item =
                                  orderList.isEmpty ? null : orderList[index];
                            } on Exception catch (_) {}

                            return item == null
                                ? Container()
                                : orderItem(index);
                          },
                        ),
                      ],
                    ),
                  ),
                  scrollGettingData
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Container(),
                ],
              ),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container(),
            ],
          );
  }

  _detailHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          // commanDesing(
          //   getTranslated(context, ORDER_TRACKING)!,
          //   Icons.share_location,
          //   0,
          //   "",
          // ),
          commanDesing(
            getTranslated(context, RECEIVED_LBL)!,
            Icons.archive_outlined,
            1,
            statusList[1],
          ),
          // commanDesing(
          //   getTranslated(context, PROCESSED_LBL)!,
          //   Icons.work_outline,
          //   2,
          //   statusList[2],
          // ),
          // commanDesing(
          //   getTranslated(context, SHIPED_LBL)!,
          //   Icons.airport_shuttle_outlined,
          //   3,
          //   statusList[3],
          // ),
        ],
      ),
    );
  }

  detailHeader2() {
    return Row(
      children: [
        // commanDesing(
        //   getTranslated(context, ORDER_TRACKING)!,
        //   Icons.share_location,
        //   0,
        //   "",
        // ),
        // commanDesing(
        //   getTranslated(context, RECEIVED_LBL)!,
        //   Icons.archive_outlined,
        //   1,
        //   statusList[1],
        // ),
        commanDesing(
          getTranslated(context, PROCESSED_LBL)!,
          Icons.work_outline,
          2,
          statusList[2],
        ),
        commanDesing(
          getTranslated(context, SHIPED_LBL)!,
          Icons.airport_shuttle_outlined,
          3,
          statusList[3],
        ),
      ],
    );
  }

  detailHeader3() {
    return Row(
      children: [
        commanDesing(
          getTranslated(context, DELIVERED_LBL)!,
          Icons.assignment_turned_in_outlined,
          4,
          statusList[4],
        ),
        commanDesing(
          getTranslated(context, AWAITING_LBL)!,
          Icons.history,
          5,
          statusList[7],
        ),
        // commanDesing(
        //   getTranslated(context, CANCELLED_LBL)!,
        //   Icons.cancel_outlined,
        //   6,
        //   statusList[5],
        // ),
        // commanDesing(
        //   getTranslated(context, RETURNED_LBL)!,
        //   Icons.upload_outlined,
        //   7,
        //   statusList[6],
        // ),
      ],
    );
  }

  _detailHeader2() {
    return Row(
      children: [
        // commanDesing(
        //   getTranslated(context, DELIVERED_LBL)!,
        //   Icons.assignment_turned_in_outlined,
        //   4,
        //   statusList[4],
        // ),
        // commanDesing(
        //   getTranslated(context, AWAITING_LBL)!,
        //   Icons.history,
        //   5,
        //   statusList[7],
        // ),
        commanDesing(
          getTranslated(context, CANCELLED_LBL)!,
          Icons.cancel_outlined,
          6,
          statusList[5],
        ),
        commanDesing(
          getTranslated(context, RETURNED_LBL)!,
          Icons.upload_outlined,
          7,
          statusList[6],
        ),
      ],
    );
  }

  orderItem(int index) {
    Order_Model model = orderList[index];
    Color back;

    if ((model.activeStatus) == DELIVERD) {
      back = Colors.green;
    } else if ((model.activeStatus) == SHIPED) {
      back = Colors.orange;
    } else if ((model.activeStatus) == CANCLED ||
        model.activeStatus == RETURNED) {
      back = Colors.red;
    } else if ((model.activeStatus) == PROCESSED) {
      back = Colors.indigo;
    } else if ((model.activeStatus) == PROCESSED) {
      back = Colors.indigo;
    } else if (model.activeStatus == "awaiting") {
      back = Colors.pinkAccent;
    } else {
      back = Colors.cyan;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(5.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      getTranslated(context, OrderNo)! + model.id!,
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: back,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(
                            4.0,
                          ),
                        ),
                      ),
                      child: Text(
                        capitalize(model.activeStatus!),
                        style: const TextStyle(color: white),
                      ),
                    )
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 14),
                          Expanded(
                            child: Text(
                              model.name != null && model.name!.isNotEmpty
                                  ? " ${capitalize(model.name!)}"
                                  : " ",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.call,
                            size: 14,
                            color: fontColor,
                          ),
                          Text(
                            " ${model.mobile!}",
                            style: const TextStyle(
                                color: fontColor,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                      onTap: () {
                        _launchCaller(model);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.money, size: 14),
                        Text(
                          " ${getTranslated(context, payableText)!}: ${CUR_CURRENCY!} ${model.payable!}",
                        ),
                      ],
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        _showTrackingDialog(model, index);
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.add_location_alt_sharp, size: 14),
                          Text(
                            getTranslated(context, addTracking)!,
                            style: const TextStyle(
                              color: fontColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.date_range, size: 14),
                        Text(
                          " ${getTranslated(context, orderonText)!}: ${model.orderDate!}",
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.payment, size: 14),
                        Text(" ${model.payMethod!}"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => OrderDetail(
                model: orderList[index],
              ),
            ),
          );
          setState(
            () {},
          );
        },
      ),
    );
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> getTotalOrderTrackingNumber() async {
    var parameter = [];
    Response response =
        await post(updateOrderTrackingmApi, body: parameter, headers: headers)
            .timeout(const Duration(seconds: timeOut));

    var getdata = json.decode(response.body);
    bool error = getdata["error"];
    if (!error) {
      if (mounted) {
        orderTrackingTotal = getdata["total"].toString();
      }
    }
  }

  Future<void> getOrderTracking() async {
    if (readOrder) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (scrollLoadmore) {
          if (mounted) {
            setState(
              () {
                scrollLoadmore = false;
                scrollGettingData = true;
                if (scrollOffset == 0) {
                  orderList = [];
                }
              },
            );
          }
          try {
            CUR_USERID = await getPrefrence(ID);
            CUR_USERNAME = await getPrefrence(USERNAME);

            var parameter = {
              LIMIT: perPage.toString(),
              OFFSET: orderList.length.toString(),
              SEARCH: _searchText.trim(),
            };

            Response response = await post(updateOrderTrackingmApi,
                    body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

            var getdata = json.decode(response.body);
            bool error = getdata["error"];
            scrollGettingData = false;
            List<Order>? tempListOfOrder = [];
            if (scrollOffset == 0) scrollNodata = error;

            if (!error) {
              whichAPICalledRecently = "OrderTracking";
              tempList.clear();
              var data = getdata["data"];
              if (data.length != 0) {
                tempListOfOrder =
                    (data as List).map((data) => Order.fromJson(data)).toList();

                for (var i = 0; i < tempListOfOrder.length; i++) {
                  tempList.add(tempListOfOrder[i].orderDetails!);
                }

                orderList.addAll(tempList);
                scrollLoadmore = true;
                scrollOffset = scrollOffset + perPage;
              } else {
                scrollLoadmore = false;
              }
            } else {
              scrollLoadmore = false;
            }
            if (mounted) {
              setState(
                () {},
              );
            }
          } on TimeoutException catch (_) {
            setsnackbar(getTranslated(context, somethingMSg)!, context);
            setState(
              () {
                scrollLoadmore = false;
              },
            );
          }
        }
      } else {
        if (mounted) {
          setState(
            () {
              _isNetworkAvail = false;
              scrollLoadmore = false;
            },
          );
        }
      }

      return;
    } else {
      setsnackbar(getTranslated(context, readProductText)!, context);
    }
  }

  Future<void> getOrder() async {
    if (readOrder) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        if (scrollLoadmore) {
          if (mounted) {
            setState(
              () {
                scrollLoadmore = false;
                scrollGettingData = true;
                if (scrollOffset == 0) {
                  orderList = [];
                }
              },
            );
          }
          try {
            CUR_USERID = await getPrefrence(ID);
            CUR_USERNAME = await getPrefrence(USERNAME);
            var parameter = {
              LIMIT: perPage.toString(),
              OFFSET: orderList.length.toString(),
              SEARCH: _searchText.trim(),
            };

            if (start != null) {
              parameter[START_DATE] = "${startDate.toLocal()}".split(' ')[0];
            }
            if (end != null) {
              parameter[END_DATE] = "${endDate.toLocal()}".split(' ')[0];
            }
            if (activeStatus != null) {
              if (activeStatus == awaitingPayment) activeStatus = "awaiting";
              parameter[ACTIVE_STATUS] = activeStatus!;
            }
            if (productType != null) {
              parameter[ORDER_TYPE] = productType!;
            }
            print("param order****$parameter}");
            Response response =
                await post(getOrdersApi, body: parameter, headers: headers)
                    .timeout(const Duration(seconds: timeOut));

            var getdata = json.decode(response.body);
            bool error = getdata["error"];
            scrollGettingData = false;
            if (scrollOffset == 0) scrollNodata = error;

            if (!error) {
              all = getdata["total"];
              received = getdata["received"];
              processed = getdata["processed"];
              shipped = getdata["shipped"];
              delivered = getdata["delivered"];
              cancelled = getdata["cancelled"];
              returned = getdata["returned"];
              awaiting = getdata["awaiting"];
              await getTotalOrderTrackingNumber();
              tempList.clear();
              var data = getdata["data"];
              if (data.length != 0) {
                tempList = (data as List)
                    .map((data) => Order_Model.fromJson(data))
                    .toList();

                orderList.addAll(tempList);
                scrollLoadmore = true;
                scrollOffset = scrollOffset + perPage;
              } else {
                scrollLoadmore = false;
              }
            } else {
              scrollLoadmore = false;
            }
            if (mounted) {
              setState(
                () {
                  whichAPICalledRecently = "getOrder";
                },
              );
            }
          } on TimeoutException catch (_) {
            setsnackbar(somethingMSg, context);
            setState(
              () {
                scrollLoadmore = false;
              },
            );
          }
        }
      } else {
        if (mounted) {
          setState(
            () {
              _isNetworkAvail = false;
              scrollLoadmore = false;
            },
          );
        }
      }

      return;
    } else {
      setsnackbar(getTranslated(context, authorizePermission)!, context);
    }
  }

  void filterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ButtonBarTheme(
          data: const ButtonBarThemeData(
            alignment: MainAxisAlignment.center,
          ),
          child: AlertDialog(
            elevation: 2.0,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5.0))),
            contentPadding: const EdgeInsets.all(0.0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        top: 19.0, bottom: 16.0),
                    child: Text(
                      getTranslated(context, FILTER_BY)!,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: fontColor),
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: getStatusList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> getStatusList() {
    return statusList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            Column(
              children: [
                SizedBox(
                  width: double.maxFinite,
                  child: TextButton(
                      child: Text(
                        capitalize(
                          statusList[index],
                        ),
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: lightBlack,
                                ),
                      ),
                      onPressed: () {
                        setState(
                          () {
                            activeStatus =
                                index == 0 ? null : statusList[index];
                            scrollLoadmore = true;
                            scrollOffset = 0;
                          },
                        );

                        getOrder();

                        Navigator.pop(context, 'option $index');
                      }),
                ),
                const Divider(
                  color: lightBlack,
                  height: 1,
                ),
              ],
            ),
          ),
        )
        .values
        .toList();
  }

  _filterRow() {
    return Padding(
      padding: const EdgeInsets.all(13.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Card(
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    width: MediaQuery.of(context).size.width * .25,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _startDate(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: primary,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: white),
                        disabledForegroundColor: fontColor.withOpacity(0.38),
                        disabledBackgroundColor: fontColor.withOpacity(0.12),
                      ),
                      child: Text(
                        start == null
                            ? getTranslated(context, startDateText)!
                            : start!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: MediaQuery.of(context).size.width * .28,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _endDate(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: primary,
                        backgroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey.withOpacity(0.38),
                        disabledBackgroundColor: Colors.grey.withOpacity(0.12),
                      ),
                      child: Text(
                        end == null
                            ? getTranslated(context, endDateText)!
                            : end!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    height: 40,
                    width: MediaQuery.of(context).size.width * .09,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(
                          () {
                            start = null;
                            end = null;
                            startDate = DateTime.now();
                            endDate = DateTime.now();
                            scrollLoadmore = true;
                            scrollOffset = 0;
                          },
                        );
                        getOrder();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: primary,
                        backgroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey.withOpacity(0.38),
                        disabledBackgroundColor: Colors.grey.withOpacity(0.12),
                        padding: const EdgeInsets.all(0),
                      ),
                      child: const Center(
                        child: Icon(Icons.close),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Card(
          //     margin: const EdgeInsetsDirectional.only(start: 10),
          //     shape: BeveledRectangleBorder(
          //       borderRadius: BorderRadius.circular(10.0),
          //     ),
          //     elevation: 0,
          //     child: Container(
          //       margin: const EdgeInsets.all(10),
          //       height: 40,
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(4.0),
          //         color: Colors.white,
          //       ),
          //       width: MediaQuery.of(context).size.width * .087,
          //       child: PopupMenuButton(
          //         icon: const Icon(
          //           Icons.more_vert,
          //           color: primary,
          //           size: 20,
          //         ),
          //         onSelected: (dynamic value) {
          //           switch (value) {
          //             case 0:
          //               return () {
          //                 setState(
          //                   () {
          //                     scrollLoadmore = true;
          //                     scrollOffset = 0;
          //                     productType = null;
          //                   },
          //                 );
          //                 getOrder();
          //               }();
          //             case 1:
          //               return () {
          //                 setState(
          //                   () {
          //                     scrollLoadmore = true;
          //                     scrollOffset = 0;
          //                     productType = 'simple';
          //                   },
          //                 );
          //                 getOrder();
          //               }();
          //             case 2:
          //               return () {
          //                 setState(
          //                   () {
          //                     scrollLoadmore = true;
          //                     scrollOffset = 0;
          //                     productType = 'digital';
          //                   },
          //                 );
          //                 getOrder();
          //               }();
          //           }
          //         },
          //         itemBuilder: (BuildContext context) => <PopupMenuEntry>[
          //           PopupMenuItem(
          //             value: 0,
          //             child: ListTile(
          //               dense: true,
          //               contentPadding: const EdgeInsetsDirectional.only(
          //                   start: 0.0, end: 0.0),
          //               leading: const Icon(
          //                 Icons.format_align_justify,
          //                 color: primary,
          //                 size: 25,
          //               ),
          //               title: Text(getTranslated(context, All)!),
          //             ),
          //           ),
          //           PopupMenuItem(
          //             value: 1,
          //             child: ListTile(
          //               dense: true,
          //               contentPadding: const EdgeInsetsDirectional.only(
          //                   start: 0.0, end: 0.0),
          //               leading: const Icon(
          //                 Icons.redeem,
          //                 color: primary,
          //                 size: 25,
          //               ),
          //               title: Text(getTranslated(context, SimpleText)!),
          //             ),
          //           ),
          //           PopupMenuItem(
          //             value: 2,
          //             child: ListTile(
          //               dense: true,
          //               contentPadding: const EdgeInsetsDirectional.only(
          //                   start: 0.0, end: 0.0),
          //               leading: const Icon(
          //                 Icons.memory,
          //                 color: primary,
          //                 size: 20,
          //               ),
          //               title: Text(getTranslated(context, DigitalText)!),
          //             ),
          //           ),
          //         ],
          //       ),
          //     )),
        ],
      ),
    );
  }

  _showTrackingDialog(Order_Model model, int index) async {
    String? urlDetails, couriourDetails, trackingDetails;
    if (model.tracking_id != "") {
      urlDetails = model.url;
      couriourDetails = model.courier_agency;
      trackingDetails = model.tracking_id;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    5.0,
                  ),
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
                          getTranslated(context, TRACKING_DETAIL)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        )),
                    const Divider(color: lightBlack),
                    Form(
                      key: _formkey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              validator: (val) => validateField(val, context),
                              initialValue: couriourDetails,
                              decoration: InputDecoration(
                                hintText:
                                    getTranslated(context, courierAgencyText)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: lightBlack,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: courierAgencyController,
                              onSaved: (value) {
                                courierAgency = value;
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              validator: (val) => validateField(val, context),
                              initialValue: trackingDetails,
                              decoration: InputDecoration(
                                hintText:
                                    getTranslated(context, trackingIDText)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: lightBlack,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              onSaved: (value) {
                                trackingId = value;
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              validator: (val) => validateField(val, context),
                              initialValue: urlDetails,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, URLText)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: lightBlack,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: urlController,
                              onSaved: (value) {
                                url = value;
                              },
                            ),
                          ),
                        ],
                      ),
                    )
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
                    }),
                TextButton(
                  child: Text(
                    getTranslated(context, SAVE_LBL)!,
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
                          isLoading = true;
                          Navigator.pop(context);
                        },
                      );
                      editTrackingDetails(model, courierAgency, trackingId, url)
                          .then(
                        (value) async {
                          orderList = [];
                          if (whichAPICalledRecently == "getOrder") {
                            await getOrder();
                          } else {
                            getTotalOrderTrackingNumber();
                            await getOrderTracking();
                          }

                          isLoading = false;
                        },
                      );
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

  _launchCaller(Order_Model model) async {
    var url = "tel:${model.mobile}";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      setsnackbar(getTranslated(context, couldnotlaunch)! + url, context);
      throw 'Could not launch $url';
    }
  }
}

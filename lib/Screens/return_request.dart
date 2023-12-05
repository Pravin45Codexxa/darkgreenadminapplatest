import 'dart:async';
import 'dart:convert';
import 'package:admin_eshop/Helper/AppBtn.dart';
import 'package:admin_eshop/Helper/Color.dart';
import 'package:admin_eshop/Helper/Constant.dart';
import 'package:admin_eshop/Helper/Session.dart';
import 'package:admin_eshop/Helper/String.dart';
import 'package:admin_eshop/Model/tracking_details_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class ReturnRequest extends StatefulWidget {
  const ReturnRequest({Key? key}) : super(key: key);

  @override
  _ReturnRequestState createState() => _ReturnRequestState();
}

class _ReturnRequestState extends State<ReturnRequest>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final TextEditingController _controller = TextEditingController();
  List<String> statusListOfBankTransfer = [
    "Pending",
    "Accepted",
    "Rejected",
  ];
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController remarkController = TextEditingController();
  Icon iconSearch = const Icon(
    Icons.search,
    color: primary,
  );
  Widget? appBarTitle;
  ScrollController? returnRequestController;
  int total = 0;
  List<TrackingDetails> tempList = [];
  bool? isSearching;
  String _searchText = "", _lastsearch = "", remark = "";
  bool _isLoading = true, isChangingStatus = false;

  bool loadingMoreRequest = true,
      notificationisgettingdata = false,
      notificationisnodata = false;
  int requestOffset = 0;
  List<TrackingDetails> returnRequestList = [];

  @override
  void initState() {
    requestOffset = 0;
    Future.delayed(Duration.zero, getDetails);
    //getDetails();

    // controller.addListener(_scrollListener);
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    returnRequestController = ScrollController(keepScrollOffset: true);
    returnRequestController!.addListener(_transactionscrollListener);

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
            (_searchText == '' || (_searchText.length >= 2))) {
          /*    setState(() {
            _lastsearch = _searchText;
            loadingMoreRequest = true; //
            requestOffset = 0;
            getDetails();
          }); */
        }
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: getAppbar(),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer()
              : notificationisnodata
                  ? Padding(
                      padding:
                          const EdgeInsetsDirectional.only(top: kToolbarHeight),
                      child: Center(
                        child: Text(
                          getTranslated(context, NoitemsFound)!,
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        RefreshIndicator(
                          key: _refreshIndicatorKey,
                          onRefresh: _refresh,
                          child: ListView.builder(
                            controller: returnRequestController,
                            itemCount: returnRequestList.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              TrackingDetails? item;
                              try {
                                item = returnRequestList.isEmpty
                                    ? null
                                    : returnRequestList[index];
                                if (loadingMoreRequest &&
                                    index == (returnRequestList.length - 1) &&
                                    returnRequestController!.position.pixels <=
                                        0) {
                                  getDetails();
                                }
                              } on Exception catch (_) {}

                              return item == "" ? Container() : listItem(index);
                            },
                          ),
                        ),
                        isChangingStatus || notificationisgettingdata
                            ? const Center(
                                //child: CircularProgressIndicator(),
                                )
                            : Container()
                      ],
                    )
          : noInternet(context),
    );
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
              title: getTranslated(context, TRY_AGAIN_INT_LBL),
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();

                Future.delayed(const Duration(seconds: 2)).then(
                  (_) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      getDetails();
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
      centerTitle: false,
      title: appBarTitle ??
          Text(
            getTranslated(context, RETURN_REQ_LBL)!,
            style: const TextStyle(color: primary),
          ),
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
                    Icons.arrow_back_ios_outlined,
                    color: primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: iconSearch,
          onPressed: () {
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
                      prefixIcon: IconButton(
                        icon: Icon(Icons.search, color: primary),
                        onPressed: () {
                          setState(() {
                            _lastsearch = _searchText;
                            loadingMoreRequest = true; //
                            requestOffset = 0;
                            getDetails();
                          });
                        },
                      ),
                      hintText: getTranslated(context, search),
                      hintStyle: const TextStyle(color: primary),
                    ),
                    //  onChanged: searchOperation,
                  );
                  _handleSearchStart();
                } else {
                  _handleSearchEnd();
                }
              },
            );
          },
        )
      ],
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

  void _handleSearchEnd() {
    if (!mounted) return;
    setState(
      () {
        iconSearch = const Icon(
          Icons.search,
          color: primary,
        );
        appBarTitle = Text(
          getTranslated(context, RETURN_REQ_LBL)!,
          style: const TextStyle(color: primary),
        );
        isSearching = false;
        _controller.clear();
        _refresh();
      },
    );
  }

  Future<void> _refresh() {
    if (mounted) {
      setState(
        () {
          _isLoading = true;
          returnRequestList.clear();
          loadingMoreRequest = true;
          requestOffset = 0;
        },
      );
    }
    total = 0;
    returnRequestList.clear();
    return getDetails();
  }

  Future<void> getDetails() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (loadingMoreRequest) {
          if (mounted) {
            setState(
              () {
                loadingMoreRequest = false;
                notificationisgettingdata = true;
                if (requestOffset == 0) {
                  returnRequestList = [];
                }
              },
            );
          }
          var parameter = {
            LIMIT: perPage.toString(),
            OFFSET: requestOffset.toString(),
            SEARCH: _searchText.trim(),
          };

          Response response =
              await post(getReturnRequestApi, headers: headers, body: parameter)
                  .timeout(const Duration(seconds: timeOut));

          if (response.statusCode == 200) {
            var getdata = json.decode(response.body);

            bool error = getdata["error"];
            String? msg = getdata["message"];
            notificationisgettingdata = false;
            if (requestOffset == 0) notificationisnodata = error;

            if (!error) {
              tempList.clear();
              var mainList = getdata["data"];

              if (mainList.length != 0) {
                tempList = (mainList as List)
                    .map((data) => TrackingDetails.fromJson(data))
                    .toList();

                returnRequestList.addAll(tempList);
                loadingMoreRequest = true;
                requestOffset = requestOffset + perPage;
              } else {
                loadingMoreRequest = false;
              }
            } else {
              loadingMoreRequest = false;
            }
          }
          if (mounted) {
            setState(
              () {
                loadingMoreRequest = false;
                _isLoading = false;
              },
            );
          }
        }
      } on TimeoutException catch (_) {
        setsnackbar(somethingMSg, context);
        if (mounted) {
          setState(
            () {
              _isLoading = false;
              // isLoadingmore = false;
            },
          );
        }
      }
    } else if (mounted) {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }

    return;
  }

  Widget listItem(int index) {
    TrackingDetails model = returnRequestList[index];
    late Color back;
    late String activeStatus;

    if ((model.status) == "1") {
      activeStatus = getTranslated(context, ACCEPTED)!;
      back = Colors.green;
    } else if ((model.status) == "0") {
      activeStatus = getTranslated(context, PENDING)!;
      back = Colors.orange;
    } else if ((model.status) == "2") {
      activeStatus = getTranslated(context, REJECTED)!;
      back = Colors.red;
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
                    Text(getTranslated(context, OrderNo)! + model.orderId!),
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
                        capitalize(activeStatus),
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
                child: Text(
                  capitalize(
                    model.productName!,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 14),
                    Text(
                      model.userName != "" && model.userName!.isNotEmpty
                          ? " ${capitalize(model.userName!)}"
                          : " ",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.pin, size: 14),
                    Text(
                      getTranslated(context, Quantity)!,
                    ),
                    const Spacer(),
                    Text(
                      "${model.quantity}",
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.money, size: 14),
                        Text(" ${getTranslated(context, PRICE_LBL)!}: "),
                      ],
                    ),
                    Text("${CUR_CURRENCY!}${model.price!}"),
                  ],
                ),
              ),
              model.discountedPrice != "" && model.discountedPrice!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 5),
                      child: Row(
                        children: [
                          const Icon(Icons.money, size: 14),
                          Text(
                            "${getTranslated(context, DiscountPrice)!}: ",
                          ),
                          Text(
                            " ${capitalize(model.discountedPrice!)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )
                  : Container(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.money, size: 14),
                        Text(
                          " ${getTranslated(context, Subtotal)!}: ",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      "${CUR_CURRENCY!}${model.subTotal!}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          _showUpdateStatusDialogue(model, index);
        },
      ),
    );
  }

  _transactionscrollListener() {
    if (returnRequestController!.offset >=
            returnRequestController!.position.maxScrollExtent &&
        !returnRequestController!.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            loadingMoreRequest = true;
            getDetails();
          },
        );
      }
    }
  }

  void _showUpdateStatusDialogue(TrackingDetails model, int index) async {
    int curStatus = 0;
    String currentStatus = statusListOfBankTransfer[curStatus];
    if (model.status!.isNotEmpty) {
      curStatus = int.parse(model.status!);
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
                        getTranslated(context, UPDATE_RETURN_REQ_LBL)!,
                        style: Theme.of(this.context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: fontColor),
                      ),
                    ),
                    const Divider(color: lightBlack),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: DropdownButtonFormField(
                        isExpanded: true,
                        dropdownColor: lightWhite,
                        isDense: true,
                        iconEnabledColor: fontColor,
                        hint: Text(
                          getTranslated(context, PENDING)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color: fontColor,
                                  fontWeight: FontWeight.bold),
                        ),
                        decoration: const InputDecoration(
                          filled: true,
                          isDense: true,
                          fillColor: lightWhite,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: fontColor),
                          ),
                        ),
                        value: statusListOfBankTransfer[curStatus],
                        onChanged: (dynamic newValue) {
                          setState(
                            () {
                              currentStatus = newValue;
                            },
                          );
                        },
                        items: statusListOfBankTransfer.map(
                          (String st) {
                            return DropdownMenuItem<String>(
                              value: st,
                              child: Text(
                                capitalize(st),
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
                    Form(
                      key: _formkey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              initialValue: model.remarks,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, Remarks)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: lightBlack,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              onSaved: (value) {
                                remark = value!;
                              },
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
                    getTranslated(context, SAVE_LBL)!,
                    style: Theme.of(this.context)
                        .textTheme
                        .titleSmall!
                        .copyWith(
                            color: fontColor, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final form = _formkey.currentState!;
                    if (form.validate()) {
                      form.save();
                      setState(
                        () {
                          if (currentStatus != "Pending") {
                            isChangingStatus = true;
                          }

                          Navigator.pop(context);
                        },
                      );
                      if (currentStatus == "Accepted") {
                        await changeReturnRequestStatus("1", model).then(
                          (value) async {
                            isChangingStatus = false;
                          },
                        );
                      } else if (currentStatus == "Rejected") {
                        await changeReturnRequestStatus("2", model).then(
                          (value) async {
                            isChangingStatus = false;
                          },
                        );
                      }
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

  changeReturnRequestStatus(String status, TrackingDetails model) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        setState(
          () {
            isChangingStatus = true;
          },
        );

        var parameter = {
          RETURN_REQ_ID: model.id,
          ORDERITEMID: model.orderItemId,
          STATUS: status.toString(),
        };
        if (UPDATE_REMARKS != "" && UPDATE_REMARKS != "") {
          parameter[UPDATE_REMARKS] = remark;
        }

        Response response = await post(getUpdateReturnRequestApi,
                body: parameter, headers: headers)
            .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        setsnackbar(msg, context);

        setState(() {
          isChangingStatus = false;
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
}

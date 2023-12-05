import 'dart:async';
import 'dart:convert';
import 'package:admin_eshop/Model/cash_collection_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Person_Model.dart';

class DeliveryBoy extends StatefulWidget {
  final bool? isDelBoy;

  const DeliveryBoy({Key? key, this.isDelBoy}) : super(key: key);

  @override
  _DeliveryBoyState createState() => _DeliveryBoyState();
}

class _DeliveryBoyState extends State<DeliveryBoy>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<PersonModel> tempList = [];
  List<String> filterList = [
    ALL,
    CASH_COLLECTED_BY_ADMIN,
    CASH_RECEIVED_BY_DEL_BOY
  ];
  String filterValue = ALL;

  List<CashCollectionModel> listOfCashCollectionHistory = [];
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true, isCashCollectionForSingleDeliveryboy = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKeyOfCashCollection =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<PersonModel> notiList = [];
  int total = 0;
  bool _isLoading = true;
  bool _isLoadingCashCollectionList = true;
  final TextEditingController _controller = TextEditingController();
  Icon iconSearch = const Icon(
    Icons.search,
    color: primary,
  );
  Widget? appBarTitle;
  ScrollController? notificationcontroller;
  ScrollController? cashCollectionScrollController;
  DateTime todayDate = DateTime.now();
  TimeOfDay currentTime = TimeOfDay.now();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  late TabController _tabController;
  bool? isSearching;
  String _searchText = "",
      _lastsearch = "",
      selectedDate = "",
      selectedTime = "",
      collectedAmount = "",
      message = "",
      deliveryboyId = "";

  bool notificationisloadmore = true,
      loadingMoreCashCollectionData = true,
      notificationisgettingdata = false,
      gettingCashCollectionData = false,
      notificationisnodata = false,
      isCashCollectionListEmpty = false;
  int notificationoffset = 0,
      cashCollectionHistoryOffset = 0,
      deliveryBoyCashCollectionHistoryOffset = 0;

  @override
  void initState() {
    selectedDate = DateFormat('dd-MM-yyyy').format(todayDate);
    Future.delayed(Duration.zero).then((value) {
      appBarTitle = Text(
          widget.isDelBoy!
              ? getTranslated(context, Del_LBL)!
              : getTranslated(context, CUST_LBL)!,
          style: const TextStyle(color: primary));
    });

    notificationoffset = 0;
    Future.delayed(Duration.zero, getDetails);
    Future.delayed(Duration.zero, getDeliveryBoyCashCollection);

    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    notificationcontroller = ScrollController(keepScrollOffset: true);
    notificationcontroller!.addListener(_transactionScrollListener);
    cashCollectionScrollController = ScrollController(keepScrollOffset: true);
    cashCollectionScrollController!.addListener(_cashCollectionScrollListener);

    _tabController = TabController(
      length: widget.isDelBoy! ? 2 : 1,
      vsync: this,
    );

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
          _lastsearch = _searchText;
          if (_tabController.index == 0) {
            notificationisloadmore = true;
            notificationoffset = 0;
            getDetails();
          } else {
            loadingMoreCashCollectionData = true;
            cashCollectionHistoryOffset = 0;
            listOfCashCollectionHistory.clear();
            getDeliveryBoyCashCollection();
          }
        }
      },
    );
    super.initState();
  }

  _transactionScrollListener() {
    if (notificationcontroller!.offset >=
            notificationcontroller!.position.maxScrollExtent &&
        !notificationcontroller!.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            notificationisloadmore = true;
            getDetails();
          },
        );
      }
    }
  }

  _cashCollectionScrollListener() {
    if (cashCollectionScrollController!.offset >=
            cashCollectionScrollController!.position.maxScrollExtent &&
        !cashCollectionScrollController!.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            loadingMoreCashCollectionData = true;
          },
        );
      }

      if (isCashCollectionForSingleDeliveryboy) {
        getDeliveryBoyCashCollection(deliveryboyID: deliveryboyId);
      } else {
        getDeliveryBoyCashCollection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: getAppbar(),
      body: Container(
        child: Column(
          children: [
            widget.isDelBoy!
                ? TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        text: getTranslated(context, Del_LBL)!,
                      ),
                      Tab(
                        text: getTranslated(context, CollectedCashText)!,
                      )
                    ],
                  )
                : Container(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isNetworkAvail
                      ? _isLoading
                          ? shimmer()
                          : notificationisnodata
                              ? Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: kToolbarHeight),
                                  child: Center(
                                    child: Text(
                                      getTranslated(context, NoitemsFound)!,
                                    ),
                                  ),
                                )
                              : NotificationListener<ScrollNotification>(
                                  child: Stack(
                                    children: <Widget>[
                                      RefreshIndicator(
                                        key: _refreshIndicatorKey,
                                        onRefresh: _refreshDeliveryBoy,
                                        child: ListView.builder(
                                          controller: notificationcontroller,
                                          itemCount: notiList.length,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            PersonModel? item;
                                            try {
                                              item = notiList.isEmpty
                                                  ? null
                                                  : notiList[index];
                                              if (notificationisloadmore &&
                                                  index ==
                                                      (notiList.length - 1) &&
                                                  notificationcontroller!
                                                          .position.pixels <=
                                                      0) {
                                                getDetails();
                                              }
                                            } on Exception catch (_) {}

                                            return item == ""
                                                ? Container()
                                                : listItem(index);
                                          },
                                        ),
                                      ),
                                      notificationisgettingdata
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : Container(),
                                    ],
                                  ),
                                )
                      : noInternet(context),
                  if (widget.isDelBoy!)
                    _isNetworkAvail
                        ? _isLoadingCashCollectionList
                            ? shimmer()
                            : Stack(
                                children: <Widget>[
                                  RefreshIndicator(
                                    key: _refreshIndicatorKeyOfCashCollection,
                                    onRefresh: _refreshCashCollection,
                                    child: Column(
                                      children: [
                                        Card(
                                          elevation: 1,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 10,
                                                          top: 5,
                                                          bottom: 5),
                                                  child:
                                                      DropdownButtonFormField(
                                                    isExpanded: true,
                                                    dropdownColor: lightWhite,
                                                    isDense: true,
                                                    iconEnabledColor: fontColor,
                                                    hint: Text(
                                                      getTranslated(context,
                                                          updateStatus)!,
                                                      style: Theme.of(
                                                              this.context)
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
                                                              horizontal: 10),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: fontColor,
                                                        ),
                                                      ),
                                                    ),
                                                    value: filterValue,
                                                    onChanged:
                                                        (dynamic newValue) {
                                                      setState(
                                                        () {
                                                          cashCollectionHistoryOffset =
                                                              0;
                                                          deliveryBoyCashCollectionHistoryOffset =
                                                              0;
                                                          filterValue =
                                                              newValue;
                                                          loadingMoreCashCollectionData =
                                                              true;
                                                        },
                                                      );
                                                      getDeliveryBoyCashCollection(
                                                          deliveryboyID:
                                                              deliveryboyId);
                                                    },
                                                    items: filterList.map(
                                                      (String listValue) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: listValue,
                                                          child: Text(
                                                            capitalize(
                                                                listValue),
                                                            style:
                                                                const TextStyle(
                                                                    color:
                                                                        fontColor,
                                                                    fontSize:
                                                                        12),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                            softWrap: true,
                                                          ),
                                                        );
                                                      },
                                                    ).toList(),
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                flex: 1,
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(
                                                      () {
                                                        isCashCollectionForSingleDeliveryboy =
                                                            false;
                                                        deliveryBoyCashCollectionHistoryOffset =
                                                            0;
                                                        cashCollectionHistoryOffset =
                                                            0;
                                                        deliveryboyId = "";
                                                        filterValue = ALL;
                                                      },
                                                    );
                                                    getDeliveryBoyCashCollection();
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        5.0,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 15.0,
                                                          vertical: 10.0),
                                                      child: Text(
                                                        getTranslated(
                                                          context,
                                                          ResetText,
                                                        )!,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            controller:
                                                cashCollectionScrollController,
                                            itemCount:
                                                listOfCashCollectionHistory
                                                    .length,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              CashCollectionModel? item;
                                              try {
                                                item = listOfCashCollectionHistory
                                                        .isEmpty
                                                    ? null
                                                    : listOfCashCollectionHistory[
                                                        index];
                                                if (loadingMoreCashCollectionData &&
                                                    index ==
                                                        (listOfCashCollectionHistory
                                                                .length -
                                                            1) &&
                                                    cashCollectionScrollController!
                                                            .position.pixels <=
                                                        0) {
                                                  if (isCashCollectionForSingleDeliveryboy) {
                                                    getDeliveryBoyCashCollection(
                                                        deliveryboyID:
                                                            deliveryboyId);
                                                  } else {
                                                    getDeliveryBoyCashCollection();
                                                  }
                                                }
                                              } on Exception catch (_) {}
                                              late Color back;

                                              var deliveryBoyDetails =
                                                  listOfCashCollectionHistory[
                                                      index];

                                              if ((deliveryBoyDetails.type) ==
                                                  "Collected") {
                                                back = Colors.green;
                                              } else if ((deliveryBoyDetails
                                                      .type) ==
                                                  "Received") {
                                                back = Colors.orange;
                                              }
                                              return Card(
                                                elevation: 1,
                                                margin:
                                                    const EdgeInsets.all(5.0),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal:
                                                                    8.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: <Widget>[
                                                            Text(
                                                                "${getTranslated(context, ID_LBL)!}:- ${deliveryBoyDetails.id!}"),
                                                            const Spacer(),
                                                            Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      left: 8),
                                                              padding: const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: back,
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                  Radius
                                                                      .circular(
                                                                          4.0),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                capitalize(getTranslated(
                                                                    context,
                                                                    deliveryBoyDetails
                                                                        .type!)!),
                                                                style: const TextStyle(
                                                                    color:
                                                                        white),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      const Divider(),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 8.0,
                                                                vertical: 5),
                                                        child: Row(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .person_outline,
                                                                    size: 14),
                                                                Text(
                                                                  deliveryBoyDetails.name !=
                                                                              "" &&
                                                                          deliveryBoyDetails
                                                                              .name!
                                                                              .isNotEmpty
                                                                      ? " ${capitalize(deliveryBoyDetails.name!)}"
                                                                      : " ",
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                            const Spacer(),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .calendar_today_outlined,
                                                                    size: 14),
                                                                Text(
                                                                  " ${deliveryBoyDetails.date!}",
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 8.0,
                                                                vertical: 5),
                                                        child: Row(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .money_outlined,
                                                                    size: 14),
                                                                Text(
                                                                  " ${getTranslated(
                                                                    context,
                                                                    AMT_LBL,
                                                                  )!}:",
                                                                ),
                                                                Text(
                                                                  " ${deliveryBoyDetails.amount}",
                                                                ),
                                                              ],
                                                            ),
                                                            const Spacer(),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .phone_android_outlined,
                                                                    size: 14),
                                                                Text(
                                                                  " ${deliveryBoyDetails.mobile}",
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 8.0,
                                                                vertical: 5),
                                                        child: Row(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .text_snippet_outlined,
                                                                    size: 14),
                                                                Text(
                                                                    " ${getTranslated(context, MSG_LBL)!}: "),
                                                              ],
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                deliveryBoyDetails
                                                                    .message!,
                                                                maxLines: 2,
                                                                softWrap: true,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  loadingMoreCashCollectionData
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : Container(),
                                ],
                              )
                        : noInternet(context),
                ],
              ),
            ),
          ],
        ),
      ),
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
              title: getTranslated(context, TRY_AGAIN_INT_LBL)!,
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
                      prefixIcon: const Icon(Icons.search, color: primary),
                      hintText: '${getTranslated(context, search)!}...',
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
        ),
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
          widget.isDelBoy!
              ? getTranslated(context, Del_LBL)!
              : getTranslated(context, CUST_LBL)!,
          style: const TextStyle(color: primary),
        );
        isSearching = false;
        _controller.clear();
      },
    );
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget listItem(int index) {
    PersonModel model = notiList[index];

    String add = "${model.street!} ${model.area!} ${model.city!}";

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        "${getTranslated(context, NAME_LBL)!}: ",
                      ),
                      Text(
                        model.name!,
                        style: const TextStyle(color: primary),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: model.status == "1" ? Colors.green : Colors.red,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(4.0),
                    ),
                  ),
                  child: Text(
                    model.status == "1"
                        ? getTranslated(context, ActiveText)!
                        : getTranslated(context, DeactiveText)!,
                    style: const TextStyle(color: white, fontSize: 11),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      add.length > 2
                          ? Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Row(
                                children: [
                                  Text(
                                    "${getTranslated(context, SHOW_ADD)!}: ",
                                  ),
                                  Text(
                                      "${model.street!} ${model.area!} ${model.city!}"),
                                ],
                              ),
                            )
                          : Container(),
                      model.email != ""
                          ? GestureDetector(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "${getTranslated(context, EmailText)!}: ",
                                    ),
                                    Expanded(
                                      child: Text(
                                        model.email!,
                                        style: const TextStyle(
                                          color: fontColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                _launchMail(model.email);
                              },
                            )
                          : Container(),
                      GestureDetector(
                        child: Row(
                          children: [
                            Text(
                              "${getTranslated(context, SHOW_CONTACT)!}: ",
                            ),
                            Text(
                              model.mobile!,
                              style: const TextStyle(
                                color: fontColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _launchCaller(model.mobile);
                        },
                      ),
                      Row(
                        children: [
                          Text(
                            "${getTranslated(context, SHOW_BALANCE)!}: ",
                          ),
                          Text(
                            model.balance!,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                model.img != null && model.img != ''
                    ? SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3.0),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(model.img!),
                            radius: 25,
                          ),
                        ),
                      )
                    : Container(
                        height: 0,
                      ),
              ],
            ),
            widget.isDelBoy!
                ? Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              "${getTranslated(context, SHOW_CASH_TO_COLLECT)!}: ",
                            ),
                            Expanded(
                              child: Text(
                                model.cashToCollect!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      model.cashToCollect! != "0" && model.cashToCollect! != ""
                          ? Tooltip(
                              message:
                                  getTranslated(context, SHOW_COLLECT_CASH)!,
                              child: Container(
                                height: 30,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.payments_outlined,
                                    size: 15,
                                  ),
                                  onPressed: () {
                                    _showCollectCashDialogue(
                                        context,
                                        model.name!,
                                        model.cashToCollect!,
                                        model.id!);
                                  },
                                ),
                              ),
                            )
                          : Container(),
                      Tooltip(
                        message: getTranslated(context, SHOW_TRANSACTION)!,
                        child: Container(
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.yellow,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 15,
                            ),
                            onPressed: () async {
                              setState(
                                () {
                                  notificationisgettingdata = true;
                                },
                              );
                              var data = await showDeliveryBoyCashCollection(
                                model.id!,
                              );
                              setState(
                                () {
                                  notificationisgettingdata = false;
                                },
                              );
                              Future.delayed(
                                const Duration(milliseconds: 100),
                              ).then(
                                (value) {
                                  _tabController.animateTo(1);
                                },
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  showDeliveryBoyCashCollection(String deliveryBoyID) async {
    if (mounted) {
      setState(
        () {
          isCashCollectionForSingleDeliveryboy = true;
          deliveryBoyCashCollectionHistoryOffset = 0;
          cashCollectionHistoryOffset = 0;
          deliveryboyId = deliveryBoyID;
        },
      );
    }

    return getDeliveryBoyCashCollection(deliveryboyID: deliveryboyId);
  }

  _launchCaller(String? mobile) async {
    var url = "tel:$mobile";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _refreshDeliveryBoy() {
    if (mounted) {
      setState(
        () {
          _isLoading = true;
          notiList.clear();
          notificationisloadmore = true;
          notificationoffset = 0;
        },
      );
    }
    dateController.clear();
    timeController.clear();
    total = 0;
    notiList.clear();
    return getDetails();
  }

  Future<void> _refreshCashCollection() {
    if (mounted) {
      setState(
        () {
          _isLoadingCashCollectionList = true;
          listOfCashCollectionHistory.clear();
          loadingMoreCashCollectionData = true;
          cashCollectionHistoryOffset = 0;
          deliveryBoyCashCollectionHistoryOffset = 0;
        },
      );
    }

    if (isCashCollectionForSingleDeliveryboy) {
      return getDeliveryBoyCashCollection(deliveryboyID: deliveryboyId);
    } else {
      return getDeliveryBoyCashCollection();
    }
  }

  Future<void> getDetails() async {
    if (widget.isDelBoy! && readDel || !widget.isDelBoy! && readCust) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (notificationisloadmore) {
            if (mounted) {
              setState(() {
                notificationisloadmore = false;
                notificationisgettingdata = true;
                if (notificationoffset == 0) {
                  notiList = [];
                }
              });
            }
            var parameter = {
              LIMIT: perPage.toString(),
              OFFSET: notificationoffset.toString(),
              SEARCH: _searchText.trim(),
            };

            Response response = await post(
                    widget.isDelBoy! ? getDelBoyApi : getCustApi,
                    headers: headers,
                    body: parameter)
                .timeout(const Duration(seconds: timeOut));

            if (response.statusCode == 200) {
              var getdata = json.decode(response.body);
              bool error = getdata["error"];
              notificationisgettingdata = false;
              if (notificationoffset == 0) notificationisnodata = error;

              if (!error) {
                tempList.clear();
                var mainList = getdata["data"];

                if (mainList.length != 0) {
                  tempList = (mainList as List)
                      .map((data) => PersonModel.fromJson(data))
                      .toList();

                  notiList.addAll(tempList);
                  notificationisloadmore = true;
                  notificationoffset = notificationoffset + perPage;
                } else {
                  notificationisloadmore = false;
                }
              } else {
                notificationisloadmore = false;
              }
            }
            if (mounted) {
              setState(() {
                notificationisloadmore = false;
                _isLoading = false;
              });
            }
          }
        } on TimeoutException catch (_) {
          setsnackbar(somethingMSg, context);
          if (mounted) {
            setState(
              () {
                _isLoading = false;
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
    } else {
      setState(
        () {
          _isLoading = false;
        },
      );
      setsnackbar(getTranslated(context, permissiontext)!, context);
    }
    return;
  }

  Future updateDeliveryBoyCashCollection(
      String deliveryBoyID, String amount, String message) async {
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(
            () {
              notificationisgettingdata = true;
            },
          );
        }
        var parameter = {
          DEL_BOY_ID: deliveryBoyID,
          AMT: amount,
          MSG: message,
          TRANSACTION_DATE: "$selectedDate $selectedTime"
        };

        Response response = await post(manageDeliveryBoyCashCollectionApi,
                headers: headers, body: parameter)
            .timeout(const Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          String? msg = getdata["message"];
          notificationisgettingdata = false;
          setsnackbar(msg!, context);
        }
        if (mounted) {
          setState(
            () {
              notificationisloadmore = false;
            },
          );
        }
      } on TimeoutException catch (exception) {
        setsnackbar(exception.message!, context);
        if (mounted) {
          setState(
            () {
              notificationisloadmore = false;
            },
          );
        }
      } on FormatException catch (exception) {
        setsnackbar(exception.message, context);
        if (mounted) {
          setState(
            () {
              notificationisloadmore = false;
            },
          );
        }
      }
    } else if (mounted) {
      setState(
        () {
          notificationisloadmore = false;
          _isNetworkAvail = false;
        },
      );
    }
  }

  Future<bool> getDeliveryBoyCashCollection({String? deliveryboyID}) async {
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(
            () {
              gettingCashCollectionData = true;
            },
          );
        }
        if (cashCollectionHistoryOffset == 0 &&
            (deliveryBoyCashCollectionHistoryOffset == 0)) {
          listOfCashCollectionHistory = [];
        }
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: cashCollectionHistoryOffset.toString(),
          SEARCH: _searchText.trim(),
        };

        if (deliveryboyID != "") {
          parameter["delivery_boy_id"] = deliveryboyId;
          parameter[OFFSET] = deliveryBoyCashCollectionHistoryOffset.toString();
        }

        if (filterValue == "admin") {
          parameter["status"] = "delivery_boy_cash_collection";
        } else if (filterValue == "deliveryBoy") {
          parameter["status"] = "delivery_boy_cash";
        }

        Response response = await post(getDeliveryBoyCashCollectionApi,
                headers: headers, body: parameter)
            .timeout(const Duration(seconds: timeOut));
        gettingCashCollectionData = false;
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];

          if (!error) {
            var cashCollectionHistoryList = getdata["data"];

            if (cashCollectionHistoryList.length != 0) {
              listOfCashCollectionHistory.addAll(
                  (cashCollectionHistoryList as List)
                      .map((data) => CashCollectionModel.fromJson(data))
                      .toList());
              loadingMoreCashCollectionData = true;

              if (deliveryboyID != "") {
                deliveryBoyCashCollectionHistoryOffset += perPage;
              } else {
                cashCollectionHistoryOffset += perPage;
              }
            } else {
              loadingMoreCashCollectionData = false;
            }
          } else {
            loadingMoreCashCollectionData = false;
          }
        }
        if (mounted) {
          setState(
            () {
              loadingMoreCashCollectionData = false;
              _isLoadingCashCollectionList = false;
            },
          );
        }
      } on TimeoutException catch (exception) {
        setsnackbar(exception.message!, context);
        if (mounted) {
          setState(
            () {
              loadingMoreCashCollectionData = false;
            },
          );
        }
      } on FormatException catch (exception) {
        setsnackbar(exception.message, context);
        if (mounted) {
          setState(
            () {
              loadingMoreCashCollectionData = false;
            },
          );
        }
      }
    } else if (mounted) {
      setState(
        () {
          loadingMoreCashCollectionData = false;
          _isNetworkAvail = false;
        },
      );
    }
    return true;
  }

  _launchMail(String? email) async {
    var url = "mailto:$email";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showCollectCashDialogue(
      BuildContext cashContext,
      String deliveryBoyName,
      String cashToCollect,
      String deliveryBoyID) async {
    await showDialog(
      context: cashContext,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext dialogueContext, StateSetter setStater) {
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
                        getTranslated(context, COLLECT_AMOUNT_LBL)!,
                        style: Theme.of(this.context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: fontColor),
                      ),
                    ),
                    const Divider(color: lightBlack),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 2.0),
                        child: Row(
                          children: [
                            Text(
                              "${getTranslated(context, NAME_LBL)!}: ",
                              style: const TextStyle(color: primary),
                            ),
                            Text(
                              deliveryBoyName,
                              style: const TextStyle(color: lightBlack),
                            ),
                          ],
                        )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 2.0),
                      child: Row(
                        children: [
                          Text(
                            "${getTranslated(context, SHOW_CASH_TO_COLLECT)!}: ",
                            style: const TextStyle(color: primary),
                          ),
                          Text(
                            cashToCollect,
                            style: const TextStyle(color: lightBlack),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Divider(color: lightBlack),
                    ),
                    Form(
                      key: _formkey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: getTranslated(
                                    context, AMOUNT_TO_BE_COLLECTED_HINT_LBL)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: lightBlack,
                                        fontWeight: FontWeight.normal),
                              ),
                              onSaved: (value) {
                                collectedAmount = value!;
                              },
                              validator: (val) => validateField(val, context),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, MSG_LBL)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: lightBlack,
                                        fontWeight: FontWeight.normal),
                              ),
                              onSaved: (value) {
                                message = value!;
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20.0, 0.0, 10.0, 0.0),
                                  child: TextFormField(
                                    onTap: () {
                                      _showDateDialogue(
                                          dialogueContext, setStater);
                                    },
                                    controller: dateController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: getTranslated(
                                          context, SELECT_DATE_HINT_LBL)!,
                                      hintStyle: Theme.of(this.context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            color: lightBlack,
                                            fontWeight: FontWeight.normal,
                                          ),
                                    ),
                                    validator: (val) =>
                                        validateField(val, context),
                                  ),
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      2.0, 0, 20.0, 0),
                                  child: TextFormField(
                                    onTap: () {
                                      _showTimeDialogue(
                                          dialogueContext, setStater);
                                    },
                                    textAlign: TextAlign.center,
                                    readOnly: true,
                                    controller: timeController,
                                    decoration: InputDecoration(
                                      hintText: getTranslated(
                                          context, SELECT_TIME_HINT_LBL)!,
                                      hintStyle: Theme.of(this.context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              color: lightBlack,
                                              fontWeight: FontWeight.normal),
                                    ),
                                    validator: (val) =>
                                        validateField(val, context),
                                  ),
                                ),
                              ),
                            ],
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
                  },
                ),
                TextButton(
                  child: Text(
                    getTranslated(context, COLLECT_LBL)!,
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
                      Navigator.pop(context);
                      await updateDeliveryBoyCashCollection(
                          deliveryBoyID, collectedAmount, message);
                      _refreshDeliveryBoy();
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

  Future<void> _showDateDialogue(
      BuildContext context, StateSetter setStater) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: todayDate,
        firstDate: DateTime(2020, 1),
        lastDate: DateTime.now());
    if (picked != null) {
      setStater(
        () {
          todayDate = picked;
          selectedDate = DateFormat('dd-MM-yyyy').format(todayDate);
          dateController.text = selectedDate;
        },
      );
    }
  }

  Future<void> _showTimeDialogue(
      BuildContext context, StateSetter setStater) async {
    final TimeOfDay? picked = await showTimePicker(
      initialTime: currentTime,
      context: context,
    );
    if (picked != null) {
      setStater(
        () {
          currentTime = picked;
          selectedTime = "${currentTime.hour}:${currentTime.minute}";
          timeController.text = selectedTime;
        },
      );
    }
  }
}

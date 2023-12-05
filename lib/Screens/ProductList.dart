import 'dart:async';
import 'dart:convert';
import 'package:admin_eshop/Screens/Home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'AddProduct.dart';
import 'EditProduct.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import 'Search.dart';

class ProductList extends StatefulWidget {
  final String? flag;

  const ProductList({Key? key, this.flag}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProduct();
}

class StateProduct extends State<ProductList> with TickerProviderStateMixin {
  bool _isLoading = true, _isProgress = false, _isButtonExtended = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Product> productList = [];
  List<Product> tempList = [];
  String? sortBy = 'p.id', orderBy = "DESC", flag = '';
  int offset = 0;
  int total = 0;
  String? totalProduct;
  bool isLoadingmore = true;
  ScrollController controller = ScrollController();
  List<dynamic>? filterList = [];
  List<String>? attnameList;
  List<String>? attsubList;
  List<String>? attListId;
  bool _isNetworkAvail = true;
  List<String> selectedId = [];
  bool _isFirstLoad = true;
  String? filter = "";
  String selId = "";
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool listType = true;
  final List<TextEditingController> _controller = [];
  var items;

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    flag = widget.flag;
    getProduct("0");

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
  }

  @override
  void dispose() {
    buttonController!.dispose();
    controller.removeListener(
          () {},
    );
    for (int i = 0; i < _controller.length; i++) {
      _controller[i].dispose();
    }
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightWhite,
      appBar: getAppbar(),
      floatingActionButton: floatingBtn(),
      key: _scaffoldKey,
      body: _isNetworkAvail
          ? _isLoading
          ? shimmer()
          : productList.isEmpty
          ? getNoItem()
          : Stack(
        children: <Widget>[
          _showForm(),
          showCircularProgress(_isProgress, primary),
        ],
      )
          : noInternet(context),
    );
  }

//==============================================================================
//=============================== floating Button ==============================

  floatingBtn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          isExtended: _isButtonExtended,
          backgroundColor: white,
          label: Text(getTranslated(context, 'ADD NEW PRODUCT')!),
          icon: const Icon(
            Icons.add,
            size: 32,
            color: primary,
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute<String>(
                builder: (context) => const AddProduct(),
              ),
            );
            print("result: " + result.toString());
            if (result == 'refresh') {
              //_refresh();
              setState(
                    () {
                  _isLoading = true;
                  isLoadingmore = true;
                  offset = 0;
                  total = 0;
                  productList.clear();
                },
              );

              getProduct("0");
            }
          },
        ),
        const SizedBox(height: 10),
      ],
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
                      offset = 0;
                      total = 0;
                      flag = '';
                      getProduct("0");
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

  noIntBtn(BuildContext context) {
    double width = deviceWidth;
    return Container(
      padding: const EdgeInsetsDirectional.only(
        bottom: 10.0,
        top: 50.0,
      ),
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(80.0),
            ),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (BuildContext context) => super.widget,
              ),
            );
          },
          child: Ink(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: width / 1.2,
                minHeight: 45,
              ),
              alignment: Alignment.center,
              child: Text(
                getTranslated(context, NO_INTERNET)!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: white,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget listItem(int index) {
    if (index < productList.length) {
      Product model = productList[index];
      totalProduct = model.total;

      String stockType = "";
      if (model.stockType == "") {
        stockType = "Not enabled";
      } else if (model.stockType == "1" || model.stockType == "0") {
        stockType = "Global";
      } else if (model.stockType == "2") {
        stockType = "Varient wise";
      }

      if (_controller.length < index + 1) {
        _controller.add(TextEditingController());
      }

      _controller[index].text =
      model.prVarientList![model.selVarient!].cartCount!;
      items = List<String>.generate(
          model.totalAllow != "" ? int.parse(model.totalAllow!) : 10,
              (i) => (i + 1).toString());

      double price =
      double.parse(model.prVarientList![model.selVarient!].disPrice!);
      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }
      return Card(
        elevation: 0,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProduct(
                  model: model,
                ),
              ),
            ).then(
                  (value) => () {
                setState(
                      () {
                    _isLoading = true;
                    isLoadingmore = true;
                    offset = 0;
                    total = 0;
                    productList.clear();
                  },
                );
                return getProduct("0");
              }(),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Hero(
                      tag: "$index${model.id}",
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(7.0),
                          child: FadeInImage(
                            image: NetworkImage(model.image!),
                            height: 80.0,
                            width: 80.0,
                            placeholder: placeHolder(80),
                            imageErrorBuilder: ((context, error, stackTrace) {
                              return erroWidget(80);
                            }),
                          )),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              model.name!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(color: lightBlack),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: <Widget>[
                                Text("${CUR_CURRENCY!} $price ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  double.parse(model
                                      .prVarientList![model.selVarient!]
                                      .disPrice!) !=
                                      0
                                      ? "${CUR_CURRENCY!}${model.prVarientList![model.selVarient!].price!}"
                                      : "",
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                      decoration:
                                      TextDecoration.lineThrough,
                                      letterSpacing: 0),
                                ),
                              ],
                            ),
                            Text(
                              '${getTranslated(context, StockType)!}: $stockType',
                            ),
                            model.prVarientList![model.selVarient!].stock != ""
                                ? Text(
                              '${getTranslated(context, StockCount)!}: ${model.prVarientList![model.selVarient!].stock}',
                              style: const TextStyle(
                                  color: fontColor,
                                  fontWeight: FontWeight.bold),
                            )
                                : Container(),
                            // model.type == "variable_product"
                            //     ? Align(
                            //         alignment: Alignment.bottomRight,
                            //         child: OutlinedButton(
                            //           onPressed: () {
                            //             Product model = productList[index];
                            //             _chooseVarient(model);
                            //           },
                            //           child: Text(
                            //             getTranslated(context, SelectVarient)!,
                            //           ),
                            //         ),
                            //       )
                            //     : Container()
                            // InkWell(
                            //   onTap: () {
                            //     productDeletDialog(
                            //       model.name!,
                            //       model.id!,
                            //     );
                            //   },
                            //   child: const Icon(
                            //     Icons.delete,
                            //     color: red,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              model.availability == "0"
                  ? Text(
                getTranslated(context, OutofStock)!,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : Container(),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  productDeletDialog(String productName, String id) async {
    String pName = productName;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Text(
                "${getTranslated(context, SURE_LBL)!} \"  $pName \" ${getTranslated(context, "PRODUCT")!}",
                style: Theme.of(this.context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: fontColor),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    getTranslated(context, "No")!,
                    style: Theme.of(this.context)
                        .textTheme
                        .titleSmall!
                        .copyWith(
                        color: lightBlack, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    getTranslated(context, "Yes")!,
                    style: Theme.of(this.context)
                        .textTheme
                        .titleSmall!
                        .copyWith(
                        color: fontColor, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    delProductApi(id);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  delProductApi(String id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var parameter = {
        "product_id": id,
      };
      apiBaseHelper.postAPICall(getDeleteProductApi, parameter).then(
            (getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            setsnackbar(msg!, context);
            _isLoading = true;
            isLoadingmore = true;
            offset = 0;
            total = 0;
            productList.clear();
            getProduct("0");
          } else {
            setsnackbar(msg!, context);

            _isLoading = true;
            isLoadingmore = true;
            offset = 0;
            total = 0;
            productList.clear();
            getProduct("0");
          }
        },
        onError: (error) {},
      );
    } else {
      if (mounted) {
        setState(
              () {
            _isNetworkAvail = false;
            _isLoading = false;
          },
        );
      }
    }
    return null;
  }

  updateProductList() {
    if (mounted) {
      setState(
            () {},
      );
    }
  }

  Future<void> getProduct(String top) async {
    if (readProduct) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var parameter = {
            //CATID: widget.id ?? '',
            SORT: sortBy,
            "order": orderBy,
            LIMIT: perPage.toString(),
            OFFSET: offset.toString(),
            TOP_RETAED: top,
            FLAG: flag
          };
          if (selId != "") {
            parameter[ATTRIBUTE_VALUE_ID] = selId;
          }
          print("parameter : $parameter");

          Response response =
          await post(getProductApi, headers: headers, body: parameter)
              .timeout(const Duration(seconds: timeOut));
          print(
              "API is $getProductApi \n para are $parameter \n response : ${response.body}");

          if (response.statusCode == 200) {
            var getdata = json.decode(response.body);
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              total = int.parse(getdata["total"]);

              if (_isFirstLoad) {
                filterList = getdata["filters"];
                _isFirstLoad = false;
              }

              if ((offset) < total) {
                tempList.clear();

                var data = getdata["data"];
                tempList = (data as List)
                    .map((data) => Product.fromJson(data))
                    .toList();
                getAvailVarient();

                offset = offset + perPage;
              }
            } else {
              if (msg != "Products Not Found !") setsnackbar(msg!, context);
              isLoadingmore = false;
            }
            if (mounted) {
              setState(
                    () {
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
                isLoadingmore = false;
              },
            );
          }
        }
      } else {
        if (mounted) {
          setState(
                () {
              _isNetworkAvail = false;
            },
          );
        }
      }
    } else {
      if (mounted) {
        setState(
              () {
            _isLoading = false;
          },
        );
      }
      Future.delayed(const Duration(microseconds: 500)).then(
            (_) async {
          setsnackbar(getTranslated(context, readProductText)!, context);
        },
      );
    }
    return;
  }

  void getAvailVarient() {
    for (int j = 0; j < tempList.length; j++) {
      if (tempList[j].stockType == "2") {
        for (int i = 0; i < tempList[j].prVarientList!.length; i++) {
          if (tempList[j].prVarientList![i].availability == "1") {
            tempList[j].selVarient = i;

            break;
          }
        }
      }
    }
    productList.addAll(tempList);
  }

  getAppbar() {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: lightWhite,
      iconTheme: const IconThemeData(color: primary),
      title: Text(
        getTranslated(context, PRO_LBL)!,
        style: const TextStyle(
          color: primary,
        ),
      ),
      elevation: 5,
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
                child: const Padding(
                  padding: EdgeInsetsDirectional.only(end: 4.0),
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
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                stockFilter();
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.filter_alt_outlined,
                  color: primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const Search(),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.search,
                  color: primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    listType ? Icons.grid_view : Icons.list,
                    color: primary,
                    size: 22,
                  ),
                ),
                onTap: () {
                  productList.isNotEmpty
                      ? setState(
                        () {
                      listType = !listType;
                    },
                  )
                      : setState(
                        () {},
                  );
                },
              ),
            ),
          ),
        ),
        Container(
          width: 40,
          margin: const EdgeInsetsDirectional.only(top: 10, bottom: 10, end: 5),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: Material(
              color: Colors.transparent,
              child: PopupMenuButton(
                padding: EdgeInsets.zero,
                onSelected: (dynamic value) {
                  switch (value) {
                    case 0:
                      return filterDialog();
                    case 1:
                      return sortDialog();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    value: 0,
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsetsDirectional.only(
                          start: 0.0, end: 0.0),
                      leading: const Icon(
                        Icons.tune,
                        color: fontColor,
                        size: 20,
                      ),
                      title: Text(
                        getTranslated(context, FilterText)!,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: 0.0,
                        end: 0.0,
                      ),
                      leading:
                      const Icon(Icons.sort, color: fontColor, size: 20),
                      title: Text(
                        getTranslated(context, Sort)!,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget productItem(int index, bool pad) {
    if (index < productList.length) {
      Product model = productList[index];

      double price =
      double.parse(model.prVarientList![model.selVarient!].disPrice!);
      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }
      if (_controller.length < index + 1) {
        _controller.add(
          TextEditingController(),
        );
      }

      _controller[index].text =
      model.prVarientList![model.selVarient!].cartCount!;
      items = List<String>.generate(
          model.totalAllow != "" ? int.parse(model.totalAllow!) : 10,
              (i) => (i + 1).toString());

      String stockType = "";
      if (model.stockType == "") {
        stockType = "Not enabled";
      } else if (model.stockType == "1" || model.stockType == "0") {
        stockType = "Global";
      } else if (model.stockType == "2") {
        stockType = "Varient wise";
      }

      double width = deviceWidth * 0.5;

      return Card(
        elevation: 0.2,
        margin: EdgeInsetsDirectional.only(bottom: 5, end: pad ? 5 : 0),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProduct(
                  model: model,
                ),
              ),
            ).then(
                  (value) => () {
                setState(() {
                  _isLoading = true;
                  isLoadingmore = true;
                  offset = 0;
                  total = 0;
                  productList.clear();
                });
                return getProduct("0");
              }(),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
                      child: Hero(
                        tag: "$index${model.id}",
                        child: FadeInImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          image: NetworkImage(model.image!),
                          height: double.maxFinite,
                          width: double.maxFinite,
                          imageErrorBuilder: ((context, error, stackTrace) {
                            return erroWidget(width);
                          }),
                          placeholder: placeHolder(width),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.topStart,
                      child: model.availability == "0"
                          ? Text(
                        getTranslated(context, OutofStock)!,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : Container(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 5.0, top: 5, bottom: 5),
                child: Text(
                  model.name!,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: lightBlack),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text(
                    " ${CUR_CURRENCY!} $price ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  double.parse(model
                      .prVarientList![model.selVarient!].disPrice!) !=
                      0
                      ? Flexible(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            double.parse(model
                                .prVarientList![model.selVarient!]
                                .disPrice!) !=
                                0
                                ? "${CUR_CURRENCY!}${model.prVarientList![model.selVarient!].price!}"
                                : "",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                              decoration: TextDecoration.lineThrough,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : Container()
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Text(
                  '${getTranslated(context, StockType)!}: $stockType',
                ),
              ),
              model.prVarientList![model.selVarient!].stock != ""
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Text(
                  '${getTranslated(context, StockCount)!}: ${model.prVarientList![model.selVarient!].stock ?? ''}',
                  style: const TextStyle(
                    color: fontColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : Container(),
              // model.type == "variable_product"
              //     ? Align(
              //         alignment: Alignment.bottomRight,
              //         child: Padding(
              //           padding: const EdgeInsets.only(right: 5.0),
              //           child: OutlinedButton(
              //             onPressed: () {
              //               Product model = productList[index];
              //               _chooseVarient(model);
              //             },
              //             child: Text(
              //               getTranslated(context, SelectVarient)!,
              //             ),
              //           ),
              //         ),
              //       )
              //     : Container()
              InkWell(
                onTap: () {
                  productDeletDialog(
                    model.name!,
                    model.id!,
                  );
                },
                child: const Icon(
                  Icons.delete,
                  color: red,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  // void _chooseVarient(Product model) {
  //   bool? available, outOfStock;
  //   int? selectIndex = 0;
  //   List<int?> _selectedIndex = [];
  //   ChoiceChip choiceChip;
  //   int? _oldSelVarient = 0;
  //   _selectedIndex.clear();
  //   if (model.stockType == "0" || model.stockType == "1") {
  //     if (model.availability == "1") {
  //       available = true;
  //       outOfStock = false;
  //       _oldSelVarient = model.selVarient;
  //     } else {
  //       available = false;
  //       outOfStock = true;
  //     }
  //   } else if (model.stockType == "") {
  //     available = true;
  //     outOfStock = false;
  //     _oldSelVarient = model.selVarient;
  //   } else if (model.stockType == "2") {
  //     if (model.prVarientList![model.selVarient!].availability == "1") {
  //       available = true;
  //       outOfStock = false;
  //       _oldSelVarient = model.selVarient;
  //     } else {
  //       available = false;
  //       outOfStock = true;
  //     }
  //   }

  //   List<String> selList =
  //       model.prVarientList![model.selVarient!].attribute_value_ids!.split(",");

  //   for (int i = 0; i < model.attributeList!.length; i++) {
  //     List<String> sinList = model.attributeList![i].id!.split(',');

  //     for (int j = 0; j < sinList.length; j++) {
  //       if (selList.contains(sinList[j])) {
  //         _selectedIndex.insert(i, j);
  //       }
  //     }

  //     if (_selectedIndex.length == i) _selectedIndex.insert(i, null);
  //   }

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(10),
  //         topRight: Radius.circular(
  //           10,
  //         ),
  //       ),
  //     ),
  //     builder: (builder) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return Container(
  //             constraints: BoxConstraints(
  //                 maxHeight: MediaQuery.of(context).size.height * 0.9),
  //             child: ListView(
  //               shrinkWrap: true,
  //               children: <Widget>[
  //                 Padding(
  //                   padding: const EdgeInsets.all(15.0),
  //                   child: Text(
  //                     getTranslated(context, SelectVarient)!,
  //                     style: Theme.of(context).textTheme.headline6,
  //                   ),
  //                 ),
  //                 Divider(),
  //                 _title(model.name!),
  //                 available! || outOfStock!
  //                     ? _price(model.prVarientList![_oldSelVarient!].disPrice!,
  //                         model.prVarientList![_oldSelVarient!].price)
  //                     : Container(),
  //                 available! || outOfStock!
  //                     ? _offPrice(
  //                         model.prVarientList![_oldSelVarient!].disPrice!,
  //                         model.prVarientList![_oldSelVarient!].price)
  //                     : Container(),
  //                 ListView.builder(
  //                   shrinkWrap: true,
  //                   physics: NeverScrollableScrollPhysics(),
  //                   itemCount: model.attributeList!.length,
  //                   itemBuilder: (context, index) {
  //                     List<Widget> chips = [];
  //                     List<String> att =
  //                         model.attributeList![index].value!.split(',');
  //                     List<String> attId =
  //                         model.attributeList![index].id!.split(',');
  //                     List<String> attSType =
  //                         model.attributeList![index].sType!.split(',');

  //                     List<String> attSValue =
  //                         model.attributeList![index].sValue!.split(',');

  //                     int? varSelected;

  //                     List<String> wholeAtt = model.attrIds!.split(',');
  //                     for (int i = 0; i < att.length; i++) {
  //                       Widget itemLabel;
  //                       if (attSType[i] == "1") {
  //                         String clr = (attSValue[i].substring(1));

  //                         String color = "0xff" + clr;

  //                         itemLabel = Container(
  //                           width: 25,
  //                           decoration: BoxDecoration(
  //                               shape: BoxShape.circle,
  //                               color: Color(int.parse(color))),
  //                         );
  //                       } else if (attSType[i] == "2") {
  //                         itemLabel = ClipRRect(
  //                           borderRadius: BorderRadius.circular(10.0),
  //                           child: Image.network(
  //                             attSValue[i],
  //                             width: 80,
  //                             height: 80,
  //                             errorBuilder: (context, error, stackTrace) =>
  //                                 erroWidget(80),
  //                           ),
  //                         );
  //                       } else {
  //                         itemLabel = Text(
  //                           att[i],
  //                           style: TextStyle(
  //                             color: _selectedIndex[index] == (i)
  //                                 ? fontColor
  //                                 : white,
  //                           ),
  //                         );
  //                       }

  //                       if (_selectedIndex[index] != null) if (wholeAtt
  //                           .contains(attId[i])) {
  //                         choiceChip = ChoiceChip(
  //                           selected: _selectedIndex.length > index
  //                               ? _selectedIndex[index] == i
  //                               : false,
  //                           label: itemLabel,
  //                           labelPadding: EdgeInsets.all(0),
  //                           selectedColor: fontColor.withOpacity(0.1),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(
  //                                 attSType[i] == "1" ? 100 : 10),
  //                             side: BorderSide(
  //                                 color: _selectedIndex[index] == (i)
  //                                     ? fontColor
  //                                     : fontColor.withOpacity(0.8),
  //                                 width: 1.5),
  //                           ),
  //                           onSelected: att.length == 1
  //                               ? null
  //                               : (bool selected) {
  //                                   if (selected) if (mounted)
  //                                     setState(
  //                                       () {
  //                                         available = false;
  //                                         _selectedIndex[index] =
  //                                             selected ? i : null;
  //                                         List<int> selectedId =
  //                                             []; //list where user choosen item id is stored
  //                                         List<bool> check = [];
  //                                         for (int i = 0;
  //                                             i < model.attributeList!.length;
  //                                             i++) {
  //                                           List<String> attId = model
  //                                               .attributeList![i].id!
  //                                               .split(',');

  //                                           if (_selectedIndex[i] != null)
  //                                             selectedId.add(int.parse(
  //                                                 attId[_selectedIndex[i]!]));
  //                                         }
  //                                         check.clear();
  //                                         late List<String> sinId;
  //                                         findMatch:
  //                                         for (int i = 0;
  //                                             i < model.prVarientList!.length;
  //                                             i++) {
  //                                           sinId = model.prVarientList![i]
  //                                               .attribute_value_ids!
  //                                               .split(",");

  //                                           for (int j = 0;
  //                                               j < selectedId.length;
  //                                               j++) {
  //                                             if (sinId.contains(
  //                                                 selectedId[j].toString())) {
  //                                               check.add(true);

  //                                               if (selectedId.length ==
  //                                                       sinId.length &&
  //                                                   check.length ==
  //                                                       selectedId.length) {
  //                                                 varSelected = i;
  //                                                 selectIndex = i;
  //                                                 break findMatch;
  //                                               }
  //                                             } else {
  //                                               check.clear();
  //                                               selectIndex = null;
  //                                               break;
  //                                             }
  //                                           }
  //                                         }

  //                                         if (selectedId.length ==
  //                                                 sinId.length &&
  //                                             check.length ==
  //                                                 selectedId.length) {
  //                                           if (model.stockType == "0" ||
  //                                               model.stockType == "1") {
  //                                             if (model.availability == "1") {
  //                                               available = true;
  //                                               outOfStock = false;
  //                                               _oldSelVarient = varSelected;
  //                                             } else {
  //                                               available = false;
  //                                               outOfStock = true;
  //                                             }
  //                                           } else if (model.stockType == "") {
  //                                             available = true;
  //                                             outOfStock = false;
  //                                             _oldSelVarient = varSelected;
  //                                           } else if (model.stockType == "2") {
  //                                             if (model
  //                                                     .prVarientList![
  //                                                         varSelected!]
  //                                                     .availability ==
  //                                                 "1") {
  //                                               available = true;
  //                                               outOfStock = false;
  //                                               _oldSelVarient = varSelected;
  //                                             } else {
  //                                               available = false;
  //                                               outOfStock = true;
  //                                             }
  //                                           }
  //                                         } else {
  //                                           available = false;
  //                                           outOfStock = false;
  //                                         }
  //                                       },
  //                                     );
  //                                 },
  //                         );

  //                         chips.add(choiceChip);
  //                       }
  //                     }

  //                     String value = _selectedIndex[index] != null &&
  //                             _selectedIndex[index]! <= att.length
  //                         ? att[_selectedIndex[index]!]
  //                         : getTranslated(context, pleaseSelect)!;

  //                     return chips.length > 0
  //                         ? Padding(
  //                             padding: const EdgeInsets.all(8.0),
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: <Widget>[
  //                                 Text(
  //                                   model.attributeList![index].name! +
  //                                       " : " +
  //                                       value,
  //                                   style:
  //                                       TextStyle(fontWeight: FontWeight.bold),
  //                                 ),
  //                                 new Wrap(
  //                                   children: chips.map<Widget>(
  //                                     (Widget chip) {
  //                                       return Padding(
  //                                         padding: const EdgeInsets.all(2.0),
  //                                         child: chip,
  //                                       );
  //                                     },
  //                                   ).toList(),
  //                                 ),
  //                               ],
  //                             ),
  //                           )
  //                         : Container();
  //                   },
  //                 ),
  //                 available == false || outOfStock == true
  //                     ? Center(
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(5.0),
  //                           child: Text(
  //                             outOfStock == true
  //                                 ? getTranslated(context, OutofStock)!
  //                                 : getTranslated(context, variantdoestexist)!,
  //                             style: TextStyle(color: Colors.red),
  //                           ),
  //                         ),
  //                       )
  //                     : Container(),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  _price(String disPrice, String? price1) {
    double price = double.parse(disPrice);
    if (price == 0) price = double.parse(price1!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Text(
        "${CUR_CURRENCY!} $price",
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  _offPrice(String disPrice, String? price1) {
    double price = double.parse(disPrice);

    if (price != 0) {
      double off = (double.parse(price1!) - double.parse(disPrice)).toDouble();
      off = off * 100 / double.parse(price1);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: <Widget>[
            Text(
              "${CUR_CURRENCY!} $price1",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                decoration: TextDecoration.lineThrough,
                letterSpacing: 0,
              ),
            ),
            Text(
              " | ${off.toStringAsFixed(2)}% off",
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: primary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  _title(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Text(
        name,
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: lightBlack),
      ),
    );
  }

  void stockFilter() {
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
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            contentPadding: const EdgeInsets.all(0.0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                        top: 19.0, bottom: 16.0),
                    child: Text(
                      getTranslated(context, StockFilter)!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(color: lightBlack),
                  TextButton(
                    child: Text(
                      getTranslated(context, All)!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: lightBlack,
                      ),
                    ),
                    onPressed: () {
                      flag = '';
                      if (mounted) {
                        setState(
                              () {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          },
                        );
                      }
                      getProduct("0");
                      Navigator.pop(context, 'option 1');
                    },
                  ),
                  const Divider(color: lightBlack),
                  TextButton(
                    child: Text(
                      getTranslated(context, SOLD_LBL)!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: lightBlack,
                      ),
                    ),
                    onPressed: () {
                      flag = 'sold';
                      if (mounted) {
                        setState(() {
                          _isLoading = true;
                          total = 0;
                          offset = 0;
                          productList.clear();
                        });
                      }
                      getProduct("0");
                      Navigator.pop(context, 'option 1');
                    },
                  ),
                  const Divider(color: lightBlack),
                  TextButton(
                    child: Text(
                      getTranslated(context, LOW_LBL)!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: lightBlack,
                      ),
                    ),
                    onPressed: () {
                      flag = 'low';
                      if (mounted) {
                        setState(
                              () {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          },
                        );
                      }
                      getProduct("0");
                      Navigator.pop(context, 'option 2');
                    },
                  ),
                  const Divider(color: white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void sortDialog() {
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
              borderRadius: BorderRadius.all(
                Radius.circular(
                  5.0,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.all(0.0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: const EdgeInsetsDirectional.only(
                          top: 19.0, bottom: 16.0),
                      child: Text(
                        getTranslated(context, soartBy)!,
                        style: Theme.of(context).textTheme.titleLarge,
                      )),
                  const Divider(color: lightBlack),
                  TextButton(
                    child: Text(
                      getTranslated(context, topRated)!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: lightBlack,
                      ),
                    ),
                    onPressed: () {
                      sortBy = '';
                      orderBy = 'DESC';
                      flag = '';
                      if (mounted) {
                        setState(
                              () {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          },
                        );
                      }
                      getProduct("1");
                      Navigator.pop(context, 'option 1');
                    },
                  ),
                  const Divider(color: lightBlack),
                  TextButton(
                    child: Text(
                      getTranslated(context, newestFirst)!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: lightBlack,
                      ),
                    ),
                    onPressed: () {
                      sortBy = 'p.date_added';
                      orderBy = 'DESC';
                      flag = '';
                      if (mounted) {
                        setState(
                              () {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          },
                        );
                      }
                      getProduct("0");
                      Navigator.pop(context, 'option 1');
                    },
                  ),
                  const Divider(color: lightBlack),
                  TextButton(
                    child: Text(
                      getTranslated(context, oldestFirst)!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: lightBlack,
                      ),
                    ),
                    onPressed: () {
                      sortBy = 'p.date_added';
                      orderBy = 'ASC';
                      flag = '';
                      if (mounted) {
                        setState(
                              () {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          },
                        );
                      }
                      getProduct("0");
                      Navigator.pop(context, 'option 2');
                    },
                  ),
                  const Divider(color: lightBlack),
                  TextButton(
                    child: Text(
                      getTranslated(context, pricelowtoHigh)!,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: lightBlack),
                    ),
                    onPressed: () {
                      sortBy = 'pv.price';
                      orderBy = 'ASC';
                      flag = '';
                      if (mounted) {
                        setState(
                              () {
                            _isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          },
                        );
                      }
                      getProduct("0");
                      Navigator.pop(context, 'option 3');
                    },
                  ),
                  const Divider(color: lightBlack),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 5.0),
                    child: TextButton(
                      child: Text(
                        getTranslated(context, pricehightolow)!,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: lightBlack),
                      ),
                      onPressed: () {
                        sortBy = 'pv.price';
                        orderBy = 'DESC';
                        flag = '';
                        if (mounted) {
                          setState(
                                () {
                              _isLoading = true;
                              total = 0;
                              offset = 0;
                              productList.clear();
                            },
                          );
                        }
                        getProduct("0");
                        Navigator.pop(context, 'option 4');
                      },
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

  _scrollListener() {
    setState(() {
      _isButtonExtended =
          controller.position.userScrollDirection == ScrollDirection.forward;
    });

    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(
                () {
              isLoadingmore = true;

              if (offset < total) getProduct("0");
            },
          );
        }
      }
    }
  }

  Future<void> _refresh() {
    if (mounted) {
      setState(
            () {
          _isLoading = true;
          isLoadingmore = true;
          offset = 0;
          total = 0;
          productList.clear();
        },
      );
    }
    return getProduct("0");
  }

  _showForm() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refresh,
      child: listType
          ? ListView.builder(
        controller: controller,
        itemCount: (offset < total)
            ? productList.length + 1
            : productList.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return (index == productList.length && isLoadingmore)
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : listItem(index);
        },
      )
          : GridView.count(
        padding: const EdgeInsetsDirectional.only(top: 5),
        crossAxisCount: 2,
        controller: controller,
        childAspectRatio: 0.8,
        physics: const AlwaysScrollableScrollPhysics(),
        children: List.generate(
          (offset < total) ? productList.length + 1 : productList.length,
              (index) {
            return (index == productList.length && isLoadingmore)
                ? shimmer2()
            // ? const Center(
            //     child: CircularProgressIndicator(),
            //   )
                : productItem(index, index % 2 == 0 ? true : false);
          },
        ),
      ),
    );
  }

  void filterDialog() {
    if (filterList!.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        enableDrag: false,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        builder: (builder) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 30.0),
                    child: AppBar(
                      backgroundColor: lightWhite,
                      title: Text(
                        getTranslated(context, FilterText)!,
                        style: const TextStyle(
                          color: fontColor,
                        ),
                      ),
                      elevation: 5,
                      leading: Builder(builder: (BuildContext context) {
                        return Container(
                          margin: const EdgeInsets.all(10),
                          decoration: shadow(),
                          child: Card(
                            elevation: 0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => Navigator.of(context).pop(),
                              child: const Padding(
                                padding: EdgeInsetsDirectional.only(end: 4.0),
                                child: Icon(
                                  Icons.arrow_back_ios_outlined,
                                  color: primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      actions: [
                        Container(
                          margin: const EdgeInsetsDirectional.only(end: 10.0),
                          alignment: Alignment.center,
                          child: InkWell(
                            child: Text(
                              getTranslated(context, clearFilters)!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                fontWeight: FontWeight.normal,
                                color: fontColor,
                              ),
                            ),
                            onTap: () {
                              if (mounted) {
                                setState(
                                      () {
                                    selectedId.clear();
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: lightWhite,
                      padding: const EdgeInsetsDirectional.only(
                          start: 7.0, end: 7.0, top: 7.0),
                      child: Card(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                color: lightWhite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 10.0),
                                  itemCount: filterList!.length,
                                  itemBuilder: (context, index) {
                                    attsubList = filterList![index]
                                    ['attribute_values']
                                        .split(',');

                                    attListId = filterList![index]
                                    ['attribute_values_id']
                                        .split(',');

                                    if (filter == "") {
                                      filter = filterList![0]["name"];
                                    }

                                    return InkWell(
                                      onTap: () {
                                        if (mounted) {
                                          setState(
                                                () {
                                              filter =
                                              filterList![index]['name'];
                                            },
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding:
                                        const EdgeInsetsDirectional.only(
                                            start: 20,
                                            top: 10.0,
                                            bottom: 10.0),
                                        decoration: BoxDecoration(
                                          color: filter ==
                                              filterList![index]['name']
                                              ? white
                                              : lightWhite,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(7),
                                            bottomLeft: Radius.circular(7),
                                          ),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          filterList![index]['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                              color: filter ==
                                                  filterList![index]
                                                  ['name']
                                                  ? fontColor
                                                  : lightBlack,
                                              fontWeight:
                                              FontWeight.normal),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding:
                                const EdgeInsetsDirectional.only(top: 10.0),
                                scrollDirection: Axis.vertical,
                                itemCount: filterList!.length,
                                itemBuilder: (context, index) {
                                  if (filter == filterList![index]["name"]) {
                                    attsubList = filterList![index]
                                    ['attribute_values']
                                        .split(',');

                                    attListId = filterList![index]
                                    ['attribute_values_id']
                                        .split(',');
                                    return Container(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                        const NeverScrollableScrollPhysics(),
                                        itemCount: attListId!.length,
                                        itemBuilder: (context, i) {
                                          return CheckboxListTile(
                                            dense: true,
                                            title: Text(
                                              attsubList![i],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                  color: lightBlack,
                                                  fontWeight:
                                                  FontWeight.normal),
                                            ),
                                            value: selectedId
                                                .contains(attListId![i]),
                                            activeColor: primary,
                                            controlAffinity:
                                            ListTileControlAffinity.leading,
                                            onChanged: (bool? val) {
                                              if (mounted) {
                                                setState(
                                                      () {
                                                    if (val == true) {
                                                      selectedId
                                                          .add(attListId![i]);
                                                    } else {
                                                      selectedId.remove(
                                                          attListId![i]);
                                                    }
                                                  },
                                                );
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  } else {
                                    return Container();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    color: white,
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding:
                          const EdgeInsetsDirectional.only(start: 15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(total.toString()),
                              Text(
                                getTranslated(context, productsFound)!,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SimBtn(
                          size: 0.4,
                          title: getTranslated(context, apply)!,
                          onBtnSelected: () {
                            if (selectedId.isNotEmpty) {
                              selId = selectedId.join(',');
                            }

                            if (mounted) {
                              setState(
                                    () {
                                  _isLoading = true;
                                  total = 0;
                                  offset = 0;
                                  productList.clear();
                                },
                              );
                            }
                            getProduct("0");
                            Navigator.pop(context, 'Product Filter');
                          },
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          );
        },
      );
    }
  }
}

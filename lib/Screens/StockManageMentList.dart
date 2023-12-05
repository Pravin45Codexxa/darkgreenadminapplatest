import 'dart:async';
import 'dart:convert';
import 'package:admin_eshop/Helper/String.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/ShowOverlay.dart';
import '../Helper/SimBtn.dart';
import '../Model/Section_Model.dart';

class StockManagementList extends StatefulWidget {
  const StockManagementList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProductStock();
}

bool isUpdateDone = false;

final TextEditingController controllerForStock = TextEditingController();

class StateProductStock extends State<StockManagementList>
    with TickerProviderStateMixin {
  bool isLoading = true, isProgress = false;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  List<Product> productList = [];
  List<Product> tempList = [];
  String? sortBy = 'p.id', orderBy = "DESC";
  int offset = 0;
  int total = 0;
  String? totalProduct;
  bool isLoadingmore = true;
  ScrollController controller = ScrollController();
  List<dynamic>? filterList = [];
  List<String>? attnameList;
  List<String>? attsubList;
  List<String>? attListId;
  List<String> selectedId = [];
  bool isFirstLoad = true;
  String? filter = "";
  String selId = "";
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool listType = true;
  final List<TextEditingController> controllers = [];
  var items;
  bool isNetworkAvail = true;

  initializaedVariableWithDefualtValue() {
    isLoading = true;
    isProgress = false;
    productList = [];
    tempList = [];
    sortBy = 'p.id';
    orderBy = "DESC";
    offset = 0;
    total = 0;
    totalProduct = null;
    isLoadingmore = true;
    filterList = [];
    attnameList = null;
    attsubList = null;
    attListId = null;
    selectedId = [];
    isFirstLoad = true;
    filter = "";
    selId = "";
    listType = true;
    items = null;
  }

  @override
  void initState() {
    super.initState();
    controllerForStock.text = '';

    initializaedVariableWithDefualtValue();
    controller.addListener(_scrollListener);
    getProduct("0", context);
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
    controller.removeListener(() {});
    for (int i = 0; i < controllers.length; i++) {
      controllers[i].dispose();
    }
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      //
    }
  }

  Future<void> getProduct(
    String top,
    BuildContext context,
  ) async {
    if (readProduct) {
      isNetworkAvail = await isNetworkAvailable();
      if (isNetworkAvail) {
        var parameter = {
          //CATID: widget.id ?? '',
          USER_ID: CUR_USERID,
          SORT: sortBy,
          ORDER: orderBy,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          TOP_RETAED: top,
          'show_only_active_products': "0",
          //'show_only_stock_product': '1',
        };
        if (selId != "") {
          parameter[ATTRIBUTE_VALUE_ID] = selId;
        }
        print("param****product***$parameter");
        Response response =
            await post(getProductApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));
        print("response statuscode***${response.statusCode}");
        /* var result =
        await ProductListRepository.getProduct(parameter: parameter);*/

        var result = json.decode(response.body);

        bool error = result["error"];
        if (!error) {
          total = int.parse(result["total"]);
          print("total****$total");

          if (isFirstLoad) {
            filterList = result["filters"];
            isFirstLoad = false;
          }
          if ((offset) < total) {
            tempList.clear();
            var data = result["data"];
            tempList =
                (data as List).map((data) => Product.fromJson(data)).toList();
            getAvailVarient();
            offset = offset + perPage;
          }
        } else {
          isLoadingmore = false;
        }
        isLoading = false;
        setState(() {});
      } else {
        isNetworkAvail = false;
        setState(() {});
      }
    } else {
      isLoading = false;
      setState(() {});

      Future.delayed(const Duration(microseconds: 500)).then(
        (_) async {
          setsnackbar(
              'You have not authorized permission for read Product!!', context);
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

  AppBar getAppbar() {
    return AppBar(
      title: Text(
        getTranslated(context, StockManagementText)!,
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
        Material(
          color: Colors.transparent,
          child: PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
              color: primary,
              size: 18,
            ),
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
                  contentPadding:
                      const EdgeInsetsDirectional.only(start: 0.0, end: 0.0),
                  leading: const Icon(
                    Icons.tune,
                    color: fontColor,
                    size: 25,
                  ),
                  title: Text(getTranslated(context, FilterText)!),
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsetsDirectional.only(start: 0.0, end: 0.0),
                  leading: const Icon(Icons.sort, color: fontColor, size: 20),
                  title: Text(getTranslated(context, Sort)!),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightWhite,
      appBar: getAppbar(),
      key: scaffoldKey,
      body: isNetworkAvail
          ? Stack(
              children: <Widget>[
                _showForm(),
                showCircularProgress(
                  isProgress,
                  primary,
                ),
              ],
            )
          : noInternet(
              context,
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
              title: getTranslated(context, NO_INTERNET)!,
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();

                Future.delayed(const Duration(seconds: 2)).then(
                  (_) async {
                    isNetworkAvail = await isNetworkAvailable();
                    if (isNetworkAvail) {
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

  /* setStateNoInternate() async {
    _playAnimation();
    Future.delayed(const Duration(seconds: 2)).then(
      (_) async {
        isNetworkAvail = await isNetworkAvailable();
        if (isNetworkAvail) {
          offset = 0;
          total = 0;
          getProduct('0', context);
        } else {
          await buttonController!.reverse();
          if (mounted) setState(() {});
        }
      },
    );
  }*/

  Future<void> manageStockDialog(
    BuildContext context,
    String title,
    String stockValue,
    String variantId,
  ) async {
    controllerForStock.text = '0';
    bool? addValue = true;
    bool selectTypeValue = false;
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (
            BuildContext ctx,
            StateSetter setState,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: deviceWidth * 0.8,
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: fontColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                              },
                              child: const Icon(
                                Icons.close,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                getTranslated(context, CurrentStockText)!,
                              ),
                              Container(
                                width: 80,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: lightWhite,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: lightBlack2,
                                    style: BorderStyle.solid,
                                    width: 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    stockValue == '' ? '0' : stockValue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(getTranslated(context, QUANTITY_LBL)!),
                              Row(
                                children: [
                                  InkWell(
                                      onTap: () {
                                        int temp =
                                            int.parse(controllerForStock.text);
                                        // stockFocus!.unfocus();
                                        controllerForStock.text = temp == 0
                                            ? '1'
                                            : (temp + 1).toString();
                                        setState(() {});
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: lightBlack2,
                                            style: BorderStyle.solid,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(5.0),
                                          child: Icon(
                                            Icons.add,
                                            color: fontColor,
                                            size: 18,
                                          ),
                                        ),
                                      )),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  SizedBox(
                                    width: deviceWidth * 0.2,
                                    height: 25,
                                    child: Center(
                                      child: TextFormField(
                                        controller: controllerForStock,
                                        /*onFieldSubmitted: (v) {
                                          FocusScope.of(context)
                                              .requestFocus(stockFocus);
                                        },*/
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          color: fontColor,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        // focusNode: stockFocus,
                                        onSaved: (value) {
                                          // stockFocus!.unfocus();
                                        },
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          counterText: "",
                                          counterStyle: const TextStyle(
                                              height: double.minPositive),
                                          filled: true,
                                          fillColor: lightWhite,
                                          prefixIconConstraints:
                                              const BoxConstraints(
                                                  minWidth: 40, maxHeight: 20),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: fontColor),
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: lightWhite),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  InkWell(
                                      onTap: () {
                                        int temp =
                                            int.parse(controllerForStock.text);
                                        if (controllerForStock.text == '' ||
                                            controllerForStock.text == '0') {
                                          controllerForStock.text = '0';
                                        } else {
                                          controllerForStock.text =
                                              (temp - 1).toString();
                                        }
                                        setState(() {});
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: lightBlack2,
                                            style: BorderStyle.solid,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(5.0),
                                          child: Icon(
                                            Icons.remove,
                                            color: fontColor,
                                            size: 18,
                                          ),
                                        ),
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(getTranslated(context, TypeText)!),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      addValue = true;
                                      setState(() {});
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: addValue == null
                                            ? white
                                            : addValue!
                                                ? primary
                                                : white,
                                        border: Border.all(
                                          color: fontColor,
                                          style: BorderStyle.solid,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(1.0),
                                        child: Icon(
                                          Icons.done,
                                          color: white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                      vertical: 2.0,
                                    ),
                                    child:
                                        Text(getTranslated(context, AddText)!),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  InkWell(
                                    onTap: () {
                                      addValue = false;
                                      setState(() {});
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: addValue == null
                                            ? white
                                            : addValue!
                                                ? white
                                                : primary,
                                        border: Border.all(
                                          color: fontColor,
                                          style: BorderStyle.solid,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(1.0),
                                        child: Icon(
                                          Icons.done,
                                          color: white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                      vertical: 2.0,
                                    ),
                                    child: Text(
                                      getTranslated(context, SubtractText)!,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        selectTypeValue
                            ? Text(
                                getTranslated(context, NoteSelectTypeText)!,
                                style: const TextStyle(color: red),
                              )
                            : Container(),
                        SimBtn(
                          onBtnSelected: () {
                            if (addValue == null) {
                              selectTypeValue = true;
                              setState(() {});
                            } else if (addValue == false &&
                                int.parse(controllerForStock.text.toString()) >
                                    (stockValue == ''
                                        ? 0
                                        : int.parse(stockValue))) {
                              showOverlay(
                                getTranslated(context, QtySubtractWarningText)!,
                                context,
                              );
                            } else if (controllerForStock.text == '' ||
                                controllerForStock.text == '0') {
                              selectTypeValue = false;
                              setState(() {});
                            } else {
                              print(
                                  "submit********************************$addValue***${controllerForStock.text}");
                              selectTypeValue = false;
                              isUpdateDone = true;
                              setState(() {});
                              Navigator.pop(ctx);
                              setStockValue(
                                variantId,
                                context,
                                addValue!,
                                controllerForStock.text.toString(),
                                stockValue,
                              );
                            }
                          },
                          title: getTranslated(context, SubmitText)!,
                          size: 50,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> setStockValue(
    String productVariantIdValue,
    BuildContext context,
    bool isAddValue,
    String quanntity,
    String currentStock,
  ) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      setState(() {
        isLoading = true;
      });
      var parameter = {
        PRODUCT_VARIENT_ID: productVariantIdValue,
        QUANTITY: quanntity,
        TYPE: isAddValue ? 'add' : 'subtract',
        'current_stock': currentStock,
      };

      print("set parameter: " + parameter.toString());

      Response response =
          await post(manageStockApi, body: parameter, headers: headers)
              .timeout(const Duration(seconds: timeOut));
      var result = json.decode(response.body);

      bool error = result["error"];
      String msg = result["message"];

      setsnackbar(msg, context);

      isLoading = false;
    } else {
      isNetworkAvail = false;
    }
    return;
  }

  Widget listItem(int index) {
    if (index < productList.length) {
      Product? model = productList[index];
      totalProduct = model.total;
      String stockType = '';
      if (model.stockType == "null") {
        stockType = "Not enabled";
      } else if (model.stockType == "1" || model.stockType == "0") {
        stockType = "Global";
      } else if (model.stockType == "2") {
        stockType = "Varient wise";
      }
      if (controllers.length < index + 1) {
        controllers.add(TextEditingController());
      }
      if (model.prVarientList!.isNotEmpty) {
        controllers[index].text =
            model.prVarientList![model.selVarient!].cartCount!;
        double price =
            double.parse(model.prVarientList![model.selVarient!].disPrice!);
        if (price == 0) {
          price = double.parse(model.prVarientList![model.selVarient!].price!);
        }
      }
      items = List<String>.generate(
          model.totalAllow != "" ? int.parse(model.totalAllow!) : 10,
          (i) => (i + 1).toString());
      return Padding(
        padding: const EdgeInsets.only(
          right: 15.0,
          left: 15.0,
          top: 13,
        ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: lightBlack.withOpacity(0.3),
                  offset: const Offset(0, 0),
                  blurRadius: 4,
                  spreadRadius: 0),
            ],
            color: white,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: InkWell(
            onTap: () {
              if (model.stockType == "2") {
              } else {
                manageStockDialog(
                  context,
                  model.name!,
                  model.stockType == "1"
                      ? model.prVarientList!.isNotEmpty
                          ? model.prVarientList![0].stock ?? ''
                          : model.stock ?? ""
                      : model.stock ?? '',
                  model.prVarientList!.isNotEmpty
                      ? model.prVarientList![0].id!
                      : model.id!,
                ).then(
                  (value) async {
                    if (isUpdateDone) {
                      isUpdateDone = false;
                      if (mounted) {
                        setState(
                          () {
                            isLoading = true;
                            offset = 0;
                            total = 0;
                            productList.clear();
                          },
                        );
                      }
                      Future.delayed(const Duration(
                        seconds: 01,
                      )).then(
                        (_) {
                          getProduct("0", context);
                        },
                      );
                    } else {
                      isUpdateDone = false;
                      setState(() {});
                    }
                  },
                );
              }
            },
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        top: 12.0,
                        start: 12.0,
                        end: 12.0,
                        bottom: 5.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: 12.0,
                            ),
                            child: Hero(
                              tag: "$index${model.id}+ $index${model.name}",
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: FadeInImage.assetNetwork(
                                    image: model.image!,
                                    placeholder:
                                        'assets/images/placeholder.png',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    fadeInDuration: const Duration(
                                      milliseconds: 150,
                                    ),
                                    fadeOutDuration: const Duration(
                                      milliseconds: 150,
                                    ),
                                    fadeInCurve: Curves.linear,
                                    fadeOutCurve: Curves.linear,
                                    imageErrorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        child: erroWidget(70),
                                      );
                                    },
                                  )),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(
                                    model.name!,
                                    style: const TextStyle(
                                      color: fontColor,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                model.prVarientList!.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0),
                                        child: Row(
                                          children: <Widget>[
                                            Text(
                                                "${getTranslated(context, PRICE_LBL)} : ",
                                                style: const TextStyle(
                                                  color: lightBlack2,
                                                  fontWeight: FontWeight.w400,
                                                  fontStyle: FontStyle.normal,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.left),
                                            model.prVarientList!.isNotEmpty
                                                ? Text(
                                                    double.parse(model
                                                                .prVarientList![
                                                                    model
                                                                        .selVarient!]
                                                                .disPrice!) !=
                                                            0
                                                        ? "${CUR_CURRENCY!} ${double.parse(model.prVarientList![model.selVarient!].disPrice!)}"
                                                        : "",
                                                    style: const TextStyle(
                                                        color: fontColor,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontStyle:
                                                            FontStyle.normal,
                                                        fontSize: 14),
                                                  )
                                                : Container(),
                                          ],
                                        ),
                                      )
                                    : Container(),
                                Row(
                                  children: [
                                    Text(
                                      '${getTranslated(context, Quantity)} : ',
                                      style: const TextStyle(
                                        color: lightBlack2,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                    model.prVarientList!.isNotEmpty
                                        ? Text(
                                            model.stockType == "2"
                                                ? model.stock == null ||
                                                        model.stock! == ""
                                                    ? "0"
                                                    : model.stock!
                                                : model.stockType == "1"
                                                    ? model.prVarientList![0]
                                                                    .stock ==
                                                                null ||
                                                            model
                                                                    .prVarientList![
                                                                        0]
                                                                    .stock ==
                                                                ""
                                                        ? "0"
                                                        : model
                                                            .prVarientList![0]
                                                            .stock!
                                                    : model.stock == null ||
                                                            model.stock! == ""
                                                        ? "0"
                                                        : model.stock!,
                                            style: const TextStyle(
                                              color: fontColor,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                            ),
                                          )
                                        : Text(
                                            model.stockType == "2"
                                                ? model.stock == null ||
                                                        model.stock! == ""
                                                    ? "0"
                                                    : model.stock!
                                                : model.stockType == "1"
                                                    ? model.stock == null ||
                                                            model.stock == ""
                                                        ? "0"
                                                        : model.stock!
                                                    : model.stock == null ||
                                                            model.stock! == ""
                                                        ? "0"
                                                        : model.stock!,
                                            style: const TextStyle(
                                              color: fontColor,
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: 14,
                                            ),
                                          )
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    model.stockType == "2"
                        ? SizedBox(
                            width: deviceWidth,
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              direction: Axis.horizontal,
                              children: model.prVarientList!.map(
                                (value) {
                                  return InkWell(
                                    onTap: () {
                                      //
                                      manageStockDialog(
                                        context,
                                        value.varient_value!,
                                        value.stock ?? '',
                                        value.id!,
                                      ).then(
                                        (value) async {
                                          if (isUpdateDone) {
                                            isUpdateDone = false;
                                            if (mounted) {
                                              setState(
                                                () {
                                                  isLoading = true;
                                                  offset = 0;
                                                  total = 0;
                                                  productList.clear();
                                                },
                                              );
                                            }
                                            Future.delayed(const Duration(
                                              seconds: 01,
                                            )).then(
                                              (_) {
                                                getProduct("0", context);
                                              },
                                            );
                                          } else {
                                            isUpdateDone = false;
                                            setState(() {});
                                          }
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                        left: 8.0,
                                        top: 0.0,
                                        bottom: 8.0,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.transparent,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: RichText(
                                            text: TextSpan(
                                              text: '${value.varient_value!}  ',
                                              style: const TextStyle(
                                                color: white,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: value.stock != ''
                                                      ? '(${value.stock})'
                                                      : '',
                                                  style: const TextStyle(
                                                    color: white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
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
                  5,
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
                    ),
                  ),
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
                      if (mounted) {
                        setState(
                          () {
                            isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          },
                        );
                      }

                      getProduct("1", context);
                      Navigator.pop(context, 'option 1');
                    },
                  ),
                  const Divider(color: lightBlack),
                  TextButton(
                      child: Text(
                        getTranslated(context, newestFirst)!,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: lightBlack,
                                ),
                      ),
                      onPressed: () {
                        sortBy = 'p.date_added';
                        orderBy = 'DESC';
                        if (mounted) {
                          setState(() {
                            isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                        }

                        getProduct("0", context);
                        Navigator.pop(context, 'option 1');
                      }),
                  const Divider(color: lightBlack),
                  TextButton(
                      child: Text(
                        getTranslated(context, oldestFirst)!,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: lightBlack),
                      ),
                      onPressed: () {
                        sortBy = 'p.date_added';
                        orderBy = 'ASC';
                        if (mounted) {
                          setState(() {
                            isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                        }
                        getProduct("0", context);
                        Navigator.pop(context, 'option 2');
                      }),
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
                        if (mounted) {
                          setState(() {
                            isLoading = true;
                            total = 0;
                            offset = 0;
                            productList.clear();
                          });
                        }

                        getProduct("0", context);
                        Navigator.pop(context, 'option 3');
                      }),
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
                        if (mounted) {
                          setState(
                            () {
                              isLoading = true;
                              total = 0;
                              offset = 0;
                              productList.clear();
                            },
                          );
                        }
                        getProduct("0", context);
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
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(
            () {
              isLoadingmore = true;
              if (offset < total) getProduct("0", context);
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
          isLoading = true;
          isLoadingmore = true;
          offset = 0;
          total = 0;
          productList.clear();
        },
      );
    }
    return getProduct("0", context);
  }

  _showForm() {
    return isLoading
        ? shimmer()
        : productList.isEmpty
            ? getNoItem()
            : RefreshIndicator(
                key: refreshIndicatorKey,
                onRefresh: _refresh,
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.builder(
                    shrinkWrap: true,
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
                  ),
                ),
              );
  }

  productDeletDialog(
    String productName,
    String id,
    BuildContext cntx,
  ) async {
    String pName = productName;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5),
                ),
              ),
              content: Text(
                "sure \"  $pName \" PRODUCT",
                style: Theme.of(this.context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: fontColor),
              ),
              actions: <Widget>[
                TextButton(
                    child: Text(
                      "LOGOUTNO",
                      style: Theme.of(this.context)
                          .textTheme
                          .titleSmall!
                          .copyWith(
                              color: lightBlack, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }),
                TextButton(
                  child: Text(
                    "LOGOUTYES",
                    style: Theme.of(this.context)
                        .textTheme
                        .titleSmall!
                        .copyWith(
                            color: fontColor, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    deleteProductApi(
                      id,
                      cntx,
                    );

                    setState(
                      () {
                        isLoading = true;
                        isLoadingmore = true;
                        offset = 0;
                        total = 0;
                        productList.clear();
                        getProduct("0", context);
                      },
                    );
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  deleteProductApi(String id, BuildContext context) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      var parameter = {
        PRODUCT_ID: id,
      };

      Response response =
          await post(getDeleteProductApi, body: parameter, headers: headers)
              .timeout(const Duration(seconds: timeOut));

      var result = json.decode(response.body);

      bool error = result["error"];
      String? msg = result["message"];
      if (!error) {
        showOverlay(
          msg!,
          context,
        );
      } else {
        showOverlay(
          msg!,
          context,
        );
      }
    } else {
      isNetworkAvail = false;
      isLoading = false;
      setState(() {});
    }
    return null;
  }

  void filterDialog() {
    if (filterList!.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        enableDrag: false,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
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
                      leading: Builder(
                        builder: (BuildContext context) {
                          return Container(
                            margin: const EdgeInsets.all(10),
                            decoration: shadow(),
                            child: Card(
                              elevation: 0,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(5),
                                onTap: () => Navigator.of(context).pop(),
                                child: const Padding(
                                  padding: EdgeInsetsDirectional.only(end: 4.0),
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
                        start: 7.0,
                        end: 7.0,
                        top: 7.0,
                      ),
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
                                            bottomLeft: Radius.circular(
                                              7,
                                            ),
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
                                                fontWeight: FontWeight.normal,
                                              ),
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
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: attListId!.length,
                                      itemBuilder: (context, i) {
                                        return CheckboxListTile(
                                          dense: true,
                                          title: Text(attsubList![i],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium!
                                                  .copyWith(
                                                      color: lightBlack,
                                                      fontWeight:
                                                          FontWeight.normal)),
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
                                                    selectedId
                                                        .remove(attListId![i]);
                                                  }
                                                },
                                              );
                                            }
                                          },
                                        );
                                      },
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
                              Text(getTranslated(context, productsFound)!),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SimBtn(
                          size: 0.4,
                          title: getTranslated(context, apply)!,
                          onBtnSelected: () {
                            selId = selectedId.join(',');

                            if (mounted) {
                              setState(
                                () {
                                  isLoading = true;
                                  total = 0;
                                  offset = 0;
                                  productList.clear();
                                },
                              );
                            }
                            getProduct("0", context);
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

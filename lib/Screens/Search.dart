import 'dart:async';
import 'dart:convert';

import 'package:admin_eshop/Screens/EditProduct.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../Helper/AppBtn.dart';

import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';

class Search extends StatefulWidget {
  final Function? updateHome;

  const Search({Key? key, this.updateHome}) : super(key: key);

  @override
  _StateSearch createState() => _StateSearch();
}

class _StateSearch extends State<Search> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int pos = 0;
  final bool _isProgress = false;
  List<Product> productList = [];
  final List<TextEditingController> _controllerList = [];
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;

  String _searchText = "", _lastsearch = "";
  int notificationoffset = 0;
  ScrollController? notificationcontroller;
  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    productList.clear();

    notificationoffset = 0;

    notificationcontroller = ScrollController(keepScrollOffset: true);
    notificationcontroller!.addListener(_transactionscrollListener);

    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (mounted) {
          setState(() {
            _searchText = "";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchText = _controller.text;
          });
        }
      }

      if (_lastsearch != _searchText && (_searchText.length > 2)) {
        _lastsearch = _searchText;
        notificationisloadmore = true;
        notificationoffset = 0;
        getProduct();
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
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
  }

  _transactionscrollListener() {
    if (notificationcontroller!.offset >=
            notificationcontroller!.position.maxScrollExtent &&
        !notificationcontroller!.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            getProduct();
          },
        );
      }
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    notificationcontroller!.dispose();
    _controller.dispose();
    for (int i = 0; i < _controllerList.length; i++) {
      _controllerList[i].dispose();
    }
    _animationController.dispose();
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
              title: getTranslated(context, NO_INTERNET),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
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
        backgroundColor: white,
        title: TextField(
          style: const TextStyle(color: primary),
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            prefixIcon: const Icon(
              Icons.search,
              color: primary,
              size: 17,
            ),
            hintText: getTranslated(context, search),
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
        titleSpacing: 0,
      ),
      body: _isNetworkAvail
          ? Stack(
              children: <Widget>[
                _showContent(),
                showCircularProgress(_isProgress, primary),
              ],
            )
          : noInternet(context),
    );
  }

  Widget listItem(int index) {
    Product model = productList[index];

    if (_controllerList.length < index + 1) {
      _controllerList.add(
        TextEditingController(),
      );
    }

    _controllerList[index].text =
        model.prVarientList![model.selVarient!].cartCount!;

    double price =
        double.parse(model.prVarientList![model.selVarient!].disPrice!);
    if (price == 0) {
      price = double.parse(model.prVarientList![model.selVarient!].price!);
    }

    List att = [], val = [];
    if (model.prVarientList![model.selVarient!].attr_name != null) {
      att = model.prVarientList![model.selVarient!].attr_name!.split(',');
      val = model.prVarientList![model.selVarient!].varient_value!.split(',');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          splashColor: primary.withOpacity(0.2),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProduct(
                  model: model,
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Hero(
                    tag: "$index${model.id}",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7.0),
                      child: FadeInImage(
                        image: NetworkImage(productList[index].image!),
                        height: 80.0,
                        width: 80.0,
                        imageErrorBuilder: ((context, error, stackTrace) {
                          return erroWidget(80);
                        }),
                        // fit: extendImg ? BoxFit.fill : BoxFit.contain,
                        //errorWidget:(context, url,e) => placeHolder(80) ,
                        placeholder: placeHolder(80),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            model.name!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                  color: lightBlack,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: <Widget>[
                              Text("${CUR_CURRENCY!} $price ",
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
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
                                      decoration: TextDecoration.lineThrough,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ],
                          ),
                          model.prVarientList![model.selVarient!].attr_name !=
                                      null &&
                                  model.prVarientList![model.selVarient!]
                                      .attr_name!.isNotEmpty
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
                                                .copyWith(color: lightBlack),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  start: 5.0),
                                          child: Text(
                                            val[index],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: lightBlack,
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                        )
                                      ],
                                    );
                                  },
                                )
                              : Container(),
                          Row(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: primary,
                                    size: 12,
                                  ),
                                  Text(
                                    " ${productList[index].rating!}",
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    " (${productList[index].noOfRating!})",
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              productList[index].availability == "0"
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
      ),
    );
  }

  updateSearch() {
    if (mounted) setState(() {});
  }

  void getAvailVarient(List<Product> tempList) {
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

  Future getProduct() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (notificationisloadmore) {
          if (mounted) {
            setState(
              () {
                notificationisloadmore = false;
                notificationisgettingdata = true;
                if (notificationoffset == 0) {
                  productList = [];
                }
              },
            );
          }

          var parameter = {
            SEARCH: _searchText.trim(),
            LIMIT: perPage.toString(),
            OFFSET: notificationoffset.toString(),
          };

          Response response =
              await post(getProductApi, headers: headers, body: parameter)
                  .timeout(const Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          bool error = getdata["error"];

          notificationisgettingdata = false;
          if (notificationoffset == 0) notificationisnodata = error;

          if (!error) {
            if (mounted) {
              Future.delayed(
                Duration.zero,
                () => setState(
                  () {
                    List mainlist = getdata['data'];

                    if (mainlist.isNotEmpty) {
                      List<Product> items = [];
                      List<Product> allitems = [];

                      items.addAll(mainlist
                          .map((data) => Product.fromJson(data))
                          .toList());

                      allitems.addAll(items);

                      for (Product item in items) {
                        productList.where((i) => i.id == item.id).map((obj) {
                          allitems.remove(item);
                          return obj;
                        }).toList();
                      }

                      getAvailVarient(allitems);

                      notificationisloadmore = true;
                      notificationoffset = notificationoffset + perPage;
                    } else {
                      notificationisloadmore = false;
                    }
                  },
                ),
              );
            }
          } else {
            notificationisloadmore = false;
            if (mounted) setState(() {});
          }
        }
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, somethingMSg)!, context);
        if (mounted) {
          setState(() {
            notificationisloadmore = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  _showContent() {
    return notificationisnodata
        ? getNoItem()
        : NotificationListener<ScrollNotification>(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsetsDirectional.only(
                        bottom: 5, start: 10, end: 10, top: 12),
                    controller: notificationcontroller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      Product? item;
                      try {
                        item = productList.isEmpty ? null : productList[index];
                        if (notificationisloadmore &&
                            index == (productList.length - 1) &&
                            notificationcontroller!.position.pixels <= 0) {
                          getProduct();
                        }
                      } on Exception catch (_) {}

                      return item == null ? Container() : listItem(index);
                    },
                  ),
                ),
                notificationisgettingdata
                    ? const Padding(
                        padding: EdgeInsetsDirectional.only(top: 5, bottom: 5),
                        child: CircularProgressIndicator(),
                      )
                    : Container(),
              ],
            ),
          );
  }
}

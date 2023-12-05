import 'dart:async';
import 'dart:convert';

import 'package:admin_eshop/Model/Brand_Model.dart';
import 'package:admin_eshop/Screens/EditBrand.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'Home.dart';

class BrandsList extends StatefulWidget {
  const BrandsList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateBrandsList();
}

class StateBrandsList extends State<BrandsList> with TickerProviderStateMixin {
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoading = true;
  List<Brand> brandList = [];
  List<Brand> tempList = [];

  @override
  void initState() {
    super.initState();

    getBrand();
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

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> getBrand() async {
    if (readProduct) {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          Response response = await post(getBrandApi, headers: headers)
              .timeout(const Duration(seconds: timeOut));
          print(
              "API is $getProductApi \n  \n response : ${response.body.toString()}");

          if (response.statusCode == 200) {
            var getdata = json.decode(response.body);
            bool error = getdata["error"];
            String? msg = getdata["message"];
            if (!error) {
              tempList.clear();

              var data = getdata["data"];
              tempList =
                  (data as List).map((data) => Brand.fromJson(data)).toList();
              brandList.addAll(tempList);
            } else {
              setsnackbar(msg!, context);
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

  updateBrand() {
    setState(() {
      brandList.clear();
      getBrand();
    });
  }

  Future<void> _refresh() {
    if (mounted) {
      setState(
        () {
          _isLoading = true;
          brandList.clear();
        },
      );
    }
    return getBrand();
  }

  @override
  void dispose() {
    buttonController!.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = deviceWidth * 0.5;
    return Scaffold(
      appBar: getAppBar(
        getTranslated(context, BRANDS_LBL)!,
        context,
      ),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer()
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 25.0, start: 15, end: 15),
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _refresh,
                    child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 2 / 1.83),
                        shrinkWrap: true,
                        itemCount: brandList.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => EditBrand(
                                      model: brandList[index],
                                      index: index,
                                      updateBrand: updateBrand),
                                ),
                              );
                            },
                            child: Container(
                                padding: EdgeInsets.zero,
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(15)),
                                    border: Border.all(
                                        color: lightBlack.withOpacity(0.7),
                                        width: 1.0)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(15)),
                                          child: Hero(
                                            tag: "$index${brandList[index].id}",
                                            child: FadeInImage(
                                              fadeInDuration: const Duration(
                                                  milliseconds: 150),
                                              image: NetworkImage(
                                                  brandList[index].image!),
                                              height: deviceHeight / 7,
                                              width: double.maxFinite,
                                              fit: BoxFit.fill,
                                              imageErrorBuilder: ((context,
                                                  error, stackTrace) {
                                                return erroWidget(width);
                                              }),
                                              placeholder: placeHolder(width),
                                            ),
                                          ),
                                        ),
                                        Positioned.directional(
                                            top: 5,
                                            end: 5,
                                            textDirection:
                                                Directionality.of(context),
                                            child: InkWell(
                                              child: Container(
                                                height: 27,
                                                width: 27,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                  color: Colors.white,
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.delete,
                                                    size: 20),
                                              ),
                                              onTap: () {
                                                brandDeletDialog(
                                                    brandList[index].name!,
                                                    brandList[index].id!);
                                              },
                                            ))
                                      ],
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsetsDirectional.all(5),
                                      child: Text(
                                        brandList[index].name!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(color: fontColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )),
                          );
                        }),
                  ),
                )
          : noInternet(context),
    );
  }

  brandDeletDialog(String brandName, String id) async {
    String bName = brandName;
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
                "${getTranslated(context, SURE_LBL)!} \"  $bName \" ${getTranslated(context, BRAND_LBL)!}",
                style: Theme.of(this.context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: fontColor),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    getTranslated(context, LOGOUTNO)!,
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
                    getTranslated(context, LOGOUTYES)!,
                    style: Theme.of(this.context)
                        .textTheme
                        .titleSmall!
                        .copyWith(
                            color: fontColor, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    delBrandApi(id);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  delBrandApi(String id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var parameter = {
        "id": id,
      };
      apiBaseHelper.postAPICall(deleteBrandApi, parameter).then(
        (getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            setsnackbar(msg!, context);
            _isLoading = true;

            brandList.clear();
            getBrand();
          } else {
            setsnackbar(msg!, context);

            _isLoading = true;

            brandList.clear();
            getBrand();
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
                      getBrand();
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
}

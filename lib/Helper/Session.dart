import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:connectivity/connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../Localization/Demo_Localization.dart';
import '../Localization/Language_Constant.dart';
import 'Color.dart';
import 'Constant.dart';
import 'String.dart';

setPrefrence(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<String?> getPrefrence(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

setPrefrenceBool(String key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<bool> getPrefrenceBool(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key) ?? false;
}

Future<bool> isNetworkAvailable() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

shadow() {
  return const BoxDecoration(
    boxShadow: [
      BoxShadow(color: Color(0x1a0400ff), offset: Offset(0, 0), blurRadius: 30)
    ],
  );
}

placeHolder(double height) {
  return const AssetImage(
    'assets/images/placeholder.png',
  );
}

getAppBar(String title, BuildContext context) {
  return AppBar(
    centerTitle: false,
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
    title: Text(
      title,
      style: const TextStyle(
        color: primary,
      ),
    ),
    backgroundColor: white,
  );
}

noIntImage() {
  return Image.asset(
    'assets/images/no_internet.png',
    fit: BoxFit.contain,
    color: primary,
  );
}

noIntText(BuildContext context) {
  return Container(
    child: Text(
      getTranslated(context, NO_INTERNET)!,
      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            color: primary,
            fontWeight: FontWeight.normal,
          ),
    ),
  );
}

noIntDec(BuildContext context) {
  return Container(
    padding: const EdgeInsets.only(
      top: 30.0,
      left: 30.0,
      right: 30.0,
    ),
    child: Text(
      getTranslated(context, NO_INTERNET_DISC)!,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: lightBlack2,
            fontWeight: FontWeight.normal,
          ),
    ),
  );
}

Widget showCircularProgress(bool isProgress, Color color) {
  if (isProgress) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
  return const SizedBox(
    height: 0.0,
    width: 0.0,
  );
}

imagePlaceHolder(double size) {
  return SizedBox(
    height: size,
    width: size,
    child: Icon(
      Icons.account_circle,
      color: white,
      size: size,
    ),
  );
}

dialogAnimate(BuildContext context, Widget dialge) {
  return showGeneralDialog(
    barrierColor: fontColor,
    transitionBuilder: (context, a1, a2, widget) {
      return Transform.scale(
        scale: a1.value,
        child: Opacity(
          opacity: a1.value,
          child: dialge,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    barrierDismissible: true,
    barrierLabel: '',
    context: context,
    pageBuilder: (context, animation1, animation2) {
      return Container();
    },
  );
}
//------------------------------------------------------------------------------
//======================= Language Translate  ==================================

String? getTranslated(BuildContext context, String key) {
  return DemoLocalization.of(context)!.translate(key);
}

Future<void> clearUserSession() async {
  final waitList = <Future<void>>[];

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String getlng = await getPrefrence(LAGUAGE_CODE) ?? '';

  waitList.add(prefs.remove(ID));
  waitList.add(prefs.remove(MOBILE));
  waitList.add(prefs.remove(EMAIL));
  CUR_USERID = '';
  CUR_USERNAME = "";

  //CUR_BALANCE = '';

  await prefs.clear();
  setPrefrence(LAGUAGE_CODE, getlng);
}

Future<void> saveUserDetail(
    String userId, String name, String email, String mobile) async {
  final waitList = <Future<void>>[];
  SharedPreferences prefs = await SharedPreferences.getInstance();
  waitList.add(prefs.setString(ID, userId));
  waitList.add(prefs.setString(USERNAME, name));
  waitList.add(prefs.setString(EMAIL, email));
  waitList.add(prefs.setString(MOBILE, mobile));
  await Future.wait(waitList);
}

String? validateField(String? value, BuildContext context) {
  if (value!.isEmpty) {
    return getTranslated(context, FIELD_REQUIRED);
  } else {
    return null;
  }
}

erroWidget(double size) {
  return Image.asset(
    'assets/images/placeholder.png',
    color: primary,
    height: size,
    width: size,
  );
}

String? validateMob(String? value, BuildContext context) {
  if (value!.isEmpty) {
    return getTranslated(context, MOB_REQUIRED);
  }
  if (value.length < 9) {
    return getTranslated(context, VALID_MOB);
  }
  return null;
}

String? validatePass(String? value, BuildContext context) {
  if (value!.isEmpty) {
    return getTranslated(context, PWD_REQUIRED);
  } else if (value.length <= 5) {
    return getTranslated(context, PWD_LENGTH);
  } else {
    return null;
  }
}

String? validateAltMob(String value, BuildContext context) {
  if (value.isNotEmpty) if (value.length < 9) {
    return getTranslated(context, VALID_MOB);
  }
  return null;
}

String? urlValidation(String value, BuildContext context) {
  bool? test;
  if (value.isEmpty) {
    return getTranslated(context, FIELD_REQUIRED);
  } else {
    validUrl(value).then((result) {
      test = result;
      if (test!) {
        return getTranslated(context, AddValidDigitalProductlinkText);
      }
    });
  }
  return null;
}

Future<bool> validUrl(String value) async {
  final response = await head(Uri.parse(value));

  if (response.statusCode == 200) {
    return false;
  } else {
    return true;
  }
}

Widget getProgress() {
  return const Center(child: CircularProgressIndicator());
}

Widget getNoItem() {
  return const Center(child: Text(noItem));
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

String? validateEmail(String value, String msg1, String msg2) {
  if (value.isEmpty) {
    return msg1;
  } else if (!RegExp(
          r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)"
          r"*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+"
          r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
      .hasMatch(value)) {
    return msg2;
  } else {
    return null;
  }
}

// product name velidatation

String? validateProduct(String? value, BuildContext context) {
  if (value!.isEmpty) {
    return getTranslated(context, ProductNameRequired)!;
  }
  if (value.length < 3) {
    return getTranslated(context, PleaseEnterValidProductName)!;
  }
  return null;
}

// sort detail velidatation

String? sortdescriptionvalidate(String? value, BuildContext context) {
  if (value!.isEmpty) {
    return getTranslated(context, SortDescriptionisrequired)!;
  }
  if (value.length < 3) {
    return getTranslated(context, minimamcharacterText)!;
  }
  return null;
}

// product name velidatation

String? validateThisFieldRequered(String? value, BuildContext context) {
  if (value!.isEmpty) {
    return getTranslated(context, FieldRequiredText)!;
  }
  return null;
}

//brand name validation

String? validateBrand(String? value, BuildContext context) {
  if (value!.isEmpty) {
    return getTranslated(context, BRAND_NAME_REQ_LBL);
  }
  if (value.length < 2) {
    return getTranslated(context, BRAND_VALID_LBL);
  }
  return null;
}

Widget shimmer() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
              .map(
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80.0,
                        height: 80.0,
                        color: white,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 18.0,
                              color: white,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 5.0),
                            ),
                            Container(
                              width: double.infinity,
                              height: 8.0,
                              color: white,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 5.0),
                            ),
                            Container(
                              width: 100.0,
                              height: 8.0,
                              color: white,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 5.0),
                            ),
                            Container(
                              width: 20.0,
                              height: 8.0,
                              color: white,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

Widget shimmer2() {
  return Container(
    // width: double.infinity,
    padding: const EdgeInsets.only(left: 5, right: 3, bottom: 8),
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        child: Column(
          children: [0]
              .map(
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 207.0,
                        height: 280.0,
                        color: white,
                      ),
                      // const Padding(
                      //   padding: EdgeInsets.symmetric(horizontal: 8.0),
                      // ),
                      // Expanded(
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Container(
                      //         width: double.infinity,
                      //         height: 18.0,
                      //         color: white,
                      //       ),
                      //       const Padding(
                      //         padding: EdgeInsets.symmetric(vertical: 5.0),
                      //       ),
                      //       Container(
                      //         width: double.infinity,
                      //         height: 8.0,
                      //         color: white,
                      //       ),
                      //       const Padding(
                      //         padding: EdgeInsets.symmetric(vertical: 5.0),
                      //       ),
                      //       Container(
                      //         width: 100.0,
                      //         height: 8.0,
                      //         color: white,
                      //       ),
                      //       const Padding(
                      //         padding: EdgeInsets.symmetric(vertical: 5.0),
                      //       ),
                      //       Container(
                      //         width: 20.0,
                      //         height: 8.0,
                      //         color: white,
                      //       ),
                      //     ],
                      //   ),
                      // )
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

setsnackbar(String msg, context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      duration: const Duration(
        seconds: 2,
      ),
      backgroundColor: const Color(0xffF0F0F0),
      elevation: 1.0,
    ),
  );
}

String getToken() {
  final claimSet =
      JwtClaim(issuer: 'eshop', maxAge: const Duration(minutes: 5));

  String token = issueJwtHS256(claimSet, jwtKey);
  print("token***$token");
  return token;
}

Map<String, String> get headers => {
      "Authorization": 'Bearer ${getToken()}',
    };

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';

class PrivacyPolicy extends StatefulWidget {
  final String? title;

  const PrivacyPolicy({Key? key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? privacy;
  String url = "";
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;

  @override
  void initState() {
    super.initState();
    getSetting();
    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    return Scaffold(
        appBar: getAppBar(
          widget.title!,
          context,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _isNetworkAvail
                ? privacy != ""
                    ? SingleChildScrollView(
                        child: Html(
                          data: privacy!,
                        ),
                      )
                    : Container()
                : noInternet(context));
  }

  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        String type;
        if (widget.title == PRIVACY_POLICY_LBL) {
          type = PRIVACY_POLLICY;
        } else if (widget.title == TERM) {
          type = TERM_COND;
        }

        Response response = await post(getSettingApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        print("response: ${response.body.toString()}");

        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          String? type;

          if (widget.title == getTranslated(context, PRIVACY_POLICY_LBL)!) {
            type = PRIVACY_POLLICY;
          } else if (widget.title == getTranslated(context, TERM)) {
            type = TERM_COND;
          }

          privacy = getdata["data"][type][0].toString();
        } else {
          setsnackbar(msg!, context);
        }
        setState(
          () {
            _isLoading = false;
          },
        );
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, somethingMSg)!, context);
      }
    } else {
      setState(
        () {
          _isLoading = false;
          _isNetworkAvail = false;
        },
      );
    }
  }
}

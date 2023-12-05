import 'dart:async';
import 'package:admin_eshop/Helper/String.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';

import '../Helper/Session.dart';
import '../Model/OrderMailModel.dart';

class OrderMailDetails extends StatefulWidget {
  final OrderMailModel model;

  const OrderMailDetails({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  _OrderMailDetailsState createState() => _OrderMailDetailsState();
}

String selectedUploadFileSubDic = '';

class _OrderMailDetailsState extends State<OrderMailDetails>
    with TickerProviderStateMixin {
  ScrollController controller = ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  bool isNetworkAvail = true;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightWhite,
      body: isNetworkAvail
          ? Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      getAppBar(
                          getTranslated(context, DigitalOrderMailDetailsText)!,
                          context),
                      Padding(
                          padding: const EdgeInsets.all(
                            8.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "${getTranslated(context, ORDER_ID_LBL)} - ",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.model.orderId!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          )),
                      Padding(
                          padding: const EdgeInsets.all(
                            8.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "${getTranslated(context, OrderItemIdText)} - ",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.model.orderItemId!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          )),
                      Padding(
                        padding: const EdgeInsets.all(
                          8.0,
                        ),
                        child: Text(
                          getTranslated(context, SubjectText)!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, left: 8.0),
                        child: Container(
                            alignment: Alignment.center,
                            width: deviceWidth,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: primary.withOpacity(0.1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              widget.model.subject!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(color: fontColor.withOpacity(0.8)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              softWrap: true,
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            8.0,
                          ),
                          child: Text(
                            getTranslated(context, MSG_LBL)!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 8, end: 8, bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: primary,
                            ),
                          ),
                          width: deviceWidth,
                          child: Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                              ),
                              child: Html(
                                data: widget.model.message! ?? '',
                                onLinkTap: (url, _, __) async {
                                  if (await canLaunchUrlString(url!)) {
                                    await launchUrlString(
                                      url,
                                    );
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                },
                              )),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            8.0,
                          ),
                          child: Text(
                            getTranslated(context, FileUrlText)!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.upload_file,
                              color: Colors.green,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(widget.model.fileUrl!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : noInternet(context),
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

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }
}

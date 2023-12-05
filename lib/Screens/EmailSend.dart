import 'dart:async';
import 'package:admin_eshop/Helper/String.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../Helper/ApiBaseHelper.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/ProductDescription.dart';
import '../Helper/Session.dart';
import 'Media.dart';

class SendMail extends StatefulWidget {
  String email, orderId, orderIteamId, productName, userName;

  SendMail({
    Key? key,
    required this.email,
    required this.orderId,
    required this.orderIteamId,
    required this.productName,
    required this.userName,
  }) : super(key: key);

  @override
  _SendMailState createState() => _SendMailState();
}

String selectedUploadFileSubDic = '';

class _SendMailState extends State<SendMail> with TickerProviderStateMixin {
  ScrollController controller = ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  TextEditingController emailController = TextEditingController();
  TextEditingController subjectController = TextEditingController();
  String? message;
  bool sending = true;
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
    selectedUploadFileSubDic = '';
    emailController.text = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    subjectController.text =
        "${getTranslated(context, AttachMentForDownloadProText)} : ${widget.productName}";
    message = '''${getTranslated(context, AttachMentForDownloadText)}''';
    print("order iteam id : ${widget.orderIteamId}");

    return Scaffold(
      backgroundColor: lightWhite,
      body: isNetworkAvail
          ? Stack(
              children: [
                !sending
                    ? const Center(child: CircularProgressIndicator())
                    : Container(),
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      getAppBar(getTranslated(context, SendMailText)!, context),
                      Padding(
                        padding: const EdgeInsets.all(
                          8.0,
                        ),
                        child: Text(
                          getTranslated(context, EmailText)!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, left: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: TextField(
                            controller: emailController,
                            style: Theme.of(context).textTheme.titleSmall,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: primary.withOpacity(0.1),
                              hintText:
                                  getTranslated(context, EnterEmailIdText)!,
                            ),
                          ),
                        ),
                      ),
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
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: TextField(
                            controller: subjectController,
                            style: Theme.of(context).textTheme.titleSmall,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: primary.withOpacity(0.1),
                              hintText: getTranslated(context, SubjectText)!,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
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
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute<String>(
                                      builder: (context) =>
                                          ProductDescription("Message"),
                                    ),
                                  ).then((changed) {
                                    message = changed;
                                    setState(() {});
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: primary,
                                  ),
                                  height: 35,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 08),
                                      child: Text(
                                        getTranslated(
                                            context, EditMessageIdText)!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      message == null || message == ''
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
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
                                      data: message ?? '',
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
                        padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(
                                8.0,
                              ),
                              child: Text(
                                getTranslated(context, SelectFileText)!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => const Media(
                                        from: "file",
                                        pos: 0,
                                        type: "email",
                                      ),
                                    ),
                                  ).then(
                                    (value) => setState(() {
                                      //
                                    }),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: primary,
                                  ),
                                  height: 35,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 08),
                                      child: Text(
                                        getTranslated(context, UploadText)!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      selectedUploadFileSubDic == ''
                          ? Container()
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                                    padding: const EdgeInsets.only(
                                        bottom: 8.0, top: 8.0),
                                    child: Text(selectedUploadFileSubDic),
                                  ),
                                ],
                              ),
                            ),
                      InkWell(
                        onTap: () {
                          if (sending) {
                            setState(() {
                              sending = false;
                            });
                            getDeliveryBoy();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: primary,
                            ),
                            height: 35,
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 08),
                                child: Text(
                                  getTranslated(context, SendMailText)!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  Future<void> getDeliveryBoy() async {
    var parameter = {
      'order_id': widget.orderId,
      'order_item_id': widget.orderIteamId,
      'customer_email': emailController.text,
      'subject': subjectController.text,
      'message': message,
      'attachment': selectedUploadFileSubDic,
      'username': widget.userName,
    };

    ApiBaseHelper().postAPICall(sendDigitalProductMailApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          setsnackbar(
            msg!,
            context,
          );
        } else {
          setsnackbar(
            msg!,
            context,
          );
        }
        setState(() {
          sending = true;
        });
      },
      onError: (error) {
        setsnackbar(
          error.toString(),
          context,
        );
      },
    );
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }
}

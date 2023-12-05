import 'dart:async';
import 'dart:convert';

import 'package:admin_eshop/Helper/Constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Brand_Model.dart';
import 'Media.dart';
import 'package:http/http.dart' as http;

class EditBrand extends StatefulWidget {
  Brand? model;
  Function? updateBrand;
  int? index;

  EditBrand({Key? key, this.model, this.index, this.updateBrand}) : super(key: key);

  @override
  _EditBrandState createState() => _EditBrandState();
}

late String brandImage, brandImageUrl, brandImageRelativePath;

class _EditBrandState extends State<EditBrand> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  TextEditingController brandNameControlller = TextEditingController();
  String? brandName;
  bool _isNetworkAvail = true;

  @override
  void initState() {
    brandImage = '';
    brandImageUrl = '';
    brandImageRelativePath = '';
    brandNameControlller.text = widget.model!.name!;
    brandName = brandNameControlller.text;
    if (widget.model!.image != null && widget.model!.image != "") {
      brandImage = widget.model!.image!;
      brandImageUrl = widget.model!.image!;
      brandImageRelativePath = widget.model!.relativePath!;
    }
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
    super.initState();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      updateBrand();
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      if (brandName == '' && brandName == null) {
        setsnackbar(getTranslated(context, PLZ_ADD_BRAND_NAME_LBL)!, context);
        return false;
      } else if (brandImage == '') {
        setsnackbar(
            getTranslated(context, PLZ_ADD_BRAND_IMAGE_LBL)!, context);
        return false;
      }

      return true;
    }
    return false;
  }

  Future<void> updateBrand() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var request = http.MultipartRequest("POST", addBrandApi);

        request.headers.addAll(headers);
        // request.fields[USER_ID] = CUR_USERID!;
        request.fields['edit_brand'] = widget.model!.id!;
        request.fields['brand_input_name'] = brandName!;
        request.fields['brand_input_image'] = brandImageRelativePath;

        print("response : ${request.fields.toString()}");
        print("response : ${request.files.toString()}");
        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var getdata = json.decode(responseString);
        print("getdata : $getdata");

        bool error = getdata["error"];
        String msg = getdata['message'];
        if (!error) {
          await buttonController!.reverse();
          widget.updateBrand!();
          setsnackbar(msg, context);
        } else {
          await buttonController!.reverse();
          setsnackbar(msg, context);
        }
      } on TimeoutException catch (_) {
        setsnackbar(
          getTranslated(context, somethingMSg)!,
          context,
        );
      }
    } else if (mounted) {
      Future.delayed(const Duration(seconds: 2)).then(
        (_) async {
          await buttonController!.reverse();
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        },
      );
    }
  }

  getBodyPart() {
    return SingleChildScrollView(
      child: Form(
        key: _formkey,
        child: Column(
          children: [
            addBrandName(),
            brandImageWidget(),
            selectedBrandImageShow(),

            AppBtn(
              title: getTranslated(context, UPDATE_BRAND_LBL),
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                validateAndSubmit();
              },
            ),
            //resetProButton(),
            const SizedBox(
              width: 20,
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  addBrandName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        brandText(),
        brandTextField(),
      ],
    );
  }

  brandText() {
    return Padding(
      padding: const EdgeInsets.only(
        right: 10,
        left: 10,
        top: 15,
      ),
      child: Text(
        getTranslated(context, BRAND_NAME_LBL)!,
        style: const TextStyle(
          fontSize: 16,
          color: fontColor,
        ),
      ),
    );
  }

  brandTextField() {
    return Container(
      width: deviceWidth,
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
      ),
      child: TextFormField(
        keyboardType: TextInputType.text,
        style: const TextStyle(
          color: fontColor,
          fontWeight: FontWeight.normal,
        ),
        controller: brandNameControlller,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        onChanged: (value) {
          brandName = value;
        },
        validator: (val) => validateBrand(val, context),
        decoration: InputDecoration(
          hintText: getTranslated(context, ADD_NEW_BRAND_NAME_LBL)!,
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
        ),
      ),
    );
  }

  brandImageWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getTranslated(context, BRAND_IMAGE_LBL)!,
          ),
          InkWell(
            child: Container(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(5),
              ),
              width: 90,
              height: 40,
              child: Center(
                child: Text(
                  getTranslated(context, UploadText)!,
                  style: const TextStyle(
                    color: white,
                  ),
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Media(
                    from: "main",
                    type: "editBrand",
                  ),
                ),
              ).then(
                (value) => setState(
                  () {},
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  selectedBrandImageShow() {
    return brandImage == ''
        ? Container()
        : Image.network(
            brandImageUrl,
            width: 100,
            height: 100,
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
        getTranslated(context, UPDATE_BRAND_LBL)!,
        context,
      ),
      body: _isNetworkAvail ? getBodyPart() : noInternet(context),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'Chat.dart';
import '../Helper/Color.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
import '../Model/Model.dart';

class CustomerSupport extends StatefulWidget {
  const CustomerSupport({Key? key}) : super(key: key);

  @override
  _CustomerSupportState createState() => _CustomerSupportState();
}

class _CustomerSupportState extends State<CustomerSupport> {
  bool _isLoading = true, _isProgress = false;
  Animation? buttonSqueezeanimation;
  late AnimationController buttonController;
  bool _isNetworkAvail = true;
  List<Model> typeList = [];
  List<Model> ticketList = [];
  List<Model> statusList = [];
  List<Model> tempList = [];
  String? type, email, title, desc, status, id;
  FocusNode? nameFocus, emailFocus, descFocus;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final descController = TextEditingController();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  bool show = false;

  ScrollController controller = ScrollController();
  int offset = 0;
  late int total = 0, curEdit;
  bool isLoadingmore = true;

  @override
  void initState() {
    super.initState();
    statusList = [
      Model(id: "1", title: "Pending"),
      Model(id: "2", title: "Opened"),
      Model(id: "3", title: "Resolved"),
      Model(id: "4", title: "Closed"),
      Model(id: "5", title: "Reopen")
    ];
    controller = ScrollController();
    controller.addListener(
      () {
        setState(
          () {
            if (controller.offset >= controller.position.maxScrollExtent &&
                !controller.position.outOfRange) {
              isLoadingmore = true;

              if (offset < total) getTicket();
            }
          },
        );
      },
    );
    getType();
    getTicket();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    emailController.dispose();
    descController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(
        getTranslated(context, CustomerSupportText)!,
        context,
      ),
      body: _isLoading
          ? shimmer()
          : Stack(
              children: [
                SingleChildScrollView(
                  controller: controller,
                  child: Form(
                    key: _formkey,
                    child: Column(
                      children: [
                        show
                            ? Card(
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      setType(),
                                      setEmail(),
                                      setTitle(),
                                      setDesc(),
                                      Row(
                                        children: [
                                          statusDropDown(),
                                          const Spacer(),
                                          sendButton(),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : Container(),
                        ticketList.isNotEmpty
                            ? ListView.separated(
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        const Divider(),
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: (offset < total)
                                    ? ticketList.length + 1
                                    : ticketList.length,
                                itemBuilder: (context, index) {
                                  return (index == ticketList.length &&
                                          isLoadingmore)
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ticketItem(index);
                                },
                              )
                            : getNoItem()
                      ],
                    ),
                  ),
                ),
                showCircularProgress(_isProgress, primary),
              ],
            ),
    );
  }

  Widget setType() {
    return DropdownButtonFormField(
      iconEnabledColor: fontColor,
      isDense: true,
      hint: Text(
        getTranslated(context, SelectTypeText)!,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: fontColor,
              fontWeight: FontWeight.normal,
            ),
      ),
      decoration: InputDecoration(
        filled: true,
        isDense: true,
        fillColor: lightWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: fontColor),
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: const BorderSide(color: lightWhite),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      value: type,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(color: fontColor),
      onChanged: (String? newValue) {
        setState(
          () {
            type = newValue;
          },
        );
      },
      items: typeList.map(
        (Model user) {
          return DropdownMenuItem<String>(
            value: user.id,
            child: Text(
              user.title!,
            ),
          );
        },
      ).toList(),
    );
  }

  void validateAndSubmit() async {
    if (type == null || type == "" || status == null || status == "") {
      setsnackbar(
          getTranslated(context, PleaseSelectTypeorstatusText)!, context);
    } else {
      if (validateAndSave()) {
        checkNetwork();
      }
    }
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      sendRequest();
    } else {
      Future.delayed(const Duration(seconds: 2)).then(
        (_) async {
          if (mounted) {
            setState(
              () {
                _isNetworkAvail = false;
              },
            );
          }
          await buttonController.reverse();
        },
      );
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  setEmail() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        readOnly: true,
        keyboardType: TextInputType.emailAddress,
        focusNode: emailFocus,
        textInputAction: TextInputAction.next,
        controller: emailController,
        style: const TextStyle(color: fontColor, fontWeight: FontWeight.normal),
        validator: (val) => validateEmail(val!, EMAIL_REQUIRED, VALID_EMAIL),
        onSaved: (String? value) {
          email = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, EmailText)!,
          hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
          filled: true,
          fillColor: lightWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setTitle() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        focusNode: nameFocus,
        readOnly: true,
        textInputAction: TextInputAction.next,
        controller: nameController,
        style: const TextStyle(color: fontColor, fontWeight: FontWeight.normal),
        validator: (val) => validateField(val, context),

        onSaved: (String? value) {
          title = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, SubjectText)!,
          hintStyle: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(color: fontColor, fontWeight: FontWeight.normal),
          filled: true,
          fillColor: lightWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  setDesc() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 10.0,
      ),
      child: TextFormField(
        focusNode: descFocus,
        readOnly: true,
        controller: descController,
        maxLines: null,
        style: const TextStyle(color: fontColor, fontWeight: FontWeight.normal),
        validator: (val) => validateField(val!,context),
        onSaved: (String? value) {
          desc = value;
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, emailFocus!, nameFocus);
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, DescriptionText)!,
          hintStyle: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(color: fontColor, fontWeight: FontWeight.normal),
          filled: true,
          fillColor: lightWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode? nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  Future<void> getType() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        Response response = await post(getTicketTypeApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          typeList = (data as List)
              .map((data) => Model.fromSupport(data))
              .toList();
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
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, somethingMSg)!, context);
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
  }

  Future<void> getTicket() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          //  USER_ID: CUR_USERID,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };

        Response response =
            await post(getTicketApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];
          total = int.parse(getdata["total"]);

          if ((offset) < total) {
            tempList.clear();
            var data = getdata["data"];
            tempList = (data as List)
                .map((data) => Model.fromTicket(data))
                .toList();

            ticketList.addAll(tempList);

            offset = offset + perPage;
          }
        } else {
          setsnackbar(msg!, context);
          isLoadingmore = false;
        }
        if (mounted) {
          setState(
            () {
              _isLoading = false;
            },
          );
        }
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, somethingMSg)!, context);
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
  }

  Widget sendButton() {
    return SimBtn(
      size: 0.4,
      title: getTranslated(context, SEND_LBL),
      onBtnSelected: () {
        validateAndSubmit();
      },
    );
  }

  Future<void> sendRequest() async {
    if (mounted) {
      setState(
        () {
          _isProgress = true;
        },
      );
    }

    try {
      var data = {TICKET_ID: id, STATUS: status};

      Response response =
          await post(editTicketApi, body: data, headers: headers)
              .timeout(const Duration(seconds: timeOut));
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];
          if (mounted) {
            setState(
              () {
                ticketList[curEdit] = Model.fromTicket(data[0]);

                _isProgress = false;
                clearAll();
              },
            );
          }
        }

        setsnackbar(msg, context);
      }
    } on TimeoutException catch (_) {
      setsnackbar(getTranslated(context, somethingMSg)!, context);
    }
  }

  clearAll() {
    type = null;
    email = null;
    title = null;
    desc = null;
  }

  Widget ticketItem(int index) {
    Color back;
    String? status = ticketList[index].status;

    if (status == "1") {
      back = Colors.orange;
      status = "Pending";
    } else if (status == "2") {
      back = Colors.cyan;
      status = "Opened";
    } else if (status == "3") {
      back = Colors.green;
      status = "Resolved";
    } else if (status == "5") {
      back = Colors.cyan;
      status = "Reopen";
    } else {
      back = Colors.red;
      status = "Close";
    }
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => Chat(
                  id: ticketList[index].id,
                  status: ticketList[index].status,
                ),
              ));
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "${getTranslated(context, TypeText)!} : ${ticketList[index].type!}",
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                        color: back,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4.0))),
                    child: Text(
                      getTranslated(context, status)!,

                      style: const TextStyle(color: white),
                    ),
                  )
                ],
              ),
              Text("${getTranslated(context, SubjectText)!} : ${ticketList[index].title!}"),
              Text(
                "${getTranslated(context, DescriptionText)!} : ${ticketList[index].desc!}",
              ),
              Text("${getTranslated(context, "DateText")!} : ${ticketList[index].date!}"),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    GestureDetector(
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(start: 8),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: const BoxDecoration(
                          color: lightWhite,
                          borderRadius: BorderRadius.all(
                            Radius.circular(4.0),
                          ),
                        ),
                        child: Text(
                          getTranslated(context, EditText)!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: fontColor, fontSize: 11),
                        ),
                      ),
                      onTap: () {
                        setState(
                          () {
                            curEdit = index;
                            show = true;
                            id = ticketList[index].id;
                            emailController.text = ticketList[index].email!;
                            nameController.text = ticketList[index].title!;
                            descController.text = ticketList[index].desc!;
                            type = ticketList[index].typeId;
                          },
                        );
                      },
                    ),
                    GestureDetector(
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(start: 8),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: const BoxDecoration(
                          color: lightWhite,
                          borderRadius: BorderRadius.all(
                            Radius.circular(4.0),
                          ),
                        ),
                        child: Text(
                          getTranslated(context, CHATText)!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: fontColor, fontSize: 11),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => Chat(
                              id: ticketList[index].id,
                              status: ticketList[index].status,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  statusDropDown() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * .4,
      child: DropdownButtonFormField(
        iconEnabledColor: fontColor,
        isDense: true,
        hint: Text(
          getTranslated(context, SelectTypeText)!,
          style: Theme.of(context)
              .textTheme
              .titleSmall!
              .copyWith(color: fontColor, fontWeight: FontWeight.normal),
        ),
        decoration: InputDecoration(
          filled: true,
          isDense: true,
          fillColor: lightWhite,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: fontColor),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: lightWhite),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        value: status,
        style:
            Theme.of(context).textTheme.titleSmall!.copyWith(color: fontColor),
        onChanged: (String? newValue) {
          setState(
            () {
              status = newValue;
            },
          );
        },
        items: statusList.map(
          (Model user) {
            return DropdownMenuItem<String>(
              value: user.id,
              child: Text( capitalize(getTranslated(context, user.title!)!),
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}

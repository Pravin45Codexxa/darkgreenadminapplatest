import 'package:admin_eshop/Helper/Constant.dart';
import 'package:admin_eshop/Helper/String.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

import 'Color.dart';
import 'Session.dart';

class ProductDescription extends StatefulWidget {
  //ProductDescription({Key? key},) : super(key: key);
  String? description;

  ProductDescription(this.description, {Key? key}) : super(key: key);

  @override
  _ProductDescriptionState createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends State<ProductDescription> {
  String result = '';
  bool isLoading = true;
  final HtmlEditorController controller = HtmlEditorController();

  @override
  void initState() {
    setValue();

    super.initState();
  }

  setValue() async {
    Future.delayed(
      const Duration(seconds: 4),
      () {
        setState(() {
          isLoading = false;
        });
      },
    );

    Future.delayed(
      const Duration(seconds: 6),
      () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    controller.setText(widget.description!);
    var temp = controller.getText();

    return GestureDetector(
      onTap: () {
        if (!kIsWeb) {
          controller.clearFocus(); // for close keybord
        }
      },
      child: Scaffold(
        appBar: getAppBar(
          getTranslated(context, ProductDescriptionText)!,
          context,
        ),
        backgroundColor: white,
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              backgroundColor: white,
              onPressed: () {
                controller.editorController!.reload();
              },
              child: Text(
                getTranslated(context, ClearText)!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            FloatingActionButton(
              backgroundColor: white,
              onPressed: () {
                Navigator.of(context).pop(result);
              },
              child: Text(
                getTranslated(context, SAVE_LBL)!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
        body: isLoading
            ? shimmer()
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    HtmlEditor(
                      controller: controller,
                      htmlEditorOptions: HtmlEditorOptions(
                        hint: getTranslated(context, EnterProductDescriptionText)!,
                        shouldEnsureVisible: true,
                      ),
                      htmlToolbarOptions: HtmlToolbarOptions(
                        toolbarPosition: ToolbarPosition.aboveEditor,
                        toolbarType: ToolbarType.nativeGrid, //by default
                        gridViewHorizontalSpacing: 0,
                        gridViewVerticalSpacing: 0,
                        dropdownBackgroundColor: lightWhite,
                        toolbarItemHeight: 40,
                        buttonColor: fontColor,
                        buttonFocusColor: primary,
                        buttonBorderColor: Colors.red,
                        buttonFillColor: secondary,
                        dropdownIconColor: primary,
                        dropdownIconSize: 26,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          color: pink,
                        ),
                        onButtonPressed: (p0, p1, p2) => true,
                        /*   onButtonPressed: (ButtonType type, bool? status,
                            Function()? updateStatus) {
                          return true;
                        },*/
                        onDropdownChanged: (DropdownType type, dynamic changed,
                            Function(dynamic)? updateSelectedItem) {
                          return true;
                        },
                        mediaLinkInsertInterceptor: (String url, InsertFileType type) {
                          return true;
                        },
                        mediaUploadInterceptor: (PlatformFile file, InsertFileType type) async {
                          return true;
                        },
                      ),
                      otherOptions: OtherOptions(
                        height: deviceHeight * 0.85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: lightWhite,
                        ),
                      ),
                      callbacks: Callbacks(
                        onBeforeCommand: (String? currentHtml) {},
                        onChangeContent: (String? changed) {},
                        onChangeCodeview: (String? changed) {
                          result = changed!;
                        },
                        onChangeSelection: (EditorSettings settings) {},
                        onDialogShown: () {},
                        onEnter: () {},
                        onFocus: () {},
                        onBlur: () {},
                        onBlurCodeview: () {},
                        onInit: () {},
                        onImageUploadError: (
                          FileUpload? file,
                          String? base64Str,
                          UploadError error,
                        ) {},
                        onKeyDown: (int? keyCode) {},
                        onKeyUp: (int? keyCode) {},
                        onMouseDown: () {},
                        onMouseUp: () {},
                        onNavigationRequestMobile: (String url) {
                          return NavigationActionPolicy.ALLOW;
                        },
                        onPaste: () {},
                        onScroll: () {},
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

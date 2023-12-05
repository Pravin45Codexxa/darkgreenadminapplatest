import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:sticky_headers/sticky_headers.dart';
import '../../Helper/SimBtn.dart';
import '../../Model/Attribute Models/AttributeSetModel/AttributeSetModel.dart';
import '../../Model/CategoryModel/categoryModel.dart';
import '../../Model/TaxesModel/TaxesModel.dart';
import '../../Model/ZipCodesModel/ZipCodeModel.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/ProductDescription.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Brand_Model.dart';
import 'Home.dart';
import 'Media.dart';
import '../Model/Attribute Models/AttributeModel/AttributesModel.dart';
import '../Model/Attribute Models/AttributeValueModel/AttributeValue.dart';
import '../Model/Section_Model.dart';
import 'ProductList.dart';
import 'Widgets/FilterChips.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({Key? key}) : super(key: key);

  @override
  _AddProductState createState() => _AddProductState();
}

late String productImage, productImageUrl, uploadedVideoName, uploadFileName;
List<String> otherPhotos = [];
List<File>? otherPhotosFromGellery = [];
List<String> otherImageUrl = [];
List<Product_Varient> variationList = [];

class _AddProductState extends State<AddProduct> with TickerProviderStateMixin {
//------------------------------------------------------------------------------
//======================= Variable Declaration =================================

// temprary variable for test
  late Map<String, List<AttributeValueModel>> selectedAttributeValues = {};

// => Variable For UI ...
  String? selectedCatName; // for UI
  int? selectedTaxID; // for UI
  var mainImageProductImage;

//on-off toggles
  bool isToggled = false;
  bool isreturnable = false;
  bool isCODallow = false;
  bool iscancelable = false;
  bool taxincludedInPrice = false;
  bool isDownloadAllow = false;

//for remove extra add
  int attributeIndiacator = 0;

// network variable
  bool _isNetworkAvail = true;
  bool _isLoading = true;
  String? data;
  bool suggessionisNoData = false;

//------------------------------------------------------------------------------
//                        Parameter For API Call

  String? productName; //pro_input_name
  String? sortDescription; // short_description
  String? productMainType; // productType
  String? IdentificationofProduct;
  String? tags; // Tags
  String? taxId; // Tax (pro_input_tax)
  String? indicatorValue; // indicator
  String? madeIn; //made_in
  String? totalAllowQuantity; // total_allowed_quantity
  String? minOrderQuantity; // minimum_order_quantity
  String? quantityStepSize; // quantity_step_size
  String? warrantyPeriod; //warranty_period
  String? guaranteePeriod; //guarantee_period
  String? deliverabletypeValue = "1"; //deliverable_type
  String? deliverableZipcodes; //deliverable_zipcodes
  String? taxincludedinPrice = "0"; //is_prices_inclusive_tax
  String? isCODAllow = "0"; //cod_allowed
  String? isReturnable = "0"; //is_returnable
  String? isCancelable = "0"; //is_cancelable
  String? isDownloadAllowed = "0"; //is_cancelable
  String? tillwhichstatus; //cancelable_till
  //File? mainProductImage;//pro_input_image
  String? selectedTypeOfVideo; // video_type
  String? videoUrl; //video
  File? videoOfProduct; // pro_input_video
  String? description; // pro_input_description
  String? selectedCatID; //category_id
  //attribute_values
  String? productType; //product_type
  String? variantStockLevelType =
      "product_level"; //variant_stock_level_type // defualt is product level  if not pass
  int curSelPos = 0;

// for simple product   if(product_type == simple_product)

  String? simpleproductStockStatus = "1"; //simple_product_stock_status
  String? simpleproductPrice; //simple_price
  String? simpleproductSpecialPrice; //simple_special_price
  String? simpleproductSKU; // product_sku
  String? simpleproductTotalStock; // product_total_stock
  String? variantStockStatus =
      "0"; //variant_stock_status //fix according to riddhi mam =0 for simple product // not give any option for selection

  //for digital product    if(product_type == digital_product)

  String? digitalproductPrice; //digital_price
  String? digitalproductSpecialPrice; //digital_special_price
  String? downloadLinkType; //download_link_type
  String? digitalLink; //download_link

// for variable product
  List<List<AttributeValueModel>> finalAttList = [];
  List<List<AttributeValueModel>> tempAttList = [];
  String? variantsIds; //variants_ids
  String? variantPrice; // variant_price
  String? variantSpecialPrice; // variant_special_price
  String? variantImages; // variant_images

  //{if (variant_stock_level_type == product_level)}
  String? variantproductSKU; //sku_variant_type
  String? variantproductTotalStock; // total_stock_variant_type
  String stockStatus = '1'; // variant_status

  //{if(variant_stock_level_type == variable_level)}
  String? variantSku; // variant_sku
  String? variantTotalStock; // variant_total_stock
  String? variantLevelStockStatus; //variant_level_stock_status
  bool? _isStockSelected;

//  other
  bool simpleProductSaveSettings = false;
  bool digitalProductSaveSettings = false;
  bool variantProductProductLevelSaveSettings = false;
  bool variantProductVariableLevelSaveSettings = false;
  late StateSetter taxesState;

  // getting data
  List<TaxesModel> taxesList = [];
  List<AttributeSetModel> attributeSetList = [];
  List<AttributeModel> attributesList = [];
  List<AttributeValueModel> attributesValueList = [];
  List<ZipCodeModel> zipSearchList = [];
  List<CategoryModel> catagorylist = [];

  final List<TextEditingController> _attrController = [];
  final List<TextEditingController> _attrValController = [];
  List<bool> variationBoolList = [];
  List<int> attrId = [];
  List<int> attrValId = [];
  List<String> attrVal = [];

//------------------------------------------------------------------------------
//======================= TextEditingController ================================

  TextEditingController productNameControlller = TextEditingController();
  TextEditingController tagsControlller = TextEditingController();
  TextEditingController totalAllowController = TextEditingController();
  TextEditingController minOrderQuantityControlller = TextEditingController();
  TextEditingController quantityStepSizeControlller = TextEditingController();
  TextEditingController madeInControlller = TextEditingController();
  TextEditingController warrantyPeriodController = TextEditingController();
  TextEditingController guaranteePeriodController = TextEditingController();
  TextEditingController vidioTypeController = TextEditingController();
  TextEditingController digitalProductPriceController = TextEditingController();
  TextEditingController digitalProductSpecialPriceController =
      TextEditingController();
  TextEditingController simpleProductPriceController = TextEditingController();
  TextEditingController simpleProductSpecialPriceController =
      TextEditingController();
  TextEditingController simpleProductSKUController = TextEditingController();
  TextEditingController simpleProductTotalStock = TextEditingController();
  TextEditingController variountProductSKUController = TextEditingController();
  TextEditingController variountProductTotalStock = TextEditingController();
  TextEditingController searchCountryController = TextEditingController();

//------------------------------------------------------------------------------
//=================================== FocusNode ================================
  late int row = 1, col;
  FocusNode? productFocus,
      sortDescriptionFocus,
      IdentificationofProductFocus,
      tagFocus,
      totalAllowFocus,
      minOrderFocus,
      quantityStepSizeFocus,
      madeInFocus,
      warrantyPeriodFocus,
      guaranteePeriodFocus,
      vidioTypeFocus,
      simpleProductPriceFocus,
      simpleProductSpecialPriceFocus,
      simpleProductSKUFocus,
      simpleProductTotalStockFocus,
      variountProductSKUFocus,
      variountProductTotalStockFocus,
      rawKeyboardListenerFocus,
      tempFocusNode,
      attributeFocus = FocusNode();
  List<Brand> tempBrandList = [];
  List<Brand> brandList = [];
  bool? isLoadingMoreBrand;
  int brandOffset = 0;
  bool brandLoading = true;
  final ScrollController brandScrollController = ScrollController();

  List<Brand> tempCountryList = [];
  List<Brand> countryList = [];
  bool? isLoadingMoreCountry;
  int countryOffset = 0;
  bool countryLoading = true;
  final ScrollController countryScrollController = ScrollController();
  StateSetter? countryState;

//------------------------------------------------------------------------------
//========================= For Form Validation ================================

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

//------------------------------------------------------------------------------
//======================= Delete this  ================================

  List<String> selectedAttribute = [];

  List<String> suggestedAttribute = [];

  bool showSuggestedAttributes = false;

//------------------------------------------------------------------------------
//========================= For Animation ======================================

  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

//------------------------------------------------------------------------------
//========================= InIt MEthod ========================================
  List<String> resultAttr = [];
  List<String> resultID = [];
  late int max;

  // brand name
  String? selectedBrandName;
  String? selectedBrandId;

  @override
  void initState() {
    productImage = '';
    productImageUrl = '';
    uploadedVideoName = '';
    otherPhotos = [];
    otherImageUrl = [];
    uploadFileName = '';
    callApi();
    /* getCategories();
    getZipCodes();
    getTax();
    getAttributesValue();
    getAttributes();
    getAttributeSet();*/

    brandScrollController.addListener(_brandScrollListener);
    countryScrollController.addListener(_countryScrollListener);

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

  callApi() async {
    getCategories();
    getBrands();
    getCountry();
    getZipCodes();
    getTax();
    getAttributesValue();
    getAttributes();
    getAttributeSet();
  }

  @override
  void dispose() {
    buttonController!.dispose();
    digitalProductSpecialPriceController.dispose();
    digitalProductPriceController.dispose();
    _attrController.clear();
    _attrValController.clear();
    productNameControlller.dispose();
    tagsControlller.dispose();
    totalAllowController.dispose();
    minOrderQuantityControlller.dispose();
    quantityStepSizeControlller.dispose();
    madeInControlller.dispose();
    warrantyPeriodController.dispose();
    guaranteePeriodController.dispose();
    vidioTypeController.dispose();
    simpleProductPriceController.dispose();
    simpleProductSpecialPriceController.dispose();
    simpleProductSKUController.dispose();
    simpleProductTotalStock.dispose();
    variountProductSKUController.dispose();
    variountProductTotalStock.dispose();
    brandScrollController.dispose();
    countryScrollController.dispose();
    searchCountryController.dispose();
    super.dispose();
  }

  _brandScrollListener() async {
    if (brandScrollController.offset >=
            brandScrollController.position.maxScrollExtent &&
        !brandScrollController.position.outOfRange) {
      if (mounted) {
        setState(() {
          isLoadingMoreBrand = true;
        });

        getBrands();

        if (mounted) setState(() {});
      }
    }
  }

  _countryScrollListener() async {
    if (countryScrollController.offset >=
            countryScrollController.position.maxScrollExtent &&
        !countryScrollController.position.outOfRange) {
      if (mounted) {
        setState(() {
          isLoadingMoreCountry = true;
        });

        getCountry();
        countryState!(() {});
        if (mounted) setState(() {});
      }
    }
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

  Future<void> getCountry() async {
    int countryPerPage = 20;
    try {
      var parameter = {
        LIMIT: countryPerPage.toString(),
        OFFSET: countryOffset.toString(),
      };

      apiBaseHelper.postAPICall(getCountriesDataApi, parameter).then(
        (result) async {
          bool error = result['error'];
          String message = result['message'];

          tempCountryList.clear();

          if (!error) {
            var data = result['data'];

            tempCountryList =
                (data as List).map((data) => Brand.fromJson(data)).toList();

            countryList.addAll(tempCountryList);
          }

          countryLoading = false;
          isLoadingMoreCountry = false;
          countryOffset += countryPerPage;
          if (countryState != null) {
            countryState!(() {});
          }
        },
        onError: (error) {
          setsnackbar(
            error.toString(),
            context,
          );
        },
      );
    } catch (e) {
      setsnackbar(
        e.toString(),
        context,
      );
    }
  }

  Future<void> getBrands() async {
    int brandPerPage = 20;
    try {
      var parameter = {
        LIMIT: brandPerPage.toString(),
        OFFSET: brandOffset.toString(),
      };

      apiBaseHelper.postAPICall(getBrandApi, parameter).then(
        (result) async {
          bool error = result['error'];
          String message = result['message'];

          tempBrandList.clear();

          if (!error) {
            var data = result['data'];

            tempBrandList =
                (data as List).map((data) => Brand.fromJson(data)).toList();
            brandList.addAll(tempBrandList);
          }

          brandLoading = false;
          isLoadingMoreBrand = false;
          brandOffset += brandPerPage;
        },
        onError: (error) {
          setsnackbar(
            error.toString(),
            context,
          );
        },
      );
    } catch (e) {
      setsnackbar(
        e.toString(),
        context,
      );
    }
  }

  //========================================================
/*  Future<void> getBrands() async {
    apiBaseHelper.postAPICall(getBrandApi, {}).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          brandList.clear();
          var data = getdata["data"];
          brandList =
              (data as List).map((data) => Brand.fromJson(data)).toList();
        } else {
          setsnackbar(
            msg!,
            context,
          );
        }
      },
      onError: (error) {
        setsnackbar(
          error.toString(),
          context,
        );
      },
    );
  }*/

  brandSelectButtomSheet() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStater) {
          taxesState = setStater;
          return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100.0),
              child: AlertDialog(
                  scrollable: true,
                  contentPadding: const EdgeInsets.all(0.0),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                  ),
                  title: Center(
                    child: Text(
                      getTranslated(context, SEL_BRAND_LBL)!,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: fontColor),
                    ),
                  ),
                  content: SizedBox(
                      //height: double.maxFinite,
                      width: double.maxFinite, //<- this line is important
                      child: SingleChildScrollView(
                        controller: brandScrollController,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: brandList
                                .asMap()
                                .map(
                                  (index, element) => MapEntry(
                                    index,
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                        selectedBrandName =
                                            brandList[index].name;
                                        selectedBrandId = brandList[index].id;
                                        setState(() {});
                                      },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Divider(),
                                          Row(
                                            children: [
                                              selectedBrandId ==
                                                      brandList[index].id
                                                  ? Container(
                                                      height: 20,
                                                      width: 20,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: lightBlack2,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Container(
                                                          height: 16,
                                                          width: 16,
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: primary,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      height: 20,
                                                      width: 20,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: lightBlack2,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Container(
                                                          height: 16,
                                                          width: 16,
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: white,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              SizedBox(
                                                width: deviceWidth * 0.6,
                                                child: Text(
                                                  brandList[index].name!,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .values
                                .toList()),
                      ) /*ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsetsDirectional.only(
                            bottom: 5, start: 10, end: 10),
                        // physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: brandList.length,
                        itemBuilder: (context, index) {
                          Brand? item;
                          item = brandList.isEmpty ? null : brandList[index];
                          return item == null ? Container() : getbrands(index);
                        },
                      )*/
                      )));
        });
      },
    );
  }

//=====================================================================
  getbrands(int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
            selectedBrandName = brandList[index].name;
            selectedBrandId = brandList[index].id;
            setState(() {});
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              Row(
                children: [
                  selectedBrandId == brandList[index].id
                      ? Container(
                          height: 20,
                          width: 20,
                          decoration: const BoxDecoration(
                            color: lightBlack2,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              height: 16,
                              width: 16,
                              decoration: const BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 20,
                          width: 20,
                          decoration: const BoxDecoration(
                            color: lightBlack2,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              height: 16,
                              width: 16,
                              decoration: const BoxDecoration(
                                color: white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: deviceWidth * 0.6,
                    child: Text(
                      brandList[index].name!,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
        ),
      ],
    );
  }

  countryDialog(
    BuildContext context,
  ) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            countryState = setStater;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                    child: Text(
                      getTranslated(context, MadeInText)!,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: primary),
                    ),
                  ),
                  /*  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: searchCountryController,
                            autofocus: false,
                            style: const TextStyle(
                              color: fontColor,
                            ),
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                              hintText: getTranslated(context, search),
                              hintStyle:
                                  TextStyle(color: primary.withOpacity(0.5)),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: IconButton(
                          onPressed: () async {
                            isLoadingMoreCountry = true;
                          },
                          icon: const Icon(
                            Icons.search,
                            size: 20,
                          ),
                        ),
                      )
                    ],
                  ),
                  const Divider(), */
                  countryLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 50.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : (countryList.isNotEmpty)
                          ? Flexible(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.8,
                                child: SingleChildScrollView(
                                  controller: countryScrollController,
                                  child: Stack(
                                    children: [
                                      Column(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: getCountryList(
                                                setStater, context),
                                          ),
                                          if (isLoadingMoreCountry!)
                                            const Center(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 50.0),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                        ],
                                      ),
                                      // const Center(
                                      //   child: Padding(
                                      //     padding: EdgeInsets.symmetric(
                                      //         vertical: 50.0),
                                      //     // child: CircularProgressIndicator(),
                                      //   ),
                                      // )
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: getNoItem(),
                            )
                ],
              ),
            );
          },
        );
      },
    );
  }

  getCountryList(Function setStater, BuildContext context) {
    return countryList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                setState(() {
                  madeIn = countryList[index].name;
                });

                Navigator.of(context).pop();
                //setState;
              },
              child: SizedBox(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30.0, 8.0, 20, 8),
                  child: Text(
                    countryList[index].name!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  Future<void> getZipCodes() async {
    var parameter = {};
    apiBaseHelper.postAPICall(getZipcodesApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          zipSearchList.clear();
          var data = getdata["data"];
          zipSearchList = (data as List)
              .map((data) => ZipCodeModel.fromJson(data))
              .toList();
        } else {
          setsnackbar(msg!, context);
        }
      },
      onError: (error) {
        setsnackbar(error.toString(), context);
      },
    );
  }

  Future<void> getCategories() async {
    var parameter = {};
    apiBaseHelper.postAPICall(getCategoriesApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          catagorylist.clear();
          var data = getdata["data"];
          catagorylist = (data as List)
              .map((data) => CategoryModel.fromJson(data))
              .toList();
        } else {
          setsnackbar(msg!, context);
        }
      },
      onError: (error) {
        setsnackbar(
          error.toString(),
          context,
        );
      },
    );
  }

//------------------------------------------------------------------------------
//======================== getAttributeSet API =================================

  Future<void> getAttributeSet() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        http.Response response = await http
            .post(getAttributeSetApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        if (!error) {
          var data = getdata["data"];
          attributeSetList = (data as List)
              .map(
                (data) => AttributeSetModel.fromJson(data),
              )
              .toList();
        }
        setState(
          () {
            _isLoading = false;
          },
        );
      } on TimeoutException catch (_) {
        setsnackbar(
          getTranslated(context, somethingMSg)!,
          context,
        );
      }
    }
  }

//------------------------------------------------------------------------------
//======================== getAttributes API ===================================

  Future<void> getAttributes() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        http.Response response = await http
            .post(getAttributesApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        if (!error) {
          var data = getdata["data"];
          attributesList = (data as List)
              .map(
                (data) => AttributeModel.fromJson(data),
              )
              .toList();
          for (var element in attributesList) {
            selectedAttributeValues[element.id!] = [];
          }

          setState(
            () {},
          );
        }
        setState(
          () {
            _isLoading = false;
          },
        );
      } on TimeoutException catch (_) {
        setsnackbar(
          getTranslated(context, somethingMSg)!,
          context,
        );
      }
    }
  }

//------------------------------------------------------------------------------
//======================== getAttributrValuesApi API ===========================

  Future<void> getAttributesValue() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        http.Response response = await http
            .post(getAttributrValuesApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        if (!error) {
          var data = getdata["data"];
          attributesValueList = (data as List)
              .map(
                (data) => AttributeValueModel.fromJson(data),
              )
              .toList();
        }
        setState(
          () {
            _isLoading = false;
          },
        );
      } on TimeoutException catch (_) {
        setsnackbar(
          getTranslated(context, somethingMSg)!,
          context,
        );
      }
    }
  }

//------------------------------------------------------------------------------
//======================== getTax API ==========================================

  Future<void> getTax() async {
    print("tax*****");
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        http.Response response = await http
            .post(getTaxesApi, headers: headers)
            .timeout(const Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];
          taxesList =
              (data as List).map((data) => TaxesModel.fromJson(data)).toList();
        } else {
          setsnackbar(msg, context);
        }
        setState(
          () {
            _isLoading = false;
          },
        );
      } on TimeoutException catch (_) {
        setsnackbar(
          getTranslated(context, somethingMSg)!,
          context,
        );
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

//------------------------------------------------------------------------------
//================================= ProductName ================================

// logic clear....

  addProductName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        productText(),
        productTextField(),
      ],
    );
  }

  productText() {
    return Padding(
      padding: const EdgeInsets.only(
        right: 10,
        left: 10,
        top: 15,
      ),
      child: Text(
        getTranslated(context, ProductNameText)!,
        style: const TextStyle(
          fontSize: 16,
          color: fontColor,
        ),
      ),
    );
  }

  productTextField() {
    return Container(
      width: deviceWidth,
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
      ),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(productFocus);
        },
        focusNode: productFocus,
        keyboardType: TextInputType.text,
        style: const TextStyle(
          color: fontColor,
          fontWeight: FontWeight.normal,
        ),
        controller: productNameControlller,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        onChanged: (value) {
          productName = value;
        },
        validator: (val) => validateProduct(val, context),
        decoration: InputDecoration(
          hintText: getTranslated(context, AddnewProductText)!,
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

//------------------------------------------------------------------------------
//=========================== ShortDescription =================================

// logic clear

  shortDescription() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, shortDescriptionText)!,
            style: const TextStyle(
              fontSize: 16,
              color: fontColor,
            ),
          ),
          const SizedBox(
            height: 05,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: lightBlack,
                width: 1,
              ),
            ),
            width: deviceWidth,
            height: deviceHeight * 0.12,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
              ),
              child: TextFormField(
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(sortDescriptionFocus);
                },
                focusNode: sortDescriptionFocus,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                validator: (val) => sortdescriptionvalidate(val, context),
                onChanged: (value) {
                  sortDescription = value;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  hintText: getTranslated(context, addSortDescText)!,
                ),
                minLines: null,
                maxLines: null,
                expands: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

//------------------------------------------------------------------------------
//=========================== Product Type =====================================
  productTypeField() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, ProductTypeLbl)!,
            style: const TextStyle(
              fontSize: 16,
              color: fontColor,
            ),
          ),
          const SizedBox(
            height: 05,
          ),
          InkWell(
            child: Container(
              padding: const EdgeInsets.only(
                top: 5,
                bottom: 5,
                left: 5,
                right: 5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: lightBlack,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        productMainType != null
                            ? Text(
                                getTranslated(context, DigitalProductText)!,
                              )
                            : Text(
                                getTranslated(context, PhysicalProductText)!,
                              ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: primary,
                  )
                ],
              ),
            ),
            onTap: () {
              productMainTypeDialog();
            },
          ),
        ],
      ),
    );
  }

  productMainTypeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, PleaseselectproducttypeText)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  productMainType = null;
                                  productType = null;
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(
                                          context, PhysicalProductText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  productMainType = 'digital_product';
                                  productType = 'digital_product';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                // child: Row(
                                //   mainAxisAlignment:
                                //       MainAxisAlignment.spaceBetween,
                                //   children: [
                                //     Text(
                                //       getTranslated(
                                //           context, DigitalProductText)!,
                                //     ),
                                //   ],
                                // ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//=========================== ShortDescription =================================

// logic clear

  identificationofProduct() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, IdentificationofProductText)!,
            style: const TextStyle(
              fontSize: 16,
              color: fontColor,
            ),
          ),
          const SizedBox(
            height: 05,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: lightBlack,
                width: 1,
              ),
            ),
            width: deviceWidth,
            height: deviceHeight * 0.06,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
              ),
              child: TextFormField(
                onFieldSubmitted: (v) {
                  FocusScope.of(context)
                      .requestFocus(IdentificationofProductFocus);
                },
                focusNode: IdentificationofProductFocus,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                validator: (val) => validateThisFieldRequered(val, context),
                onChanged: (value) {
                  IdentificationofProduct = value;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  hintText:
                      getTranslated(context, ProductIdentificationNumberText)!,
                ),
                minLines: null,
                maxLines: null,
                expands: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

//------------------------------------------------------------------------------
//================================= Tags Add ===================================

  // logic clear

  tagsAdd() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10.0,
        right: 10.0,
        bottom: 10.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          tagsText(),
          addTagName(),
        ],
      ),
    );
  }

  tagsText() {
    return Row(
      children: [
        Text(
          getTranslated(context, Tags)!,
          style: const TextStyle(
            fontSize: 16,
            color: fontColor,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            getTranslated(context, TagsHelpText)!,
            style: const TextStyle(
              color: Color.fromARGB(255, 8, 6, 6),
            ),
            softWrap: false,
          ),
        ),
      ],
    );
  }

  addTagName() {
    return SizedBox(
      width: deviceWidth,
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(tagFocus);
        },
        focusNode: tagFocus,
        keyboardType: TextInputType.text,
        style: const TextStyle(
          color: fontColor,
          fontWeight: FontWeight.normal,
        ),
        controller: tagsControlller,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        onChanged: (value) {
          tags = value;
        },
        decoration: InputDecoration(
          hintText: getTranslated(context, TagsHelpText2)!,
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

//------------------------------------------------------------------------------
//============================== Tax Selection =================================
  taxSelection() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: selectedTaxID != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            taxesList[selectedTaxID!].title!,
                          ),
                          Text(
                            taxesList[selectedTaxID!].percentage!,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getTranslated(context, SelectTax)!,
                          ),
                          const Text(
                            "0%",
                          ),
                        ],
                      ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          taxesDialog();
        },
      ),
    );
  }

  taxesDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, SelectTax)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                        Text(
                          "0%",
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: getTaxtList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> getTaxtList() {
    return taxesList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  setState(
                    () {
                      selectedTaxID = index;
                      taxId = taxesList[selectedTaxID!].id;
                      Navigator.of(context).pop();
                    },
                  );
                }
              },
              child: SizedBox(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.all(
                    20.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        taxesList[index].title!,
                      ),
                      Text(
                        "${taxesList[index].percentage!}%",
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

//------------------------------------------------------------------------------
//========================= Indicator Selection ================================

  indicatorField() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: InkWell(
          child: Container(
            padding: const EdgeInsets.only(
              top: 5,
              bottom: 5,
              left: 5,
              right: 5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: lightBlack,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      indicatorValue != null
                          ? Text(
                              indicatorValue == '0'
                                  ? getTranslated(context, None)!
                                  : indicatorValue == '1'
                                      ? getTranslated(context, Veg)!
                                      : getTranslated(context, nonVeg)!,
                            )
                          : Text(
                              getTranslated(context, SelectIndicator)!,
                            ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: primary,
                )
              ],
            ),
          ),
          onTap: () {
            indicatorDialog();
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  attributeDialog(int pos) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              getTranslated(context, SelectAttribute)!,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(color: fontColor),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: lightBlack),
                      suggessionisNoData
                          ? getNoItem()
                          : SizedBox(
                              width: double.maxFinite,
                              height: attributeSetList.isNotEmpty
                                  ? MediaQuery.of(context).size.height * 0.3
                                  : 0,
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: attributeSetList.length,
                                  itemBuilder: (context, index) {
                                    List<AttributeModel> attrList = [];

                                    AttributeSetModel item =
                                        attributeSetList[index];

                                    for (int i = 0;
                                        i < attributesList.length;
                                        i++) {
                                      if (item.id ==
                                          attributesList[i].attributeSetId) {
                                        attrList.add(attributesList[i]);
                                      }
                                    }
                                    return Material(
                                      child: StickyHeaderBuilder(
                                        builder: (BuildContext context,
                                            double stuckAmount) {
                                          return Container(
                                            decoration: BoxDecoration(
                                                color: primary,
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 2),
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              attributeSetList[index].name ??
                                                  '',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          );
                                        },
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: List<int>.generate(
                                              attrList.length, (i) => i).map(
                                            (item) {
                                              return InkWell(
                                                onTap: () {
                                                  setState(
                                                    () {
                                                      _attrController[pos]
                                                              .text =
                                                          attrList[item].name!;
                                                      attributeIndiacator =
                                                          pos + 1;
                                                      if (!attrId.contains(
                                                          int.parse(
                                                              attrList[item]
                                                                  .id!))) {
                                                        attrId.add(int.parse(
                                                            attrList[item]
                                                                .id!));
                                                        Navigator.pop(context);
                                                      } else {
                                                        setsnackbar(
                                                          getTranslated(context,
                                                              alredyInserted)!,
                                                          context,
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                                child: Container(
                                                  width: double.maxFinite,
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    attrList[item].name ?? '',
                                                    textAlign: TextAlign.start,
                                                  ),
                                                ),
                                              );
                                            },
                                          ).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  indicatorDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, SelectIndicator)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  indicatorValue = '0';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, None)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  indicatorValue = '1';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, Veg)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  indicatorValue = '2';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, nonVeg)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//========================= TotalAllow Quantity ================================

//logic clear

  totalAllowedQuantity() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                bottom: 8,
              ),
              child: SizedBox(
                width: deviceWidth * 0.4,
                child: Text(
                  "${getTranslated(context, TotalAllowedQuantityText)!} :",
                  style: const TextStyle(
                    fontSize: 16,
                    color: fontColor,
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            Container(
              width: deviceWidth * 0.5,
              padding: const EdgeInsets.only(),
              child: TextFormField(
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(totalAllowFocus);
                },
                keyboardType: TextInputType.number,
                controller: totalAllowController,
                style: const TextStyle(
                  color: fontColor,
                  fontWeight: FontWeight.normal,
                ),
                focusNode: totalAllowFocus,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (String? value) {
                  totalAllowQuantity = value;
                },
                validator: (val) => validateThisFieldRequered(val, context),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: lightWhite,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 20),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: fontColor),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: lightWhite),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

//------------------------------------------------------------------------------
//========================= Minimum Order Quantity =============================

  minimumOrderQuantity() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                bottom: 8,
              ),
              child: SizedBox(
                width: deviceWidth * 0.4,
                child: Text(
                  "${getTranslated(context, MinimumOrderQuantityText)!} :",
                  style: const TextStyle(
                    fontSize: 16,
                    color: fontColor,
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            Container(
              width: deviceWidth * 0.5,
              padding: const EdgeInsets.only(),
              child: TextFormField(
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(minOrderFocus);
                },
                keyboardType: TextInputType.number,
                controller: minOrderQuantityControlller,
                style: const TextStyle(
                  color: fontColor,
                  fontWeight: FontWeight.normal,
                ),
                focusNode: minOrderFocus,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (String? value) {
                  minOrderQuantity = value;
                },
                validator: (val) => validateThisFieldRequered(val, context),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: lightWhite,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 20),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: fontColor),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: lightWhite),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

//------------------------------------------------------------------------------
//========================= Quantity Step Size =================================

  _quantityStepSize() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                bottom: 8,
              ),
              child: SizedBox(
                width: deviceWidth * 0.4,
                child: Text(
                  "${getTranslated(context, QuantityStepSizeText)!} :",
                  style: const TextStyle(
                    fontSize: 16,
                    color: fontColor,
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            Container(
              width: deviceWidth * 0.5,
              padding: const EdgeInsets.only(),
              child: TextFormField(
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(quantityStepSizeFocus);
                },
                keyboardType: TextInputType.number,
                controller: quantityStepSizeControlller,
                style: const TextStyle(
                  color: fontColor,
                  fontWeight: FontWeight.normal,
                ),
                focusNode: quantityStepSizeFocus,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (String? value) {
                  quantityStepSize = value;
                },
                validator: (val) => validateThisFieldRequered(val, context),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: lightWhite,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 20),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: fontColor),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: lightWhite),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

//------------------------------------------------------------------------------
//=================================== Made In ==================================

  _madeIn() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 10.0,
              bottom: 8,
            ),
            child: SizedBox(
              width: deviceWidth * 0.4,
              child: Text(
                "${getTranslated(context, MadeInText)!} :",
                style: const TextStyle(
                  fontSize: 16,
                  color: fontColor,
                ),
                maxLines: 2,
              ),
            ),
          ),
          InkWell(
            child: Container(
              width: deviceWidth * 0.5,
              padding: const EdgeInsetsDirectional.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: lightWhite,
              ),
              child: madeIn == null || madeIn == ""
                  ? const Text(
                      "",
                    )
                  : Text(madeIn!),
            ),
            onTap: () {
              countryDialog(context);
            },
          ),
          /*Container(
            width: deviceWidth * 0.5,
            padding: EdgeInsetsDirectional.zero,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: lightWhite,
                border: Border.all(color: fontColor)),
            child: IntlPhoneField(
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: fontColor, fontWeight: FontWeight.normal),
              initialCountryCode: countryCode,
              onTap: () {},
              onCountryChanged: (country) {
                setState(() {
                  madeIn = country.name;
                });
              },
              showCountryFlag: false,
              disableLengthCheck: true,
              readOnly: true,
              showDropdownIcon: false,
              pickerDialogStyle: PickerDialogStyle(
                padding: const EdgeInsets.only(left: 10, right: 10),
              ),
            ), */ /*TextFormField(
              onFieldSubmitted: (v) {
                FocusScope.of(context).requestFocus(madeInFocus);
              },
              keyboardType: TextInputType.text,
              controller: madeInControlller,
              style: TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: madeInFocus,
              textInputAction: TextInputAction.next,
              onChanged: (String? value) {
                madeIn = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),*/ /*
            */ /* CountryCodePicker(
                padding: EdgeInsetsDirectional.zero,
                showCountryOnly: false,
                // flagWidth: 20,
                searchDecoration: InputDecoration(
                  hintText: getTranslated(context, COUNTRY_CODE_LBL)!,
                  fillColor: fontColor,
                ),
                showOnlyCountryWhenClosed: true,
                initialSelection: countryCode,
                showFlag: false,
                dialogSize: Size(deviceWidth, deviceHeight),
                textOverflow: TextOverflow.ellipsis,
                alignLeft: true,
                textStyle: const TextStyle(
                  color: fontColor,
                  fontWeight: FontWeight.normal,
                ),
                onChanged: (CountryCode countryCode) {
                  //  countrycode = countryCode.toString().replaceFirst("+", "");
                  madeIn = countryCode.name;
                },
                onInit: (code) {
                  madeIn = code!.name.toString();
                  //countrycode = code.toString().replaceFirst("+", "");
                },
              )*/ /*
          ),*/
        ],
      ),
    );
  }

//------------------------------------------------------------------------------
//============================ Warranty Period =================================

  _warrantyPeriod() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                bottom: 8,
              ),
              child: SizedBox(
                width: deviceWidth * 0.4,
                child: Text(
                  "${getTranslated(context, WarrantyPeriodText)!} :",
                  style: const TextStyle(
                    fontSize: 16,
                    color: fontColor,
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            Container(
              width: deviceWidth * 0.5,
              padding: const EdgeInsets.only(),
              child: TextFormField(
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(warrantyPeriodFocus);
                },
                keyboardType: TextInputType.text,
                controller: warrantyPeriodController,
                style: const TextStyle(
                  color: fontColor,
                  fontWeight: FontWeight.normal,
                ),
                focusNode: warrantyPeriodFocus,
                textInputAction: TextInputAction.next,
                validator: (val) => validateThisFieldRequered(val, context),
                onChanged: (String? value) {
                  warrantyPeriod = value;
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: lightWhite,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 20),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: fontColor),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: lightWhite),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

//------------------------------------------------------------------------------
//============================ Guarantee Period ================================

//logic clear

  _guaranteePeriod() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                bottom: 8,
              ),
              child: SizedBox(
                width: deviceWidth * 0.4,
                child: Text(
                  "${getTranslated(context, GuaranteePeriodText)!} :",
                  style: const TextStyle(
                    fontSize: 16,
                    color: fontColor,
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            Container(
              width: deviceWidth * 0.5,
              padding: const EdgeInsets.only(),
              child: TextFormField(
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(guaranteePeriodFocus);
                },
                keyboardType: TextInputType.text,
                controller: guaranteePeriodController,
                style: const TextStyle(
                  color: fontColor,
                  fontWeight: FontWeight.normal,
                ),
                focusNode: guaranteePeriodFocus,
                textInputAction: TextInputAction.next,
                onChanged: (String? value) {
                  guaranteePeriod = value;
                },
                validator: (val) => validateThisFieldRequered(val, context),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: lightWhite,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, maxHeight: 20),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: fontColor),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: lightWhite),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  brandSelectWidget() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        width: deviceWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${getTranslated(context, BRAND_LBL)!} :",
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: InkWell(
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.only(
                      top: 5,
                      bottom: 5,
                      left: 5,
                      right: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: lightBlack,
                        width: 1,
                      ),
                    ),
                    child: selectedBrandName == null || selectedBrandName == ""
                        ? Text(
                            getTranslated(context, SEL_BRAND_LBL)!,
                          )
                        : Text(selectedBrandName!),
                  ),
                  onTap: () {
                    brandSelectButtomSheet();
                  },
                )),
          ],
        ),
      ),
    );
  }

//------------------------------------------------------------------------------
//============================ Deliverable Type ================================

  deliverableType() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(
          width: deviceWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${getTranslated(context, DeliverableTypeText)!} :",
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: InkWell(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 5,
                      bottom: 5,
                      left: 5,
                      right: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: lightBlack,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              deliverabletypeValue != null
                                  ? Text(
                                      deliverabletypeValue == '0'
                                          ? getTranslated(context, None)!
                                          : deliverabletypeValue == '1'
                                              ? getTranslated(context, All)!
                                              : deliverabletypeValue == '2'
                                                  ? getTranslated(
                                                      context, IncludeText)!
                                                  : getTranslated(
                                                      context, ExcludeText)!,
                                    )
                                  : Text(
                                      getTranslated(context, SelectIndicator)!,
                                    ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: primary,
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    deliverableZipcodes = null;
                    deliverableTypeDialog();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  deliverableTypeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, SelectDeliverableTypeText)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  deliverabletypeValue = '0';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, None)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  deliverabletypeValue = '1';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, All)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  deliverabletypeValue = '2';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, IncludeText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  deliverabletypeValue = '3';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, ExcludeText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//============================ Selected Pin codes Type =========================

  selectZipcode() {
    return deliverabletypeValue == "2" || deliverabletypeValue == "3"
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 5,
                        bottom: 5,
                        left: 5,
                        right: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: lightBlack,
                          width: 1,
                        ),
                      ),
                      child: deliverableZipcodes == null
                          ? Text(
                              getTranslated(context, SelectZipCodeText)!,
                            )
                          : Text("$deliverableZipcodes"),
                    ),
                    onTap: () {
                      zipcodeDialog();
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                deliverableZipcodes == null
                    ? Container()
                    : InkWell(
                        onTap: () {
                          setState(
                            () {
                              deliverableZipcodes = null;
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: fontColor),
                          ),
                          child: const Icon(Icons.close, color: red),
                        ),
                      ),
              ],
            ),
          )
        : Container();
  }

  zipcodeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              actions: [
                TextButton(
                  child: Text(
                    getTranslated(context, OkText)!,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    5.0,
                  ),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                    child: Text(
                      getTranslated(context, SelectZipCodeText)!,
                      style: Theme.of(this.context)
                          .textTheme
                          .titleMedium!
                          .copyWith(color: fontColor),
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: () {
                          bool flag = false;
                          return zipSearchList
                              .asMap()
                              .map(
                                (index, element) => MapEntry(
                                  index,
                                  InkWell(
                                    onTap: () {
                                      if (!flag) {
                                        flag = true;
                                      }
                                      if (mounted) {
                                        setState(
                                          () {
                                            if (deliverableZipcodes == null) {
                                              deliverableZipcodes =
                                                  zipSearchList[index].zipcode;
                                            } else if (deliverableZipcodes!
                                                .contains(zipSearchList[index]
                                                    .zipcode!)) {
                                            } else {
                                              deliverableZipcodes =
                                                  "${deliverableZipcodes!},${zipSearchList[index].zipcode!}";
                                            }
                                          },
                                        );
                                      }
                                    },
                                    child: SizedBox(
                                      width: double.maxFinite,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          zipSearchList[index].zipcode!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .values
                              .toList();
                        }(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//========================= select Category Header =============================

  selectCategory() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${getTranslated(context, selectedcategoryText)!} :",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[400],
                      border: Border.all(color: fontColor)),
                  width: 200,
                  height: 20,
                  child: Center(
                    child: selectedCatName == null
                        ? Text(
                            getTranslated(context, NotSelectedText)!,
                          )
                        : Text(selectedCatName!),
                  ),
                )
              ],
            ),
          ),
          Container(
            width: deviceWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: lightWhite,
              border: Border.all(color: fontColor),
            ),
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsetsDirectional.only(
                        bottom: 5, start: 10, end: 10),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: catagorylist.length,
                    itemBuilder: (context, index) {
                      CategoryModel? item;

                      item = catagorylist.isEmpty ? null : catagorylist[index];

                      return item == null ? Container() : getCategorys(index);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  getCategorys(int index) {
    CategoryModel model = catagorylist[index];
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            selectedCatName = model.name;
            selectedCatID = model.id;
            setState(() {});
          },
          child: Row(
            children: [
              const Icon(
                Icons.fiber_manual_record_rounded,
                size: 20,
                color: primary,
              ),
              const SizedBox(
                width: 10,
              ),
              SizedBox(
                width: deviceWidth * 0.6,
                child: Text(
                  model.name!,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Container(
          child: ListView.builder(
            shrinkWrap: true,
            padding:
                const EdgeInsetsDirectional.only(bottom: 5, start: 15, end: 15),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: model.children!.length,
            itemBuilder: (context, index) {
              CategoryModel? item1;
              item1 = model.children!.isEmpty ? null : model.children![index];
              return item1 == null
                  ? Container(
                      child: Text(
                        getTranslated(context, nosubcatText)!,
                      ),
                    )
                  : Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {});
                            selectedCatName = item1!.name;
                            selectedCatID = item1.id;
                          },
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              const Icon(
                                Icons.subdirectory_arrow_right_outlined,
                                color: secondary,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              SizedBox(
                                width: deviceWidth * 0.62,
                                child: Text(
                                  item1.name!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsetsDirectional.only(
                                bottom: 5, start: 10, end: 10),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: item1.children!.length,
                            itemBuilder: (context, index) {
                              CategoryModel? item2;
                              item2 = item1!.children!.isEmpty
                                  ? null
                                  : item1.children![index];
                              return item2 == null
                                  ? Container()
                                  : Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {});
                                            selectedCatName = item2!.name;
                                            selectedCatID = item2.id;
                                          },
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              const Icon(
                                                Icons
                                                    .subdirectory_arrow_right_outlined,
                                                color: primary,
                                                size: 20,
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              SizedBox(
                                                width: deviceWidth * 0.42,
                                                child: Text(
                                                  item2.name!,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            padding: const EdgeInsetsDirectional
                                                    .only(
                                                bottom: 5, start: 10, end: 10),
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: item2.children!.length,
                                            itemBuilder: (context, index) {
                                              CategoryModel? item3;
                                              item3 = item2!.children!.isEmpty
                                                  ? null
                                                  : item2.children![index];
                                              return item3 == null
                                                  ? Container()
                                                  : Column(
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            setState(
                                                              () {},
                                                            );
                                                            selectedCatName =
                                                                item3!.name;
                                                            selectedCatID =
                                                                item3.id;
                                                          },
                                                          child: Row(
                                                            children: [
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              const Icon(
                                                                Icons
                                                                    .subdirectory_arrow_right_outlined,
                                                                color:
                                                                    secondary,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Text(item3.name!),
                                                            ],
                                                          ),
                                                        ),
                                                        Container(
                                                          child:
                                                              ListView.builder(
                                                            shrinkWrap: true,
                                                            padding:
                                                                const EdgeInsetsDirectional
                                                                        .only(
                                                                    bottom: 5,
                                                                    start: 10,
                                                                    end: 10),
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            itemCount: item3
                                                                .children!
                                                                .length,
                                                            itemBuilder:
                                                                (context,
                                                                    index) {
                                                              CategoryModel?
                                                                  item4;
                                                              item4 = item3!
                                                                      .children!
                                                                      .isEmpty
                                                                  ? null
                                                                  : item3.children![
                                                                      index];
                                                              return item4 ==
                                                                      null
                                                                  ? Container()
                                                                  : Column(
                                                                      children: [
                                                                        InkWell(
                                                                          onTap:
                                                                              () {
                                                                            setState(() {});
                                                                            selectedCatName =
                                                                                item4!.name;
                                                                            selectedCatID =
                                                                                item4.id;
                                                                          },
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              const SizedBox(
                                                                                width: 10,
                                                                              ),
                                                                              const Icon(
                                                                                Icons.subdirectory_arrow_right_outlined,
                                                                                color: primary,
                                                                                size: 20,
                                                                              ),
                                                                              const SizedBox(
                                                                                width: 5,
                                                                              ),
                                                                              Text(item4.name!),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          child:
                                                                              ListView.builder(
                                                                            shrinkWrap:
                                                                                true,
                                                                            padding: const EdgeInsetsDirectional.only(
                                                                                bottom: 5,
                                                                                start: 10,
                                                                                end: 10),
                                                                            physics:
                                                                                const NeverScrollableScrollPhysics(),
                                                                            itemCount:
                                                                                item4.children!.length,
                                                                            itemBuilder:
                                                                                (context, index) {
                                                                              CategoryModel? item5;
                                                                              item5 = item4!.children!.isEmpty ? null : item4.children![index];
                                                                              return item5 == null
                                                                                  ? Container()
                                                                                  : Column(
                                                                                      children: [
                                                                                        InkWell(
                                                                                          onTap: () {
                                                                                            setState(() {});
                                                                                            selectedCatName = item5!.name;
                                                                                            selectedCatID = item5.id;
                                                                                          },
                                                                                          child: Row(
                                                                                            children: [
                                                                                              const SizedBox(
                                                                                                width: 10,
                                                                                              ),
                                                                                              const Icon(
                                                                                                Icons.subdirectory_arrow_right_outlined,
                                                                                                color: secondary,
                                                                                                size: 20,
                                                                                              ),
                                                                                              const SizedBox(
                                                                                                width: 5,
                                                                                              ),
                                                                                              Text(item5.name!),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    );
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                            },
                          ),
                        ),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }

//------------------------------------------------------------------------------
//============================= Is Returnable ==================================

  _isReturnable() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 15.0,
          right: 15.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: deviceWidth * 0.5,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  getTranslated(context, IsReturnableText)!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Switch(
              onChanged: (value) {
                setState(
                  () {
                    isreturnable = value;
                    if (value) {
                      isReturnable = "1";
                    } else {
                      isReturnable = "0";
                    }
                  },
                );
              },
              value: isreturnable,
            )
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

//------------------------------------------------------------------------------
//============================= Is COD allowed =================================

  _isCODAllow() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 15.0,
          right: 15.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: deviceWidth * 0.5,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  getTranslated(context, IsCODallowedText)!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Switch(
              onChanged: (value) {
                setState(
                  () {
                    isCODallow = value;
                    if (value) {
                      isCODAllow = "1";
                    } else {
                      isCODAllow = "0";
                    }
                  },
                );
              },
              value: isCODallow,
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

//------------------------------------------------------------------------------
//=========================== Tax included in prices ===========================

  taxIncludedInPrice() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 15.0,
        right: 15.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.5,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getTranslated(context, TaxincludedinpricesText)!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Switch(
            onChanged: (value) {
              setState(
                () {
                  taxincludedInPrice = value;
                  if (value) {
                    taxincludedinPrice = "1";
                  } else {
                    taxincludedinPrice = "0";
                  }
                },
              );
            },
            value: taxincludedInPrice,
          ),
        ],
      ),
    );
  }

//------------------------------------------------------------------------------
//============================= Is Cancelable ==================================

  _isCancelable() {
    if (productType != 'digital_product') {
      return Padding(
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 8.0,
          left: 15.0,
          right: 15.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: deviceWidth * 0.5,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  getTranslated(context, IsCancelableText)!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Switch(
              onChanged: (value) {
                setState(
                  () {
                    iscancelable = value;
                    if (value) {
                      isCancelable = "1";
                    } else {
                      isCancelable = "0";
                    }
                  },
                );
              },
              value: iscancelable,
            )
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

//------------------------------------------------------------------------------
//============================= Till which status ==============================

  tillWhichStatus() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    tillwhichstatus != null
                        ? Text(
                            tillwhichstatus == 'received'
                                ? getTranslated(context, RECEIVED_LBL)!
                                : tillwhichstatus == 'processed'
                                    ? getTranslated(context, PROCESSED_LBL)!
                                    : getTranslated(context, SHIPED_LBL)!,
                          )
                        : Text(
                            getTranslated(context, TillwhichstatusText)!,
                          ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          tillWhichStatusDialog();
        },
      ),
    );
  }

  tillWhichStatusDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  tillwhichstatus = 'received';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, RECEIVED_LBL)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  tillwhichstatus = 'processed';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, PROCESSED_LBL)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // InkWell(
                          //   onTap: () {
                          //     setState(
                          //       () {
                          //         tillwhichstatus = 'shipped';
                          //         Navigator.of(context).pop();
                          //       },
                          //     );
                          //   },
                          //   child: SizedBox(
                          //     width: double.maxFinite,
                          //     child: Padding(
                          //       padding: const EdgeInsets.fromLTRB(
                          //           20.0, 20.0, 20.0, 20.0),
                          //       child: Row(
                          //         mainAxisAlignment:
                          //             MainAxisAlignment.spaceBetween,
                          //         children: [
                          //           Text(
                          //             getTranslated(context, SHIPED_LBL)!,
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//========================= Main Image =========================================

  mainImage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${getTranslated(context, MainImageText)!} * ",
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
                    type: "add",
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

  mainImageFromGallery() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'eps'],
    );
    if (result != null) {
      File image = File(result.files.single.path!);
      setState(() {
        mainImageProductImage = image;
      });
    } else {}
  }

  selectedMainImageShow() {
    return productImage == ''
        ? Container()
        : Image.network(
            productImageUrl,
            width: 100,
            height: 100,
          );
  }

//------------------------------------------------------------------------------
//========================= Other Image ========================================

  otherImages(String from, int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getTranslated(context, OtherImagesText)!,
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
                  builder: (context) => Media(
                    from: from,
                    pos: pos,
                    type: "add",
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

  variantOtherImageShow(int pos) {
    return variationList.length == pos || variationList[pos].imagesUrl == null
        ? Container()
        : SizedBox(
            width: double.infinity,
            height: 105,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: variationList[pos].imagesUrl!.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return InkWell(
                  child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Image.network(
                        variationList[pos].imagesUrl![i],
                        width: 100,
                        height: 100,
                      ),
                      Container(
                        color: Colors.black26,
                        child: const Icon(
                          Icons.clear,
                          size: 15,
                        ),
                      )
                    ],
                  ),
                  onTap: () {
                    if (mounted) {
                      setState(
                        () {
                          variationList[pos].imagesUrl!.removeAt(i);
                        },
                      );
                    }
                  },
                );
              },
            ),
          );
  }

  uploadedOtherImageShow() {
    return otherImageUrl.isEmpty
        ? Container()
        : SizedBox(
            width: double.infinity,
            height: 105,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: otherPhotos.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, i) {
                  if (i < otherPhotos.length) {
                    return InkWell(
                      child: Stack(
                        alignment: AlignmentDirectional.topEnd,
                        children: [
                          Image.network(
                            otherImageUrl[i],
                            width: 100,
                            height: 100,
                          ),
                          Container(
                            color: Colors.black26,
                            child: const Icon(
                              Icons.clear,
                              size: 15,
                            ),
                          )
                        ],
                      ),
                      onTap: () {
                        if (mounted) {
                          otherPhotos.removeAt(i);
                          otherImageUrl.removeAt(i);
                          setState(
                            () {},
                          );
                        }
                      },
                    );
                  } else {
                    return const SizedBox();
                  }
                }),
          );
  }

//------------------------------------------------------------------------------
//========================= Main Image =========================================

  videoUpload() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${getTranslated(context, Video)!} * ",
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
                    from: "video",
                    pos: 0,
                    type: "add",
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

  selectedVideoShow() {
    return uploadedVideoName == ''
        ? Container()
        : Container(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(uploadedVideoName),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          );
  }

//------------------------------------------------------------------------------
//========================= Video Type =========================================

  videoType() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    selectedTypeOfVideo != null
                        ? Text(
                            selectedTypeOfVideo == 'vimeo'
                                ? getTranslated(context, Vimeo)!
                                : selectedTypeOfVideo == 'youtube'
                                    ? getTranslated(context, Youtube)!
                                    : selectedTypeOfVideo == 'Self Hosted'
                                        ? getTranslated(
                                            context, SelfHostedText)!
                                        : getTranslated(
                                            context, SelectVideoTypeText)!,
                          )
                        : Text(
                            getTranslated(context, SelectVideoTypeText)!,
                          ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          videoselectionDialog();
        },
      ),
    );
  }

  videoselectionDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, SelectVideoTypeText)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  selectedTypeOfVideo = null;
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, None)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  selectedTypeOfVideo = 'vimeo';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, Vimeo)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  selectedTypeOfVideo = 'youtube';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, Youtube)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  selectedTypeOfVideo = 'Self Hosted';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, SelfHostedText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//------------------------------------------------------------------------------
//========================= Video Type =========================================

  addUrlOfVideo() {
    return selectedTypeOfVideo == null
        ? Container()
        : selectedTypeOfVideo == 'vimeo'
            ? videoUrlEnterField(
                getTranslated(context, PasteVimeoText)!,
              )
            : selectedTypeOfVideo == 'youtube'
                ? videoUrlEnterField(
                    getTranslated(context, PasteYoutubeText)!,
                  )
                : selectedTypeOfVideo == 'Self Hosted'
                    ? videoUpload()
                    : Container();
  }

  videoUrlEnterField(String hinttitle) {
    return Container(
      height: 65,
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(vidioTypeFocus);
        },
        keyboardType: TextInputType.text,
        controller: vidioTypeController,
        style: const TextStyle(
          color: fontColor,
          fontWeight: FontWeight.normal,
        ),
        focusNode: vidioTypeFocus,
        textInputAction: TextInputAction.next,
        onChanged: (String? value) {
          videoUrl = value;
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: lightWhite,
          hintText: hinttitle,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 20),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: fontColor),
            borderRadius: BorderRadius.circular(7.0),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: const BorderSide(color: lightWhite),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

//------------------------------------------------------------------------------
//========================= Additional Info ====================================

// logic painding

  additionalInfo() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: primary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: curSelPos == 0
                      ? TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primary,
                          disabledForegroundColor:
                              Colors.grey.withOpacity(0.38),
                        )
                      : null,
                  onPressed: () {
                    setState(
                      () {
                        curSelPos = 0;
                      },
                    );
                  },
                  child: Text(
                    getTranslated(context, GeneralInformationText)!,
                  ),
                ),
                TextButton(
                  style: curSelPos == 1
                      ? TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primary,
                          disabledForegroundColor:
                              Colors.grey.withOpacity(0.38),
                        )
                      : null,
                  onPressed: () {
                    setState(
                      () {
                        curSelPos = 1;
                      },
                    );
                  },
                  child: Text(
                    getTranslated(context, AttributesText)!,
                  ),
                ),
                productType == 'variable_product'
                    ? TextButton(
                        style: curSelPos == 2
                            ? TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: primary,
                                disabledForegroundColor:
                                    Colors.grey.withOpacity(0.38),
                              )
                            : null,
                        onPressed: () {
                          setState(
                            () {
                              curSelPos = 2;
                            },
                          );
                        },
                        child: Text(
                          getTranslated(context, VariationsText)!,
                        ),
                      )
                    : Container(),
              ],
            ),
            curSelPos == 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text("${getTranslated(context, TypeOfProduct)!} :"),
                      ),
                      typeSelectionField(),

                      // For Simple Product

                      productType == 'simple_product' ||
                              productType == 'digital_product'
                          ? simpleProductPrice()
                          : Container(),
                      productType == 'simple_product' ||
                              productType == 'digital_product'
                          ? simpleProductSpecialPrice()
                          : Container(),

                      productType == 'digital_product'
                          ? downloadAllowed()
                          : const SizedBox.shrink(),
                      isDownloadAllow && productType == 'digital_product'
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  "${getTranslated(context, DownloadLinkTypeText)!} :"),
                            )
                          : const SizedBox.shrink(),
                      isDownloadAllow && productType == 'digital_product'
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                child: Container(
                                  padding: const EdgeInsets.only(
                                    top: 5,
                                    bottom: 5,
                                    left: 5,
                                    right: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: lightBlack,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            downloadLinkType != null
                                                ? Text(
                                                    downloadLinkType == 'None'
                                                        ? getTranslated(
                                                            context, None)!
                                                        : downloadLinkType ==
                                                                'self_hosted'
                                                            ? getTranslated(
                                                                context,
                                                                SelfHostedText)!
                                                            : getTranslated(
                                                                context,
                                                                AddLinkText)!,
                                                  )
                                                : Text(
                                                    getTranslated(
                                                        context, None)!,
                                                  ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: primary,
                                      )
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                  downloadLinkTypeDialog();
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                      downloadLinkType == 'self_hosted' &&
                              productType == 'digital_product'
                          ? Column(
                              children: [fileUpload(), selectedFileShow()],
                            )
                          : const SizedBox.shrink(),
                      downloadLinkType == 'add_link' &&
                              productType == 'digital_product'
                          ? digitalProductLink()
                          : const SizedBox.shrink(),
                      productType != 'digital_product'
                          ? CheckboxListTile(
                              title: Text(
                                getTranslated(
                                    context, EnableStockManagementText)!,
                              ),
                              value: _isStockSelected ?? false,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isStockSelected = value!;
                                });
                              },
                            )
                          : const SizedBox.shrink(),
                      _isStockSelected != null &&
                              _isStockSelected == true &&
                              productType == 'simple_product'
                          ? simpleProductSKU()
                          : Container(),

                      productType == 'digital_product'
                          ? Align(
                              alignment: Alignment.bottomRight,
                              child: SimBtn(
                                title:
                                    getTranslated(context, SaveSettingsText)!,
                                size: MediaQuery.of(context).size.width * 0.5,
                                onBtnSelected: () {
                                  if (digitalProductPriceController
                                      .text.isEmpty) {
                                    setsnackbar(
                                      getTranslated(context,
                                          PleaseenterproductpriceText)!,
                                      context,
                                    );
                                  } else if (digitalProductSpecialPriceController
                                      .text.isEmpty) {
                                    setState(
                                      () {
                                        setsnackbar(
                                          getTranslated(context,
                                              PleaseenterproductspecialpriceText)!,
                                          context,
                                        );
                                      },
                                    );
                                  } else if (int.parse(digitalproductPrice!) <
                                      int.parse(digitalproductSpecialPrice!)) {
                                    setsnackbar(
                                      getTranslated(
                                          context, SpecialpricemustbelessText)!,
                                      context,
                                    );
                                  } else if (downloadLinkType == null ||
                                      downloadLinkType == 'None') {
                                    setsnackbar(
                                      getTranslated(
                                          context, SelDownloadLinkTypeText)!,
                                      context,
                                    );
                                  } else if (downloadLinkType ==
                                          'self_hosted' &&
                                      uploadFileName == '') {
                                    setsnackbar(
                                      getTranslated(
                                          context, AddDigitalProductFileText)!,
                                      context,
                                    );
                                  } else if (downloadLinkType == 'add_link' &&
                                      (digitalLink == null ||
                                          digitalLink!.isEmpty)) {
                                    setsnackbar(
                                      getTranslated(
                                          context, AddDigitalProductlinkText)!,
                                      context,
                                    );
                                  } else {
                                    setState(
                                      () {
                                        digitalProductSaveSettings = true;
                                        setsnackbar(
                                          getTranslated(context,
                                              SettingsavedsuccessfullyText)!,
                                          context,
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            )
                          : Container(),

                      productType == 'simple_product'
                          ? Align(
                              alignment: Alignment.bottomRight,
                              child: SimBtn(
                                title:
                                    getTranslated(context, SaveSettingsText)!,
                                size: MediaQuery.of(context).size.width * 0.5,
                                onBtnSelected: () {
                                  if (simpleProductPriceController
                                      .text.isEmpty) {
                                    setsnackbar(
                                      getTranslated(context,
                                          PleaseenterproductpriceText)!,
                                      context,
                                    );
                                  } else if (simpleProductSpecialPriceController
                                      .text.isEmpty) {
                                    setState(
                                      () {
                                        //simpleProductSaveSettings = true;
                                        setsnackbar(
                                          getTranslated(context,
                                              PleaseenterproductspecialpriceText)!,
                                          context,
                                        );
                                      },
                                    );
                                  } else if (int.parse(simpleproductPrice!) <
                                      int.parse(simpleproductSpecialPrice!)) {
                                    setsnackbar(
                                      getTranslated(
                                          context, SpecialpricemustbelessText)!,
                                      context,
                                    );
                                  } else {
                                    setState(
                                      () {
                                        simpleProductSaveSettings = true;
                                        setsnackbar(
                                          getTranslated(context,
                                              SettingsavedsuccessfullyText)!,
                                          context,
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            )
                          : Container(),

                      _isStockSelected != null &&
                              _isStockSelected == true &&
                              productType == 'variable_product'
                          ? variableProductStockManagementType()
                          : Container(),

                      productType == 'variable_product' &&
                              variantStockLevelType == "product_level" &&
                              _isStockSelected != null &&
                              _isStockSelected == true
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                variableProductSKU(),
                                variantProductTotalstock(),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${getTranslated(context, StockStatusText)!} :",
                                  ),
                                ),
                                productStockStatusSelect()
                              ],
                            )
                          : Container(),

                      productType == 'variable_product' &&
                              variantStockLevelType == "product_level"
                          ? SimBtn(
                              title: "Save Settings",
                              size: MediaQuery.of(context).size.width * 0.5,
                              onBtnSelected: () {
                                if (_isStockSelected != null &&
                                    _isStockSelected == true &&
                                    (variountProductTotalStock.text.isEmpty ||
                                        stockStatus.isEmpty)) {
                                  setsnackbar(
                                    getTranslated(
                                        context, PleaseenteralldetailsText)!,
                                    context,
                                  );
                                } else {
                                  setState(
                                    () {
                                      variantProductProductLevelSaveSettings =
                                          true;
                                      setsnackbar(
                                        getTranslated(context,
                                            SettingsavedsuccessfullyText)!,
                                        context,
                                      );
                                    },
                                  );
                                }
                              },
                            )
                          : Container(),
                      productType == 'variable_product' &&
                              variantStockLevelType == "variable_level"
                          ? SimBtn(
                              title: getTranslated(context, SaveSettingsText)!,
                              size: MediaQuery.of(context).size.width * 0.5,
                              onBtnSelected: () {
                                setState(
                                  () {
                                    variantProductVariableLevelSaveSettings =
                                        true;
                                    setsnackbar(
                                      getTranslated(context,
                                          SettingsavedsuccessfullyText)!,
                                      context,
                                    );
                                  },
                                );
                              },
                            )
                          : Container(),
                    ],
                  )
                : Container(),
            curSelPos == 1 &&
                    (simpleProductSaveSettings ||
                        variantProductVariableLevelSaveSettings ||
                        variantProductProductLevelSaveSettings ||
                        digitalProductSaveSettings)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                child: Text(
                                  getTranslated(context, AttributesText)!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  if (attributeIndiacator ==
                                      _attrController.length) {
                                    setState(() {
                                      _attrController
                                          .add(TextEditingController());
                                      _attrValController
                                          .add(TextEditingController());
                                      variationBoolList.add(false);
                                    });
                                  } else {
                                    setsnackbar(
                                      getTranslated(context,
                                          filltheboxthenaddanotherText)!,
                                      context,
                                    );
                                  }
                                },
                                child: Text(
                                  getTranslated(context, AddAttributeText)!,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  tempAttList.clear();
                                  List<String> attributeIds = [];
                                  for (var i = 0;
                                      i < variationBoolList.length;
                                      i++) {
                                    if (variationBoolList[i]) {
                                      final attributes = attributesList
                                          .where((element) =>
                                              element.name ==
                                              _attrController[i].text)
                                          .toList();
                                      if (attributes.isNotEmpty) {
                                        attributeIds.add(attributes.first.id!);
                                      }
                                    }
                                  }
                                  setState(
                                    () {
                                      resultAttr = [];
                                      resultID = [];
                                      variationList = [];
                                      finalAttList = [];
                                      for (var key in attributeIds) {
                                        tempAttList
                                            .add(selectedAttributeValues[key]!);
                                      }
                                      for (int i = 0;
                                          i < tempAttList.length;
                                          i++) {
                                        finalAttList.add(tempAttList[i]);
                                      }
                                      if (finalAttList.isNotEmpty) {
                                        max = finalAttList.length - 1;

                                        getCombination([], [], 0);
                                        row = 1;
                                        col = max + 1;
                                        for (int i = 0; i < col; i++) {
                                          int singleRow =
                                              finalAttList[i].length;
                                          row = row * singleRow;
                                        }
                                      }
                                      setsnackbar(
                                        getTranslated(context,
                                            AttributessavedsuccessfullyText)!,
                                        context,
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  getTranslated(context, SaveAttributeText)!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      productType == 'variable_product'
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                getTranslated(context, selectcheckboxText)!,
                              ),
                            )
                          : Container(),
                      for (int i = 0; i < _attrController.length; i++)
                        addAttribute(i)
                    ],
                  )
                : Container(),
            curSelPos == 2 && variationList.isNotEmpty
                ? ListView.builder(
                    itemCount: row,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      return ExpansionTile(
                        title: Row(
                          children: [
                            for (int j = 0; j < col; j++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(variationList[i]
                                      .attr_name!
                                      .split(',')[j]),
                                ),
                              ),
                            InkWell(
                              child: const Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Icon(
                                  Icons.close,
                                ),
                              ),
                              onTap: () {
                                setState(
                                  () {
                                    variationList.removeAt(i);

                                    for (int i = 0;
                                        i < variationList.length;
                                        i++) {
                                      row = row - 1;
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        children: <Widget>[
                          Column(
                            children: _buildExpandableContent(i),
                          ),
                        ],
                      );
                    },
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  downloadAllowed() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.5,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getTranslated(context, IsDownloadAllowedText)!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Switch(
            onChanged: (value) {
              setState(
                () {
                  isDownloadAllow = value;
                  if (value) {
                    isDownloadAllowed = "1";
                  } else {
                    isDownloadAllowed = "0";
                  }
                },
              );
            },
            value: isDownloadAllow,
          ),
        ],
      ),
    );
  }

  digitalProductLink() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, DigitalProLinkText)!,
            style: const TextStyle(
              fontSize: 16,
              color: fontColor,
            ),
          ),
          const SizedBox(
            height: 05,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: lightBlack,
                width: 1,
              ),
            ),
            width: deviceWidth,
            height: deviceHeight * 0.06,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
              ),
              child: TextFormField(
                textInputAction: TextInputAction.done,
                // keyboardType: TextInputType.multiline,
                validator: (val) => urlValidation(val!, context),
                onChanged: (value) {
                  digitalLink = value;
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  hintText: getTranslated(context, DigitalProLinkHintText)!,
                ),
                minLines: null,
                maxLines: null,
                expands: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  fileUpload() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getTranslated(context, SelectFileText)!,
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
                    from: "file",
                    type: "add",
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

  selectedFileShow() {
    return uploadFileName == ''
        ? Container()
        : Container(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(uploadFileName),
            ),
          );
  }

  getCombination(List<String> att, List<String> attId, int i) {
    for (int j = 0, l = finalAttList[i].length; j < l; j++) {
      List<String> a = [];
      List<String> aId = [];
      if (att.isNotEmpty) {
        a.addAll(att);
        aId.addAll(attId);
      }
      a.add(finalAttList[i][j].value!);
      aId.add(finalAttList[i][j].id!);
      if (i == max) {
        resultAttr.addAll(a);
        resultID.addAll(aId);
        Product_Varient model =
            Product_Varient(attr_name: a.join(","), id: aId.join(","));
        variationList.add(model);
      } else {
        getCombination(a, aId, i + 1);
      }
    }
  }

  _buildExpandableContent(int pos) {
    List<Widget> columnContent = [];

    columnContent.add(
      variantProductPrice(pos),
    );
    columnContent.add(
      variantProductSpecialPrice(pos),
    );

    columnContent.add(productType == 'variable_product' &&
            variantStockLevelType == "variable_level" &&
            _isStockSelected != null &&
            _isStockSelected == true
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              variableVariableSKU(pos),
              variantVariableTotalstock(pos),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "${getTranslated(context, StockStatusText)!} :",
                ),
              ),
              variantStockStatusSelect(pos)
            ],
          )
        : Container());

    columnContent.add(otherImages("variant", pos));

    columnContent.add(variantOtherImageShow(pos));
    return columnContent;
  }

  Widget variantProductPrice(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, PRICE_LBL)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.4,
            height: 40,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              keyboardType: TextInputType.number,
              initialValue: variationList[pos].price ?? '',
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (String? value) {
                variationList[pos].price = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget variantProductSpecialPrice(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, SpecialPriceText)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.4,
            height: 40,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              keyboardType: TextInputType.number,
              initialValue: variationList[pos].disPrice ?? '',
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (String? value) {
                variationList[pos].disPrice = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  addValAttribute(List<AttributeValueModel> selected,
      List<AttributeValueModel> searchRange, String attributeId) {
    showModalBottomSheet<List<AttributeValueModel>>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
      ),
      enableDrag: true,
      context: context,
      builder: (context) {
        return SizedBox(
          height: 240,
          width: MediaQuery.of(context).size.width,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Select Attribute Value",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    mainAxisSpacing: 5.0,
                    crossAxisSpacing: 5.0),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return filterChipWidget(
                      chipName: searchRange[index],
                      selectedList: selected,
                      update: update,
                    );
                  },
                  childCount: searchRange.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  update() {
    setState(
      () {},
    );
  }

  addAttribute(int pos) {
    final result = attributesList
        .where((element) => element.name == _attrController[pos].text)
        .toList();
    final attributeId = result.isEmpty ? "" : result.first.id;
    return Card(
      color: const Color(0xffDCDCDC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslated(context, SelectAttribute)!,
                ),
                Checkbox(
                  value: variationBoolList[pos],
                  onChanged: (bool? value) {
                    setState(() {
                      variationBoolList[pos] = value ?? false;
                    });
                  },
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextFormField(
              textAlign: TextAlign.center,
              readOnly: true,
              onTap: () {
                attributeDialog(pos);
              },
              controller: _attrController[pos],
              keyboardType: TextInputType.text,
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                hintText: getTranslated(context, SelectAttribute)!,
                hintStyle: Theme.of(context).textTheme.bodySmall,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: GestureDetector(
              onTap: () {
                final attributeValues = attributesValueList
                    .where((element) => element.attributeId == attributeId)
                    .toList();
                for (var e in attributeValues) {}
                addValAttribute(selectedAttributeValues[attributeId]!,
                    attributeValues, attributeId!);
              },
              child: Container(
                width: deviceWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7.0),
                  color: lightWhite,
                ),
                constraints: const BoxConstraints(
                  minHeight: 50,
                ),
                child: (selectedAttributeValues[attributeId!] ?? []).isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Center(
                          child: Text(
                            getTranslated(context, AddattributevalueText)!,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Wrap(
                        alignment: WrapAlignment.center,
                        direction: Axis.horizontal,
                        children: selectedAttributeValues[attributeId]!
                            .map(
                              (value) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: primary_app,
                                    border: Border.all(
                                      color: fontColor,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      value.value!,
                                      style: const TextStyle(
                                        color: white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  productStockStatusSelect() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    stockStatus != null
                        ? Text(
                            stockStatus == '1'
                                ? getTranslated(context, InStockText)!
                                : getTranslated(context, OutofStock)!,
                          )
                        : Text(
                            getTranslated(context, SelectStockStatusText)!,
                          ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          variantStockStatusDialog("product", 0);
        },
      ),
    );
  }

  variantStockStatusSelect(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      variationList[pos].stockStatus == '1'
                          ? getTranslated(context, InStockText)!
                          : getTranslated(context, OutofStock)!,
                    )
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          variantStockStatusDialog("variable", pos);
        },
      ),
    );
  }

  variantStockStatusDialog(String from, int pos) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, SelectTypeText)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  if (from == 'variable') {
                                    variationList[pos].stockStatus = "1";
                                  } else {
                                    stockStatus = '1';
                                  }
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, InStockText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  if (from == 'variable') {
                                    variationList[pos].stockStatus = "0";
                                  } else {
                                    stockStatus = '0';
                                  }
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, OutofStock)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  variantVariableTotalstock(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, TotalStockText)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.4,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              keyboardType: TextInputType.number,
              initialValue: variationList[pos].stock ?? '',
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: variountProductTotalStockFocus,
              textInputAction: TextInputAction.next,
              onChanged: (String? value) {
                variationList[pos].stock = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget variableVariableSKU(int pos) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, SKUText)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.4,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              onFieldSubmitted: (v) {
                FocusScope.of(context).requestFocus(variountProductSKUFocus);
              },
              initialValue: variationList[pos].sku ?? '',
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: variountProductSKUFocus,
              textInputAction: TextInputAction.next,
              onChanged: (String? value) {
                variationList[pos].sku = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  variantProductTotalstock() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, TotalStockText)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.4,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              onFieldSubmitted: (v) {
                FocusScope.of(context)
                    .requestFocus(variountProductTotalStockFocus);
              },
              keyboardType: TextInputType.number,
              controller: variountProductTotalStock,
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: variountProductTotalStockFocus,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (String? value) {
                variantproductTotalStock = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget variableProductSKU() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, SKUText)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.4,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              onFieldSubmitted: (v) {
                FocusScope.of(context).requestFocus(variountProductSKUFocus);
              },
              controller: variountProductSKUController,
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: variountProductSKUFocus,
              textInputAction: TextInputAction.next,
              onChanged: (String? value) {
                variantproductSKU = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

//==============================================================================
//=========================== Simple Product Fields ============================

  simpleProductPrice() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, PRICE_LBL)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.3,
            height: 40,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              onFieldSubmitted: (v) {
                FocusScope.of(context).requestFocus(simpleProductPriceFocus);
              },
              keyboardType: TextInputType.number,
              controller: productType == 'digital_product'
                  ? digitalProductPriceController
                  : simpleProductPriceController,
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: simpleProductPriceFocus,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (String? value) {
                if (productType == 'digital_product') {
                  digitalproductPrice = value;
                } else {
                  simpleproductPrice = value;
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  simpleProductSpecialPrice() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, SpecialPriceText)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.3,
            height: 40,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              onFieldSubmitted: (v) {
                FocusScope.of(context)
                    .requestFocus(simpleProductSpecialPriceFocus);
              },
              keyboardType: TextInputType.number,
              controller: productType == 'digital_product'
                  ? digitalProductSpecialPriceController
                  : simpleProductSpecialPriceController,
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: simpleProductSpecialPriceFocus,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (String? value) {
                if (productType == 'digital_product') {
                  digitalproductSpecialPrice = value;
                } else {
                  simpleproductSpecialPrice = value;
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget simpleProductSKU() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: deviceWidth * 0.4,
                child: Text(
                  "${getTranslated(context, SKUText)!} :",
                  style: const TextStyle(
                    fontSize: 16,
                    color: fontColor,
                  ),
                  maxLines: 2,
                ),
              ),
              Container(
                width: deviceWidth * 0.3,
                height: 40,
                padding: const EdgeInsets.only(),
                child: TextFormField(
                  onFieldSubmitted: (v) {
                    FocusScope.of(context).requestFocus(simpleProductSKUFocus);
                  },
                  keyboardType: TextInputType.text,
                  controller: simpleProductSKUController,
                  style: const TextStyle(
                    color: fontColor,
                    fontWeight: FontWeight.normal,
                  ),
                  focusNode: simpleProductSKUFocus,
                  textInputAction: TextInputAction.next,
                  onChanged: (String? value) {
                    simpleproductSKU = value;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: lightWhite,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 40, maxHeight: 20),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: fontColor),
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: const BorderSide(color: lightWhite),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        simpleProductTotalstock(),
        simpleProductStockStatusSelect()
      ],
    );
  }

  simpleProductStockStatusSelect() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    simpleproductStockStatus != null
                        ? Text(
                            simpleproductStockStatus == '1'
                                ? getTranslated(context, InStockText)!
                                : getTranslated(context, OutofStock)!,
                          )
                        : Text(
                            getTranslated(context, SelectStockStatusText)!,
                          ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          stockStatusDialog();
        },
      ),
    );
  }

  stockStatusDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, SelectTypeText)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  simpleproductStockStatus = '1';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, InStockText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  simpleproductStockStatus = '0';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, OutofStock)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget simpleProductTotalstock() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: deviceWidth * 0.4,
            child: Text(
              "${getTranslated(context, TotalStockText)!} :",
              style: const TextStyle(
                fontSize: 16,
                color: fontColor,
              ),
              maxLines: 2,
            ),
          ),
          Container(
            width: deviceWidth * 0.3,
            height: 40,
            padding: const EdgeInsets.only(),
            child: TextFormField(
              onFieldSubmitted: (v) {
                FocusScope.of(context)
                    .requestFocus(simpleProductTotalStockFocus);
              },
              keyboardType: TextInputType.number,
              controller: simpleProductTotalStock,
              style: const TextStyle(
                color: fontColor,
                fontWeight: FontWeight.normal,
              ),
              focusNode: simpleProductTotalStockFocus,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (String? value) {
                simpleproductTotalStock = value;
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: lightWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, maxHeight: 20),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: fontColor),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: const BorderSide(color: lightWhite),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  typeSelectionField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    productType != null
                        ? Text(
                            productType == 'simple_product'
                                ? getTranslated(context, SimpleProductText)!
                                : productType == 'digital_product'
                                    ? getTranslated(
                                        context, DigitalProductText)!
                                    : getTranslated(
                                        context, VariableProductText)!,
                          )
                        : Text(
                            getTranslated(context, SelectTypeText)!,
                          ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          if (productType != 'digital_product') {
            FocusScope.of(context).requestFocus(FocusNode());
            productTypeDialog();
          }
        },
      ),
    );
  }

  downloadLinkTypeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, DownloadLinkTypeText)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  downloadLinkType = 'None';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, None)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  downloadLinkType = 'self_hosted';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, SelfHostedText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  downloadLinkType = 'add_link';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, AddLinkText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  productTypeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, SelectTypeText)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  variantProductVariableLevelSaveSettings =
                                      false;
                                  variantProductProductLevelSaveSettings =
                                      false;
                                  simpleProductSaveSettings = false;
                                  productType = 'simple_product';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(
                                          context, SimpleProductText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  //----reset----
                                  simpleProductPriceController.text = '';
                                  simpleProductSpecialPriceController.text = '';
                                  _isStockSelected = false;

                                  //--------------set
                                  variantProductVariableLevelSaveSettings =
                                      false;
                                  variantProductProductLevelSaveSettings =
                                      false;
                                  simpleProductSaveSettings = false;
                                  productType = 'variable_product';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(
                                          context, VariableProductText)!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//==============================================================================
//=========================== Variable Product Fields ==========================

// Choose Stock Management Type:

  variableProductStockManagementType() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${getTranslated(context, ChooseStockManagementTypeType)!} :",
        ),
        variableProductStockManagementTypeSelection(),
      ],
    );
  }

  variableProductStockManagementTypeSelection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 5,
            left: 5,
            right: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: lightBlack,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    variantStockLevelType != null
                        ? Expanded(
                            child: Text(
                              variantStockLevelType == 'product_level'
                                  ? getTranslated(
                                      context, ProductLevelStockText)!
                                  : getTranslated(
                                      context, VariantLevelStockText)!,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          )
                        : Expanded(
                            child: Text(
                              getTranslated(context, SelectStockStatusText)!,
                            ),
                          ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: primary,
              )
            ],
          ),
        ),
        onTap: () {
          variountProductStockManagementTypeDialog();
        },
      ),
    );
  }

  variountProductStockManagementTypeDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            taxesState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(5.0),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated(context, SelectStockStatusText)!,
                          style: Theme.of(this.context)
                              .textTheme
                              .titleMedium!
                              .copyWith(color: fontColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  variantStockLevelType = 'product_level';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        getTranslated(
                                            context, ProductLevelStockText)!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(
                                () {
                                  variantStockLevelType = 'variable_level';
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                            child: SizedBox(
                              width: double.maxFinite,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20.0, 20.0, 20.0, 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        getTranslated(
                                            context, VariantLevelStockText)!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

//==============================================================================
//=========================== Description ======================================

// without validation logic is clear

  longDescription() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        left: 8.0,
        right: 8.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${getTranslated(context, DescriptionText)!} :",
                style: const TextStyle(fontSize: 16),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<String>(
                      builder: (context) =>
                          ProductDescription(description ?? ""),
                    ),
                  ).then((changed) {
                    description = changed;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  // width: 120,
                  // height: 20,
                  child: Center(
                    child: (description == "" || description == null)
                        ? Text(
                            getTranslated(context, AddDescriptionText)!,
                            style: const TextStyle(
                              color: white,
                            ),
                          )
                        : Text(
                            getTranslated(context, EditText)!,
                            style: const TextStyle(
                              color: white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 05,
          ),
          (description == "" || description == null)
              ? Container()
              : Container(
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
                      data: description ?? "",
                    ),
                  ),
                ),
        ],
      ),
    );
  }

//==============================================================================
//=========================== Add Product Button ===============================

  resetProButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<String>(
                builder: (context) => const AddProduct(),
              ),
            );
            setsnackbar("Reset Successfully", context);
          },
          child: Container(
            height: 50,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: lightBlack2,
            ),
            child: Center(
              child: Text(
                getTranslated(context, "Reset All")!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

//==============================================================================
//=========================== Add Product API Call =============================

  Future<void> addProductAPI(List<String> attributesValuesIds) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var request = http.MultipartRequest("POST", addProductsApi);
        print(addProductsApi);
        request.headers.addAll(headers);

        if (productType != 'digital_product') {
          request.fields['cod_allowed'] = isCODAllow!;
          request.fields['is_returnable'] = isReturnable!;
          request.fields['is_cancelable'] = isCancelable!;
          if (tillwhichstatus != null) {
            request.fields['cancelable_till'] = tillwhichstatus!;
          }
          if (indicatorValue != null) {
            request.fields['indicator'] = indicatorValue!;
          }
          request.fields['total_allowed_quantity'] = totalAllowQuantity!;
          request.fields['minimum_order_quantity'] = minOrderQuantity!;
          request.fields['quantity_step_size'] = quantityStepSize!;
          if (warrantyPeriod != null) {
            request.fields['warranty_period'] = warrantyPeriod!;
          }
          if (guaranteePeriod != null) {
            request.fields['guarantee_period'] = guaranteePeriod!;
          }
          request.fields['deliverable_type'] = deliverabletypeValue!;
          request.fields['deliverable_zipcodes'] =
              deliverableZipcodes ?? "null";
          request.fields['variant_stock_level_type'] = variantStockLevelType!;
          request.fields['attribute_values'] = attributesValuesIds.join(",");
        } else {
          request.fields['simple_price'] = digitalProductPriceController.text;
          request.fields['simple_special_price'] =
              digitalProductSpecialPriceController.text;
          request.fields['deliverable_type'] = "0";
          request.fields['download_allowed'] = isDownloadAllowed!;
          request.fields['download_link_type'] = downloadLinkType!;
          if (downloadLinkType == 'self_hosted') {
            request.fields['pro_input_zip'] = uploadFileName;
          }
          if (downloadLinkType == 'add_link') {
            request.fields['download_link'] = digitalLink!;
          }
        }

        request.fields[USER_ID] = CUR_USERID!;
        request.fields['pro_input_name'] = productName!;
        request.fields['short_description'] = sortDescription!;
        request.fields['product_identity'] = IdentificationofProduct!;
        if (tags != null) request.fields['tags'] = tags!;
        if (taxId != null) request.fields['pro_input_tax'] = taxId!;

        if (madeIn != null) request.fields['made_in'] = madeIn!;

        request.fields['is_prices_inclusive_tax'] = taxincludedinPrice!;

        request.fields['pro_input_image'] = productImage;

        if (otherPhotos.isNotEmpty) {
          request.fields['other_images'] = otherPhotos.join(",");
        }
        if (selectedTypeOfVideo != null) {
          request.fields['video_type'] = selectedTypeOfVideo!;
        }
        if (videoUrl != null) request.fields['video'] = videoUrl!;
        if (uploadedVideoName != '') {
          request.fields['pro_input_video'] = uploadedVideoName;
        }
        if (description != null) {
          request.fields['pro_input_description'] = description!;
        }
        request.fields['category_id'] = selectedCatID!;
        request.fields['product_type'] = productType!;

        if (selectedBrandName != null) {
          request.fields['brand'] = selectedBrandName!;
        }

        if (productType == 'simple_product') {
          String? status;
          if (_isStockSelected == null) {
            status = null;
          } else {
            status = simpleproductStockStatus;
          }
          request.fields['simple_product_stock_status'] = status ?? 'null';
          request.fields['simple_price'] = simpleProductPriceController.text;
          request.fields['simple_special_price'] =
              simpleProductSpecialPriceController.text;
          if (_isStockSelected != null &&
              _isStockSelected == true &&
              simpleproductSKU != null) {
            request.fields['product_sku'] = simpleproductSKU!;
            request.fields['product_total_stock'] = simpleproductTotalStock!;
            request.fields['variant_stock_status'] = "0";
          }
        } else if (productType == 'variable_product') {
          String val = '', price = '', sprice = '', images = '';
          List<List<String>> imagesList = [];

          for (int i = 0; i < variationList.length; i++) {
            String testing = "";
            if (variationList[i].attribute_value_ids.toString() != "null") {
              testing =
                  variationList[i].attribute_value_ids!.replaceAll(',', ' ');
            } else {
              testing = variationList[i].id!.replaceAll(',', ' ');
            }
            if (testing != "") {
              if (val == '') {
                val = variationList[i].id!.replaceAll(',', ' ');
                price = variationList[i].price!;
                sprice = variationList[i].disPrice ?? ' ';
              } else {
                val = "$val,${variationList[i].id!.replaceAll(',', ' ')}";
                price = "$price,${variationList[i].price!}";
                sprice = "$sprice,${variationList[i].disPrice ?? ' '}";
              }
            }
            if (variationList[i].imageRelativePath != null) {
              if (variationList[i].imageRelativePath!.isNotEmpty &&
                  images != '') {
                images =
                    '$images,${variationList[i].imageRelativePath!.join(",")}';
              } else if (variationList[i].imageRelativePath!.isNotEmpty &&
                  images == '') {
                images = variationList[i].imageRelativePath!.join(",");
              }
              List<String> subListofImage = images.split(',');
              for (int j = 0; j < subListofImage.length; j++) {
                subListofImage[j] = '"${subListofImage[j]}"';
              }
              imagesList.add(subListofImage);
            }
          }

          request.fields['variants_ids'] = val;
          request.fields['variant_price'] = price;
          request.fields['variant_special_price'] = sprice;
          request.fields['variant_images'] = imagesList.toString();

          if (variantStockLevelType == 'product_level') {
            request.fields['sku_variant_type'] =
                variountProductSKUController.text;
            request.fields['total_stock_variant_type'] =
                variountProductTotalStock.text;
            request.fields['variant_status'] = stockStatus;
          } else if (variantStockLevelType == 'variable_level') {
            String sku = '', totalStock = '', stkStatus = '';
            for (int i = 0; i < variationList.length; i++) {
              if (sku == '') {
                sku = variationList[i].sku!;
                totalStock = variationList[i].stock!;
                stkStatus = variationList[i].stockStatus!;
              } else {
                sku = "$sku,${variationList[i].sku!}";
                totalStock = "$totalStock,${variationList[i].stock!}";
                stkStatus = "$stkStatus,${variationList[i].stockStatus!}";
              }
            }

            request.fields['variant_sku'] = sku;
            request.fields['variant_total_stock'] = totalStock;
            request.fields['variant_level_stock_status'] = stkStatus;
          }
        }
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

          setsnackbar(msg, context);
          Navigator.pop(context, 'refresh');
          //MaterialPageRoute(builder: (context) => const ProductList()));
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

//==============================================================================
//=========================== Body Part ========================================

  getBodyPart() {
    return SingleChildScrollView(
      child: Form(
        key: _formkey,
        child: Column(
          children: [
            addProductName(),
            shortDescription(),
            productTypeField(),
            identificationofProduct(),
            tagsAdd(),
            taxSelection(),
            indicatorField(),
            totalAllowedQuantity(),
            minimumOrderQuantity(),
            _quantityStepSize(),
            _madeIn(),
            _warrantyPeriod(),
            _guaranteePeriod(),
            brandSelectWidget(),
            deliverableType(),
            selectZipcode(),
            selectCategory(),
            _isReturnable(),
            _isCODAllow(),
            taxIncludedInPrice(),
            _isCancelable(),
            isCancelable == "1" ? tillWhichStatus() : Container(),
            mainImage(),
            selectedMainImageShow(),
            otherImages("other", 0),
            uploadedOtherImageShow(),
            selectedVideoShow(),
            videoType(),
            addUrlOfVideo(),
            longDescription(),
            additionalInfo(),
            AppBtn(
              title: getTranslated(context, AddProductText)!,
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                validateAndSubmit();
              },
            ),
            resetProButton(),
            const SizedBox(
              width: 20,
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  void validateAndSubmit() async {
    List<String> attributeIds = [];
    List<String> attributesValuesIds = [];

    for (var i = 0; i < variationBoolList.length; i++) {
      if (variationBoolList[i]) {
        final attributes = attributesList
            .where((element) => element.name == _attrController[i].text)
            .toList();
        if (attributes.isNotEmpty) {
          attributeIds.add(attributes.first.id!);
        }
      }
    }
    for (var key in attributeIds) {
      for (var element in selectedAttributeValues[key]!) {
        attributesValuesIds.add(element.id!);
      }
    }
    if (validateAndSave()) {
      _playAnimation();
      addProductAPI(attributesValuesIds);
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      if (productType == null) {
        setsnackbar(
            getTranslated(context, PleaseselectproducttypeText)!, context);
        return false;
      } else if (description == '' && description == null) {
        setsnackbar(
            getTranslated(context, PleaseaddproductimageText)!, context);
        return false;
      } else if (productImage == '' && mainImageProductImage == "") {
        setsnackbar(getTranslated(context, PleaseselectcategoryText)!, context);
        return false;
      } else if (selectedCatID == null) {
        setsnackbar(getTranslated(context, PleaseselectcategoryText)!, context);
        return false;
      } else if (selectedTypeOfVideo != null && videoUrl == null) {
        setsnackbar(getTranslated(context, PleaseentervideourlText)!, context);
        return false;
      } else if (productType == 'simple_product') {
        if (simpleProductPriceController.text.isEmpty) {
          setsnackbar(
              getTranslated(context, PleaseenterproductpriceText)!, context);
          return false;
        } else if (simpleProductPriceController.text.isNotEmpty &&
            simpleProductSpecialPriceController.text.isNotEmpty &&
            double.parse(simpleProductSpecialPriceController.text) >
                double.parse(simpleProductPriceController.text)) {
          setsnackbar(getTranslated(context, SpecialpriceText)!, context);
          return false;
        } else if (_isStockSelected != null && _isStockSelected == true) {
          if (simpleproductSKU == null || simpleproductTotalStock == null) {
            setsnackbar(
                getTranslated(context, PleaseenterstockdetailsText)!, context);
            return false;
          }
          return true;
        }
        return true;
      } else if (productType == 'variable_product') {
        for (int i = 0; i < variationList.length; i++) {
          if (variationList[i].price == null ||
              variationList[i].price!.isEmpty) {
            setsnackbar(
                getTranslated(context, PleaseenterpricedetailsText)!, context);
            return false;
          }
        }
        if (_isStockSelected != null && _isStockSelected == true) {
          if (variantStockLevelType == "product_level" &&
              (variantproductSKU == null || variantproductTotalStock == null)) {
            setsnackbar(
                getTranslated(context, PleaseenterstockdetailsText)!, context);
            return false;
          }

          if (variantStockLevelType == "variable_level") {
            for (int i = 0; i < variationList.length; i++) {
              if (variationList[i].sku == null ||
                  variationList[i].sku!.isEmpty ||
                  variationList[i].stock == null ||
                  variationList[i].stock!.isEmpty) {
                setsnackbar(
                    getTranslated(context, PleaseenterstockdetailsText)!,
                    context);
                return false;
              }
            }
            return true;
          }
          return true;
        }
      } else if (productType == 'digital_product') {
        if (digitalProductPriceController.text.isEmpty) {
          setsnackbar(
            getTranslated(context, PleaseenterproductpriceText)!,
            context,
          );
          return false;
        } else if (digitalProductSpecialPriceController.text.isEmpty) {
          setState(
            () {
              setsnackbar(
                getTranslated(context, PleaseenterproductspecialpriceText)!,
                context,
              );
            },
          );
          return false;
        } else if (int.parse(digitalproductPrice!) <
            int.parse(digitalproductSpecialPrice!)) {
          setsnackbar(
            getTranslated(context, SpecialpricemustbelessText)!,
            context,
          );
          return false;
        } else if (downloadLinkType == null || downloadLinkType == 'None') {
          setsnackbar(
            getTranslated(context, SelDownloadLinkTypeText)!,
            context,
          );
          return false;
        } else if (downloadLinkType == 'self_hosted' && uploadFileName == '') {
          setsnackbar(
            getTranslated(context, AddDigitalProductFileText)!,
            context,
          );
          return false;
        } else if (downloadLinkType == 'add_link' &&
            (digitalLink == null || digitalLink!.isEmpty)) {
          setsnackbar(
            getTranslated(context, AddDigitalProductlinkText)!,
            context,
          );
          return false;
        }
        return true;
      }

      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: getAppBar(
        getTranslated(context, AddNewProduct)!,
        context,
      ),
      body: _isNetworkAvail ? getBodyPart() : noInternet(context),
    );
  }
}

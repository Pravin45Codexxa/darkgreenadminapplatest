import 'package:admin_eshop/Helper/String.dart';

class SectionModel {
  String? id,
      title,
      varientId,
      qty,
      productId,
      perItemTotal,
      perItemPrice,
      style;
  List<Product>? productList;
  List<Filter>? filterList;
  List<String>? selectedId = [];
  int? offset, totalItem;

  SectionModel(
      {this.id,
      this.title,
      this.productList,
      this.varientId,
      this.qty,
      this.productId,
      this.perItemTotal,
      this.perItemPrice,
      this.style,
      this.totalItem,
      this.offset,
      this.selectedId,
      this.filterList});

  factory SectionModel.fromJson(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => Product.fromJson(data))
        .toList();

    var flist = (parsedJson[FILTERS] as List?);
    List<Filter> filterList = [];
    if (flist == null || flist.isEmpty) {
      filterList = [];
    } else {
      filterList = flist.map((data) => Filter.fromJson(data)).toList();
    }
    List<String> selected = [];
    return SectionModel(
        id: parsedJson[ID],
        title: parsedJson[TITLE],
        style: parsedJson[STYLE],
        productList: productList,
        offset: 0,
        totalItem: 0,
        filterList: filterList,
        selectedId: selected);
  }

  factory SectionModel.fromCart(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => Product.fromJson(data))
        .toList();

    return SectionModel(
        id: parsedJson[ID],
        varientId: parsedJson[PRODUCT_VARIENT_ID],
        qty: parsedJson[QTY],
        perItemTotal: "0",
        perItemPrice: "0",
        productList: productList);
  }

  factory SectionModel.fromFav(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => Product.fromJson(data))
        .toList();

    return SectionModel(
        id: parsedJson[ID],
        productId: parsedJson[PRODUCT_ID],
        productList: productList);
  }
}

class Product {
  String? id,
      name,
      desc,
      image,
      catName,
      type,
      rating,
      productIdentity,
      noOfRating,
      attrIds,
      tax,
      taxId,
      relativeImagePath,
      categoryId,
      sku,
      shortDescription,
      stock;
  List<String>? otherImage;
  List<String>? showOtherImage;
  List<Product_Varient>? prVarientList;
  List<Attribute>? attributeList;
  List<String>? selectedId = [];
  List<String>? tagList = [];
  String? isFav,
      isReturnable,
      isCancelable,
      isPurchased,
      taxincludedInPrice,
      isCODAllow,
      availability,
      madein,
      indicator,
      stockType,
      cancleTill,
      total,
      banner,
      totalAllow,
      video,
      videoType,
      warranty,
      minimumOrderQuantity,
      quantityStepSize,
      madeIn,
      deliverableType,
      deliverableZipcodesIds,
      deliverableZipcodes,
      cancelableTill,
      description,
      gurantee,
      brand,
      downloadAllow,
      downloadType,
      downloadLink;

  bool? isFavLoading = false, isFromProd = false;
  int? offset, totalItem, selVarient;

  List<Product>? subList;
  List<Filter>? filterList;

  Product(
      {this.id,
      this.name,
      this.desc,
      this.image,
      this.catName,
      this.type,
      this.productIdentity,
      this.otherImage,
      this.prVarientList,
      this.relativeImagePath,
      this.sku,
      this.attributeList,
      this.isFav,
      this.isCancelable,
      this.isReturnable,
      this.isCODAllow,
      this.isPurchased,
      this.availability,
      this.noOfRating,
      this.attrIds,
      this.selectedId,
      this.rating,
      this.isFavLoading,
      this.indicator,
      this.madein,
      this.tax,
      this.taxId,
      this.shortDescription,
      this.total,
      this.categoryId,
      this.subList,
      this.filterList,
      this.stockType,
      this.isFromProd,
      this.showOtherImage,
      this.cancleTill,
      this.totalItem,
      this.offset,
      this.totalAllow,
      this.minimumOrderQuantity,
      this.quantityStepSize,
      this.madeIn,
      this.banner,
      this.selVarient,
      this.video,
      this.videoType,
      this.tagList,
      this.warranty,
      this.taxincludedInPrice,
      this.stock,
      this.description,
      this.deliverableType,
      this.deliverableZipcodesIds,
      this.deliverableZipcodes,
      this.cancelableTill,
      this.gurantee,
      this.brand,
      this.downloadLink,
      this.downloadAllow,
      this.downloadType});

  factory Product.fromJson(Map<String, dynamic> json) {
    List<Product_Varient> varientList = (json[PRODUCT_VARIENT] as List)
        .map((data) => Product_Varient.fromJson(data))
        .toList();

    List<Attribute> attList = (json[ATTRIBUTES] as List)
        .map((data) => Attribute.fromJson(data))
        .toList();

    var flist = (json[FILTERS] as List?);
    List<Filter> filterList = [];
    if (flist == null || flist.isEmpty) {
      filterList = [];
    } else {
      filterList = flist.map((data) => Filter.fromJson(data)).toList();
    }

    List<String> otherImage =
        List<String>.from(json["other_images_relative_path"]);

    List<String> showOtherimage = List<String>.from(json["other_images"]);
    List<String> selected = [];
    List<String> tags = List<String>.from(json['tags']);

    return Product(
      id: json[ID],
      name: json[NAME],
      desc: json[DESC],
      image: json[IMAGE],
      catName: json[CAT_NAME],
      rating: json[RATING],
      noOfRating: json[NO_OF_RATE],
      stock: json[STOCK],
      productIdentity: json["product_identity"],
      type: json[TYPE],
      relativeImagePath: json["relative_path"],
      isFav: json[FAV].toString(),
      isCancelable: json[ISCANCLEABLE],
      availability: json[AVAILABILITY].toString(),
      isPurchased: json[ISPURCHASED].toString(),
      isReturnable: json[ISRETURNABLE],
      otherImage: otherImage,
      showOtherImage: showOtherimage,
      prVarientList: varientList,
      sku: json["sku"],
      attributeList: attList,
      filterList: filterList,
      isFavLoading: false,
      selVarient: 0,
      attrIds: json[ATTR_VALUE],
      madein: json[MADEIN],
      indicator: json[INDICATOR].toString(),
      stockType: json[STOCKTYPE].toString(),
      tax: json[TAX_PER],
      total: json[TOTAL],
      categoryId: json[CATID],
      selectedId: selected,
      totalAllow: json[TOTALALOOW],
      cancleTill: json[CANCLE_TILL],
      shortDescription: json['short_description'],
      tagList: tags,
      minimumOrderQuantity: json['minimum_order_quantity'],
      quantityStepSize: json['quantity_step_size'],
      madeIn: json['made_in'],
      warranty: json['warranty_period'],
      gurantee: json['guarantee_period'],
      isCODAllow: json["cod_allowed"],
      taxincludedInPrice: json['is_prices_inclusive_tax'],
      videoType: json['video_type'],
      video: json["video_relative_path"],
      taxId: json['tax_id'],
      deliverableType: json['deliverable_type'],
      deliverableZipcodesIds: json['deliverable_zipcodes_ids'],
      deliverableZipcodes: json['deliverable_zipcodes'],
      description: json['description'],
      cancelableTill: json['cancelable_till'],
      brand: json['brand'],
      downloadAllow: json['download_allowed'],
      downloadType: json['download_type'],
      downloadLink: json['download_link'],
    );
  }

  factory Product.fromCat(Map<String, dynamic> parsedJson) {
    return Product(
      id: parsedJson[ID],
      name: parsedJson[NAME],
      image: parsedJson[IMAGE],
      banner: parsedJson[BANNER],
      isFromProd: false,
      offset: 0,
      totalItem: 0,
      tax: parsedJson[TAX],
      subList: createSubList(parsedJson["children"]),
    );
  }

  static List<Product>? createSubList(List? parsedJson) {
    if (parsedJson == null || parsedJson.isEmpty) return null;

    return parsedJson.map((data) => Product.fromCat(data)).toList();
  }
}

class Product_Varient {
  String? id,
      productId,
      attribute_value_ids,
      price,
      disPrice,
      type,
      attr_name,
      varient_value,
      availability,
      cartCount,
      stock,
      stockType,
      sku,
      stockStatus = '1';

  List<String>? images;
  List<String>? imagesUrl;
  List<String>? imageRelativePath;

  Product_Varient(
      {this.id,
      this.productId,
      this.attr_name,
      this.varient_value,
      this.price,
      this.disPrice,
      this.attribute_value_ids,
      this.availability,
      this.cartCount,
      this.stock,
      this.imageRelativePath,
      this.images,
      this.imagesUrl,
      this.stockType,
      this.sku,
      this.stockStatus = '1'});

  factory Product_Varient.fromJson(Map<String, dynamic> json) {
    List<String> images = List<String>.from(json[IMAGES]);
    List<String> variantRelativePath =
        List<String>.from(json["variant_relative_path"]);

    return Product_Varient(
        id: json[ID],
        attribute_value_ids: json[ATTRIBUTE_VALUE_ID],
        productId: json[PRODUCT_ID],
        attr_name: json[ATTR_NAME],
        varient_value: json[VARIENT_VALUE],
        disPrice: json[DIS_PRICE],
        price: json[PRICE],
        availability: json[AVAILABILITY].toString(),
        cartCount: json[CART_COUNT],
        stock: json[STOCK],
        stockType: json['status'],
        imageRelativePath: variantRelativePath,
        sku: json['sku'],
        images: images);
  }
}

class Attribute {
  String? id, value, name, sType, sValue;

  Attribute({this.id, this.value, this.name, this.sType, this.sValue});

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
        id: json[IDS],
        name: json[NAME],
        value: json[VALUE],
        sType: json[STYPE],
        sValue: json[SVALUE]);
  }
}

class Filter {
  String? attributeValues, attributeValId, name;

  Filter({this.attributeValues, this.attributeValId, this.name});

  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
      attributeValId: json[ATT_VAL_ID],
      name: json[NAME],
      attributeValues: json[ATT_VAL],
    );
  }
}

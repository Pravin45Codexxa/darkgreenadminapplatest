import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:admin_eshop/Screens/AddBrand.dart';
import 'package:admin_eshop/Screens/BrandsList.dart';
import 'package:admin_eshop/Screens/Customer_Support.dart';
import 'package:admin_eshop/Screens/DeliveryBoy.dart';
import 'package:admin_eshop/Screens/OrderList.dart';
import 'package:admin_eshop/Screens/ProductList.dart';
import 'package:admin_eshop/Screens/StockManageMentList.dart';
import 'package:admin_eshop/Screens/return_request.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Localization/Language_Constant.dart';
import '../main.dart';
import 'AddProduct.dart';
import '../Helper/ApiBaseHelper.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/PushNotificationService.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'Authentication/Login.dart';
import '../Model/Order_Model.dart';
import '../Model/Person_Model.dart';
import 'Privacy_Policy.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateHome();
  }
}

int? total, offset;
List<Order_Model> orderList = [];
ApiBaseHelper apiBaseHelper = ApiBaseHelper();

bool isLoadingmore = true;
List<PersonModel> delBoyList = [];

class StateHome extends State<Home> with TickerProviderStateMixin {
  int curDrwSel = 0;
  int curChart = 0;
  List<String?> languageList = [];
  int? selectLan;

  int? touchedIndex;
  bool _isNetworkAvail = true;
  List<Order_Model> tempList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  String? profile;
  ScrollController controller = ScrollController();
  String? orderCount,
      productCount,
      custCount,
      delBoyCount,
      soldOutCount,
      lowStockCount;
  Map<int, LineChartData>? chartList;
  List? days = [], dayEarning = [];
  List? months = [], monthEarning = [];
  List? weeks = [], weekEarning = [];
  List? catCountList = [], catList = [];
  List colorList = [];
  bool _isLoading = true;

//==============================================================================
//============================= For Language Selection =========================

  List<String> langCode = [
    ENGLISH,
    HINDI,
    CHINESE,
    SPANISH,
    ARABIC,
    RUSSIAN,
    JAPANESE,
    DEUTSCH
  ];

  get lightWhite => null;

  @override
  void initState() {
    offset = 0;
    total = 0;
    orderList.clear();
    final pushNotificationService = PushNotificationService(context: context);

    pushNotificationService.initialise();
    getStatics();
    getDeliveryBoy();
    getSaveDetail();

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

//==============================================================================
//=============================== floating Button ==============================

  floatingBtn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          backgroundColor: white,
          child: const Icon(
            Icons.add,
            size: 32,
            color: primary,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<String>(
                builder: (context) => const AddProduct(),
              ),
            );
          },
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }

//==============================================================================
//============================= Language Implementation ========================

  languageDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            languageList = [
              getTranslated(context, English),
              getTranslated(context, Hindi),
              getTranslated(context, Chinese),
              getTranslated(context, Spanish),
              getTranslated(context, Arabic),
              getTranslated(context, Russian),
              getTranslated(context, Japanese),
              getTranslated(context, Deutch),
            ];

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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 2.0),
                    child: Text(
                      getTranslated(context, ChooseLanguageText)!,
                      style: Theme.of(this.context)
                          .textTheme
                          .titleMedium!
                          .copyWith(
                            color: fontColor,
                          ),
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: getLngList(context),
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
//======================== Language List Generate ==============================

  List<Widget> getLngList(BuildContext ctx) {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted) {
                  setState(
                    () {
                      selectLan = index;
                      _changeLan(langCode[index], ctx);
                    },
                  );
                }
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 25.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectLan == index ? primary : white,
                            border: Border.all(color: primary),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: selectLan == index
                                ? const Icon(
                                    Icons.check,
                                    size: 17.0,
                                    color: white,
                                  )
                                : const Icon(
                                    Icons.check_box_outline_blank,
                                    size: 15.0,
                                    color: white,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 15.0,
                          ),
                          child: Text(
                            languageList[index]!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(color: lightBlack),
                          ),
                        )
                      ],
                    ),
                    index == languageList.length - 1
                        ? Container(
                            margin: const EdgeInsetsDirectional.only(
                              bottom: 10,
                            ),
                          )
                        : const Divider(
                            color: lightBlack,
                          ),
                  ],
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  void _changeLan(String language, BuildContext ctx) async {
    Locale locale = await setLocale(language);

    MyApp.setLocale(ctx, locale);
  }

  getSaveDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String getlng = await getPrefrence(LAGUAGE_CODE) ?? '';

    selectLan = langCode.indexOf(getlng == '' ? "en" : getlng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: lightWhite,
      floatingActionButton: floatingBtn(),
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          getTranslated(context, 'Admin darkGreen')!,
          style: const TextStyle(
            color: primary,
          ),
        ),
        iconTheme: const IconThemeData(color: primary),
        backgroundColor: white,
      ),
      drawer: _getDrawer(),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer()
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          detailHeader0(),
                          detailHeader1(),
                          detailHeader2(),
                          SizedBox(
                            height: 250,
                            child: Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(
                                  top: 10, left: 5, right: 5),
                              child: Stack(
                                children: <Widget>[
                                  Column(
                                    children: <Widget>[
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0, top: 8),
                                          child: Text(
                                            getTranslated(
                                                context, productSalesText)!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(color: primary),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            style: curChart == 0
                                                ? TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor: primary,
                                                    disabledForegroundColor:
                                                        Colors.grey
                                                            .withOpacity(0.38),
                                                  )
                                                : null,
                                            onPressed: () {
                                              setState(
                                                () {
                                                  curChart = 0;
                                                },
                                              );
                                            },
                                            child: Text(
                                              getTranslated(context, DayText)!,
                                              style: TextStyle(
                                                color: curChart == 0
                                                    ? white
                                                    : fontColor,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            style: curChart == 1
                                                ? TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor:primary,
                                                    disabledForegroundColor:
                                                        Colors.grey
                                                            .withOpacity(0.38),
                                                  )
                                                : null,
                                            onPressed: () {
                                              setState(
                                                () {
                                                  curChart = 1;
                                                },
                                              );
                                            },
                                            child: Text(
                                              getTranslated(context, Week)!,
                                              style: TextStyle(
                                                color: curChart == 1
                                                    ? white
                                                    : fontColor,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            style: curChart == 2
                                                ? TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.white,
                                                    backgroundColor: primary,
                                                    disabledForegroundColor:
                                                        Colors.grey
                                                            .withOpacity(0.38),
                                                  )
                                                : null,
                                            onPressed: () {
                                              setState(() {
                                                curChart = 2;
                                              });
                                            },
                                            child: Text(
                                              getTranslated(context, Month)!,
                                              style: TextStyle(
                                                color: curChart == 2
                                                    ? white
                                                    : fontColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: LineChart(
                                          chartList![curChart]!,
                                          swapAnimationDuration: const Duration(
                                            milliseconds: 250,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          catChart()
                        ],
                      ),
                    ),
                  ),
                )
          : noInternet(context),
    );
  }

  LineChartData dayData() {
    if (dayEarning!.isEmpty) {
      dayEarning!.add(0);
      days!.add(0);
    }
    List<FlSpot> spots = dayEarning!.asMap().entries.map(
      (e) {
        return FlSpot(double.parse(days![e.key].toString()),
            double.parse(e.value.toString()));
      },
    ).toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          color: primary,
          belowBarData: BarAreaData(
            show: true,
            color: primary.withOpacity(0.5),
          ),
          aboveBarData: BarAreaData(
            show: true,
            color: fontColor.withOpacity(0.2),
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(),
        topTitles: AxisTitles(),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          // reservedSize: 3,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 7.0,
              //angle: 0.0,
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: fontColor,
                  fontSize: 9,
                ),
              ),
            );
          },
          // margin: 10,
        )),
        /*leftTitles:  AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child:  Text(value.toInt().toString(),style: TextStyle(
                color: fontColor,
                fontSize: 9,
              ),),
            );
          },
        ),
      )*/
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  catChart() {
    Size size = MediaQuery.of(context).size;
    double width = size.width > size.height ? size.height : size.width;
    double ratio;
    if (width > 600) {
      ratio = 0.5;
      // Do something for tablets here
    } else {
      ratio = 0.8;
      // Do something for phones
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: AspectRatio(
        aspectRatio: 1.23,
        child: Card(
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  getTranslated(context, categoryProductCountText)!,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: fontColor),
                ),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      height: 18,
                    ),
                    Expanded(
                      flex: 2,
                      child: AspectRatio(
                        aspectRatio: .8,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                    setState(
                                      () {
                                        if (!event
                                                .isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection ==
                                                null) {
                                          touchedIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      },
                                    );
                                  },
                                ),
                                borderData: FlBorderData(
                                  show: false,
                                ),
                                sectionsSpace: 0,
                                startDegreeOffset: 180,
                                centerSpaceRadius: 40,
                                sections: showingSections(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shrinkWrap: true,
                        itemCount: colorList.length,
                        itemBuilder: (context, i) {
                          return Indicator(
                            color: colorList[i],
                            text: catList![i] + " " + catCountList![i],
                            textColor:
                                touchedIndex == i ? fontColor : Colors.grey,
                            isSquare: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 28,
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

  List<PieChartSectionData> showingSections() {
    return List.generate(
      catCountList!.length,
      (i) {
        final isTouched = i == touchedIndex;
        final double fontSize = isTouched ? 25 : 16;
        final double radius = isTouched ? 60 : 50;

        return PieChartSectionData(
          color: colorList[i],
          value: double.parse(
            catCountList![i].toString(),
          ),
          title: "",
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            color: const Color(0xffffffff),
          ),
        );
      },
    );
  }

  Color generateRandomColor() {
    Random random = Random();
    // Pick a random number in the range [0.0, 1.0)
    double randomDouble = random.nextDouble();

    return Color((randomDouble * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  LineChartData weekData() {
    if (weekEarning!.isEmpty) {
      weekEarning!.add(0);
      weeks!.add(0);
    }
    List<FlSpot> spots = weekEarning!.asMap().entries.map(
      (e) {
        return FlSpot(
          double.parse(e.key.toString()),
          double.parse(
            e.value.toString(),
          ),
        );
      },
    ).toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          color: primary,
          belowBarData: BarAreaData(
            show: true,
            color: primary.withOpacity(0.5),
          ),
          aboveBarData: BarAreaData(
            show: true,
            color: fontColor.withOpacity(0.2),
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          // reservedSize: 3,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 7.0,
              //angle: 0.0,
              child: Text(
                weeks![value.toInt()].toString(),
                style: const TextStyle(
                  color: fontColor,
                  fontSize: 9,
                ),
              ),
            );
          },
        )),
        rightTitles: AxisTitles(),
        topTitles: AxisTitles(),
        /* leftTitles:  AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child:  Text(value.toInt().toString(),style: TextStyle(
                color: fontColor,
                fontSize: 9,
              ),),
            );
          },
        )),*/
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  LineChartData monthData() {
    if (monthEarning!.isEmpty) {
      monthEarning!.add(0);
      months!.add(0);
    }

    List<FlSpot> spots = monthEarning!.asMap().entries.map(
      (e) {
        return FlSpot(
          double.parse(e.key.toString()),
          double.parse(
            e.value.toString(),
          ),
        );
      },
    ).toList();

    return LineChartData(
      lineTouchData: LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 2,
          color: primary,
          belowBarData: BarAreaData(
            show: true,
            color: primary.withOpacity(0.5),
          ),
          aboveBarData: BarAreaData(
            show: true,
            color: fontColor.withOpacity(0.2),
          ),
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      minY: 0,
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(),
        topTitles: AxisTitles(),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          // reservedSize: 3,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 7.0,
              //angle: 0.0,
              child: Text(
                months![value.toInt()].toString(),
                style: const TextStyle(
                  color: fontColor,
                  fontSize: 9,
                ),
              ),
            );
          },
        )),
        /*leftTitles:  AxisTitles(sideTitles: SideTitles(
          showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child:  Text(value.toInt().toString(),style: TextStyle(
                  color: fontColor,
                  fontSize: 9,
                ),),
              );
            }
        ),
      )*/
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: fontColor.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

//==============================================================================
//============================ Desing Implimentation ===========================

  commanDesingButtons(
    int flex,
    int index,
    IconData icon,
    String title,
    String? data,
  ) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderList(),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductList(
                  flag: '',
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DeliveryBoy(
                  isDelBoy: false,
                ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DeliveryBoy(
                  isDelBoy: true,
                ),
              ),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ProductList(
                  flag: "sold",
                ),
              ),
            );
          } else if (index == 5) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ProductList(
                  flag: "low",
                ),
              ),
            );
          }
        },
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Card(
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 0,
              child: SizedBox(
                height: 100,
                width: deviceWidth * 0.4,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    bottom: 20.0,
                    left: 10.0,
                    right: 10.0,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        color: fontColor,
                        size: 30,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: fontColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 90.0),
              child: Container(
                height: 36,
                width: 56,
                decoration: const BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      10.0,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    data ?? "",
                    style: const TextStyle(
                      color: white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _getDrawer() {
    return Drawer(
      child: SafeArea(
        child: Container(
          color: white,
          child: ListView(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            children: <Widget>[
              _getHeader(),
              const Divider(),
              _getDrawerItem(
                0,
                getTranslated(context, HOME_LBL)!,
                Icons.home_outlined,
              ),
              _getDrawerItem(
                7,
                getTranslated(context, ORDER)!,
                Icons.shopping_cart_outlined,
              ),
              _getDrawerItem(
                5,
                getTranslated(context, PRO_LBL)!,
                Icons.dashboard_outlined,
              ),
              _getDrawerItem(
                10,
                getTranslated(context, AddProductText)!,
                Icons.add,
              ),
              _getDrawerItem(
                14,
                getTranslated(context, BRANDS_LBL)!,
                Icons.branding_watermark,
              ),
              _getDrawerItem(
                15,
                getTranslated(context, ADD_BRAND_LBL)!,
                Icons.add_moderator_outlined,
              ),
              _getDrawerItem(
                16,
                getTranslated(context, StockManagementText)!,
                Icons.add_box_outlined,
              ),
              _getDrawerItem(
                2,
                getTranslated(context, Del_LBL)!,
                Icons.directions_bike_outlined,
              ),
              _getDrawerItem(
                3,
                getTranslated(context, CUST_LBL)!,
                Icons.group_outlined,
              ),
              // _getDrawerItem(
              //   13,
              //   getTranslated(context, ChangeLanguageText)!,
              //   Icons.translate,
              // ),
              ticketRead
                  ? _getDrawerItem(
                      4,
                      getTranslated(context, TICKET_LBL)!,
                      Icons.support_agent_outlined,
                    )
                  : Container(),
              _getDrawerItem(
                12,
                getTranslated(context, RETURN_REQ_LBL)!,
                Icons.refresh,
              ),
              // _getDivider(),
              // _getDrawerItem(
              //   8,
              //   getTranslated(context, PRIVACY_POLICY_LBL)!,
              //   Icons.lock_outline,
              // ),
              // _getDrawerItem(
              //   9,
              //   getTranslated(context, TERM)!,
              //   Icons.speaker_notes_outlined,
              // ),
              CUR_USERID == "" || CUR_USERID == null
                  ? Container()
                  : _getDivider(),
              CUR_USERID == "" || CUR_USERID == null
                  ? Container()
                  : _getDrawerItem(
                      11,
                      getTranslated(context, LOGOUT)!,
                      Icons.input,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  _getHeader() {
    return InkWell(
      child: Container(
        color: primary,
        padding: const EdgeInsetsDirectional.only(start: 10.0, bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 20, start: 10),
                child: Text(
                  CUR_USERNAME!,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: white,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
              ),
            ),
            //Spacer(),
            Container(
              margin: const EdgeInsetsDirectional.only(top: 20, end: 20),
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 1.0, color: white)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: imagePlaceHolder(62),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {},
    );
  }

  _getDivider() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Divider(
        height: 1,
      ),
    );
  }

  _getDrawerItem(int index, String title, IconData icn) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      // decoration: BoxDecoration(
      //   gradient: curDrwSel == index
      //       ? const LinearGradient(
      //           begin: Alignment.centerLeft,
      //           end: Alignment.centerRight,
      //           colors: [
      //             primary,
      //             primary,
      //           ],
      //           stops: [0, 1],
      //         )
      //       : null,
      //   borderRadius: const BorderRadius.only(
      //     topRight: Radius.circular(50),
      //     bottomRight: Radius.circular(50),
      //   ),
      // ),
      child: ListTile(
        dense: true,
        leading: Icon(icn, color: lightBlack2
            //curDrwSel == index ? white : lightBlack2,
            ),
        title: Text(
          title,
          style: const TextStyle(
              //color: curDrwSel == index ? white : lightBlack2,
              fontSize: 15),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (title == getTranslated(context, HOME_LBL)) {
            setState(() {
              curDrwSel = index;
            });
            Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
          } else if (title == NOTIFICATION) {
            setState(() {
              curDrwSel = index;
            });
          } else if (title == getTranslated(context, LOGOUT)) {
            logOutDailog();
          } else if (title == getTranslated(context, AddProductText)!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            // Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProduct(),
              ),
            );
          } else if (title == getTranslated(context, TICKET_LBL)!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const CustomerSupport(),
              ),
            );
          } else if (title == getTranslated(context, RETURN_REQ_LBL)!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ReturnRequest(),
              ),
            );
          // } else if (title == getTranslated(context, PRIVACY_POLICY_LBL)!) {
          //   setState(
          //     () {
          //       curDrwSel = index;
          //     },
          //   );
          //   Navigator.push(
          //     context,
          //     CupertinoPageRoute(
          //       builder: (context) => PrivacyPolicy(
          //         title: getTranslated(context, PRIVACY_POLICY_LBL)!,
          //       ),
          //     ),
          //   );
          } else if (title == getTranslated(context, ChangeLanguageText)!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            languageDialog();
          // } else if (title == getTranslated(context, TERM)) {
          //   setState(
          //     () {
          //       curDrwSel = index;
          //     },
          //   );
          //   Navigator.push(
          //     context,
          //     CupertinoPageRoute(
          //       builder: (context) => PrivacyPolicy(
          //         title: getTranslated(context, TERM)!,
          //       ),
          //     ),
          //   );
          } else if (title == getTranslated(context, Del_LBL)!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const DeliveryBoy(
                  isDelBoy: true,
                ),
              ),
            );
          } else if (title == getTranslated(context, CUST_LBL)!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const DeliveryBoy(
                  isDelBoy: false,
                ),
              ),
            );
          } else if (title == getTranslated(context, PRO_LBL)!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ProductList(
                  flag: '',
                ),
              ),
            );
          } else if (title == getTranslated(context, ORDER)!) {
            setState(
              () {
                curDrwSel = index;
              },
            );
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const OrderList(),
              ),
            );
          } else if (title == getTranslated(context, BRANDS_LBL)) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const BrandsList(),
              ),
            );
          } else if (title == getTranslated(context, ADD_BRAND_LBL)) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const AddBrand(),
              ),
            );
          } else if (title == getTranslated(context, StockManagementText)!) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StockManagementList(),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    offset = 0;
    total = 0;
    orderList.clear();

    setState(
      () {
        _isLoading = true;
      },
    );
    return getStatics();
  }

  logOutDailog() async {
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
                getTranslated(context, LOGOUTTXT)!,
                style: Theme.of(this.context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: fontColor),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    getTranslated(context, LOGOUTNO)!,
                    style:
                        Theme.of(this.context).textTheme.titleSmall!.copyWith(
                              color: lightBlack,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    getTranslated(context, LOGOUTYES)!,
                    style:
                        Theme.of(this.context).textTheme.titleSmall!.copyWith(
                              color: fontColor,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  onPressed: () {
                    clearUserSession();
                    Navigator.of(context).pushAndRemoveUntil(
                      CupertinoPageRoute(
                        builder: (context) => const Login(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                )
              ],
            );
          },
        );
      },
    );
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

  detailHeader0() {
    return Row(
      children: [
        commanDesingButtons(
          1,
          0,
          Icons.shopping_cart_outlined,
          getTranslated(context, ORDER)!,
          orderCount,
        ),
        commanDesingButtons(
          1,
          1,
          Icons.dashboard_outlined,
          getTranslated(context, PRO_LBL)!,
          productCount,
        ),
      ],
    );
  }

  detailHeader1() {
    return Row(
      children: [
        commanDesingButtons(
          1,
          2,
          Icons.group_outlined,
          getTranslated(context, CUST_LBL)!,
          custCount,
        ),
        commanDesingButtons(
          1,
          3,
          Icons.directions_bike_outlined,
          getTranslated(context, Del_LBL)!,
          delBoyCount,
        ),
      ],
    );
  }

  detailHeader2() {
    return Row(
      children: [
        commanDesingButtons(
          1,
          4,
          Icons.not_interested,
          getTranslated(context, SOLD_LBL)!,
          soldOutCount,
        ),
        commanDesingButtons(
          1,
          5,
          Icons.offline_bolt_outlined,
          getTranslated(context, LOW_LBL)!,
          lowStockCount,
        ),
      ],
    );
  }

  Future<void> getStatics() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        CUR_USERID = await getPrefrence(ID);
        CUR_USERNAME = await getPrefrence(USERNAME);

        var parameter = {USER_ID: CUR_USERID};

        Response response =
            await post(getStaticsApi, body: parameter, headers: headers)
                .timeout(
          const Duration(seconds: timeOut),
        );

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String? msg = getdata["message"];

          if (!error) {
            CUR_CURRENCY = getdata["currency_symbol"];

            readOrder =
                getdata["permissions"]["orders"]["read"] == "on" ? true : false;
            editOrder = getdata["permissions"]["orders"]["update"] == "on"
                ? true
                : false;
            deleteOrder = getdata["permissions"]["orders"]["delete"] == "on"
                ? true
                : false;

            readProduct = getdata["permissions"]["product"]["read"] == "on"
                ? true
                : false;
            editProduct = getdata["permissions"]["product"]["update"] == "on"
                ? true
                : false;
            deletProduct = getdata["permissions"]["product"]["delete"] == "on"
                ? true
                : false;

            readCust = getdata["permissions"]["customers"]["read"] == "on"
                ? true
                : false;
            readDel = getdata["permissions"]["delivery_boy"]["read"] == "on"
                ? true
                : false;

            ticketRead =
                getdata["permissions"]["support_tickets"]["read"] == "on"
                    ? true
                    : false;

            ticketWrite =
                getdata["permissions"]["support_tickets"]["update"] == "on"
                    ? true
                    : false;



            var count = getdata['counts'][0];
            print("stockCount ${count["count_products_low_status"]}");
            productCount = count["product_counter"];
            soldOutCount = count['count_products_sold_out_status'];
            lowStockCount = count["count_products_low_status"];
            delBoyCount = count["delivery_boy_counter"];
            custCount = count["user_counter"];
            orderCount = count["order_counter"];

            days = getdata['earnings'][0]["daily_earnings"]['day'];
            dayEarning = getdata['earnings'][0]["daily_earnings"]['total_sale'];
            months = getdata['earnings'][0]["monthly_earnings"]['month_name'];
            monthEarning =
                getdata['earnings'][0]["monthly_earnings"]['total_sale'];

            weeks = getdata['earnings'][0]["weekly_earnings"]['week'];
            weekEarning =
                getdata['earnings'][0]["weekly_earnings"]['total_sale'];

            if (chartList != null) chartList!.clear();
            chartList = {0: dayData(), 1: weekData(), 2: monthData()};

            catCountList = getdata['category_wise_product_count']['counter'];
            catList = getdata['category_wise_product_count']['cat_name'];
            colorList.clear();
            for (int i = 0; i < catList!.length; i++) {
              colorList.add(
                generateRandomColor(),
              );
            }
          } else {
            setsnackbar(msg!, context);
          }

          setState(
            () {
              _isLoading = false;
            },
          );
        }
      } else {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    } on TimeoutException catch (_) {
      setsnackbar(getTranslated(context, somethingMSg)!, context);
    }

    return;
  }

  Future<void> getDeliveryBoy() async {
    try {
      Response response = await post(getDelBoyApi, headers: headers)
          .timeout(const Duration(seconds: timeOut));

      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          delBoyList.clear();
          var data = getdata["data"];
          delBoyList =
              (data as List).map((data) => PersonModel.fromJson(data)).toList();
        } else {
          setsnackbar(msg!, context);
        }
      }
    } on TimeoutException catch (_) {
      setsnackbar(getTranslated(context, somethingMSg)!, context);
    }
  }
}

class Indicator extends StatelessWidget {
  final Color? color;
  final String? text;
  final bool? isSquare;
  final double size;
  final Color? textColor;

  const Indicator({
    Key? key,
    this.color,
    this.text,
    this.isSquare,
    this.size = 9,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare! ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Expanded(
          child: Text(
            text!,
            style: TextStyle(
              fontSize: 9,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}

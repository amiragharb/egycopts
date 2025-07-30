import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Colors/colors.dart';
import 'package:egpycopsversion4/Family/addFamilyMemberActivity.dart';
import 'package:egpycopsversion4/Family/familyFragment.dart' show FamilyFragment;
import 'package:egpycopsversion4/Firebase/FirebaseMessageWrapper.dart';
import 'package:egpycopsversion4/Home/homeFragment.dart';
import 'package:egpycopsversion4/Home/myBookingsFragment.dart';
import 'package:egpycopsversion4/Home/youtubeLiveFragment.dart';
import 'package:egpycopsversion4/Login/login.dart';
import 'package:egpycopsversion4/Models/user.dart';
import 'package:egpycopsversion4/NetworkConnectivity/noNetworkConnectionActivity.dart';
import 'package:egpycopsversion4/Settings/settingsActivity.dart';
import 'package:egpycopsversion4/Settings/changePasswordActivity.dart';
import 'package:egpycopsversion4/Translation/LocaleHelper.dart';
import 'package:egpycopsversion4/Translation/localizations.dart' hide SpecificLocalizationDelegate;

import '../main.dart' show languageHome;

typedef LocaleChangeCallback = void Function(Locale locale);

late BuildContext mContext;

BaseUrl BASE_URL = BaseUrl();
String baseUrl = BASE_URL.BASE_URL;

// Variables globales
String userID = "";
String accountType = "";
String userName = "";
String userEmail = "";
String? fragment;
String? mobileToken;
late bool firstLogin;

String loginUsername = "";
String sucessCode = "";
String name = "";
String email = "";
String address = "";
bool hasMainAccount = false;
int defaultGovernateID = 0, defaultBranchID = 0;

// Helper de langue
LocaleHelper helper = LocaleHelper();

class HomeActivity extends StatefulWidget {
  final bool fromMain;
  const HomeActivity(this.fromMain, {Key? key}) : super(key: key);

  @override
  HomeActivityState createState() => HomeActivityState();
}

class HomeActivityState extends State<HomeActivity> {
  late SpecificLocalizationDelegate _specificLocalizationDelegate;
  late GlobalKey<ScaffoldState> _scaffoldKey;
  int selectedBottomItem = 0;

  Locale _appLocale = Locale(languageHome ?? 'en');

  // Contrôleurs personnalisés
  MyCustomControllerDrawerName customControllerDrawerName =
      MyCustomControllerDrawerName(drawerNameController: TextEditingController());
  MyCustomControllerDrawerEmail customControllerDrawerEmail =
      MyCustomControllerDrawerEmail(drawerEmailController: TextEditingController());
  MyCustomControllerMyBookings customControllerMyBookings =
      MyCustomControllerMyBookings(myBookingsController: TextEditingController());
  MyCustomControllerProfile customControllerProfile =
      MyCustomControllerProfile(profileController: TextEditingController());
  MyCustomControllerNews customControllerNews =
      MyCustomControllerNews(newsController: TextEditingController());
  MyCustomControllerFamily customControllerFamily =
      MyCustomControllerFamily(familyController: TextEditingController());
  MyCustomControllerLive customControllerLive =
      MyCustomControllerLive(liveController: TextEditingController());

  @override
  void initState() {
    super.initState();
    _scaffoldKey = GlobalKey();
    helper.onLocaleChanged = onLocaleChange;
    _specificLocalizationDelegate =
        SpecificLocalizationDelegate(Locale(languageHome ?? 'en'));

    fragment = "MyBookings"; // Valeur par défaut
    initApp();
  }

  Future<void> initApp() async {
    try {
      mobileToken = await FirebaseMessaging.instance.getToken();
    } catch (e, s) {
      debugPrint("❌ Erreur Firebase Token: $e");
      debugPrint("$s");
    }

    if (mobileToken == null || mobileToken!.isEmpty) {
      Fluttertoast.showToast(msg: "Erreur lors de l'initialisation du token Firebase.");
      return;
    }

    await getSharedData();
  }

  void onLocaleChange(Locale locale) {
    setState(() {
      _specificLocalizationDelegate = SpecificLocalizationDelegate(locale);
      _appLocale = locale;
    });
  }

  void onBottomNavTap(int index) {
    setState(() {
      selectedBottomItem = index;
      switch (index) {
        case 0:
          fragment = "MyBookings";
          break;
        case 1:
          fragment = "News";
          break;
        case 2:
          fragment = "Live";
          break;
        case 3:
          if (accountType == "1") {
            fragment = "Profile";
          } else {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddFamilyMemberActivity(
                  false, "", "0", 0, "", "", "", "", "", "", "", 1, true),
            )).then((_) {
              setState(() {
                selectedBottomItem = 0;
                fragment = "MyBookings";
              });
            });
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mContext = context;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FallbackCupertinoLocalisationsDelegate(),
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      locale: _appLocale,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        hintColor: accentColor,
        fontFamily: 'cocon-next-arabic-regular',
      ),
      home: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: buildDrawer(),
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            title: Image.asset('images/logotransparents.png', height: 100.0, width: 100.0),
            backgroundColor: primaryDarkColor,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          body: buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedBottomItem,
            onTap: onBottomNavTap,
            showUnselectedLabels: true,
            unselectedItemColor: greyColor,
            selectedItemColor: primaryColor,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: MyCustomIconMyBookings(customController: customControllerMyBookings),
                label: AppLocalizations.of(context)?.myBookings ?? "Bookings",
              ),
              BottomNavigationBarItem(
                icon: MyCustomIconNews(customController: customControllerNews),
                label: AppLocalizations.of(context)?.news ?? "News",
              ),
              BottomNavigationBarItem(
                icon: MyCustomIconLive(customController: customControllerLive),
                label: AppLocalizations.of(context)?.live ?? "Live",
              ),
              BottomNavigationBarItem(
                icon: accountType == "1"
                    ? MyCustomIconFamily(customController: customControllerFamily)
                    : MyCustomIconProfile(customController: customControllerProfile),
                label: accountType == "1"
                    ? (AppLocalizations.of(context)?.myFamily ?? "Family")
                    : (AppLocalizations.of(context)?.myProfile ?? "Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    switch (fragment) {
      case "News":
        return FirebaseMessageWrapper(child: HomeFragment());
      case "MyBookings":
        return FirebaseMessageWrapper(child: MyBookingsFragment());
      case "Profile":
        return FirebaseMessageWrapper(child: FamilyFragment());
      case "Live":
        return FirebaseMessageWrapper(child: YoutubeLiveFragment());
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Future<bool> _onWillPop() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
      return false;
    }

    if (fragment != "MyBookings") {
      setState(() {
        fragment = "MyBookings";
        selectedBottomItem = 0;
      });
      return false;
    }

    bool? exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          AppLocalizations.of(mContext)?.areYouSureOfExitFromEGYCopts ?? "Exit?",
          style: const TextStyle(fontFamily: 'cocon-next-arabic-regular'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
            child: Text(AppLocalizations.of(mContext)?.yes ?? "Yes"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(mContext)?.no ?? "No"),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  Future<void> getSharedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userID = prefs.getString("userID") ?? "";
      userName = prefs.getString("loginUsername") ?? "";
      userEmail = prefs.getString("email") ?? "";
      accountType = prefs.getString("accountType") ?? "";
      fragment = fragment ?? "MyBookings";

      customControllerDrawerName.drawerNameController.text = userName;
      customControllerDrawerEmail.drawerEmailController.text = userEmail;
    });
  }

  Drawer buildDrawer() {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            color: primaryColor,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, left: 30.0, right: 30.0),
                  child: SizedBox(
                    width: 140,
                    height: 110,
                    child: Image.asset('images/logotransparents.png', fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: MyCustomDrawerName(customController: customControllerDrawerName),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: MyCustomDrawerEmail(customController: customControllerDrawerEmail),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === Classes des contrôleurs et widgets personnalisés ===

class MyCustomControllerDrawerName {
  final TextEditingController drawerNameController;
  bool enable;
  MyCustomControllerDrawerName({required this.drawerNameController, this.enable = true});
}

class MyCustomDrawerName extends StatelessWidget {
  final MyCustomControllerDrawerName customController;
  const MyCustomDrawerName({Key? key, required this.customController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      userName,
      style: const TextStyle(fontSize: 20.0, color: Colors.white),
    );
  }
}

class MyCustomControllerDrawerEmail {
  final TextEditingController drawerEmailController;
  bool enable;
  MyCustomControllerDrawerEmail({required this.drawerEmailController, this.enable = true});
}

class MyCustomDrawerEmail extends StatelessWidget {
  final MyCustomControllerDrawerEmail customController;
  const MyCustomDrawerEmail({Key? key, required this.customController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Text(
        userEmail,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18.0, color: Colors.white),
      ),
    );
  }
}

// === CONTROLEURS ET ICONES POUR LA NAVIGATION BASSE ===

class MyCustomControllerMyBookings {
  final TextEditingController myBookingsController;
  Color color;
  MyCustomControllerMyBookings({required this.myBookingsController, this.color = Colors.white});
}

class MyCustomIconMyBookings extends StatelessWidget {
  final MyCustomControllerMyBookings customController;
  const MyCustomIconMyBookings({Key? key, required this.customController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image(image: const ExactAssetImage('images/online_booking.png'), color: customController.color);
  }
}

class MyCustomControllerProfile {
  final TextEditingController profileController;
  Color color;
  MyCustomControllerProfile({required this.profileController, this.color = Colors.white});
}

class MyCustomIconProfile extends StatelessWidget {
  final MyCustomControllerProfile customController;
  const MyCustomIconProfile({Key? key, required this.customController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image(image: const ExactAssetImage('images/user.png'), color: customController.color);
  }
}

class MyCustomControllerNews {
  final TextEditingController newsController;
  Color color;
  MyCustomControllerNews({required this.newsController, this.color = Colors.white});
}

class MyCustomIconNews extends StatelessWidget {
  final MyCustomControllerNews customController;
  const MyCustomIconNews({Key? key, required this.customController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image(image: const ExactAssetImage('images/earth.png'), color: customController.color);
  }
}

class MyCustomControllerFamily {
  final TextEditingController familyController;
  Color color;
  MyCustomControllerFamily({required this.familyController, this.color = Colors.white});
}

class MyCustomIconFamily extends StatelessWidget {
  final MyCustomControllerFamily customController;
  const MyCustomIconFamily({Key? key, required this.customController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image(image: const ExactAssetImage('images/love.png'), color: customController.color);
  }
}

class MyCustomControllerLive {
  final TextEditingController liveController;
  Color color;
  MyCustomControllerLive({required this.liveController, this.color = Colors.white});
}

class MyCustomIconLive extends StatelessWidget {
  final MyCustomControllerLive customController;
  const MyCustomIconLive({Key? key, required this.customController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image(image: const ExactAssetImage('images/live.png'), color: customController.color);
  }
}

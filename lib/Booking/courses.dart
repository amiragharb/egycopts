import 'dart:async';
import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Colors/colors.dart';
import 'package:egpycopsversion4/Models/courseTime.dart';
import 'package:egpycopsversion4/Translation/localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:skeleton_text/skeleton_text.dart';
import 'newBookingActivity.dart';

typedef void LocaleChangeCallback(Locale locale);

BaseUrl BASE_URL = BaseUrl();
String baseUrl = BASE_URL.BASE_URL;

String userID = "";
String mobileToken = "";
String myLanguage = "";
String chosenDate = "", branchID = "";
int loadingState = 0;
String churchNameEn = "", churchNameAr = "";

class CoursesActivity extends StatefulWidget {
  CoursesActivity(
      String chosenDateConstructor, String branchIDConstructor,
      churchNameEnConstructor, churchNameArConstructor) {
    chosenDate = chosenDateConstructor;
    branchID = branchIDConstructor;
    churchNameEn = churchNameEnConstructor;
    churchNameAr = churchNameArConstructor;
  }

  @override
  _CoursesActivityState createState() => _CoursesActivityState();
}

class _CoursesActivityState extends State<CoursesActivity> {
  List<CourseTime> coursesList = [];
  List<Map<String, dynamic>> listViewCourses = [];

  late BuildContext mContext;

  bool showFirstBottomSheetOption = false;
  bool showSecondBottomSheetOption = false;

  List<ListAttendanceTypes> listAttendanceTypes = [];
  List<Map<String, dynamic>> listViewAttendanceTypes = [];

  int firstBottomSheetOptionID = 0;
  int secondBottomSheetOptionID = 0;

  String firstBottomSheetOptionNameAr = "",
      firstBottomSheetOptionNameEn = "",
      secondBottomSheetOptionNameAr = "",
      secondBottomSheetOptionNameEn = "";

  @override
  void initState() {
    super.initState();
    loadingState = 0;
    showFirstBottomSheetOption = true;
    showSecondBottomSheetOption = true;
    getSharedData();
  }

  Future<void> getSharedData() async {
    mobileToken = await FirebaseMessaging.instance.getToken() ?? "";
    print("Token: $mobileToken");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    myLanguage = (prefs.getString('language') ?? "en");
    userID = prefs.getString("userID") ?? "";

    coursesList = (await getCourses())!;
    if (loadingState == 1 && coursesList.isNotEmpty) {
      coursesListViewData();
    }
  }

  void coursesListViewData() {
    setState(() {
      for (var course in coursesList) {
        listViewCourses.add({
          "id": course.id,
          "nameAr": course.nameAr,
          "nameEn": course.nameEn,
          "isDefualt": course.isDefualt,
          "remAttendanceCount": course.remAttendanceCount,
          "remAttendanceDeaconCount": course.remAttendanceDeaconCount,
          "courseDate": course.courseDate,
          "courseDateAr": course.courseDateAr,
          "courseDateEn": course.courseDateEn,
          "courseTimeAr": course.courseTimeAr,
          "courseTimeEn": course.courseTimeEn,
          "churchRemarks": course.churchRemarks,
          "courseRemarks": course.courseRemarks,
          "governerateNameAr": course.governerateNameAr,
          "governerateNameEn": course.governerateNameEn,
          "churchNameAr": course.churchNameAr,
          "courseTypeName": course.courseTypeName,
          "churchNameEn": course.churchNameEn,
          "courseNameAr": course.courseNameAr,
          "courseNameEn": course.courseNameEn,
          "timeCount": course.timeCount,
          "avaliableAttendanceTypes": course.avaliableAttendanceTypes,
          "showAttendanceTypePopup": course.showAttendanceTypePopup,
        });
      }
    });
  }

  Future<List<CourseTime>?> getCourses() async {
    var uri = Uri.parse(
        '$baseUrl/Booking/GetCourseTimeByDate/?BranchID=$branchID&CourseDate=$chosenDate&UserAccountID=$userID&token=$mobileToken');
    print("Request URL: $uri");

    var response = await http.get(uri);
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      if (response.body == "[]") {
        setState(() {
          loadingState = 2;
        });
        print("getCourses empty");
        return [];
      } else {
        setState(() {
          loadingState = 1;
        });
        print("getCourses not empty");
      }
      return courseTimeFromJson(response.body);
    } else {
      setState(() {
        loadingState = 2;
      });
      print("getCourses error: ${response.statusCode}");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    mContext = context;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            AppLocalizations.of(context)!.chooseHolyLiturgyDate,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
          ),
        ),
        backgroundColor: primaryDarkColor,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: buildChild(),
    );
  }

  Widget buildChild() {
    if (loadingState == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          physics: BouncingScrollPhysics(),
          itemCount: 10,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(14.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0, bottom: 5.0),
                          child: SkeletonAnimation(
                            child: Container(
                              height: 15,
                              width: MediaQuery.of(context).size.width * 0.7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: SkeletonAnimation(
                            child: Container(
                              width: 110,
                              height: 13,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else if (loadingState == 1) {
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              child: Text(
                myLanguage == "en" ? churchNameEn : churchNameAr,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'cocon-next-arabic-regular',
                  fontWeight: FontWeight.normal,
                  color: primaryDarkColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Text(
              myLanguage == "en"
                  ? listViewCourses[0]["courseDateEn"]
                  : listViewCourses[0]["courseDateAr"],
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'cocon-next-arabic-regular',
                fontWeight: FontWeight.normal,
                color: logoBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: listViewCourses.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  child: Card(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: logoBlue),
                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      ),
                      padding: EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  listViewCourses[index]["courseTypeName"],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'cocon-next-arabic-regular',
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  myLanguage == "en"
                                      ? listViewCourses[index]["courseTimeEn"]
                                      : listViewCourses[index]["courseTimeAr"],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'cocon-next-arabic-regular',
                                    fontWeight: FontWeight.normal,
                                    color: primaryDarkColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    // Handle tap logic here...
                  },
                );
              },
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.errorConnectingWithServer,
          style: TextStyle(
            fontSize: 20.0,
            fontFamily: 'cocon-next-arabic-regular',
            color: Colors.grey,
          ),
        ),
      );
    }
  }
}
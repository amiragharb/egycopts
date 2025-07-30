import 'dart:async';
import 'dart:io';

import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Booking/calendarOfBookings.dart';
import 'package:egpycopsversion4/Booking/chooseBookingFamilyMembersActivity.dart';
import 'package:egpycopsversion4/Colors/colors.dart';
import 'package:egpycopsversion4/Models/churchs.dart';
import 'package:egpycopsversion4/Models/courseDetails.dart';
import 'package:egpycopsversion4/Models/courses.dart';
import 'package:egpycopsversion4/Models/governorates.dart';
import 'package:egpycopsversion4/Translation/localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:skeleton_text/skeleton_text.dart';

typedef void LocaleChangeCallback(Locale locale);

String accountType = "";

BaseUrl BASE_URL = new BaseUrl();
String baseUrl = BASE_URL.BASE_URL;
bool flagAddCourse=false;
int availableSeatsState = 0;
String myLanguage="";
int loadingState = 0;
int dateState = 0;
bool isDateChosen = false;
bool isChurchChosen = false;
String churchOfAttendanceID = "0";
String governorateID="";
String courseID = "0";
String churchNameAr ="",
    churchNameEn="",
    remAttendanceCount="",
    remAttendanceDeaconCount="",
    churchRemarks="",
    courseRemarks="",
    courseDateAr="",
    courseDateEn="",
    courseTimeAr="",
    courseTimeEn="",
    courseTypeName="";
int defaultGovernateID=0, defaultBranchID=0;
String branchNameAr="", branchNameEn="";
int attendanceTypeIDNewBooking=0;
String attendanceTypeNameArNewBooking="", attendanceTypeNameEnNewBooking="";

class NewBookingActivity extends StatefulWidget {
  NewBookingActivity();

  @override
  _NewBookingActivityState createState() => _NewBookingActivityState();
}

class _NewBookingActivityState extends State<NewBookingActivity> {
  List<Map> listDropChurchOfAttendance = [];
  List<Map> listDropGovernorates = [];
  List<Map> listDropCourses = [];
  String mobileToken="";

  List<Churchs> churchOfAttendanceList = [];
List<Governorates> governoratesList = [];
List<Course> coursesList = [];

  String userBranchID = "0";
  churchOfAttendanceDropDownData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    listDropChurchOfAttendance.clear();
    if (churchOfAttendanceList.length > 0) {
      setState(() {
        listDropChurchOfAttendance
          ..add({
            "id": "0",
            "nameAr": "اختار الكنيسة",
            "nameEn": "Choose Church",
            "isDefualt": false
          });

        String tempID="";

        for (int i = 0; i < churchOfAttendanceList.length; i++) {
          listDropChurchOfAttendance
            ..add({
              "id": churchOfAttendanceList.elementAt(i).id,
              "nameAr": churchOfAttendanceList.elementAt(i).nameAr,
              "nameEn": churchOfAttendanceList.elementAt(i).nameEn,
              "isDefualt": churchOfAttendanceList.elementAt(i).isDefualt
            });
          if(userBranchID == churchOfAttendanceList.elementAt(i).id.toString()){
            tempID = userBranchID;
          }
        }
        if(tempID.isEmpty){
          churchOfAttendanceID = "0";
        }else{
          churchOfAttendanceID = tempID;
        }
      });
    }
  }

  coursesDropDownData() async {
    listDropCourses.clear();
    if (coursesList.length > 0) {
      setState(() {
        listDropCourses
          ..add({
            "id": "0",
            "nameAr": "اختار التاريخ",
            "nameEn": "Choose date",
            "isDefualt": false
          });

        for (int i = 0; i < coursesList.length; i++) {
          listDropCourses
            ..add({
              "id": coursesList.elementAt(i).id,
              "nameAr": coursesList.elementAt(i).nameAr,
              "nameEn": coursesList.elementAt(i).nameEn,
              "isDefualt": coursesList.elementAt(i).isDefualt
            });
        }
      });
    } else {
      setState(() {
        availableSeatsState = 2;
      });
    }
  }

  Future<void> governoratesDropDownData() async {
  listDropGovernorates.clear();

  listDropGovernorates.add({
    "id": "0",
    "nameAr": "اختار المحافظة",
    "nameEn": "Choose Governorate",
    "isDefualt": false,
  });

  for (var gov in governoratesList) {
    listDropGovernorates.add({
      "id": gov.id,
      "nameAr": gov.nameAr,
      "nameEn": gov.nameEn,
      "isDefualt": gov.isDefualt,
    });

    if (gov.isDefualt == true) {
      governorateID = gov.id.toString();
    }
  }

  setState(() {}); // Mise à jour unique
}


//  Future<List<Governorates>> getGovernorates() async {
//    var response = await http.get('$baseUrl/Booking/GetGovernorates/');
//    print('$baseUrl/Booking/GetGovernorates/');
//    print(response.body);
//    if (response.statusCode == 200) {
//      print('GetGovernorates= response.statusCode ${response.statusCode}');
//      var governoratesObj = governoratesFromJson(response.body.toString());
//      print('jsonResponse $governoratesObj');
//      return governoratesObj;
//    } else {
//      print("GetGovernorates error");
//      print('GetGovernorates= response.statusCode ${response.statusCode}');
//      return null;
//    }
//  }

  Future<List<Governorates>?> getGovernoratesByUserID() async {
    var response = await http
        .get('$baseUrl/Booking/GetGovernoratesByUserID/?UserAccountID=$userID' as Uri);
    print('$baseUrl/Booking/GetGovernoratesByUserID/?UserAccountID=$userID');
    print(response.body);
    if (response.statusCode == 200) {
      print('GetGovernorates= response.statusCode ${response.statusCode}');
      var governoratesObj = governoratesFromJson(response.body.toString());
      print('jsonResponse $governoratesObj');
      return governoratesObj;
    } else {
      print("GetGovernorates error");
      print('GetGovernorates= response.statusCode ${response.statusCode}');
      return null;
    }
  }

  Future<List<Churchs>?> getChurchs(String governorateID) async {
    setState(() {
      flagAddCourse = true;
    });
    var response = await http
        .get('$baseUrl/Booking/GetChurch/?GovernerateID=$governorateID' as Uri);
    print('$baseUrl/Booking/GetChurch/?GovernerateID=$governorateID');
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        loadingState = 1;
      });
      print('GetChurch= response.statusCode ${response.statusCode}');
      var churchsObj = churchsFromJson(response.body.toString());
      print('jsonResponse $churchsObj');
      return churchsObj;
    } else {
      setState(() {
        loadingState = 2;
      });
      print("GetChurch error");
      print('GetChurch= response.statusCode ${response.statusCode}');
      return null;
    }
  }

  Future<List<Course>?> getCourses(String churchID) async {
    setState(() {
      flagAddCourse = true;
    });
    var response =
        await http.get('$baseUrl/Booking/GetCourses/?BranchID=$churchID' as Uri);
    print('$baseUrl/Booking/GetCourses/?BranchID=$churchID');
    print(response.body);
    if (response.statusCode == 200) {
      if (response.body.toString() == "[]") {
        print("getCourses empty");
        setState(() {
          dateState = 0;
          isDateChosen = true;
          isChurchChosen = false;
        });
      } else {
        print("getCourses not empty");
        setState(() {
          dateState = 1;
          isChurchChosen = true;
        });
      }
      print('getCourses= response.statusCode ${response.statusCode}');
      var coursesObj = courseFromJson(response.body.toString());
      print('jsonResponse $coursesObj');
      return coursesObj;
    } else {
      setState(() {
        dateState = 0;
        isDateChosen = true;
        isChurchChosen = false;
      });
      print("getCourses error");
      print('getCourses= response.statusCode ${response.statusCode}');
      return null;
    }
  }

  Future<CourseDetails?> getCourseDetails(String courseID) async {
    var response = await http.get(
        '$baseUrl/Booking/GetCourseDetails/?CourseID=$courseID&UserAccountID=$userID&token=$mobileToken' as Uri);
    print(
        '$baseUrl/Booking/GetCourseDetails/?CourseID=$courseID&UserAccountID=$userID&token=$mobileToken');
    print(response.body);
    if (response.statusCode == 200) {
      print('GetCourseDetails= response.statusCode ${response.statusCode}');
      var courseDetailsObj = courseDetailsFromJson(response.body.toString());
      print('jsonResponse $courseDetailsObj');
      setState(() {
        flagAddCourse = false;
        availableSeatsState = 1;
        remAttendanceCount = courseDetailsObj.remAttendanceCount.toString();
        remAttendanceDeaconCount =
            courseDetailsObj.remAttendanceDeaconCount.toString();
        churchRemarks = courseDetailsObj.churchRemarks.toString();
        churchNameEn = courseDetailsObj.churchNameEn.toString();
        churchNameAr = courseDetailsObj.churchNameAr.toString();
        courseRemarks = courseDetailsObj.courseRemarks.toString();
        courseDateAr = courseDetailsObj.courseDateAr.toString();
        courseDateEn = courseDetailsObj.courseDateEn.toString();
        courseTimeAr = courseDetailsObj.courseTimeAr.toString();
        courseTimeEn = courseDetailsObj.courseTimeEn.toString();
        courseTypeName = courseDetailsObj.courseTypeName.toString();
      });
      return courseDetailsObj;
    } else {
      print("GetCourseDetails error");
      print('GetCourseDetails= response.statusCode ${response.statusCode}');
      return null;
    }
  }

  

  @override
  void dispose() {
    super.dispose();
  }

  String userID = "";

 Future<void> getSharedData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  myLanguage = prefs.getString('language') ?? "en";
  userID = prefs.getString("userID") ?? "";
  accountType = prefs.getString("accountType") ?? "0";

  defaultGovernateID = prefs.getInt("governateID") ?? 0;
  defaultBranchID = prefs.getInt("branchID") ?? 0;

  // 🔹 Charger les gouvernorats
  governoratesList = await getGovernoratesByUserID() ?? [];

  if (governoratesList.isNotEmpty) {
    await governoratesDropDownData();

    setState(() {
      loadingState = 1; // ✅ Très important pour afficher la page principale
    });
  } else {
    setState(() {
      loadingState = 2; // Erreur ou liste vide
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: new IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
  AppLocalizations.of(context)?.newBooking ?? "New Booking",
  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
),

        ),
        backgroundColor: primaryDarkColor, systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBar: loadingState == 1
    ? buildBookButton()
    : const SizedBox.shrink(),

      body: buildChild(),
    );
  }

  Widget buildBookButton() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50.0,
      child: ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: int.parse(
      attendanceTypeIDNewBooking == 3
        ? remAttendanceDeaconCount
        : remAttendanceCount
    ) > 0
        ? primaryDarkColor
        : greyColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
  ),
  onPressed: () async {
    if ((attendanceTypeIDNewBooking == 3 &&
            int.parse(remAttendanceDeaconCount) > 0) ||
        (attendanceTypeIDNewBooking == 1 &&
            int.parse(remAttendanceCount) > 0) ||
        (attendanceTypeIDNewBooking == 2 &&
            int.parse(remAttendanceCount) > 0) ||
        (attendanceTypeIDNewBooking == 0 &&
            int.parse(remAttendanceCount) > 0)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChooseBookingFamilyMembersActivity(
            attendanceTypeIDNewBooking == 3
                ? remAttendanceDeaconCount
                : remAttendanceCount,
            churchRemarks,
            courseRemarks,
            courseDateAr,
            courseDateEn,
            courseTimeAr,
            courseTimeEn,
            churchNameAr,
            churchNameEn,
            courseID,
            courseTypeName,
            attendanceTypeIDNewBooking,
            attendanceTypeNameArNewBooking,
            attendanceTypeNameEnNewBooking,
          ),
        ),
      );
    } else {
  String msg = "";
  final localizations = AppLocalizations.of(context);

  if (isChurchChosen) {
    msg = localizations?.pleaseChooseBookingDate ?? "Please choose a booking date";
  } else if (isDateChosen) {
    msg = localizations?.noSeatsAvailable ?? "No seats available";
  } else {
    msg = localizations?.pleaseChooseChurch ?? "Please choose a church";
  }


      Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.white,
        textColor: Colors.red,
        fontSize: 16.0,
      );
    }
  },
  child: accountType == "1"
      ? Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: <Widget>[
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Image.asset(
        'images/love.png',
        color: Colors.white,
        width: 25,
        height: 25,
      ),
    ),
    Text(
      AppLocalizations.of(context)?.chooseFamilyMembers2 ?? "Choose Family Members",
      style: const TextStyle(
        fontSize: 18.0,
        fontFamily: 'cocon-next-arabic-regular',
        fontWeight: FontWeight.normal,
      ),
    ),
  ],
)

      :Text(
  AppLocalizations.of(context)?.book ?? "Book",
  style: const TextStyle(
    fontSize: 18.0,
    fontFamily: 'cocon-next-arabic-regular',
    fontWeight: FontWeight.normal,
  ),
),

));

  }

  Widget buildChild() {
  if (loadingState == 0) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: 10,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(14.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
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
                        padding: const EdgeInsets.only(left: 15.0, right: 5.0),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: double.infinity,
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                showGovernoratesLayout(),
                showChurchOfAttendanceLayout(),
                showCourses(),
                availableSeats(),
              ],
            ),
          ),
        ),
      ),
    );
  } else if (loadingState == 2) {
    return Center(
     child: Text(
  AppLocalizations.of(context)?.errorConnectingWithServer ?? "Error connecting to server",
  style: const TextStyle(
    fontSize: 20.0,
    fontFamily: 'cocon-next-arabic-regular',
    color: Colors.grey,
  ),
),


    );
  }

  // ✅ Cas par défaut pour éviter "missing return"
  return Container();
}

  Widget availableSeats() {
    if (availableSeatsState == 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 10.0, left: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    myLanguage == "ar" ? courseDateAr : courseDateEn,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontFamily: 'cocon-next-arabic-regular',
                      color: primaryDarkColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  //      width: double.infinity,
                ),
              ),
              attendanceTypeIDNewBooking == 0 ? Container() : Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Container(
                  width: double.infinity,

                  child: Text(
  AppLocalizations.of(context)?.attendanceType ?? "Attendance Type",
  style: const TextStyle(
    fontSize: 20.0,
    color: Colors.black,
  ),
),

                    ),
              ),
              attendanceTypeIDNewBooking == 0 ? Container() : Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    myLanguage == "ar"
                        ? attendanceTypeNameArNewBooking
                        : attendanceTypeNameEnNewBooking,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontFamily: 'cocon-next-arabic-regular',
                      color: attendanceTypeIDNewBooking == 3 ? accentColor : logoBlue,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  //      width: double.infinity,
                ),
              ),
              Container(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
AppLocalizations.of(context)?.time ?? "Time",
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              myLanguage == "en"
                  ? Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Container(
                        width: double.infinity,
                        child: Text(
                          courseTimeEn,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontFamily: 'cocon-next-arabic-regular',
                            color: primaryDarkColor,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        //      width: double.infinity,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Container(
                        width: double.infinity,
                        child: Text(
                          courseTimeAr,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontFamily: 'cocon-next-arabic-regular',
                            color: primaryDarkColor,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        //  width: double.infinity,
                      ),
                    ),
              int.parse(attendanceTypeIDNewBooking == 3 ? remAttendanceDeaconCount: remAttendanceCount) > 10
                  ? IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            child: Text(
AppLocalizations.of(context)?.thereAre ?? "There are",
                              style: TextStyle(
                                fontSize: 18.0,
                                fontFamily: 'cocon-next-arabic-regular',
                                color: primaryDarkColor,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 5.0, top: 8.0, bottom: 8.0, right: 5.0),
                            child: Text(
                              attendanceTypeIDNewBooking == 3 ? remAttendanceDeaconCount: remAttendanceCount,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontFamily: 'cocon-next-arabic-regular',
                                color: Colors.green,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: Text(
AppLocalizations.of(context)?.availableSeat ?? "Available seat",
                              style: TextStyle(
                                fontSize: 18.0,
                                fontFamily: 'cocon-next-arabic-regular',
                                color: primaryDarkColor,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : int.parse(attendanceTypeIDNewBooking == 3 ? remAttendanceDeaconCount: remAttendanceCount) > 1
                      ? IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
AppLocalizations.of(context)?.thereAre ?? "There are",
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontFamily: 'cocon-next-arabic-regular',
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 5.0, right: 5.0),
                                child: Text(
                                  attendanceTypeIDNewBooking == 3
                                      ? remAttendanceDeaconCount
                                      : remAttendanceCount,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontFamily: 'cocon-next-arabic-regular',
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
AppLocalizations.of(context)?.availableSeats ?? "Available Seats",
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontFamily: 'cocon-next-arabic-regular',
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        )
                      : IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
AppLocalizations.of(context)?.thereIs ?? "There is",
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontFamily: 'cocon-next-arabic-regular',
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 5.0, right: 5.0),
                                child: Text(
                                  attendanceTypeIDNewBooking == 3
                                      ? remAttendanceDeaconCount
                                      : remAttendanceCount,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontFamily: 'cocon-next-arabic-regular',
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context)?.availableSeatSingular ?? "Seat",

                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontFamily: 'cocon-next-arabic-regular',
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
              courseRemarks.isEmpty
                  ? new Container()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        courseRemarks,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontFamily: 'cocon-next-arabic-regular',
                          color: Colors.redAccent,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
              churchRemarks.isEmpty
                  ? new Container()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        churchRemarks,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontFamily: 'cocon-next-arabic-regular',
                          color: primaryDarkColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );
    } else if (availableSeatsState == 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 20.0, left: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
AppLocalizations.of(context)?.noSeatsAvailable ?? "No seats available",
                style: TextStyle(
                  fontSize: 18.0,
                  fontFamily: 'cocon-next-arabic-regular',
                  color: Colors.redAccent,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (availableSeatsState == 3) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Container();
    }
  }

  BoxDecoration myBoxDecoration() {
    return BoxDecoration(
      border: Border.all(
        width: 1.5,
        color: accentColor,
      ),
      borderRadius: BorderRadius.all(
          Radius.circular(15.0) //                 <--- border radius here
          ),
    );
  }

  Widget showGovernoratesLayout() {
    if (myLanguage == "en") {
      return Padding(
        padding: const EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
AppLocalizations.of(context)?.governorate ?? "Governorate",
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: new DropdownButton(
                  value: governorateID,
                  isExpanded: true,
                  items: listDropGovernorates.map((Map map) {
                    return DropdownMenuItem<String>(
                      value: map["id"].toString(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 10, left: 5.0, right: 5.0),
                            child: new MyBullet(),
                          ),
                          Expanded(
                            child: Text(
                              map["nameEn"],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryDarkColor,
                                fontSize: 20.0,
                                fontFamily: 'cocon-next-arabic-regular',
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      governorateID = value!;
                      setState(() {
                        availableSeatsState = 0;
                        dateState = 0;

                        churchOfAttendanceID = "0";
                        courseID = "0";
                        listDropCourses.clear();
                        listDropChurchOfAttendance.clear();
                        remAttendanceCount = "0";
                        remAttendanceDeaconCount = "0";
                      });
                      if (value != 0) {
                        getChurchWithGovernorateID();
                      }

                      print("governorateID : $governorateID");
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
AppLocalizations.of(context)?.governorate ?? "Governorate",
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: new DropdownButton(
                  value: governorateID,
                  isExpanded: true,
                  items: listDropGovernorates.map((Map map) {
                    return DropdownMenuItem<String>(
                      value: map["id"].toString(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 10, left: 5.0, right: 5.0),
                            child: new MyBullet(),
                          ),
                          Expanded(
                            child: Text(
                              map["nameAr"],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryDarkColor,
                                fontSize: 20.0,
                                fontFamily: 'cocon-next-arabic-regular',
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      governorateID = value!;
                      setState(() {
                        availableSeatsState = 0;
                        listDropCourses.clear();
                        listDropChurchOfAttendance.clear();
                        churchOfAttendanceID = "0";
                        courseID = "0";
                        remAttendanceCount = "0";
                        remAttendanceDeaconCount = "0";
                        dateState = 0;
                      });

                      if (value != 0) {
                        getChurchWithGovernorateID();
                      }

                      print("governorateID : $governorateID");
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  getChurchWithGovernorateID() async {
    setState(() {
      flagAddCourse = true;
    });
    churchOfAttendanceList = (await getChurchs(governorateID))!;
    await churchOfAttendanceDropDownData();
  }

  getCoursesWithChurchID() async {
    for (int i = 0; i < churchOfAttendanceList.length; i++) {
      if (churchOfAttendanceID ==
          churchOfAttendanceList.elementAt(i).id.toString()) {
        branchNameAr = churchOfAttendanceList.elementAt(i).nameAr!;
        branchNameEn = churchOfAttendanceList.elementAt(i).nameEn!;
        print("branchNameAr $branchNameAr");
        print("branchNameEn $branchNameEn");
      }
    }
    coursesList = (await getCourses(churchOfAttendanceID))!;

    await coursesDropDownData();
  }

  getCourseDetailsWithCourseID() async {
    await getCourseDetails(courseID);
  }

  Widget showChurchOfAttendanceLayout() {
    if (myLanguage == "en") {
      return Padding(
        padding: const EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
AppLocalizations.of(context)?.church ?? "Church",
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: new DropdownButton(
                  value: churchOfAttendanceID,
                  isExpanded: true,
                  itemHeight: 95,
                  items: listDropChurchOfAttendance.map((Map map) {
                    return DropdownMenuItem<String>(
                      value: map["id"].toString(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 20, left: 5.0, right: 5.0),
                            child: new MyBullet(),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(
                                map["nameEn"],
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: primaryDarkColor,
                                  fontSize: 20.0,
                                  fontFamily: 'cocon-next-arabic-regular',
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      churchOfAttendanceID = value!;
                      courseID = "0";
                      availableSeatsState = 0;
                      remAttendanceCount = "0";
                      remAttendanceDeaconCount = "0";
                      if (value != "0") {
                        dateState = 2;
                        isDateChosen = false;
                        isChurchChosen = false;
                        getCoursesWithChurchID();
                      } else {
                        remAttendanceCount = "0";
                        remAttendanceDeaconCount = "0";
                        isDateChosen = false;
                        isChurchChosen = false;
                        dateState = 0;
                      }
                      print("churchOfAttendanceID : $churchOfAttendanceID");
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
AppLocalizations.of(context)?.church ?? "Church",
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                child: new DropdownButton(
                  value: churchOfAttendanceID,
                  itemHeight: 95,
                  isExpanded: true,
                  items: listDropChurchOfAttendance.map((Map map) {
                    return DropdownMenuItem<String>(
                      value: map["id"].toString(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 20, left: 5.0, right: 5.0),
                            child: new MyBullet(),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(
                                map["nameAr"],
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: primaryDarkColor,
                                  fontSize: 20.0,
                                  fontFamily: 'cocon-next-arabic-regular',
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      churchOfAttendanceID = value!;
                      courseID = "0";
                      availableSeatsState = 0;
                      remAttendanceCount = "0";
                      remAttendanceDeaconCount = "0";
                      if (value != "0") {
                        dateState = 2;
                        isDateChosen = false;
                        isChurchChosen = false;
                        getCoursesWithChurchID();
                      } else {
                        remAttendanceCount = "0";
                        remAttendanceDeaconCount = "0";
                        isDateChosen = false;
                        isChurchChosen = false;
                        dateState = 0;
                      }
                      print("churchOfAttendanceID : $churchOfAttendanceID");
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget showCourses() {
    if (dateState == 0) {
      return Container();
    } else if (dateState == 2) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  flagAddCourse
                      ? Container()
                      : Text(
AppLocalizations.of(context)?.bookingType ?? "Booking Type",
                          style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.black,
                          ),
                        ),
                  !flagAddCourse
                      ? GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .push(
                              new MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    CalendarOfBookingsActivity(
                                        churchOfAttendanceID,
                                        branchNameAr,
                                        branchNameEn),
                              ),
                            )
                                .then((value) {
                              if (courseID != "0") {
                                setState(() {
                                  availableSeatsState = 3;
                                  remAttendanceCount = "0";
                                  remAttendanceDeaconCount = "0";
                                });
                                getCourseDetailsWithCourseID();
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: logoBlue),
                              borderRadius: BorderRadius.all(Radius.circular(
                                      5.0) //                 <--- border radius here
                                  ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Row(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 5.0, right: 5.0),
                                    child: Text(
AppLocalizations.of(context)?.modify ?? "Modify",
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        color: logoBlue,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 5.0, right: 5.0),
                                    child: Icon(
                                      Icons.edit,
                                      color: logoBlue,
                                      size: 17,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
              flagAddCourse
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        courseTypeName,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: primaryDarkColor,
                        ),
                      ),
                    ),
              flagAddCourse
                  ? Container()
                  : Text(
AppLocalizations.of(context)?.holyLiturgyDate ?? "Holy Liturgy Date",
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                      ),
                    ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 0,
                ),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width - 100,
                    height: flagAddCourse ? 50.0 : 0,
                    child: 
                       flagAddCourse
  ? ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDarkColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (BuildContext context) => CalendarOfBookingsActivity(
              churchOfAttendanceID,
              branchNameAr,
              branchNameEn,
            ),
          ),
        )
            .then((value) {
          if (courseID != "0") {
            setState(() {
              availableSeatsState = 3;
              remAttendanceCount = "0";
              remAttendanceDeaconCount = "0";
            });
            getCourseDetailsWithCourseID();
          }
        });
      },
      child: Text(
AppLocalizations.of(context)?.chooseHolyLiturgyDate ?? "Choose Holy Liturgy Date",
        style: TextStyle(
          fontSize: 18.0,
          fontFamily: 'cocon-next-arabic-regular',
          fontWeight: FontWeight.normal,
        ),
      ),
    )
  : Container(),

                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

extension on AppLocalizations? {
  String? get errorConnectingWithServer => null;
}

class MyBullet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container(
      height: 5.0,
      width: 5.0,
      decoration: new BoxDecoration(
        color: primaryDarkColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
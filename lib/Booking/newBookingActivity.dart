import 'dart:async';
import 'dart:io';
import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Booking/calendarOfBookings.dart';
import 'package:egpycopsversion4/Booking/chooseBookingFamilyMembersActivity.dart';
import 'package:egpycopsversion4/Colors/colors.dart';
import 'package:egpycopsversion4/Home/homeActivity.dart';
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
BaseUrl BASE_URL = BaseUrl();
String baseUrl = BASE_URL.BASE_URL;
bool flagAddCourse = false;
int availableSeatsState = 0;
String myLanguage = "";
int loadingState = 0;
int dateState = 0;
bool isDateChosen = false;
bool isChurchChosen = false;
String churchOfAttendanceID = "0";
String governorateID = "";
String courseID = "0";
String churchNameAr = "",
    churchNameEn = "",
    remAttendanceCount = "",
    remAttendanceDeaconCount = "",
    churchRemarks = "",
    courseRemarks = "",
    courseDateAr = "",
    courseDateEn = "",
    courseTimeAr = "",
    courseTimeEn = "",
    courseTypeName = "";
int defaultGovernateID = 0, defaultBranchID = 0;
int attendanceTypeIDNewBooking = 0;
String attendanceTypeNameArNewBooking = "", attendanceTypeNameEnNewBooking = "";

class NewBookingActivity extends StatefulWidget {
  @override
  _NewBookingActivityState createState() => _NewBookingActivityState();
}

class _NewBookingActivityState extends State<NewBookingActivity> {
  List<Map> listDropChurchOfAttendance = [];
  List<Map> listDropGovernorates = [];
  List<Map> listDropCourses = [];
  String mobileToken = "";

  List<Churchs> churchOfAttendanceList = [];
  List<Governorates> governoratesList = [];
  List<Course> coursesList = [];

  String userBranchID = "0";
  String userID = "";
  String userEmail = "";

  @override
  void initState() {
    super.initState();

    // Reset des variables
    churchOfAttendanceID = "0";
    governorateID = "0";
    courseID = "0";
    loadingState = 0;
    availableSeatsState = 0;
    remAttendanceCount = "0";
    remAttendanceDeaconCount = "0";
    dateState = 0;
    isDateChosen = false;
    isChurchChosen = false;
    churchRemarks = "";
    courseRemarks = "";
    courseDateAr = "";
    courseDateEn = "";
    courseTimeAr = "";
    courseTimeEn = "";
    churchNameAr = "";
    churchNameEn = "";
    courseTypeName = "";
    flagAddCourse = true;

    // 🔹 Récupération du token Firebase
    FirebaseMessaging.instance.getToken().then((String? token) {
      if (token != null && token.isNotEmpty) {
        debugPrint("Token: $token");
        mobileToken = token;
      } else {
        debugPrint("⚠️ Aucun token Firebase reçu");
        mobileToken = "";
      }
    });

    getSharedData();
  }

  // 🔹 Récupération des données SharedPreferences
  Future<void> getSharedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    myLanguage = prefs.getString('language') ?? "en";
    userID = prefs.getString("userID") ?? "";
    userEmail = prefs.getString("userEmail") ?? "";
    accountType = prefs.getString("accountType") ?? "0";

    defaultGovernateID = prefs.getInt("governateID") ?? 0;
    defaultBranchID = prefs.getInt("branchID") ?? 0;

    debugPrint("defaultGovernateID $defaultGovernateID");
    debugPrint("defaultBranchID $defaultBranchID");

    // Charger les gouvernorats
    governoratesList = await getGovernoratesByUserID() ?? [];
    await governoratesDropDownData();

    if (defaultGovernateID != 0) {
      setState(() {
        governorateID = defaultGovernateID.toString();
        userBranchID = defaultBranchID.toString();
      });

      churchOfAttendanceList = await getChurchs(governorateID) ?? [];
      await churchOfAttendanceDropDownData();

      if (churchOfAttendanceID != "0") {
        debugPrint("defaultBranchID != 0");
        setState(() {
          courseID = "0";
          availableSeatsState = 0;
          remAttendanceCount = "0";
          remAttendanceDeaconCount = "0";
          dateState = 2;
          isDateChosen = false;
          isChurchChosen = false;
        });
        getCoursesWithChurchID();
      } else {
        debugPrint("defaultBranchID == 0");
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
        getChurchWithGovernorateID();
      }
    }
  }

  // 🔹 Dropdown Gouvernorats
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

    setState(() {}); // Refresh dropdown
  }

  // 🔹 API : Gouvernorats par UserID
  Future<List<Governorates>?> getGovernoratesByUserID() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Booking/GetGovernoratesByUserID/?UserAccountID=$userID'),
    );

    if (response.statusCode == 200) {
      return governoratesFromJson(response.body.toString());
    } else {
      debugPrint("GetGovernoratesByUserID error: ${response.statusCode}");
      return null;
    }
  }

  // 🔹 API : Églises
  Future<List<Churchs>?> getChurchs(String governorateID) async {
    setState(() => flagAddCourse = true);

    final response = await http.get(
      Uri.parse('$baseUrl/Booking/GetChurch/?GovernerateID=$governorateID'),
    );

    if (response.statusCode == 200) {
      setState(() => loadingState = 1);
      return churchsFromJson(response.body.toString());
    } else {
      setState(() => loadingState = 2);
      debugPrint("GetChurch error: ${response.statusCode}");
      return null;
    }
  }

  // 🔹 Remplir dropdown églises
  Future<void> churchOfAttendanceDropDownData() async {
    listDropChurchOfAttendance.clear();

    if (churchOfAttendanceList.isNotEmpty) {
      setState(() {
        listDropChurchOfAttendance.add({
          "id": "0",
          "nameAr": "اختار الكنيسة",
          "nameEn": "Choose Church",
          "isDefualt": false
        });

        for (var church in churchOfAttendanceList) {
          listDropChurchOfAttendance.add({
            "id": church.id,
            "nameAr": church.nameAr,
            "nameEn": church.nameEn,
            "isDefualt": church.isDefualt,
          });
        }
      });
    }
  }

  // 🔹 Bouton Réserver
  Widget buildBookButton(BuildContext context) {
    final int remCount = int.tryParse(remAttendanceCount) ?? 0;
    final int remDeaconCount = int.tryParse(remAttendanceDeaconCount) ?? 0;

    final bool hasSeats = (attendanceTypeIDNewBooking == 3 && remDeaconCount > 0) ||
        (attendanceTypeIDNewBooking != 3 && remCount > 0);

    final Color btnColor = hasSeats ? primaryDarkColor : greyColor;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: () async {
          if (hasSeats) {
            final String seats = attendanceTypeIDNewBooking == 3
                ? remAttendanceDeaconCount
                : remAttendanceCount;

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChooseBookingFamilyMembersActivity(
                  seats,
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
            String msg;
            if (!isChurchChosen) {
              msg = AppLocalizations.of(context)?.pleaseChooseChurch ?? "Please choose a church";
            } else if (!isDateChosen) {
              msg = AppLocalizations.of(context)?.pleaseChooseBookingDate ?? "Please choose a date";
            } else {
              msg = AppLocalizations.of(context)?.noSeatsAvailable ?? "No seats available";
            }

            Fluttertoast.showToast(
              msg: msg,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
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
            : Text(
                AppLocalizations.of(context)?.book ?? "Book",
                style: const TextStyle(
                  fontSize: 18.0,
                  fontFamily: 'cocon-next-arabic-regular',
                  fontWeight: FontWeight.normal,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            AppLocalizations.of(context)?.newBooking ?? "New Booking",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
          ),
        ),
        backgroundColor: primaryDarkColor,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBar: loadingState == 1
          ? buildBookButton(context)
          : const SizedBox.shrink(),
      body: buildChild(),
    );
  }
}

  Widget buildChild(BuildContext context) {
  if (loadingState == 0) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: 10,
        itemBuilder: (BuildContext context, int index) {
          final screenWidth = MediaQuery.of(context).size.width;

          return Padding(
            padding: const EdgeInsets.all(14.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0, bottom: 5.0),
                        child: SkeletonAnimation(
                          child: Container(
                            height: 15,
                            width: screenWidth * 0.7,
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
  } 
  else if (loadingState == 1) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: double.infinity,
        child: Form(
          child: SingleChildScrollView(
            child: Column(
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
  } 
  else if (loadingState == 2) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Text(
        localizations?.errorConnectingWithServer ?? "Error connecting to server",
        style: const TextStyle(
          fontSize: 20.0,
          fontFamily: 'cocon-next-arabic-regular',
          color: Colors.grey,
        ),
      ),
    );
  }

  return const SizedBox.shrink(); // Par défaut
}



  Widget availableSeats(BuildContext context) 
  {
  final localizations = AppLocalizations.of(context);

  if (availableSeatsState == 1) {
    final int remCount =
        int.tryParse(attendanceTypeIDNewBooking == 3 ? remAttendanceDeaconCount : remAttendanceCount) ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 10.0, left: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 🔹 Date du cours
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                myLanguage == "ar" ? courseDateAr : courseDateEn,
                style: TextStyle(
                  fontSize: 18.0,
                  fontFamily: 'cocon-next-arabic-regular',
                  color: primaryDarkColor,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),

            // 🔹 Type de participation
            if (attendanceTypeIDNewBooking != 0) ...[
              const SizedBox(height: 8),
              Text(
                localizations?.attendanceType ?? "Attendance Type",
                style: const TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Text(
                  myLanguage == "ar"
                      ? attendanceTypeNameArNewBooking
                      : attendanceTypeNameEnNewBooking,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'cocon-next-arabic-regular',
                    color: attendanceTypeIDNewBooking == 3 ? accentColor : logoBlue,
                  ),
                ),
              ),
            ],

            // 🔹 Heure
            const SizedBox(height: 8),
            Text(
              localizations?.time ?? "Time",
              style: const TextStyle(
                fontSize: 20.0,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                myLanguage == "en" ? courseTimeEn : courseTimeAr,
                style: TextStyle(
                  fontSize: 18.0,
                  fontFamily: 'cocon-next-arabic-regular',
                  color: primaryDarkColor,
                ),
              ),
            ),

            // 🔹 Affichage du nombre de sièges
            const SizedBox(height: 8),
            if (remCount > 10)
              _buildSeatsInfo(context, remCount, Colors.green, localizations?.availableSeat ?? "Seat", plural: true)
            else if (remCount > 1)
              _buildSeatsInfo(context, remCount, Colors.redAccent, localizations?.availableSeats ?? "Seats", plural: true)
            else
              _buildSeatsInfo(context, remCount, Colors.redAccent, localizations?.availableSeatSingular ?? "Seat", plural: false),

            // 🔹 Remarques cours
            if (courseRemarks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  courseRemarks,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'cocon-next-arabic-regular',
                    color: Colors.redAccent,
                  ),
                ),
              ),

            // 🔹 Remarques église
            if (churchRemarks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  churchRemarks,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontFamily: 'cocon-next-arabic-regular',
                    color: primaryDarkColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  } 
  else if (availableSeatsState == 2) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, right: 20.0, left: 20.0),
        child: Text(
          AppLocalizations.of(context)?.noSeatsAvailable ?? "No seats available",
          style: const TextStyle(
            fontSize: 18.0,
            fontFamily: 'cocon-next-arabic-regular',
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  } 
  else if (availableSeatsState == 3) {
    return const Center(child: CircularProgressIndicator());
  } 

  return const SizedBox.shrink();
}

// 🔹 Widget réutilisable pour afficher les infos de sièges
Widget _buildSeatsInfo(BuildContext context, int seats, Color color, String label, {required bool plural}) {
  final localizations = AppLocalizations.of(context);

  return IntrinsicHeight(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          plural
              ? localizations?.thereAre ?? "There are"
              : localizations?.thereIs ?? "There is",
          style: TextStyle(
            fontSize: 18.0,
            fontFamily: 'cocon-next-arabic-regular',
            color: color,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            seats.toString(),
            style: TextStyle(
              fontSize: 18.0,
              fontFamily: 'cocon-next-arabic-regular',
              color: color,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 18.0,
            fontFamily: 'cocon-next-arabic-regular',
            color: color,
          ),
        ),
      ],
    ),
  );
}
  BoxDecoration myBoxDecoration() {
  return BoxDecoration(
    border: Border.all(
      width: 1.5,
      color: accentColor,
    ),
    borderRadius: const BorderRadius.all(
      Radius.circular(15.0),
    ),
  );
}

Widget showGovernoratesLayout(BuildContext context) {
  final localizations = AppLocalizations.of(context);

  return Padding(
    padding: const EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          localizations?.governorate ?? "Governorate",
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.black,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          child: DropdownButton<String>(
            value: governorateID,
            isExpanded: true,
            items: listDropGovernorates.map((Map map) {
              return DropdownMenuItem<String>(
                value: map["id"].toString(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 5.0, right: 5.0),
                      child: MyBullet(),
                    ),
                    Expanded(
                      child: Text(
                        myLanguage == "en" ? map["nameEn"] : map["nameAr"],
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
            onChanged: (String? value) {
              if (value == null) return;
              setState(() {
                governorateID = value;
                availableSeatsState = 0;
                dateState = 0;
                churchOfAttendanceID = "0";
                courseID = "0";
                listDropCourses.clear();
                listDropChurchOfAttendance.clear();
                remAttendanceCount = "0";
                remAttendanceDeaconCount = "0";
              });

              if (value != "0") {
                getChurchWithGovernorateID();
              }

              debugPrint("governorateID : $governorateID");
            },
          ),
        ),
      ],
    ),
  );
}
+++++++

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
                AppLocalizations.of(context)!.church,
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
                AppLocalizations.of(context)!.church,
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
                          AppLocalizations.of(context)!.bookingType,
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
                                      AppLocalizations.of(context)!.modify,
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
                      AppLocalizations.of(context)!.holyLiturgyDate,
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
        AppLocalizations.of(context)!.chooseHolyLiturgyDate,
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

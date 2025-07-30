import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Booking/bookingSuccessActivity.dart' show BookingSuccessActivity;
import 'package:egpycopsversion4/Colors/colors.dart';
import 'package:egpycopsversion4/Models/addBookingDetails.dart';
import 'package:egpycopsversion4/Models/familyMember.dart';
import 'package:egpycopsversion4/NetworkConnectivity/noNetworkConnectionActivity.dart';
import 'package:egpycopsversion4/Translation/localizations.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:skeleton_text/skeleton_text.dart';

typedef void LocaleChangeCallback(Locale locale);

// 🔐 Variables liées à la réservation
late String bookNumberAddBooking;
late String courseDateArAddBooking;
late String courseDateEnAddBooking;
late String courseTimeArAddBooking;
late String courseTimeEnAddBooking;

String remainingCountFailure = '';
String courseTypeName = '';

// 🏛 Informations sur l'église et la gouvernorat
String churchRemarksAddBooking = '';
String courseRemarksAddBooking = '';
String churchNameArAddBooking = '';
String churchNameEnAddBooking = '';
String governerateNameArAddBooking = '';
String governerateNameEnAddBooking = '';

// 🌐 Base de l'API
final BaseUrl BASE_URL = BaseUrl();
final String baseUrl = BASE_URL.BASE_URL;

// 📅 Détails du cours sélectionné
String remAttendanceCount = '0';
String churchRemarks = '';
String courseRemarks = '';
String courseDateAr = '';
String courseDateEn = '';
String courseTimeAr = '';
String courseTimeEn = '';
String churchNameAr = '';
String churchNameEn = '';
String courseID = '';

// 🔤 Langue de l'utilisateur
String myLanguage = '';

// 🔄 État
int bookingState = 0;
String firstAttendDate = '';

// 👤 Compte utilisateur
String accountType = '';

// 🪪 Type de participation
int attendanceTypeID = 0;
String attendanceTypeNameAr = '';
String attendanceTypeNameEn = '';

// Type spécifique à la réservation
int attendanceTypeIDAddBooking = 0;

String attendanceTypeNameArAddBooking= '', attendanceTypeNameEnAddBooking= '';
class ChooseBookingFamilyMembersActivity extends StatefulWidget {
  ChooseBookingFamilyMembersActivity(
      remAttendanceCountConstructor,
      churchRemarksConstructor,
      courseRemarksConstructor,
      courseDateArConstructor,
      courseDateEnConstructor,
      courseTimeArConstructor,
      courseTimeEnConstructor,
      churchNameArConstructor,
      churchNameEnConstructor,
      courseIDConstructor,
      courseTypeNameConstructor,
      int attendanceTypeIDCon,
      String attendanceTypeNameArCon,
      String attendanceTypeNameEnCon) {
    remAttendanceCount = remAttendanceCountConstructor;
    churchRemarks = churchRemarksConstructor;
    courseRemarks = courseRemarksConstructor;
    courseDateAr = courseDateArConstructor;
    courseDateEn = courseDateEnConstructor;
    courseTimeAr = courseTimeArConstructor;
    courseTimeEn = courseTimeEnConstructor;
    churchNameAr = churchNameArConstructor;
    churchNameEn = churchNameEnConstructor;
    courseID = courseIDConstructor;
    courseTypeName = courseTypeNameConstructor;
    attendanceTypeID = attendanceTypeIDCon;
    attendanceTypeNameAr = attendanceTypeNameArCon;
    attendanceTypeNameEn = attendanceTypeNameEnCon;
  }

  @override
  _ChooseBookingFamilyMembersActivityState createState() =>
      _ChooseBookingFamilyMembersActivityState();
}

class _ChooseBookingFamilyMembersActivityState
    extends State<ChooseBookingFamilyMembersActivity> {
  List<FamilyMember> myFamilyList = [];
  List<Map> listViewMyFamily = [];
  ScrollController _scrollController = new ScrollController();
  int loadingState = 0;
  int pageNumber = 0;
  String userID = "";
  late String mobileToken;
  String failureMessage = "";
  List<BookedPersonsList> bookedPersonsList = [];

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getToken().then((String token) {
      print("Token  " + token);
      mobileToken = token;
    } as FutureOr<Null> Function(String? value));
    remainingCountFailure = "0";
    pageNumber = 0;
    bookingState = 0;
    loadingState = 0;
    getDataFromShared();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        //getDataFromShared();
      }
    });
  }

  Future<String> _checkInternetConnection() async {
    String connectionResult;
    var result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      connectionResult = "0";
    } else {
      connectionResult = "1";
    }
    return connectionResult;
  }

  getDataFromShared() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    myLanguage = (prefs.getString('language') ?? "en");
    accountType = prefs.getString("accountType")!;
    userID = prefs.getString("userID")!;
    setState(() {
      loadingState = 0;
      pageNumber = 0;
      showSaveButton = false;
    });
    String connectionResponse = await _checkInternetConnection();
    print("connectionResponse");
    print(connectionResponse);
    if (connectionResponse == '1') {
      myFamilyList = (await getMyFamily())!;
    } else {
      Navigator.of(context)
          .push(
        new MaterialPageRoute(
          builder: (BuildContext context) => NoInternetConnectionActivity(),
        ),
      )
          .then((value) async {
        myFamilyList = (await getMyFamily())!;
      });
    }
    if (loadingState == 1 && myFamilyList != null) {
      myFamilyListViewData();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Widget buildBookButton() {
    if (bookingState == 1) {
      return SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            value: null,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ));
    } else {
      return Text(
        AppLocalizations.of(context)!.confirmBooking,
        style: TextStyle(
          fontSize: 18.0,
          fontFamily: 'cocon-next-arabic-regular',
          fontWeight: FontWeight.normal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        height: 50.0,
        child: bookbutton(),
      ),
      appBar: AppBar(
        iconTheme: new IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.all(2.0),
          child: new Text(
            AppLocalizations.of(context)!.bookADate,
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
          ),
        ),
        backgroundColor: primaryDarkColor, systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: buildChild(),
    );
  }

  void myFamilyListViewData() {
  setState(() {
    listViewMyFamily.clear(); // Important : réinitialise pour éviter les doublons

    for (final member in myFamilyList) {
      if (attendanceTypeID == 3 && !(member.isDeacon ?? false)) {
        continue; // Ignorer les membres non-diacre si type == 3
      }

      listViewMyFamily.add({
        "userAccountMemberId": member.userAccountMemberId,
        "userAccountId": member.userAccountId,
        "accountMemberNameAr": member.accountMemberNameAr,
        "genderTypeId": member.genderTypeId,
        "genderTypeNameAr": member.genderTypeNameAr,
        "genderTypeNameEn": member.genderTypeNameEn,
        "isDeacon": member.isDeacon,
        "nationalIdNumber": member.nationalIdNumber,
        "mobile": member.mobile,
        "personRelationId": member.personRelationId,
        "personRelationNameAr": member.personRelationNameAr,
        "personRelationNameEn": member.personRelationNameEn,
        "isMainPerson": member.isMainPerson,
        "isChecked": false,
      });
    }

    if (accountType == "2" && listViewMyFamily.isNotEmpty) {
      listViewMyFamily[0]["isChecked"] = true;
      showSaveButton = true;
    }
  });
}


  Widget bookbutton() {
  return ElevatedButton(
    onPressed: showSaveButton ? () async => book() : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: showSaveButton ? Colors.green : greyColor,
      foregroundColor: Colors.white,
    ),
    child: buildBookButton(),
  );
}


  chosenMemberCount() {
    String chosenMembers = "";
    for (int i = 0; i < listViewMyFamily.length; i++) {
      if (listViewMyFamily[i]["isChecked"]) {
        chosenMembers = chosenMembers +
            listViewMyFamily[i]["userAccountMemberId"].toString() +
            ",";
      }
    }
    print("chosenMembers $chosenMembers");
    if (chosenMembers.isEmpty) {
      setState(() {
        showSaveButton = false;
      });
    } else {
      setState(() {
        showSaveButton = true;
      });
    }
  }

  bool showSaveButton = false;

  book() async {
    String chosenMembers = "";
    print("chosenMembers $chosenMembers");

    for (int i = 0; i < listViewMyFamily.length; i++) {
      if (listViewMyFamily[i]["isChecked"]) {
        chosenMembers = chosenMembers +
            listViewMyFamily[i]["userAccountMemberId"].toString() +
            ",";
        print("chosenMembers $chosenMembers");
      }
    }
    print("chosenMembers $chosenMembers");

    if (chosenMembers.isEmpty) {
      Fluttertoast.showToast(
          msg: AppLocalizations.of(context)!.pleaseChooseAtLeastFamilyMember,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize: 16.0);
    } else {
      setState(() {
        bookingState = 1;
      });
      chosenMembers = chosenMembers.substring(0, chosenMembers.length - 1);
      print("chosenMembers = $chosenMembers");
      String? addBookingResponse = await addBooking(chosenMembers, courseID);
      if (addBookingResponse == "1") {
        setState(() {
          bookingState = 2;
        });
        Navigator.of(context).pop();

        Navigator.of(context).push(
          new MaterialPageRoute(
            builder: (BuildContext context) => BookingSuccessActivity(
                bookNumberAddBooking,
                courseDateArAddBooking,
                courseDateEnAddBooking,
                courseTimeArAddBooking,
                courseTimeEnAddBooking,
                churchRemarksAddBooking,
                courseRemarksAddBooking,
                churchNameArAddBooking,
                churchNameEnAddBooking,
                governerateNameArAddBooking,
                governerateNameEnAddBooking,
                myLanguage,
                courseTypeName,
                attendanceTypeIDAddBooking,
                attendanceTypeNameArAddBooking,
                attendanceTypeNameEnAddBooking,
                bookedPersonsList),
          ),
        );
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.bookedSuccessfully,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.white,
            textColor: Colors.green,
            fontSize: 16.0);
        }
      else if (addBookingResponse == "3") {
        setState(() {
          bookingState = 2;
        });

        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.sorryYouCannotBookBefore +
                " " +
                firstAttendDate,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.white,
            textColor: Colors.red,
            fontSize: 16.0);
      }
      else if (addBookingResponse == "4") {
        setState(() {
          bookingState = 2;
        });

        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!
                .youCannotBookBecauseYouHaveABookingOnTheSameTime,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.white,
            textColor: Colors.red,
            fontSize: 16.0);
      }
      else if (addBookingResponse == "5") {
        setState(() {
          bookingState = 2;
        });

        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!
                .youAreNotRegisteredInThisChurchMembership,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.white,
            textColor: Colors.red,
            fontSize: 16.0);
      }
      else if (addBookingResponse == "7") {
        setState(() {
          bookingState = 2;
        });

        Fluttertoast.showToast(
            msg: failureMessage,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.white,
            textColor: Colors.red,
            fontSize: 16.0);
      }
      else if (addBookingResponse == "6") {
        setState(() {
          bookingState = 2;
        });

        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!
                .chosenPersonIsNotaDeacon,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.white,
            textColor: Colors.red,
            fontSize: 16.0);
      }
      else if (addBookingResponse == "0") {
        setState(() {
          bookingState = 2;
        });
        if (int.parse(remainingCountFailure) > 10) {
          Fluttertoast.showToast(
              msg: AppLocalizations.of(context)!.thereAre +
                  " " +
                  remainingCountFailure +
                  " " +
                  AppLocalizations.of(context)!.availableSeat,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.white,
              textColor: Colors.red,
              fontSize: 16.0);
        } else {
          if (int.parse(remainingCountFailure) > 1) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.thereAre +
                    " " +
                    remainingCountFailure +
                    " " +
                    AppLocalizations.of(context)!.availableSeats,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.white,
                textColor: Colors.red,
                fontSize: 16.0);
          } else {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.thereIs +
                    " " +
                    remainingCountFailure +
                    " " +
                    AppLocalizations.of(context)!.availableSeatSingular,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.white,
                textColor: Colors.red,
                fontSize: 16.0);
          }
        }
      }
      else {
        setState(() {
          bookingState = 2;
        });
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)!.errorConnectingWithServer,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.white,
            textColor: Colors.red,
            fontSize: 16.0);
      }
    }
  }

  Future<String?> addBooking(String chosenMembers, String courseID) async {
    var response = await http.post(
        '$baseUrl/Booking/AddBooking/?listAccountMemberIDs=$chosenMembers&CourseID=$courseID&UserAccountID=$userID&AttendanceTypeID=$attendanceTypeID&Token=$mobileToken' as Uri);
    print(
        '$baseUrl/Booking/AddBooking/?listAccountMemberIDs=$chosenMembers&CourseID=$courseID&UserAccountID=$userID&AttendanceTypeID=$attendanceTypeID&Token=$mobileToken');
    print("response body");
    print(response.body);
    print("response statusCode");
    print(response.statusCode);
    if (response.statusCode == 200) {
      var myAddBookingDetailsObj =
          addBookingDetailsFromJson(response.body.toString());
      print('jsonResponse $myAddBookingDetailsObj');

      bookNumberAddBooking = myAddBookingDetailsObj.bookNumber!;
      courseDateArAddBooking = myAddBookingDetailsObj.courseDateAr!;
      courseDateEnAddBooking = myAddBookingDetailsObj.courseDateEn!;
      courseTimeArAddBooking = myAddBookingDetailsObj.courseTimeAr!;
      courseTimeEnAddBooking = myAddBookingDetailsObj.courseTimeEn!;
      churchRemarksAddBooking = myAddBookingDetailsObj.churchRemarks!;
      courseRemarksAddBooking = myAddBookingDetailsObj.courseRemarks!;
      churchNameArAddBooking = myAddBookingDetailsObj.churchNameAr!;
      churchNameEnAddBooking = myAddBookingDetailsObj.churchNameEn!;
      governerateNameArAddBooking = myAddBookingDetailsObj.governerateNameAr!;
      governerateNameEnAddBooking = myAddBookingDetailsObj.governerateNameEn!;
      firstAttendDate = myAddBookingDetailsObj.firstAttendDate!;
      firstAttendDate = myAddBookingDetailsObj.firstAttendDate!;
      attendanceTypeIDAddBooking = myAddBookingDetailsObj.attendanceTypeID!;
      attendanceTypeNameEnAddBooking = myAddBookingDetailsObj.attendanceTypeNameEn!;
      attendanceTypeNameArAddBooking = myAddBookingDetailsObj.attendanceTypeNameAr!;
      if(myLanguage == "ar"){
        failureMessage = myAddBookingDetailsObj.errorMessageAr!;
      }else{
        failureMessage = myAddBookingDetailsObj.errorMessageEn!;
      }
      bookedPersonsList = myAddBookingDetailsObj.personList;
      if (myAddBookingDetailsObj.sucessCode == "1") {
        courseTypeName = myAddBookingDetailsObj.courseTypeName!;
      }
      return myAddBookingDetailsObj.sucessCode;
    } else {
      return "0";
    }
  }

  Future<List<FamilyMember>?> getMyFamily() async {
    var response = await http.get(
        '$baseUrl/Family/GetFamilyMembers/?UserID=$userID&Token=$mobileToken' as Uri);
    print(
        '$baseUrl/Family/GetFamilyMembers/?UserID=$userID&Token=$mobileToken');
    print("response body");
    print(response.body);
    print("response statusCode");
    print(response.statusCode);
    if (response.statusCode == 200) {
      if (response.body.isEmpty && listViewMyFamily.length == 0) {
        setState(() {
          loadingState = 3;
        });
      } else {
        setState(() {
          loadingState = 1;
        });

        var myFamilyMembersObj = familyMemberFromJson(response.body.toString());
        print('jsonResponse $myFamilyMembersObj');

        return myFamilyMembersObj;
      }
    } else {
      setState(() {
        loadingState = 2;
      });
      print("get my Family error");
      return null;
    }
  }

  Widget holyLiturgyDate() {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 5.0),
              child: Text(
                AppLocalizations.of(context)!.holyLiturgyDate,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: myLanguage == "en"
                  ? Text(
                      courseDateEn,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: primaryDarkColor,
                      ),
                    )
                  : Text(
                      courseDateAr,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: primaryDarkColor,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget liturgyTime() {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppLocalizations.of(context)!.time,
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: myLanguage == "en"
                  ? Text(
                      courseTimeEn,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: primaryDarkColor,
                      ),
                    )
                  : Text(
                      courseTimeAr,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: primaryDarkColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget church() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 20.0, right: 20.0),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppLocalizations.of(context)!.church,
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: myLanguage == "en"
                  ? Text(
                      churchNameEn,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: primaryDarkColor,
                      ),
                    )
                  : Text(
                      churchNameAr,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: primaryDarkColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget availableSeatsLayout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0, right: 18.0, left: 18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            int.parse(remAttendanceCount) > 10
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context)!.thereAre,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontFamily: 'cocon-next-arabic-regular',
                          color: primaryDarkColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                        child: Text(
                          remAttendanceCount,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontFamily: 'cocon-next-arabic-regular',
                            color: Colors.green,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.availableSeat,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontFamily: 'cocon-next-arabic-regular',
                          color: primaryDarkColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  )
                : int.parse(remAttendanceCount) > 1
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            AppLocalizations.of(context)!.thereAre,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontFamily: 'cocon-next-arabic-regular',
                              color: Colors.redAccent,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 5.0, right: 5.0),
                            child: Text(
                              remAttendanceCount,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontFamily: 'cocon-next-arabic-regular',
                                color: Colors.redAccent,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.availableSeats,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontFamily: 'cocon-next-arabic-regular',
                              color: Colors.redAccent,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            AppLocalizations.of(context)!.thereIs,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontFamily: 'cocon-next-arabic-regular',
                              color: Colors.redAccent,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 5.0, right: 5.0),
                            child: Text(
                              remAttendanceCount,
                              style: TextStyle(
                                fontSize: 18.0,
                                fontFamily: 'cocon-next-arabic-regular',
                                color: Colors.redAccent,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.availableSeatSingular,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontFamily: 'cocon-next-arabic-regular',
                              color: Colors.redAccent,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget churchRemarksLayout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(
            top: 5.0, right: 20.0, left: 20.0, bottom: 5.0),
        child: churchRemarks.isEmpty
            ? new Container()
            : Text(
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
    );
  }

  Widget courseRemarksLayout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0, right: 20.0, left: 20.0),
        child: courseRemarks.isEmpty
            ? new Container()
            : Text(
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
    );
  }

Widget buildChild() {
  if (loadingState == 0) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
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
                        padding: const EdgeInsets.only(left: 15.0, bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5.0),
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
    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 10.0, right: 10.0),
            child: Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)!.bookingInformation,
                    style: TextStyle(fontSize: 20.0, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          church(),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
            child: Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)!.bookingType,
                    style: TextStyle(fontSize: 18.0, color: Colors.black),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Text(
                      courseTypeName,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 18.0, color: primaryDarkColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          attendanceTypeID == 0
              ? Container()
              : Padding(
                  padding:
                      const EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(context)!.attendanceType,
                          style: TextStyle(fontSize: 18.0, color: Colors.black),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Text(
                            myLanguage == "ar"
                                ? attendanceTypeNameAr
                                : attendanceTypeNameEn,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: attendanceTypeID == 1
                                  ? logoBlue
                                  : attendanceTypeID == 2
                                      ? logoBlue
                                      : accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          holyLiturgyDate(),
          liturgyTime(),
          availableSeatsLayout(),
          courseRemarksLayout(),
          churchRemarksLayout(),
        ],
      ),
    );
  } else if (loadingState == 2) {
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
  } else if (loadingState == 3) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.noMembersFound,
        style: TextStyle(
          fontSize: 20.0,
          fontFamily: 'cocon-next-arabic-regular',
          color: Colors.grey,
        ),
      ),
    );
  }

  return Center(child: CircularProgressIndicator());
}

}

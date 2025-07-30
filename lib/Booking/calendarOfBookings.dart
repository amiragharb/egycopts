import 'dart:convert';
import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Booking/chooseBookingFamilyMembersActivity.dart';
import 'package:egpycopsversion4/Booking/courses.dart';
import 'package:egpycopsversion4/Colors/colors.dart';
import 'package:egpycopsversion4/Models/calendarCourses.dart';
import 'package:egpycopsversion4/Translation/localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

BaseUrl BASE_URL = BaseUrl();
String baseUrl = BASE_URL.BASE_URL;

String churchNameAr = "";
String churchNameEn = "";
String month = "", year = "";
String myLanguage = "";
String churchOfAttendanceID = "0";

class CalendarOfBookingsActivity extends StatefulWidget {
  CalendarOfBookingsActivity(
      String churchOfAttendanceIDConstructor,
      String churchNameArConstructor,
      String churchNameEnConstructor) {
    churchOfAttendanceID = churchOfAttendanceIDConstructor;
    churchNameAr = churchNameArConstructor;
    churchNameEn = churchNameEnConstructor;
  }

  @override
  _CalendarOfBookingsActivityState createState() =>
      _CalendarOfBookingsActivityState();
}

class _CalendarOfBookingsActivityState
    extends State<CalendarOfBookingsActivity> {
  late Map<DateTime, List<dynamic>> _events;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final _formKey = GlobalKey<FormState>();
  late SharedPreferences prefs;
  final formatter = DateFormat('yyyy-MM-dd');
  String mobileToken = "";
  int loadingState = 0;
  List<CalendarCourse> coursesList = [];
  String userID = "";
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _events = {};
    loadingState = 0;
    month = _focusedDay.month.toString();
    year = _focusedDay.year.toString();
    getSharedData();
  }

  Future<void> getSharedData() async {
    prefs = await SharedPreferences.getInstance();
    myLanguage = (prefs.getString('language') ?? "en");
    userID = prefs.getString("userID") ?? "";
    mobileToken = (await FirebaseMessaging.instance.getToken()) ?? "";

    coursesList = await getCourseByCalender();
    for (var course in coursesList) {
      for (int j = 0; j < (course.timeCount ?? 0); j++) {
  DateTime formattedDate =
      DateTime.parse("${course.courseDate}T00:00:00.000Z");
  _events.update(formattedDate, (value) => value..add("1"),
      ifAbsent: () => ["1"]);
}

    }

    setState(() {});
  }

  Future<List<CalendarCourse>> getCourseByCalender() async {
    final uri = Uri.parse(
        '$baseUrl/Booking/GetCourseByCalender/?BranchID=$churchOfAttendanceID&Month=$month&Year=$year&UserAccountID=$userID&token=$mobileToken');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      loadingState = 1;
      return calendarCourseFromJson(response.body.toString());
    } else {
      loadingState = 2;
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Text(
            AppLocalizations.of(context)!.chooseHolyLiturgyDate2,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.normal),
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
      return const Center(child: CircularProgressIndicator());
    } else if (loadingState == 1) {
      return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                myLanguage == "en" ? churchNameEn : churchNameAr,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'cocon-next-arabic-regular',
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: (day) => _events[DateTime.utc(day.year, day.month, day.day)] ?? [],
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;

                  final events = _events[DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day)] ?? [];
                  if (events.isNotEmpty) {
                    final formatted = DateFormat('yyyy-MM-dd').format(selectedDay);
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => CoursesActivity(
                                  formatted,
                                  churchOfAttendanceID,
                                  churchNameEn,
                                  churchNameAr,
                                )))
                        .then((value) {
                      if (courseID != "0") {
                        Navigator.of(context).pop();
                      }
                    });
                  } else {
                    Fluttertoast.showToast(
                        msg: AppLocalizations.of(context)!.noSeatsAvailable,
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.white,
                        textColor: Colors.red);
                  }
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration:
                    BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                selectedDecoration:
                    BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                weekendTextStyle: TextStyle(color: Colors.red),
              ),
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                month = focusedDay.month.toString();
                year = focusedDay.year.toString();
                getSharedData();
              },
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.errorConnectingWithServer,
          style: const TextStyle(
              fontSize: 20,
              fontFamily: 'cocon-next-arabic-regular',
              color: Colors.grey),
        ),
      );
    }
  }
}

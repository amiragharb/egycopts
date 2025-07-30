import 'dart:async';
import 'dart:io';
import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Booking/calendarOfBookings.dart';
import 'package:egpycopsversion4/Booking/chooseBookingFamilyMembersActivity.dart' hide baseUrl;
import 'package:egpycopsversion4/Colors/colors.dart';
import 'package:egpycopsversion4/Home/homeActivity.dart' hide baseUrl;
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

class NewBookingActivity extends StatefulWidget {
  const NewBookingActivity({Key? key}) : super(key: key);

  @override
  _NewBookingActivityState createState() => _NewBookingActivityState();
}

class _NewBookingActivityState extends State<NewBookingActivity> {
  // Dropdown Lists
  List<Map<String, dynamic>> listDropChurchOfAttendance = [];
  List<Map<String, dynamic>> listDropGovernorates = [];
  List<Map<String, dynamic>> listDropCourses = [];

  // API & Data
  List<Churchs> churchOfAttendanceList = [];
  List<Governorates> governoratesList = [];
  List<Course> coursesList = [];

  // Variables
  String mobileToken = "";
  String userBranchID = "0";
  String userID = "";
  String userEmail = "";
  String accountType = "0";
  String myLanguage = "en";

  // Booking state
  bool flagAddCourse = true;
  int availableSeatsState = 0;
  int loadingState = 0;
  int dateState = 0;
  bool isDateChosen = false;
  bool isChurchChosen = false;

  // Booking info
  String churchOfAttendanceID = "0";
  String governorateID = "0";
  String courseID = "0";
  String churchNameAr = "";
  String churchNameEn = "";
  String remAttendanceCount = "0";
  String remAttendanceDeaconCount = "0";
  String churchRemarks = "";
  String courseRemarks = "";
  String courseDateAr = "";
  String courseDateEn = "";
  String courseTimeAr = "";
  String courseTimeEn = "";
  String courseTypeName = "";

  int defaultGovernateID = 0;
  int defaultBranchID = 0;
  int attendanceTypeIDNewBooking = 0;
  String attendanceTypeNameArNewBooking = "";
  String attendanceTypeNameEnNewBooking = "";

  @override
  void initState() {
    super.initState();
    resetBookingState();
    _initializeFirebaseToken();
    getSharedData();
  }

  Future<void> _initializeFirebaseToken() async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint("Token: $token");
        setState(() {
          mobileToken = token;
        });
      } else {
        debugPrint("⚠️ Aucun token Firebase reçu");
        setState(() {
          mobileToken = "";
        });
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération du token Firebase: $e");
      setState(() {
        mobileToken = "";
      });
    }
  }

  void resetBookingState() {
    setState(() {
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
    });
  }

  Future<void> getSharedData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      setState(() {
        myLanguage = prefs.getString('language') ?? "en";
        userID = prefs.getString("userID") ?? "";
        userEmail = prefs.getString("userEmail") ?? "";
        accountType = prefs.getString("accountType") ?? "0";
        defaultGovernateID = prefs.getInt("governateID") ?? 0;
        defaultBranchID = prefs.getInt("branchID") ?? 0;
      });

      // Charger les gouvernorats
      final govList = await getGovernoratesByUserID();
      if (govList != null) {
        setState(() {
          governoratesList = govList;
        });
        await governoratesDropDownData();

        // Si un gouvernorat par défaut existe
        if (defaultGovernateID != 0) {
          setState(() {
            governorateID = defaultGovernateID.toString();
            userBranchID = defaultBranchID.toString();
          });

          await _loadChurchesForGovernorate();
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des données partagées: $e");
      setState(() {
        loadingState = 2; // Erreur
      });
    }
  }

  Future<void> _loadChurchesForGovernorate() async {
    try {
      final churches = await getChurchs(governorateID);
      if (churches != null) {
        setState(() {
          churchOfAttendanceList = churches;
        });
        await churchOfAttendanceDropDownData();

        if (churchOfAttendanceID != "0") {
          setState(() {
            courseID = "0";
            availableSeatsState = 0;
            remAttendanceCount = "0";
            remAttendanceDeaconCount = "0";
            dateState = 2;
            isDateChosen = false;
            isChurchChosen = false;
          });
          await getCoursesWithChurchID();
        } else {
          resetChurchState();
          await getChurchWithGovernorateID();
        }
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des églises: $e");
    }
  }

  void resetChurchState() {
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
  }

  Future<List<Governorates>?> getGovernoratesByUserID() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Booking/GetGovernoratesByUserID/?UserAccountID=$userID'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return governoratesFromJson(response.body);
      } else {
        debugPrint("GetGovernoratesByUserID error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Erreur réseau GetGovernoratesByUserID: $e");
      return null;
    }
  }

  Future<void> governoratesDropDownData() async {
    listDropGovernorates.clear();
    listDropGovernorates.add({
      "id": "0",
      "nameAr": "اختار المحافظة",
      "nameEn": "Choose Governorate",
      "isDefault": false,
    });

    for (var gov in governoratesList) {
      listDropGovernorates.add({
        "id": gov.id.toString(),
        "nameAr": gov.nameAr ?? "",
        "nameEn": gov.nameEn ?? "",
        "isDefault": gov.isDefualt ?? false,
      });

      if (gov.isDefualt == true) {
        governorateID = gov.id.toString();
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<Churchs>?> getChurchs(String governorateID) async {
    setState(() => flagAddCourse = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Booking/GetChurch/?GovernerateID=$governorateID'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        setState(() => loadingState = 1);
        return churchsFromJson(response.body);
      } else {
        setState(() => loadingState = 2);
        return null;
      }
    } catch (e) {
      debugPrint("Erreur réseau getChurchs: $e");
      setState(() => loadingState = 2);
      return null;
    }
  }

  Future<void> churchOfAttendanceDropDownData() async {
    listDropChurchOfAttendance.clear();

    if (churchOfAttendanceList.isNotEmpty) {
      setState(() {
        listDropChurchOfAttendance.add({
          "id": "0",
          "nameAr": "اختار الكنيسة",
          "nameEn": "Choose Church",
          "isDefault": false
        });

        for (var church in churchOfAttendanceList) {
          listDropChurchOfAttendance.add({
            "id": church.id.toString(),
            "nameAr": church.nameAr ?? "",
            "nameEn": church.nameEn ?? "",
            "isDefault": church.isDefualt ?? false,
          });
        }
      });
    }
  }

  // Méthodes manquantes à implémenter
  Future<void> getCoursesWithChurchID() async {
    // TODO: Implémenter la logique pour récupérer les cours
    debugPrint("getCoursesWithChurchID appelée pour l'église: $churchOfAttendanceID");
  }

  Future<void> getChurchWithGovernorateID() async {
    // TODO: Implémenter la logique pour récupérer l'église par gouvernorat
    debugPrint("getChurchWithGovernorateID appelée pour le gouvernorat: $governorateID");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.newBooking ?? "New Booking",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryDarkColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: buildChild(context),
      bottomNavigationBar: loadingState == 1 
          ? buildBookButton(context) 
          : const SizedBox.shrink(),
    );
  }

  Widget buildChild(BuildContext context) {
    switch (loadingState) {
      case 0:
        return const Center(
          child: CircularProgressIndicator(),
        );
      case 1:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              showGovernoratesLayout(context),
              const SizedBox(height: 16),
              showChurchOfAttendanceLayout(context),
              const SizedBox(height: 16),
              showCoursesLayout(context),
            ],
          ),
        );
      case 2:
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.errorConnectingWithServer ?? "Error connecting to server",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    loadingState = 0;
                  });
                  getSharedData();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        );
    }
  }

  Widget showGovernoratesLayout(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              localizations?.governorate ?? "Governorate",
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: primaryDarkColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: governorateID,
                  isExpanded: true,
                  items: listDropGovernorates.map((Map<String, dynamic> map) {
                    return DropdownMenuItem<String>(
                      value: map["id"].toString(),
                      child: Text(
                        myLanguage == "en" ? map["nameEn"] : map["nameAr"],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryDarkColor,
                          fontSize: 16.0,
                          fontFamily: 'cocon-next-arabic-regular',
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value == null || value == governorateID) return;
                    
                    setState(() {
                      governorateID = value;
                      resetChurchState();
                    });

                    if (value != "0") {
                      _loadChurchesForGovernorate();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showChurchOfAttendanceLayout(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _getLocalizedText(localizations, 'church', "Church"),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: primaryDarkColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: churchOfAttendanceID,
                  isExpanded: true,
                  items: listDropChurchOfAttendance.map((Map<String, dynamic> map) {
                    return DropdownMenuItem<String>(
                      value: map["id"].toString(),
                      child: Text(
                        myLanguage == "en" ? map["nameEn"] : map["nameAr"],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryDarkColor,
                          fontSize: 16.0,
                          fontFamily: 'cocon-next-arabic-regular',
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value == null || value == churchOfAttendanceID) return;
                    
                    setState(() {
                      churchOfAttendanceID = value;
                      courseID = "0";
                      listDropCourses.clear();
                    });

                    if (value != "0") {
                      getCoursesWithChurchID();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget showCoursesLayout(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _getLocalizedText(localizations, 'courses', "Courses"),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: primaryDarkColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: courseID,
                  isExpanded: true,
                  items: listDropCourses.map((Map<String, dynamic> map) {
                    return DropdownMenuItem<String>(
                      value: map["id"].toString(),
                      child: Text(
                        myLanguage == "en" ? map["nameEn"] : map["nameAr"],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryDarkColor,
                          fontSize: 16.0,
                          fontFamily: 'cocon-next-arabic-regular',
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value == null || value == courseID) return;
                    
                    setState(() {
                      courseID = value;
                    });

                    // TODO: Charger les détails du cours sélectionné
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBookButton(BuildContext context) {
    final int remCount = int.tryParse(remAttendanceCount) ?? 0;
    final int remDeaconCount = int.tryParse(remAttendanceDeaconCount) ?? 0;

    final bool hasSeats = (attendanceTypeIDNewBooking == 3 && remDeaconCount > 0) ||
        (attendanceTypeIDNewBooking != 3 && remCount > 0);

    final Color btnColor = hasSeats ? primaryDarkColor : Colors.grey;
    final bool isEnabled = hasSeats && courseID != "0";

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50.0,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: isEnabled ? 3 : 0,
          ),
          onPressed: isEnabled ? () => _handleBooking() : null,
          child: Text(
            AppLocalizations.of(context)?.book ?? "Book",
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'cocon-next-arabic-regular',
            ),
          ),
        ),
      ),
    );
  }

  void _handleBooking() {
    // TODO: Implémenter la logique de réservation
    debugPrint("Réservation en cours...");
    debugPrint("Gouvernorat: $governorateID");
    debugPrint("Église: $churchOfAttendanceID");
    debugPrint("Cours: $courseID");
    
    // Naviguer vers l'écran de sélection des membres de la famille
    // Navigator.push(context, MaterialPageRoute(...));
  }

  // Méthode utilitaire pour gérer les traductions manquantes
  String _getLocalizedText(AppLocalizations? localizations, String key, String fallback) {
    if (localizations == null) return fallback;
    
    try {
      // Tentative d'accès à la propriété via reflection ou getter existant
      switch (key) {
        case 'courses':
          // Remplacez par le nom correct du getter si il existe
          // return localizations.coursesText ?? fallback;
          return fallback; // Utilisez le fallback en attendant
        case 'church':
          // Remplacez par le nom correct du getter si il existe
          // return localizations.churchText ?? fallback;
          return fallback; // Utilisez le fallback en attendant
        default:
          return fallback;
      }
    } catch (e) {
      debugPrint("Erreur de localisation pour '$key': $e");
      return fallback;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
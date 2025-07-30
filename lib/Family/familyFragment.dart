import 'dart:async';
import 'dart:convert';

import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Models/familyMember.dart';
import 'package:egpycopsversion4/NetworkConnectivity/noNetworkConnectionActivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:skeleton_text/skeleton_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Ajout du package Connectivity

typedef void LocaleChangeCallback(Locale locale);

BaseUrl BASE_URL = BaseUrl();
String baseUrl = BASE_URL.BASE_URL;

late String myLanguage;

class FamilyFragment extends StatefulWidget {
  const FamilyFragment({Key? key}) : super(key: key);

  @override
  _FamilyFragmentState createState() => _FamilyFragmentState();
}

class _FamilyFragmentState extends State<FamilyFragment> {
  List<FamilyMember> myFamilyList = [];
  List<Map> listViewMyFamily = [];
  final ScrollController _scrollController = ScrollController();
  int loadingState = 0;
  int pageNumber = 0;
  late String userID;
  String? mobileToken;

  late BuildContext mContext;

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.instance.getToken().then((String? token) {
      if (token != null) {
        debugPrint("Token: $token");
        mobileToken = token;
      }
    });

    pageNumber = 0;
    loadingState = 0;
    getDataFromShared();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        //getDataFromShared(); // Envisager le chargement infini ici
      }
    });
  }

  Future<String> _checkInternetConnection() async {
    var result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.none ? "0" : "1";
  }

  Future<void> getDataFromShared() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    myLanguage = prefs.getString('language') ?? "en";
    userID = prefs.getString("userID") ?? "";

    setState(() {
      loadingState = 0;
      pageNumber = 0;
    });

    String connectionResponse = await _checkInternetConnection();
    debugPrint("connectionResponse: $connectionResponse");

    if (connectionResponse == '1') {
      myFamilyList = await getMyFamily();
      if (loadingState == 1 && myFamilyList.isNotEmpty) {
        myFamilyListViewData();
      }
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (BuildContext context) => NoInternetConnectionActivity()))
          .then((value) async {
        myFamilyList = await getMyFamily();
        if (loadingState == 1 && myFamilyList.isNotEmpty) {
          myFamilyListViewData();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<FamilyMember>> getMyFamily() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    userID = prefs.getString("userID") ?? "";
    mobileToken = await FirebaseMessaging.instance.getToken();

    try {
      var response = await http.get(Uri.parse('$baseUrl/Family/GetFamilyMembers/?UserID=$userID&Token=$mobileToken'));
      debugPrint("Response: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty && listViewMyFamily.isEmpty) {
          setState(() {
            loadingState = 3;
          });
          return [];  // Retourne une liste vide si la réponse est vide
        } else {
          setState(() {
            loadingState = 1;
          });
          var myFamilyMembersObj = familyMemberFromJson(response.body);
          return myFamilyMembersObj;  // Retourne les données transformées en liste
        }
      } else {
        setState(() {
          loadingState = 2;
        });
        debugPrint("Error getting family data");
        return [];  // Retourne une liste vide si le code de statut n'est pas 200
      }
    } catch (e) {
      setState(() {
        loadingState = 2;
      });
      debugPrint("Exception occurred: $e");
      return [];  // En cas d'exception (erreur réseau par exemple), retourne une liste vide
    }
  }

  void myFamilyListViewData() {
    setState(() {
      listViewMyFamily.clear();
      for (var member in myFamilyList) {
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
          "address": member.address,
          "personRelationNameAr": member.personRelationNameAr,
          "personRelationNameEn": member.personRelationNameEn,
          "isMainPerson": member.isMainPerson,
          "branchID": member.branchID,
          "governorateID": member.governorateID,
          "churchOfAttendance": member.churchOfAttendance,
        });
      }
    });
  }

  // Ajout de la méthode `build` ici pour résoudre l'erreur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
      ),
      body: buildChild(), // Affiche l'interface selon l'état de `loadingState`
    );
  }

  Widget buildChild() {
    switch (loadingState) {
      case 0:
        return buildLoadingState();
      case 1:
        return buildDataState();
      case 2:
        return buildErrorState();
      case 3:
        return buildNoDataState();
      default:
        return buildLoadingState();
    }
  }

  Widget buildLoadingState() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Loading Family Members...', style: TextStyle(fontSize: 24)),
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget buildDataState() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: listViewMyFamily.length,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () {
            // Handle navigation or action on tapping the family member
          },
          child: Card(
            child: ListTile(
              title: Text(listViewMyFamily[index]['accountMemberNameAr']),
              subtitle: Text(listViewMyFamily[index]['personRelationNameEn']),
              trailing: deleteIcon(listViewMyFamily[index]['isMainPerson'], index, listViewMyFamily[index]['userAccountMemberId']),
            ),
          ),
        );
      },
    );
  }

  Widget buildErrorState() {
    return Center(
      child: const Text("Error connecting with the server"),
    );
  }

  Widget buildNoDataState() {
    return Center(
      child: const Text("No family members found"),
    );
  }

  Future<String> deleteFamilyMember(String memberID) async {
    debugPrint("Deleting member: $memberID");
    var response = await http.post(Uri.parse('$baseUrl/Family/DeleteFamilyMember/?UserAccountID=$userID&AccountMemberID=$memberID&Token=$mobileToken'));
    debugPrint("Response: ${response.body}");

    if (response.statusCode == 200 && response.body == "1") {
      return "1"; // Successful deletion
    }
    return response.body; // Return error message
  }

  Widget deleteIcon(bool isMainPerson, int index, String memberID) {
    if (isMainPerson) {
      return Container();  // Ne pas afficher l'icône de suppression pour le membre principal
    } else {
      return InkWell(
        onTap: () async {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text('Do you want to delete this member?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    String connectionResponse = await _checkInternetConnection();
                    if (connectionResponse == '1') {
                      Navigator.pop(context);

                      String response = await deleteFamilyMember(memberID);
                      if (response == "1") {
                        setState(() {
                          listViewMyFamily.removeAt(index);
                        });
                        Fluttertoast.showToast(msg: "Deleted successfully!");
                      } else {
                        Fluttertoast.showToast(msg: "Error deleting member.");
                      }
                    }
                  },
                  child: const Text("Yes"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("No"),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.delete, color: Colors.red),
      );
    }
  }
}

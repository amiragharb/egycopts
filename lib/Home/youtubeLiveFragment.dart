import 'dart:async';
import 'package:egpycopsversion4/API/apiClient.dart';
import 'package:egpycopsversion4/Colors/colors.dart';
import 'package:egpycopsversion4/Home/youtubeLiveVideo.dart';
import 'package:egpycopsversion4/Home/youtubeLiveVideoDetailsActivity.dart';
import 'package:egpycopsversion4/Models/liveVideos.dart';
import 'package:egpycopsversion4/NetworkConnectivity/noNetworkConnectionActivity.dart';
import 'package:egpycopsversion4/Translation/localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:skeleton_text/skeleton_text.dart';

BaseUrl BASE_URL = BaseUrl();
String baseUrl = BASE_URL.BASE_URL;

class YoutubeLiveFragment extends StatefulWidget {
  const YoutubeLiveFragment({Key? key}) : super(key: key);

  @override
  State<YoutubeLiveFragment> createState() => _YoutubeLiveFragmentState();
}

class _YoutubeLiveFragmentState extends State<YoutubeLiveFragment> {
  String myLanguage = "en";
  int loadingState = 0; // 0=loading, 1=loaded, 2=error, 3=empty
  bool stopLoadingData = false;
  bool isFetching = false;
  int page = 0;

  String userID = "";
  String? mobileToken;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> listViewLiveVideos = [];

  @override
  void initState() {
    super.initState();
    listViewLiveVideos.clear();
    _fetchMobileToken();
    _getDataFromShared();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !stopLoadingData &&
        !isFetching &&
        loadingState == 1) {
      _getDataFromShared();
    }
  }

  Future<void> _fetchMobileToken() async {
    mobileToken = await FirebaseMessaging.instance.getToken();
    debugPrint(mobileToken == null || mobileToken!.isEmpty
        ? "⚠️ mobileToken non récupéré"
        : "📱 Token: $mobileToken");
  }

  Future<String> _checkInternetConnection() async {
    var result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.none ? "0" : "1";
  }

  Future<void> _getDataFromShared() async {
    if (isFetching) return;
    isFetching = true;

    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        myLanguage = prefs.getString('language') ?? "en";
        userID = prefs.getString("userID") ?? "";
      });
    }

    final fetched = await _getLiveVideos();
    if (mounted && loadingState == 1 && fetched.isNotEmpty) {
      _liveVideosListViewData(fetched);
      page++;
    }

    isFetching = false;
  }

  Future<List<LiveVideos>> _getLiveVideos() async {
    final uri = Uri.parse(
        '$baseUrl/Booking/GetLiveCourses/?UserAccountID=$userID&Token=${mobileToken ?? ""}&page=$page');
    final response = await http.get(uri);

    if (!mounted) return [];

    if (response.statusCode == 200) {
      if (response.body == "[]" || response.body.isEmpty) {
        setState(() {
          stopLoadingData = true;
          if (page == 0) loadingState = 3;
        });
        return [];
      } else {
        setState(() {
          stopLoadingData = false;
          loadingState = 1;
        });
        return liveVideosFromJson(response.body);
      }
    } else {
      setState(() {
        loadingState = 2;
        stopLoadingData = true;
      });
      return [];
    }
  }

  void _liveVideosListViewData(List<LiveVideos> fetched) {
    if (!mounted) return;
    setState(() {
      for (final video in fetched) {
        if (RegExp(r'youtu(\.be|be\.com)', caseSensitive: false).hasMatch(video.liveUrl ?? '')) {
          // 🔹 Conversion de isLive en String "1" ou "0"
          String isLive = "0";
          final rawIsLive = video.isLive;

          if (rawIsLive is bool) {
            isLive = rawIsLive != null ? "1" : "0";
          } else if (rawIsLive != null) {
            final s = rawIsLive.toString().toLowerCase();
            isLive = (s == 'true' || s == '1') ? "1" : "0";
          }

          if (!listViewLiveVideos.any((e) => e["courseId"] == video.courseId)) {
            listViewLiveVideos.add({
              "courseId": video.courseId,
              "nameAr": video.nameAr,
              "nameEn": video.nameEn,
              "liveDescriptionAr": video.liveDescriptionAr,
              "liveDescriptionEn": video.liveDescriptionEn,
              "liveUrl": video.liveUrl,
              "isLive": isLive, // ✅ String "1" ou "0"
              "date": video.date ?? "",
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      color: grey200,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              localizations?.live ?? "Live",
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'cocon-next-arabic-regular',
                fontWeight: FontWeight.normal,
                color: primaryDarkColor,
              ),
              maxLines: 1,
            ),
          ),
          Expanded(child: _buildListViewChild(localizations)),
        ],
      ),
    );
  }

  Widget _buildListViewChild(AppLocalizations? localizations) {
    if (loadingState == 0) {
      return ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => _buildSkeletonItem(context),
      );
    } else if (loadingState == 1) {
      return ListView.builder(
        controller: _scrollController,
        itemCount: listViewLiveVideos.length,
        itemBuilder: (context, index) {
          final video = listViewLiveVideos[index];

          final liveUrl = video["liveUrl"] as String? ?? "";
          final isLive = video["isLive"] as String? ?? "0"; // ✅ String
          final desc = myLanguage == "en"
              ? (video["liveDescriptionEn"] as String? ?? "")
              : (video["liveDescriptionAr"] as String? ?? "");
          final name = myLanguage == "en"
              ? (video["nameEn"] as String? ?? "")
              : (video["nameAr"] as String? ?? "");
          final date = video["date"] as String? ?? "";

          return GestureDetector(
            onTap: () async {
              if (await _checkInternetConnection() == '1') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => YoutubeLiveVideoDetailsActivity(video["courseId"]),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => NoInternetConnectionActivity()),
                );
              }
            },
            child: Card(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      YoutubeLiveVideo(liveUrl, isLive, false), // ✅ String pour live
                      Container(width: double.infinity, height: 200),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    child: Text(
                      desc,
                      style: TextStyle(
                        color: logoBlue,
                        fontSize: 20.0,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'cocon-next-arabic-regular',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'cocon-next-arabic-regular',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  if (date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 8),
                      child: Text(
                        date,
                        style: TextStyle(
                          color: grey500,
                          fontSize: 14.0,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'cocon-next-arabic-regular',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } else if (loadingState == 2) {
      return Center(
        child: Text(
          localizations?.errorConnectingWithServer ?? "Server error",
          style: const TextStyle(
            fontFamily: 'cocon-next-arabic-regular',
            fontSize: 20.0,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'images/live.png',
                color: Colors.grey,
                width: 60,
                height: 60,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                localizations?.noVideosFound ?? "No videos found",
                style: const TextStyle(
                  fontFamily: 'cocon-next-arabic-regular',
                  fontSize: 20.0,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSkeletonItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonAnimation(
              child: Container(
                height: 150,
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.grey[300],
                ),
              ),
            ),
            const SizedBox(height: 5),
            SkeletonAnimation(
              child: Container(
                height: 15,
                width: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.grey[300],
                ),
              ),
            ),
            const SizedBox(height: 5),
            SkeletonAnimation(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 13,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

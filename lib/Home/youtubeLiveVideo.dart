import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeLiveVideo extends StatefulWidget {
  final String url;     // Full YouTube URL
  final String isLive; // ✅ String
  final bool autoPlay;

  const YoutubeLiveVideo(
    this.url,
    this.isLive,
    this.autoPlay, {
    Key? key,
  }) : super(key: key);

  @override
  _YoutubeLiveVideoState createState() => _YoutubeLiveVideoState();
}

class _YoutubeLiveVideoState extends State<YoutubeLiveVideo> {
  YoutubePlayerController? _youtubePlayerController;

  @override
  void initState() {
    super.initState();

    // Convert YouTube URL to video ID
    final String? videoId = YoutubePlayer.convertUrlToId(widget.url);

    if (videoId != null) {
      _youtubePlayerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
  isLive: widget.isLive == '1' || widget.isLive.toLowerCase() == 'true',
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _youtubePlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_youtubePlayerController == null) {
      // Fallback widget if URL is invalid
      return Container(
        height: 200,
        color: Colors.black12,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }

    return YoutubePlayer(
      controller: _youtubePlayerController!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.redAccent,
      onReady: () {
        debugPrint("🎥 YouTube Player Ready for ${widget.url}");
      },
    );
  }
}

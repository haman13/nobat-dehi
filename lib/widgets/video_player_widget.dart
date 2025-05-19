// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// class VideoPlayerWidget extends StatefulWidget {
//   final String videoPath;
//   final double? width;
//   final double? height;

//   const VideoPlayerWidget({
//     Key? key,
//     required this.videoPath,
//     this.width,
//     this.height,
//   }) : super(key: key);

//   @override
//   State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
// }

// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   late VideoPlayerController _controller;
//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.asset(widget.videoPath)
//       ..initialize().then((_) {
//         setState(() {
//           _isInitialized = true;
//         });
//         _controller.setLooping(true);
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return AspectRatio(
//       aspectRatio: _controller.value.aspectRatio,
//       child: SizedBox(
//         width: widget.width,
//         height: widget.height,
//         child: VideoPlayer(_controller),
//       ),
//     );
//   }
// } 
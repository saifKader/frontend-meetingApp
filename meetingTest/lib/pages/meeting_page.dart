import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc_wrapper/flutter_webrtc_wrapper.dart';
import 'package:meetingtest/pages/home_screen.dart';
import 'package:meetingtest/utils/user.utils.dart';
import 'package:meetingtest/widgets/remote_connection.dart';

import '../models/meeting_details.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../widgets/control_panel.dart';

class MeetingPage extends StatefulWidget {
  final String? meetingId;
  final String? name;
  final MeetingDetail meetingDetail;

  const MeetingPage(
      {Key? key, this.meetingId, this.name, required this.meetingDetail})
      : super(key: key);

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  final _localRenderer = RTCVideoRenderer();
  final Map<String, dynamic> mediaConstraints = {'audio': true, 'video': true};
  bool isConnectionFailed = false;
  WebRTCMeetingHelper? meetingHelper;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black87,
        body: _buildMeetingRoom(),
        bottomNavigationBar: ControlPanel(
          onAudioToggle: onAudioToggle,
          onVideoToggle: onVideoToggle,
          videoEnabled: isVideoEnabled(),
          audioEnabled: isAudioEnabled(),
          isConnectionFailed: isConnectionFailed,
          onReconnect: handleReconnect,
          onMeetingEnd: onMeetingEnd,
            onHandToggle: onHandToggle,
          handEnabled: isHandEnabled(),
        ));
  }

  void startMeeting() async {
    final String userId = await loadUserId();
    meetingHelper = WebRTCMeetingHelper(
      url: 'http://192.168.0.13:3003',
      meetingId: widget.meetingDetail.id,
      userId: userId,
      name: widget.name,
    );
    MediaStream _localStream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = _localStream;
    meetingHelper!.stream = _localStream;
    meetingHelper!.on(
      'open',
      context,
      (ev, context) {
        setState(() {
        });
      },
    );
    meetingHelper!.on(
      'connection',
      context,
      (ev, context) {
        setState(() {
        });
      },
    );
    meetingHelper!.on(
      'user-left',
      context,
          (ev, context) {
        setState(() {
          print('user-left');
          onMeetingEnd();
        });
      },
    );
    meetingHelper!.on(
      'video-toggle',
      context,
      (ev, context) {
        setState(() {});
      },
    );
    meetingHelper!.on(
      'audio-toggle',
      context,
      (ev, context) {
        setState(() {});
      },
    );
    meetingHelper!.on(
      'hand-toggle',
      context,
        (ev, context) {
      setState(() {
        print('hand-toggle');
        onHandToggle();
      });
        }
    );
    meetingHelper!.on(
      'meeting-ended',
      context,
      (ev, context) {
        setState(() {
          print('meeting-ended');
          onMeetingEnd();
        });
      },
    );
    meetingHelper!.on(
      'connection-setting-changed',
      context,
      (ev, context) {
        setState(() {
        });
      },
    );
    meetingHelper!.on(
      'stream-changed',
      context,
      (ev, context) {
        setState(() {
        });
      },
    );
    setState(() {});
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  @override
  void initState() {
    super.initState();
    initRenderers();
    startMeeting();
  }

  @override
  void deactivate() {
    super.deactivate();
    _localRenderer.dispose();
    if (meetingHelper != null) {
      meetingHelper!.destroy();
      meetingHelper = null;
    }
  }

  /*void onMeetingEnd() {
    if (meetingHelper != null) {
      bool isHost = widget.meetingDetail.hostId == meetingHelper!.userId;
      if (isHost) {
        // End the meeting for all participants
        meetingHelper!.endMeeting();
        meetingHelper = null;
        goToHomePage();
      } else {
        // End the meeting only for the participant who left
        meetingHelper!.leave();
        meetingHelper = null;
        goToHomePage();
        Navigator.pop(context);
      }
    }
  }*/
  void onMeetingEnd() {
    if (meetingHelper != null) {
      meetingHelper!.endMeeting();
      meetingHelper = null;
      goToHomePage();
    }
  }
  void onHandToggle() {
    if (meetingHelper != null) {
      setState(() {
        meetingHelper!.toggleHand();
      });
    }
  }


  _buildMeetingRoom() {
    return Stack(
      children: [
        meetingHelper != null && meetingHelper!.connections.isNotEmpty ?
            GridView.count(
              crossAxisCount: meetingHelper!. connections.length < 3 ? 1 : 2,
              children: List.generate(meetingHelper!.connections.length, (index) {
                return Padding(padding: const EdgeInsets.all(1),
                  child: RemoteConnection(
                    renderer: meetingHelper!.connections[index].renderer,
                    connection: meetingHelper!.connections[index],
                  ) ,
                );
              }),
            ):const Center(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Waiting for other participants to join',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 24
              ),
            ),
          ),
        ),
        Positioned(bottom: 10, right: 0, child: SizedBox(
          width: 150,
          height: 200,
          child: RTCVideoView(_localRenderer),
        ))
      ],
    );
  }

  void onAudioToggle() {
    if (meetingHelper != null) {
      setState(() {
        meetingHelper!.toggleAudio();
      });
    }
  }

  void onVideoToggle() {
    if (meetingHelper != null) {
      setState(() {
        meetingHelper!.toggleVideo();
      });
    }
  }

  void handleReconnect() {
    if (meetingHelper != null) {
      meetingHelper!.reconnect();
    }
  }

  bool isAudioEnabled() {
    return meetingHelper != null ? meetingHelper!.audioEnabled! : false;
  }

  bool isVideoEnabled() {
    return meetingHelper != null ? meetingHelper!.videoEnabled! : false;
  }
  bool isHandEnabled() {
    return meetingHelper != null ? meetingHelper!.handEnabled! : false;
  }

  void goToHomePage() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const HomeScreen()));
  }
}

import 'dart:async';

/// Level 3 — WebRTC Service
///
/// DEMO MODE: Simulates WebRTC call states and signaling flow.
/// PRODUCTION: Use 'flutter_webrtc' package.
///
/// ```dart
/// import 'package:flutter_webrtc/flutter_webrtc.dart';
///
/// class WebRTCService {
///   RTCPeerConnection? _peerConnection;
///   MediaStream? _localStream;
///
///   // Step 1: Get camera + microphone
///   Future<MediaStream> getUserMedia() async {
///     return await navigator.mediaDevices.getUserMedia({
///       'audio': true,
///       'video': {'facingMode': 'user'},
///     });
///   }
///
///   // Step 2: Create peer connection with STUN server
///   Future<void> createPeerConnection() async {
///     _peerConnection = await createPeerConnection({
///       'iceServers': [
///         {'urls': 'stun:stun.l.google.com:19302'}, // Google's free STUN
///       ]
///     });
///   }
///
///   // Step 3: Create offer (caller side)
///   Future<String> createOffer() async {
///     final offer = await _peerConnection!.createOffer();
///     await _peerConnection!.setLocalDescription(offer);
///     return offer.sdp!;  // Send this via Firestore (signaling)
///   }
///
///   // Step 4: Handle answer (caller side)
///   Future<void> handleAnswer(String sdp) async {
///     await _peerConnection!.setRemoteDescription(
///       RTCSessionDescription(sdp, 'answer'));
///   }
///
///   // Step 5: Add ICE candidates
///   Future<void> addIceCandidate(RTCIceCandidate candidate) async {
///     await _peerConnection!.addCandidate(candidate);
///   }
///
///   // Hang up
///   Future<void> hangUp() async {
///     _localStream?.getTracks().forEach((t) => t.stop());
///     await _peerConnection?.close();
///   }
/// }
/// ```

enum CallState { idle, ringing, connecting, connected, ended }

class CallInfo {
  final String callerId;
  final String callerName;
  final String calleeId;
  final bool isVideo;
  final CallState state;
  final Duration? duration;

  const CallInfo({
    required this.callerId,
    required this.callerName,
    required this.calleeId,
    required this.isVideo,
    required this.state,
    this.duration,
  });

  CallInfo copyWith({CallState? state, Duration? duration}) {
    return CallInfo(
      callerId: callerId,
      callerName: callerName,
      calleeId: calleeId,
      isVideo: isVideo,
      state: state ?? this.state,
      duration: duration ?? this.duration,
    );
  }
}

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._();
  factory WebRTCService() => _instance;
  WebRTCService._();

  final _callStateController = StreamController<CallInfo?>.broadcast();
  CallInfo? _currentCall;
  Timer? _durationTimer;
  Duration _callDuration = Duration.zero;

  Stream<CallInfo?> get callStream => _callStateController.stream;
  CallInfo? get currentCall => _currentCall;

  /// Initiate a call.
  /// Production: createOffer() → send SDP via Firestore signaling
  Future<void> startCall({
    required String callerId,
    required String callerName,
    required String calleeId,
    bool isVideo = false,
  }) async {
    _currentCall = CallInfo(
      callerId: callerId,
      callerName: callerName,
      calleeId: calleeId,
      isVideo: isVideo,
      state: CallState.ringing,
    );
    _callStateController.add(_currentCall);

    // Simulate connection delay (SDP exchange + ICE candidates)
    await Future.delayed(const Duration(seconds: 2));
    if (_currentCall == null) return;

    _currentCall = _currentCall!.copyWith(state: CallState.connecting);
    _callStateController.add(_currentCall);

    await Future.delayed(const Duration(seconds: 1));
    if (_currentCall == null) return;

    _currentCall = _currentCall!.copyWith(state: CallState.connected);
    _callStateController.add(_currentCall);

    // Start duration timer
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      if (_currentCall != null) {
        _currentCall = _currentCall!.copyWith(duration: _callDuration);
        _callStateController.add(_currentCall);
      }
    });
  }

  /// End the call.
  /// Production: hangUp() → close RTCPeerConnection + stop MediaStream
  void endCall() {
    _durationTimer?.cancel();
    if (_currentCall != null) {
      _currentCall = _currentCall!.copyWith(state: CallState.ended);
      _callStateController.add(_currentCall);
    }
    Future.delayed(const Duration(seconds: 1), () {
      _currentCall = null;
      _callStateController.add(null);
    });
  }

  void dispose() {
    _durationTimer?.cancel();
    _callStateController.close();
  }
}

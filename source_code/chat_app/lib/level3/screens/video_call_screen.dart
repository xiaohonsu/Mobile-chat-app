import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String callerName;
  final bool isVideo;

  const VideoCallScreen({
    super.key,
    required this.callerName,
    this.isVideo = true,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _micMuted = false;
  bool _videoOff = false;
  bool _speakerOn = true;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<CallInfo?>(
        stream: WebRTCService().callStream,
        builder: (context, snapshot) {
          final call = snapshot.data ?? WebRTCService().currentCall;

          return Stack(
            children: [
              // Remote video (simulated)
              Positioned.fill(
                child: call?.state == CallState.connected
                    ? Container(
                        color: Colors.grey[900],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppTheme.level3Color,
                              child: Text(
                                widget.callerName.isNotEmpty
                                    ? widget.callerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 48, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.callerName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        color: Colors.grey[850],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                  color: Colors.white),
                              const SizedBox(height: 16),
                              Text(
                                _getStateText(call?.state),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              // Local video (picture-in-picture)
              if (widget.isVideo && call?.state == CallState.connected)
                Positioned(
                  top: 48,
                  right: 16,
                  child: Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _videoOff
                          ? Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.videocam_off,
                                  color: Colors.white54),
                            )
                          : Container(
                              color: Colors.teal[900],
                              child: const Center(
                                child: Text('You',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ),
                            ),
                    ),
                  ),
                ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // E2EE indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text('End-to-End Encrypted',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.green)),
                            ],
                          ),
                        ),
                        // Duration
                        if (call?.state == CallState.connected &&
                            call?.duration != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatDuration(call!.duration!),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // WebRTC concept overlay
              Positioned(
                top: 90,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WebRTC Flow:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      _buildStep(
                          '1', 'getUserMedia()', call?.state != CallState.idle),
                      _buildStep('2', 'createOffer() → Firestore',
                          call?.state == CallState.connecting ||
                              call?.state == CallState.connected),
                      _buildStep('3', 'ICE Candidates exchange',
                          call?.state == CallState.connecting ||
                              call?.state == CallState.connected),
                      _buildStep(
                          '4', 'P2P stream ✓', call?.state == CallState.connected),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CallButton(
                          icon: _micMuted ? Icons.mic_off : Icons.mic,
                          label: _micMuted ? 'Unmute' : 'Mute',
                          onTap: () =>
                              setState(() => _micMuted = !_micMuted),
                        ),
                        if (widget.isVideo)
                          _CallButton(
                            icon: _videoOff
                                ? Icons.videocam_off
                                : Icons.videocam,
                            label: _videoOff ? 'Start Cam' : 'Stop Cam',
                            onTap: () =>
                                setState(() => _videoOff = !_videoOff),
                          ),
                        _CallButton(
                          icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                          label: _speakerOn ? 'Speaker' : 'Earpiece',
                          onTap: () =>
                              setState(() => _speakerOn = !_speakerOn),
                        ),
                        // End call button
                        GestureDetector(
                          onTap: () {
                            WebRTCService().endCall();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_end,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep(String num, String text, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 7,
            backgroundColor:
                active ? Colors.green : Colors.grey.withOpacity(0.5),
            child: Text(num,
                style: const TextStyle(fontSize: 8, color: Colors.white)),
          ),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 10,
                  color: active ? Colors.greenAccent : Colors.white38)),
        ],
      ),
    );
  }

  String _getStateText(CallState? state) {
    switch (state) {
      case CallState.ringing:
        return 'Calling...';
      case CallState.connecting:
        return 'Connecting (SDP exchange)...';
      case CallState.connected:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
      default:
        return 'Initializing...';
    }
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

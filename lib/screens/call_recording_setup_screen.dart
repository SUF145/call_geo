import 'package:flutter/material.dart';
import '../services/call_recording_service.dart';

class CallRecordingSetupScreen extends StatefulWidget {
  const CallRecordingSetupScreen({super.key});

  @override
  State<CallRecordingSetupScreen> createState() => CallRecordingSetupScreenState();
}

class CallRecordingSetupScreenState extends State<CallRecordingSetupScreen> {
  final CallRecordingService _callRecordingService = CallRecordingService();
  bool _isRecordingEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _isRecordingEnabled = _callRecordingService.isCallRecordingEnabled();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Recording Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Call Recording Setup',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Enable Call Recording',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When enabled, all incoming and outgoing calls will be automatically recorded.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Switch(
                      value: _isRecordingEnabled,
                      onChanged: (value) async {
                        if (value) {
                          await _callRecordingService.enableCallRecording();
                        } else {
                          await _callRecordingService.disableCallRecording();
                        }
                        setState(() {
                          _isRecordingEnabled = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    Text(
                      _isRecordingEnabled ? 'Recording Enabled' : 'Recording Disabled',
                      style: TextStyle(
                        color: _isRecordingEnabled ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'How It Works',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.call_received, color: Colors.blue),
                      title: Text('Incoming Calls'),
                      subtitle: Text('Recording starts when you answer a call'),
                    ),
                    ListTile(
                      leading: Icon(Icons.call_made, color: Colors.green),
                      title: Text('Outgoing Calls'),
                      subtitle: Text('Recording starts when the call connects'),
                    ),
                    ListTile(
                      leading: Icon(Icons.save, color: Colors.orange),
                      title: Text('Recordings'),
                      subtitle: Text('Saved automatically when the call ends'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Note: This is a demo app. In a real app, recording phone calls without consent may be illegal in some jurisdictions. Please check your local laws before using this feature.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

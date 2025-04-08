import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/call_recording_service.dart';
import 'call_recording_setup_screen.dart';

class CallRecordingScreen extends StatefulWidget {
  const CallRecordingScreen({super.key});

  @override
  State<CallRecordingScreen> createState() => CallRecordingScreenState();
}

class CallRecordingScreenState extends State<CallRecordingScreen> {
  final CallRecordingService _callRecordingService = CallRecordingService();
  
  bool _hasPermissions = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    // Check for microphone permission (simplified for demo)
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    PermissionStatus storageStatus = await Permission.storage.status;
    
    bool hasPermissions = microphoneStatus.isGranted && storageStatus.isGranted;
    
    setState(() {
      _hasPermissions = hasPermissions;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Recording'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _hasPermissions
                  ? _buildRecordingControls()
                  : _buildPermissionsRequest(),
            ),
    );
  }
  
  Widget _buildPermissionsRequest() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mic_off,
          size: 80,
          color: Colors.red,
        ),
        const SizedBox(height: 24),
        const Text(
          'Permissions Required',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'To use call recording, you need to grant the following permissions:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        _buildPermissionItem(
          'Microphone',
          'To record audio during calls',
          Icons.mic,
          Permission.microphone,
        ),
        const SizedBox(height: 12),
        _buildPermissionItem(
          'Storage',
          'To save recorded calls',
          Icons.storage,
          Permission.storage,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () async {
            await Permission.microphone.request();
            await Permission.storage.request();
            await _checkPermissions();
            
            if (_hasPermissions && mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CallRecordingSetupScreen(),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Grant Permissions',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPermissionItem(
    String title,
    String description,
    IconData icon,
    Permission permission,
  ) {
    return FutureBuilder<PermissionStatus>(
      future: permission.status,
      builder: (context, snapshot) {
        bool isGranted = snapshot.data == PermissionStatus.granted;
        
        return ListTile(
          leading: Icon(
            icon,
            color: isGranted ? Colors.green : Colors.grey,
          ),
          title: Text(title),
          subtitle: Text(description),
          trailing: Icon(
            isGranted ? Icons.check_circle : Icons.arrow_forward_ios,
            color: isGranted ? Colors.green : Colors.grey,
          ),
          onTap: isGranted
              ? null
              : () async {
                  await permission.request();
                  await _checkPermissions();
                },
        );
      },
    );
  }
  
  Widget _buildRecordingControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.call,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Call Recording',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'All permissions granted. You can now start recording your calls.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CallRecordingSetupScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
          ),
          child: const Text(
            'Continue to Setup',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        // Demo buttons for testing
        const Text(
          'Demo Controls',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _callRecordingService.simulateCallStarted();
              },
              icon: const Icon(Icons.call_received),
              label: const Text('Simulate Call Start'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _callRecordingService.simulateCallEnded();
              },
              icon: const Icon(Icons.call_end),
              label: const Text('Simulate Call End'),
            ),
          ],
        ),
      ],
    );
  }
}

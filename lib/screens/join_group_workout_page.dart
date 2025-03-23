import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart' as qr_scanner;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import '../models/models.dart';
import '../providers/workout_provider.dart';

// This page allows the user to join workout using an invite code or QR code
class JoinWorkoutPage extends StatefulWidget {
  const JoinWorkoutPage({Key? key}) : super(key: key);

  @override
  _JoinWorkoutPageState createState() => _JoinWorkoutPageState();
}

class _JoinWorkoutPageState extends State<JoinWorkoutPage> {
  final TextEditingController _codeController = TextEditingController(); //for manually entering code
  String? _errorMessage; //to display error messages
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR'); //key for the qr scanner widget
  qr_scanner.QRViewController? _qrController; //controller for the qr scanner
  final ImagePicker _imagePicker = ImagePicker(); //for picking an image from gallery or phone storage
  final mlkit.BarcodeScanner _barcodeScanner = mlkit.BarcodeScanner(); //ML kit for scanning image containing qr code

  //function to join workout using the invite code
  void _joinWorkout(String inviteCode) async {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    inviteCode = inviteCode.trim(); //remove any extra spaces

    if (inviteCode.isEmpty) {
      setState(() => _errorMessage = "Please enter or scan an invite code.");
      return;
    }

    bool success = await workoutProvider.joinGroupWorkout(inviteCode); //try to join workout

    if (success) {
      //if joining successful, get the workout details
      WorkoutPlan? workoutPlan = await workoutProvider.getWorkoutByInviteCode(inviteCode);
      if (workoutPlan != null) {
        //navigate to the workout recording page
        context.go(
          '/workoutRecording',
          extra: {'workoutPlan': workoutPlan, 'inviteCode': inviteCode},
        );
      }
    } else {
      setState(() => _errorMessage = "Invalid invite code. Please try again.");
    }
  }

  //function that listens for QR codes scanned by camera
  void _onQRViewCreated(qr_scanner.QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      _qrController?.pauseCamera(); //pause camera after scanning
      _codeController.text = scanData.code ?? '';
      _joinWorkout(_codeController.text);
    });
  }

  //function to pick an image and scan for QR code
  Future<void> _pickImageAndScanQR() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return; //if no image is selected do nothing

      final File imageFile = File(pickedFile.path);
      final mlkit.InputImage inputImage = mlkit.InputImage.fromFile(imageFile);

      final List<mlkit.Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        for (mlkit.Barcode barcode in barcodes) {
          final String? qrCodeValue = barcode.rawValue;
          if (qrCodeValue != null && qrCodeValue.isNotEmpty) {
            _codeController.text = qrCodeValue; //set scanned qr value to text field
            _joinWorkout(qrCodeValue);
            return;
          }
        }
      }

      //show error if no QR code is found in image
      setState(() => _errorMessage = "No valid QR code found in the image.");
    } catch (e) {
      setState(() => _errorMessage = "Error processing image: ${e.toString()}");
    }
  }

  //cleanup resources when the pages is closed
  @override
  void dispose() {
    _qrController?.dispose();
    _codeController.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Workout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Enter Invite Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _joinWorkout(_codeController.text),
              child: const Text("Join Workout"),
            ),
            const SizedBox(height: 16.0),
            const Text("OR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 200,
              child: qr_scanner.QRView(key: _qrKey, onQRViewCreated: _onQRViewCreated),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: _pickImageAndScanQR,
              icon: const Icon(Icons.image),
              label: const Text("Upload QR Code Image"),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8.0),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:html' as html;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _cameraController;
  bool _isCameraReady = false;
  String feedbackText = "Tap the mic and ask what's around you.";

  late stt.SpeechToText _speech;
  bool _isListening = false;

  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeCamera();
    _speech = stt.SpeechToText();
  }

  void _requestPermissions() async {
    if (kIsWeb) {
      await html.window.navigator.mediaDevices?.getUserMedia({'video': true, 'audio': true});
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController.initialize();
    if (!mounted) return;
    setState(() => _isCameraReady = true);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> captureAndConvertImage() async {
    if (!_cameraController.value.isInitialized || _cameraController.value.isTakingPicture) return;

    try {
      final XFile imageFile = await _cameraController.takePicture();
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Download image
      final blobImage = html.Blob([bytes]);
      final urlImage = html.Url.createObjectUrlFromBlob(blobImage);
      final anchorImage = html.AnchorElement(href: urlImage)
        ..setAttribute("download", "image_$timestamp.jpg")
        ..click();
      html.Url.revokeObjectUrl(urlImage);

      // Download JSON
      final imageJson = jsonEncode({"image_base64": base64Image});
      final blobJson = html.Blob([imageJson]);
      final urlJson = html.Url.createObjectUrlFromBlob(blobJson);
      final anchorJson = html.AnchorElement(href: urlJson)
        ..setAttribute("download", "image_$timestamp.json")
        ..click();
      html.Url.revokeObjectUrl(urlJson);

      setState(() {
        feedbackText = "📥 Files downloaded: image_$timestamp.jpg & image_$timestamp.json";
      });

    } catch (e) {
      debugPrint("Image capture failed: $e");
    }
  }

  Future<String?> sendToWebcamAPI({
    required Uint8List imageBytes,
    required String userContent,
    required int frameHeight,
    required int frameWidth,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final uri = Uri.parse('http://192.168.40.67:5000/'); // Replace with actual endpoint

    final body = jsonEncode({
      "img": base64Image.toString(),
      "user": userContent,
      "frameHeight": frameHeight,
      "frameWidth": frameWidth,
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint("✅ API response received: ${data['msg']}");
        return data['msg'];
      } else {
        debugPrint('API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('API Exception: $e');
      return null;
    }
  }

  void startListening() async {
    if (_isListening) return;

    setState(() {
      feedbackText = ""; // Clear console at the beginning of new input
    });

    bool available = await _speech.initialize(
      onStatus: (val) {},
      onError: (val) => print('Error: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          if (_isListening) {
            setState(() {
              feedbackText = val.recognizedWords;
            });
          }
        },
      );
    }
  }

  void stopListening() async {
    if (_isListening) {
      final userSpeech = feedbackText;
      setState(() {
        _isListening = false;
        feedbackText = "🤖 AI is analyzing...";
      });

      await _speech.stop();

      // Ensure UI updates before heavy work
      await Future.delayed(const Duration(milliseconds: 100));

      final imageFile = await _cameraController.takePicture();
      final bytes = await imageFile.readAsBytes();

      final msg = await sendToWebcamAPI(
        imageBytes: bytes,
        userContent: userSpeech,
        frameHeight: _cameraController.value.previewSize?.height.toInt() ?? 0,
        frameWidth: _cameraController.value.previewSize?.width.toInt() ?? 0,
      );

      if (msg != null && msg.trim().isNotEmpty) {
        speakTextResponse(msg);
      } else {
        speakTextResponse("Sorry, I couldn't analyze the image.");
      }
    }
  }

  Future<void> speakTextResponse(String responseText) async {
    final words = responseText.split(" ");
    const wordDelay = Duration(milliseconds: 350);

    if (kIsWeb) {
      final synth = html.window.speechSynthesis;
      if (synth != null) {
        final utterance = html.SpeechSynthesisUtterance()
          ..text = responseText
          ..lang = 'en-US'
          ..rate = 1.0;

        final voices = synth.getVoices();
        if (voices.isNotEmpty) {
          final preferredVoice = voices.firstWhere(
            (v) => v.name?.toLowerCase().contains("male") ?? false,
            orElse: () => voices.first,
          );
          utterance.voice = preferredVoice;
        }

        ("🎤 Speaking out the response: $responseText");
        synth.cancel();
        synth.speak(utterance);
      }

      setState(() => feedbackText = "");
      for (int i = 0; i < words.length; i++) {
        Future.delayed(wordDelay * i, () {
          setState(() => feedbackText += "${words[i]} ");
        });
      }

      Future.delayed(wordDelay * words.length + const Duration(seconds: 3), () {
        if (!_isListening) {
          setState(() {
            feedbackText = "Tap the mic and ask what’s around you.";
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isCameraReady
              ? SizedBox.expand(
                  child: CameraPreview(_cameraController),
                )
              : const Center(child: CircularProgressIndicator()),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTapDown: (_) => startListening(),
                    onTapUp: (_) => stopListening(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.redAccent : Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (_isListening)
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic,
                            size: 32,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isListening ? "Listening..." : "Hold to Speak",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      feedbackText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
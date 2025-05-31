import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'package:flutter_tts/flutter_tts.dart';

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
      print("Image capture failed: $e");
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
      await _speech.stop();
      setState(() {
        _isListening = false;
        feedbackText = ""; // Clear console
      });

      await captureAndConvertImage();

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          feedbackText = "🤖 Please wait, the AI is analyzing...";
        });
      });

      Future.delayed(const Duration(seconds: 2), () {
        speakDummyResponse();
      });
    }
  }

  Future<void> speakDummyResponse() async {
    const dummyResponse = "It's definitely with Saim, check his pockets! Apparently he has a thing for spoons.";

    final words = dummyResponse.split(" ");
    const wordDelay = Duration(milliseconds: 350);

    if (kIsWeb) {
      final synth = html.window.speechSynthesis;
      if (synth != null) {
        final html.SpeechSynthesisUtterance utterance = html.SpeechSynthesisUtterance()
          ..text = dummyResponse
          ..lang = 'en-US'
          ..rate = 0.9;

        final voices = synth.getVoices();
        final preferredVoice = voices.firstWhere(
          (v) =>
              (v.name?.toLowerCase().contains("male") == true ||
               v.name?.toLowerCase().contains("wavenet") == true ||
               v.name?.toLowerCase().contains("en-us") == true),
          orElse: () => voices.first,
        );
        utterance.voice = preferredVoice;

        synth.cancel();
        synth.speak(utterance);

        setState(() {
          feedbackText = "";
        });

        for (int i = 0; i < words.length; i++) {
          Future.delayed(wordDelay * i, () {
            setState(() {
              feedbackText += "${words[i]} ";
            });
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
    } else {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVoice({
        "name": "en-us-x-sfg#male_1-local",
        "locale": "en-US",
      });

      setState(() {
        feedbackText = "";
      });

      for (int i = 0; i < words.length; i++) {
        Future.delayed(wordDelay * i, () {
          setState(() {
            feedbackText += "${words[i]} ";
          });
        });
      }

      Future.delayed(wordDelay * words.length + const Duration(seconds: 3), () {
        if (!_isListening) {
          setState(() {
            feedbackText = "Tap the mic and ask what’s around you.";
          });
        }
      });

      await _flutterTts.speak(dummyResponse);
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
import 'dart:ui' as ui; // ignore: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:html' as html;

class WebCameraWidget extends StatefulWidget {
  const WebCameraWidget({super.key});

  @override
  State<WebCameraWidget> createState() => _WebCameraWidgetState();
}

class _WebCameraWidgetState extends State<WebCameraWidget> {
  late html.VideoElement _videoElement;

  @override
  void initState() {
    super.initState();

    _videoElement = html.VideoElement()
      ..autoplay = true
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true}).then((stream) {
      _videoElement.srcObject = stream;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Embed the HTML video element
    return HtmlElementView(viewType: 'webcam-view');
  }

  @override
  void didChangeDependencies() {
    // Register the custom element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('webcam-view', (int viewId) => _videoElement);
    super.didChangeDependencies();
  }
}
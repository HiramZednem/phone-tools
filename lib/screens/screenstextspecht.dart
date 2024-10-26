import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Texspech extends StatefulWidget {
  const Texspech({super.key});

  @override
  _TextSpechState createState() => _TextSpechState();
}

enum TtsState { playing, stopped, paused, continued }

class _TextSpechState extends State<Texspech> {
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  String? _newVoiceText;
  int? _inputLength;

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  @override
  initState() {
    super.initState();
    initTts();
  }

  dynamic initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }

  Future<dynamic> _getLanguages() async => await flutterTts.getLanguages;

  Future<dynamic> _getEngines() async => await flutterTts.getEngines;

  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future<void> _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null && _newVoiceText!.isNotEmpty) {
      await flutterTts.speak(_newVoiceText!);
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future<void> _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
        value: type as String?,
        child: Text((type as String)),
      ));
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language!);
      if (isAndroid) {
        flutterTts.isLanguageInstalled(language!).then((value) {
          isCurrentLanguageInstalled = value as bool;
        });
      }
    });
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Text to Speech', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _inputSection(),
              const SizedBox(height: 20),
              _buildSliders(),
              const SizedBox(height: 20),
              _btnSection(),
              const SizedBox(height: 20),
              _languageDropDownSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputSection() => Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(115, 32, 32, 32),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          maxLines: 5,
          onChanged: _onChange,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Escribe el texto a convertir en voz",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      );

  Widget _btnSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButtonColumn(Colors.green, Icons.play_arrow, 'PLAY', _speak),
        _buildButtonColumn(Colors.red, Icons.stop, 'STOP', _stop),
        _buildButtonColumn(Colors.blue, Icons.pause, 'PAUSE', _pause),
      ],
    );
  }

  Widget _buildButtonColumn(
      Color color, IconData icon, String label, Function onPress) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          onPressed: () => onPress(),
          iconSize: 40,
        ),
        Text(
          label,
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _languageDropDownSection() {
    return FutureBuilder<dynamic>(
      future: _getLanguages(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return DropdownButton<String>(
            value: language,
            items: getLanguageDropDownMenuItems(snapshot.data as List<dynamic>),
            onChanged: changedLanguageDropDownItem,
            hint: const Text("Selecciona un idioma"),
            isExpanded: true,
          );
        } else if (snapshot.hasError) {
          return const Text('Error cargando los idiomas');
        } else {
          return const Text('Cargando idiomas...');
        }
      },
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [
        _slider("Volumen", volume, (value) {
          setState(() => volume = value);
        }, 0.0, 1.0),
        _slider("Pitch", pitch, (value) {
          setState(() => pitch = value);
        }, 0.5, 2.0),
        _slider("Velocidad", rate, (value) {
          setState(() => rate = value);
        }, 0.0, 1.0),
      ],
    );
  }

  Widget _slider(String label, double value, Function(double) onChanged,
      double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${(value).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 16)),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          divisions: 10,
          label: value.toString(),
        ),
      ],
    );
  }
}

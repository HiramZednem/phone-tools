import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechText extends StatefulWidget {
  const SpeechText({super.key});

  @override
  _SpechsTextState createState() => _SpechsTextState();
}

class _SpechsTextState extends State<SpeechText> {
  bool _hasSpeech = false;
  bool _isListening = false;
  double level = 0.0;
  String lastWords = 'Di algo';
  String lastError = '';
  String _currentLocaleId = 'es_ES'; // Idioma inicial predeterminado
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _hasSpeech = await speech.initialize(
      onError: _errorListener,
      onStatus: _statusListener,
    );
    if (_hasSpeech) {
      // Obtiene los idiomas disponibles en el dispositivo
      _localeNames = await speech.locales();

      // Obtiene el idioma predeterminado del dispositivo
      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale?.localeId ?? 'es_ES';
    }
    setState(() {});
  }

  void _startListening() {
    lastWords = '';
    lastError = '';
    speech.listen(
      onResult: _resultListener,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: _soundLevelListener,
      localeId: _currentLocaleId, // Aquí se usa el idioma seleccionado
      partialResults: true,
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() {
    speech.stop();
    setState(() {
      _isListening = false;
      level = 0.0;
    });
  }

  void _cancelListening() {
    speech.cancel();
    setState(() {
      _isListening = false; // Cambia el estado a no escuchando (regresa a azul)
      level = 0.0; // Reinicia el nivel de sonido
    });
  }

  void _resultListener(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  void _soundLevelListener(double level) {
    setState(() {
      this.level = level;
    });
  }

  void _errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "Error: ${error.errorMsg}";
      _isListening = false;
    });
  }

  void _statusListener(String status) {
    setState(() {
      _isListening = speech.isListening;
    });
  }

  void _switchLang(String? selectedLocale) {
    setState(() {
      _currentLocaleId = selectedLocale!; // Cambia el idioma actual
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Speech to Text',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildRecognitionResults(),
          ),
          Expanded(
            flex: 1,
            child: _buildControls(),
          ),
          _buildErrorStatus(),
          _buildLanguageSelector(), // Selector de idiomas
        ],
      ),
    );
  }

  Widget _buildRecognitionResults() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Text(
        lastWords,
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildControls() {
    return SingleChildScrollView(
        child: Column(
      children: [
        // Indicador de nivel de sonido
        Container(
          padding: const EdgeInsets.all(10),
          child: LinearProgressIndicator(
            value: level / 100, // Normalización del nivel de sonido
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
        const SizedBox(height: 10),
        // Botón para empezar o parar de escuchar
        FloatingActionButton(
          onPressed: _isListening ? _stopListening : _startListening,
          backgroundColor: _isListening ? Colors.green : Colors.orange,
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_off,
            color: Colors.white,
          ),
        ),
      ],
    ));
  }

  Widget _buildErrorStatus() {
    if (lastError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          lastError,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // Widget para el selector de idiomas
  Widget _buildLanguageSelector() {
    return SingleChildScrollView(
        child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Seleccionar idioma: ',
                    style: TextStyle(fontSize: 16, color: Colors.black)),
                Flexible(
                  child: DropdownButton<String>(
                    value: _currentLocaleId,
                    onChanged: _switchLang,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    items: _localeNames.map((locale) {
                      return DropdownMenuItem(
                        value: locale.localeId,
                        child: Text(locale.name,
                            style: const TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            )));
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class Location extends StatefulWidget {
  const Location({super.key});
  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<Location> {
  String _locationMessage = "Ubicación no disponible";
  String? _googleMapsLink;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Obtener la ubicación actual
  void _getCurrentLocation() async {
    // Solicitar permiso de ubicación
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = "Permiso de ubicación denegado";
      });
      return;
    }

    // Obtener la posición actual
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _locationMessage =
          "Lat: ${position.latitude}, Long: ${position.longitude}";
      // Generar el enlace de Google Maps
      _googleMapsLink =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
    });
  }

  // Método para abrir el enlace de Google Maps
  Future<void> _openGoogleMaps() async {
    if (_googleMapsLink != null && await launch(_googleMapsLink!)) {
      await launch(_googleMapsLink!);
    } else {
      throw 'No se pudo abrir Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Location",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _locationMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.all(15)),
                onPressed: _googleMapsLink != null ? _openGoogleMaps : null,
                child: const Text(
                  "Maps",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

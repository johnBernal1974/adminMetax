import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../common/main_layout.dart';
import '../../src/color.dart';

class RegistroPorteriaPage extends StatefulWidget {
  const RegistroPorteriaPage({super.key});

  @override
  State<RegistroPorteriaPage> createState() => _RegistroPorteriaPageState();
}

class _RegistroPorteriaPageState extends State<RegistroPorteriaPage> {

  final String googleApiKey = "TU_API_KEY";

  final _nombreConjunto = TextEditingController();
  final _nombrePorteria = TextEditingController();
  final _telefono = TextEditingController();

  final _direccion = TextEditingController();
  final _ciudad = TextEditingController();
  final _barrio = TextEditingController();

  GoogleMapController? mapController;

  LatLng? ubicacion;

  bool guardando = false;

  String tipoPorteria = "unica";

  Set<Marker> markers = {};

  /// =========================
  /// GEOCODING (obtener direccion)
  /// =========================

  Future<void> obtenerDireccion(LatLng posicion) async {

    try {

      final url =
          "https://maps.googleapis.com/maps/api/geocode/json"
          "?latlng=${posicion.latitude},${posicion.longitude}"
          "&key=$googleApiKey";

      final response = await http.get(Uri.parse(url));

      final data = jsonDecode(response.body);

      if (data["results"].isNotEmpty) {

        final result = data["results"][0];

        _direccion.text = result["formatted_address"];

        final components = result["address_components"];

        for (var comp in components) {

          if (comp["types"].contains("locality")) {
            _ciudad.text = comp["long_name"];
          }

          if (comp["types"].contains("neighborhood") ||
              comp["types"].contains("sublocality")) {
            _barrio.text = comp["long_name"];
          }

        }

      }

    } catch (e) {
      debugPrint("Error geocoding: $e");
    }

  }

  /// =========================
  /// MAPA
  /// =========================

  void seleccionarUbicacion(LatLng posicion) {

    ubicacion = posicion;

    markers = {
      Marker(
        markerId: const MarkerId("porteria"),
        position: posicion,
        draggable: true,
        onDragEnd: (nueva) {
          seleccionarUbicacion(nueva);
        },
      )
    };

    setState(() {});

    obtenerDireccion(posicion);

  }

  /// =========================
  /// GUARDAR
  /// =========================

  Future<void> guardar() async {

    if (_nombreConjunto.text.isEmpty ||
        _telefono.text.isEmpty ||
        ubicacion == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete los campos obligatorios")),
      );

      return;

    }

    try {

      setState(() => guardando = true);

      await FirebaseFirestore.instance.collection("Porterias").add({

        "nombreConjunto": _nombreConjunto.text.trim(),
        "nombrePorteria": _nombrePorteria.text.trim(),
        "telefono": _telefono.text.trim(),

        "direccion": _direccion.text.trim(),
        "ciudad": _ciudad.text.trim(),
        "barrio": _barrio.text.trim(),

        "tipoPorteria": tipoPorteria,

        "lat": ubicacion!.latitude,
        "lng": ubicacion!.longitude,

        "activa": true,

        "fechaRegistro": FieldValue.serverTimestamp()

      });

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, 'porterias_page');

    } catch (e) {

      debugPrint("Error guardando porteria: $e");

    } finally {

      if (mounted) {
        setState(() => guardando = false);
      }

    }

  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {

    return MainLayout(
      pageTitle: "Registrar Portería",
      content: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 1400),
            child: formulario(),
          ),
        ),
      ),
    );

  }

  InputDecoration deco(String label) {

    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primary),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.white,
    );

  }

  Widget formulario() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Información de la portería",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 25),

        TextField(
          controller: _nombreConjunto,
          decoration: deco("Nombre del conjunto"),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: _nombrePorteria,
          decoration: deco("Nombre de la portería"),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: _telefono,
          keyboardType: TextInputType.phone,
          decoration: deco("Teléfono"),
        ),

        const SizedBox(height: 25),

        /// MAPA MÁS GRANDE
        SizedBox(
          height: 500,
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(4.142, -73.6266),
              zoom: 14,
            ),
            markers: markers,
            zoomControlsEnabled: true,
            onTap: seleccionarUbicacion,
            onMapCreated: (controller) {
              mapController = controller;
            },
          ),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: _direccion,
          decoration: deco("Dirección"),
        ),

        const SizedBox(height: 20),

        /// CIUDAD Y BARRIO EN UN ROW
        Row(
          children: [

            Expanded(
              child: TextField(
                controller: _ciudad,
                decoration: deco("Ciudad"),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: TextField(
                controller: _barrio,
                decoration: deco("Barrio"),
              ),
            ),

          ],
        ),

        const SizedBox(height: 20),

        DropdownButtonFormField(
          value: tipoPorteria,
          decoration: deco("Tipo de portería"),
          items: const [
            DropdownMenuItem(value: "unica", child: Text("Portería única")),
            DropdownMenuItem(value: "porteria1", child: Text("Portería 1")),
            DropdownMenuItem(value: "porteria2", child: Text("Portería 2")),
          ],
          onChanged: (v) {
            setState(() => tipoPorteria = v!);
          },
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: guardando
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.save),
            label: Text(guardando ? "Guardando..." : "Registrar portería"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: guardando ? null : guardar,
          ),
        ),

      ],
    );

  }

}
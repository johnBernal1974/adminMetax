// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../common/main_layout.dart';
import '../../src/color.dart';
import 'package:http/http.dart' as http;
import 'dart:js' as js;

class EditarPorteriaPage extends StatefulWidget {
  const EditarPorteriaPage({super.key});

  @override
  State<EditarPorteriaPage> createState() => _EditarPorteriaPageState();
}

class _EditarPorteriaPageState extends State<EditarPorteriaPage> {

  final _nombreConjunto = TextEditingController();
  final _nombrePorteria = TextEditingController();
  final _telefono = TextEditingController();

  final _direccion = TextEditingController();
  final _ciudad = TextEditingController();
  final _barrio = TextEditingController();

  String tipoPorteria = "unica";

  GoogleMapController? mapController;
  LatLng? ubicacion;
  Set<Marker> markers = {};

  bool guardando = false;

  late String id;
  Timer? _debounce;
  bool actualizandoDireccion = false;

  bool modoMoverMarker = false;
  bool bloquearScroll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments as Map;

    id = args["id"];
    final data = args["data"];

    _nombreConjunto.text = data["nombreConjunto"] ?? "";
    _nombrePorteria.text = data["nombrePorteria"] ?? "";
    _telefono.text = data["telefono"] ?? "";
    _direccion.text = data["direccion"] ?? "";
    _ciudad.text = data["ciudad"] ?? "";
    _barrio.text = data["barrio"] ?? "";

    tipoPorteria = data["tipoPorteria"] ?? "unica";

    final lat = data["lat"];
    final lng = data["lng"];

    if (lat != null && lng != null) {
      ubicacion = LatLng(lat, lng);

      markers = {
        Marker(
          markerId: const MarkerId("porteria"),
          position: ubicacion!,
          draggable: true,
          onDragEnd: (nueva) {
            seleccionarUbicacion(nueva);
          },
        )
      };

      // 🔥 sincroniza dirección al entrar
      Future.microtask(() {
        obtenerDireccion(ubicacion!);
      });
    }
  }

  Future<void> obtenerDireccion(LatLng posicion) async {
    try {

      // 🔥 ACTIVAR LOADING AQUÍ
      setState(() => actualizandoDireccion = true);

      print("🚀 Reverse geocoding con JS");

      final latLng = js.JsObject(
        js.context['google']['maps']['LatLng'],
        [posicion.latitude, posicion.longitude],
      );

      final geocoder = js.JsObject(js.context['google']['maps']['Geocoder']);

      geocoder.callMethod('geocode', [
        js.JsObject.jsify({'location': latLng}),
            (results, status) {

          print("📡 Status JS: $status");

          if (status == "OK" && results != null && results.length > 0) {

            final result = results[0];

            final direccion = result['formatted_address'];

            print("📍 Dirección nueva: $direccion");

            // 🔥 ACTUALIZA DIRECCIÓN
            _direccion.value = _direccion.value.copyWith(
              text: direccion,
              selection: TextSelection.collapsed(offset: direccion.length),
            );

            final components = result['address_components'];

            for (var comp in components) {

              final types = comp['types'];

              if (types.contains("locality")) {
                _ciudad.text = comp['long_name'];
              }

              if (types.contains("sublocality") || types.contains("neighborhood")) {
                _barrio.text = comp['long_name'];
              }
            }

            // 🔥 APAGAR LOADING AQUÍ (SUCCESS)
            setState(() => actualizandoDireccion = false);

          } else {

            print("❌ No se pudo obtener dirección");

            // 🔥 APAGAR LOADING AQUÍ (FAIL)
            setState(() => actualizandoDireccion = false);
          }
        }
      ]);

    } catch (e) {

      print("❌ Error JS geocoding: $e");

      // 🔥 APAGAR LOADING AQUÍ (ERROR)
      setState(() => actualizandoDireccion = false);
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

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      obtenerDireccion(posicion);
    });
  }

  /// =========================
  /// UBICACION ACTUAL
  /// =========================

  Future<void> usarUbicacionActual() async {

    final position = await Geolocator.getCurrentPosition();

    final latLng = LatLng(position.latitude, position.longitude);

    seleccionarUbicacion(latLng);

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 17),
    );
  }

  /// =========================
  /// GUARDAR CAMBIOS
  /// =========================

  Future<void> guardar() async {

    if (ubicacion == null) return;

    try {

      setState(() => guardando = true);

      await FirebaseFirestore.instance
          .collection("Porterias")
          .doc(id)
          .update({

        "nombreConjunto": _nombreConjunto.text.trim(),
        "nombrePorteria": _nombrePorteria.text.trim(),
        "telefono": _telefono.text.trim(),

        "direccion": _direccion.text.trim(),
        "ciudad": _ciudad.text.trim(),
        "barrio": _barrio.text.trim(),

        "tipoPorteria": tipoPorteria,

        "lat": ubicacion!.latitude,
        "lng": ubicacion!.longitude,

        "location": GeoPoint(
          ubicacion!.latitude,
          ubicacion!.longitude,
        ),

      });

      if (!mounted) return;

      // ✅ FEEDBACK BONITO
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Portería actualizada correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      // 🔙 Opcional: regresar después de guardar
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar: $e"),
          backgroundColor: Colors.red,
        ),
      );

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
      pageTitle: "Editar Portería",
      content: SingleChildScrollView(
        physics: bloquearScroll
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                TextField(
                  controller: _nombreConjunto,
                  decoration: const InputDecoration(labelText: "Conjunto"),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _nombrePorteria,
                  decoration: const InputDecoration(labelText: "Portería"),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _telefono,
                  decoration: const InputDecoration(labelText: "Teléfono"),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 400,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: ubicacion ?? const LatLng(4.142, -73.6266),
                      zoom: 16,
                    ),
                    markers: markers,
                    scrollGesturesEnabled: !modoMoverMarker,
                    zoomGesturesEnabled: !modoMoverMarker,
                    rotateGesturesEnabled: !modoMoverMarker,
                    tiltGesturesEnabled: !modoMoverMarker,
                    onTap: seleccionarUbicacion,
                    onMapCreated: (c) => mapController = c,
                  ),
                ),

                const SizedBox(height: 15),

                LayoutBuilder(
                  builder: (context, constraints) {

                    final isMobile = constraints.maxWidth < 700;

                    final botonMoverMarker = SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          modoMoverMarker
                              ? Icons.lock_open
                              : Icons.touch_app,
                          color: Colors.white,
                        ),

                        label: Text(
                          modoMoverMarker
                              ? "Mover marcador"
                              : "Activar marcador",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          modoMoverMarker ? Colors.orange : Colors.black87,

                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        onPressed: () {
                          setState(() {
                            modoMoverMarker = !modoMoverMarker;

                            bloquearScroll = modoMoverMarker;
                          });
                        },
                      ),
                    );

                    final botonUbicacion = SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),

                        label: const Text(
                          "Usar mi ubicación",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,

                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        onPressed: usarUbicacionActual,
                      ),
                    );

                    if (isMobile) {

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          botonMoverMarker,

                          const SizedBox(height: 12),

                          botonUbicacion,
                        ],
                      );

                    }

                    return Row(
                      children: [
                        Expanded(child: botonUbicacion),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _direccion,
                  decoration: const InputDecoration(labelText: "Dirección"),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ciudad,
                        decoration: const InputDecoration(labelText: "Ciudad"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _barrio,
                        decoration: const InputDecoration(labelText: "Barrio"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField(
                  value: tipoPorteria,
                  items: const [
                    DropdownMenuItem(value: "unica", child: Text("Única")),
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
                  child: ElevatedButton(
                    onPressed: guardando ? null : guardar, // 🔒 bloquea mientras guarda
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: guardando
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Guardando...",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                        : const Text(
                      "Guardar cambios",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}
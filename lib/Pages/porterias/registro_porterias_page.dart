import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../common/main_layout.dart';
import '../../src/color.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui;
import 'dart:async';

class RegistroPorteriaPage extends StatefulWidget {
  const RegistroPorteriaPage({super.key});

  @override
  State<RegistroPorteriaPage> createState() => _RegistroPorteriaPageState();
}

class _RegistroPorteriaPageState extends State<RegistroPorteriaPage> {

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

  Timer? _debounce;

  bool actualizandoDireccion = false;

  bool modoMoverMarker = false;

  bool bloquearScroll = false;

  @override
  void initState() {
    super.initState();

    ui.platformViewRegistry.registerViewFactory(
      'direccion-input',
          (int viewId) {
        final input = html.InputElement();
        input.id = 'direccion-input';
        input.placeholder = 'Buscar dirección...';
        input.style.width = '100%';
        input.style.height = '40px';
        input.style.fontSize = '16px';
        input.style.padding = '8px';
        input.style.border = '1px solid #ccc';
        input.style.borderRadius = '8px';

        return input;
      },
    );

    // Esperar a que cargue
    Future.delayed(const Duration(seconds: 1), () {
      iniciarAutocomplete();
    });
  }

  /// =========================
  /// GEOCODING (obtener direccion)
  /// =========================

  Future<void> obtenerDireccion(LatLng posicion) async {

    try {

      setState(() => actualizandoDireccion = true);

      print("🚀 Reverse geocoding con JS");

      final latLng = js.JsObject(
        js.context['google']['maps']['LatLng'],
        [posicion.latitude, posicion.longitude],
      );

      final geocoder = js.JsObject(
        js.context['google']['maps']['Geocoder'],
      );

      geocoder.callMethod('geocode', [
        js.JsObject.jsify({'location': latLng}),
            (results, status) {

          print("📡 Status JS: $status");

          if (status == "OK" &&
              results != null &&
              results.length > 0) {

            final result = results[0];

            final direccion = result['formatted_address'];

            print("📍 Dirección nueva: $direccion");

            /// 🔥 ACTUALIZA INPUT HTML
            final input = html.document.getElementById('direccion-input');

            if (input != null) {
              input.setAttribute('value', direccion);
            }

            /// 🔥 ACTUALIZA CONTROLLER
            _direccion.value = _direccion.value.copyWith(
              text: direccion,
              selection: TextSelection.collapsed(
                offset: direccion.length,
              ),
            );

            final components = result['address_components'];

            for (var comp in components) {

              final types = comp['types'];

              if (types.contains("locality")) {
                _ciudad.text = comp['long_name'];
              }

              if (types.contains("sublocality") ||
                  types.contains("neighborhood")) {
                _barrio.text = comp['long_name'];
              }
            }

            setState(() => actualizandoDireccion = false);

          } else {

            print("❌ No se pudo obtener dirección");

            setState(() => actualizandoDireccion = false);
          }
        }
      ]);

    } catch (e) {

      print("❌ Error JS geocoding: $e");

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

    _debounce = Timer(
      const Duration(milliseconds: 400),
          () {
        obtenerDireccion(posicion);
      },
    );

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
        physics: bloquearScroll
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
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
            scrollGesturesEnabled: !modoMoverMarker,
            zoomGesturesEnabled: !modoMoverMarker,
            rotateGesturesEnabled: !modoMoverMarker,
            tiltGesturesEnabled: !modoMoverMarker,
            onTap: seleccionarUbicacion,
            onMapCreated: (controller) {
              mapController = controller;
            },
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
                  modoMoverMarker ? Icons.lock_open : Icons.touch_app,
                  color: Colors.white,
                ),
                label: Text(
                  modoMoverMarker ? "Mover marcador" : "Activar marcador",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modoMoverMarker ? Colors.orange : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                icon: const Icon(Icons.my_location, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
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

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Dirección"),

            const SizedBox(height: 8),

            Stack(
              children: [

                const SizedBox(
                  height: 50,
                  child: HtmlElementView(
                    viewType: 'direccion-input',
                  ),
                ),

                if (actualizandoDireccion)
                  const Positioned(
                    right: 12,
                    top: 12,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    ),
                  ),
              ],
            ),

          ],
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
                : const Icon(Icons.save, color: Colors.black),
            label: Text(guardando ? "Guardando..." : "Registrar portería", style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold
            ),),
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

  Future<void> usarUbicacionActual() async {
    try {

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarMensaje("Activa el GPS del dispositivo");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {

        _mostrarMensaje(
          "Debes habilitar el permiso de ubicación en el navegador (🔒 arriba)",
        );

        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);

      seleccionarUbicacion(latLng);

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 17),
      );

    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }


  void iniciarAutocomplete() {
    print("🚀 Iniciando Autocomplete...");


    final input = html.document.getElementById('direccion-input');
    if (input == null) {
      print("❌ Input NO encontrado en el DOM");
    }

    if (input == null) {
      print("❌ No se encontró el input HTML");
      return;
    }

    final options = js.JsObject.jsify({
      'componentRestrictions': {'country': 'co'},
    });

    final autocomplete = js.JsObject(
      js.context['google']['maps']['places']['Autocomplete'],
      [input, options],
    );

    autocomplete.callMethod('addListener', [
      'place_changed',
          () {

        final place = autocomplete.callMethod('getPlace');

        print("📦 PLACE: $place");

        final lat = place['geometry']['location'].callMethod('lat');
        final lng = place['geometry']['location'].callMethod('lng');

        final direccion = place['formatted_address'];

        print("📍 Dirección: $direccion");
        print("🌍 Lat: $lat, Lng: $lng");

        final latLng = LatLng(lat, lng);

        seleccionarUbicacion(latLng);

        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 17),
        );

        _direccion.text = direccion;

      }
    ]);
  }

}
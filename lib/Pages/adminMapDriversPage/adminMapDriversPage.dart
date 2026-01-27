import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminDriversMapPage extends StatefulWidget {
  const AdminDriversMapPage({super.key});

  @override
  State<AdminDriversMapPage> createState() => _AdminDriversMapPageState();
}

class _AdminDriversMapPageState extends State<AdminDriversMapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? _gmap;

  BitmapDescriptor? _taxiIconNormal;
  BitmapDescriptor? _taxiIconEmergency;

  static const CameraPosition _initial = CameraPosition(
    target: LatLng(4.1461765, -73.641138),
    zoom: 12.5,
  );

  Set<Marker> _markers = {};
  StreamSubscription<QuerySnapshot>? _sub;

  // Card state
  bool _showCard = false;
  math.Point<int>? _cardPoint; // coordenada en pantalla
  LatLng? _cardLatLng;

  String _cardPlaca = '';
  String _cardNombre = '';
  String _cardId = '';
  String _cardImage = '';
  bool _cardEmergency = false;

  @override
  void initState() {
    super.initState();
    _loadIcons().then((_) {
      _listenWorkingDrivers();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    try {
      const cfg = ImageConfiguration(size: Size(40, 50), devicePixelRatio: 4.0);
      _taxiIconNormal =
      await BitmapDescriptor.fromAssetImage(cfg, 'assets/marker_conductores.png');
      _taxiIconEmergency =
      await BitmapDescriptor.fromAssetImage(cfg, 'assets/marker_conductores_emergencia.png');

      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) print('❌ Error loading icons: $e');
    }
  }

  String formatPlaca(String placa) {
    final clean = placa.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (clean.length == 6) {
      return '${clean.substring(0, 3)}-${clean.substring(3)}';
    }
    return placa;
  }

  void _listenWorkingDrivers() {
    final q = FirebaseFirestore.instance
        .collection('Locations')
        .where('status', isEqualTo: 'driver_working');

    _sub = q.snapshots().listen((snap) async {
      final markers = <Marker>{};

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final pos = data['position'];
        if (pos is! Map<String, dynamic>) continue;

        final placaRaw = pos['placa']?.toString() ?? 'SINPLACA';
        final placa = formatPlaca(placaRaw);

        final nombres = (pos['nombres'] ?? '').toString();
        final apellidos = (pos['apellidos'] ?? '').toString();
        final imageUrl = (pos['image'] ?? '').toString();
        final emergencyActive = pos['emergency_active'] == true;

        final geo = pos['geopoint'];
        if (geo is! GeoPoint) continue;

        final heading = (pos['heading'] as num?)?.toDouble() ?? 0.0;

        final icon = emergencyActive
            ? (_taxiIconEmergency ?? BitmapDescriptor.defaultMarker)
            : (_taxiIconNormal ?? BitmapDescriptor.defaultMarker);

        final latLng = LatLng(geo.latitude, geo.longitude);

        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: latLng,
            rotation: heading,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            icon: icon,
            onTap: () => _openDriverCard(
              id: doc.id,
              latLng: latLng,
              placa: placa,
              nombres: nombres,
              apellidos: apellidos,
              imageUrl: imageUrl,
              emergencyActive: emergencyActive,
            ),
          ),
        );
      }

      if (!mounted) return;
      setState(() => _markers = markers);

      // si el card está abierto, recálculalo (por si el driver se movió)
      if (_showCard) {
        await _repositionCard();
      }
    }, onError: (e) {
      if (kDebugMode) print('Locations listen error: $e');
    });
  }

  Future<void> _openDriverCard({
    required String id,
    required LatLng latLng,
    required String placa,
    required String nombres,
    required String apellidos,
    required String imageUrl,
    required bool emergencyActive,
  }) async {
    _cardId = id;
    _cardLatLng = latLng;
    _cardPlaca = placa;
    _cardNombre = '${nombres.trim()} ${apellidos.trim()}'.trim();
    _cardImage = imageUrl;
    _cardEmergency = emergencyActive;

    await _repositionCard();

    if (!mounted) return;
    setState(() => _showCard = true);
  }

  Future<void> _repositionCard() async {
    if (_gmap == null || _cardLatLng == null) return;

    final screenCoord = await _gmap!.getScreenCoordinate(_cardLatLng!);
    _cardPoint = math.Point(screenCoord.x, screenCoord.y);

    if (mounted) setState(() {});
  }

  void _closeCard() {
    if (!_showCard) return;
    setState(() {
      _showCard = false;
      _cardPoint = null;
      _cardLatLng = null;
    });
  }

  Widget _driverCard() {
    if (!_showCard || _cardPoint == null) return const SizedBox.shrink();

    // Ajustes para que el card quede encima del marker
    final left = (_cardPoint!.x - 140).toDouble(); // centra el card
    final top = (_cardPoint!.y - 140).toDouble();  // lo sube encima

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black26,
                offset: Offset(0, 6),
              )
            ],
            border: Border.all(
              color: _cardEmergency ? Colors.red : Colors.green,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (_cardImage.isNotEmpty) ? NetworkImage(_cardImage) : null,
                child: (_cardImage.isEmpty)
                    ? const Icon(Icons.person, color: Colors.black54)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placa: $_cardPlaca',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cardNombre.isEmpty ? 'Sin nombre' : _cardNombre,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cardEmergency ? '🚨 EMERGENCIA' : '🟢 En servicio',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _cardEmergency ? Colors.red : Colors.green,
                      ),
                    ),

                  ],
                ),
              ),
              IconButton(
                onPressed: _closeCard,
                icon: const Icon(Icons.close),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conductores trabajando')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initial,
            onMapCreated: (c) {
              _gmap = c; // ✅ IMPORTANTE
              if (!_mapController.isCompleted) _mapController.complete(c);
            },
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,

            // ✅ si tocas el mapa, cierra la tarjeta
            onTap: (_) => _closeCard(),

            // ✅ si mueves la cámara, reposiciona la tarjeta
            onCameraMove: (_) {
              if (_showCard) {
                _repositionCard();
              }
            },
          ),

          // ✅ tarjeta encima del marker
          _driverCard(),
        ],
      ),
    );
  }
}

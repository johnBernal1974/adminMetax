import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_audio/just_audio.dart';

import '../../src/color.dart';

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

  // Card state (popup encima del marker)
  bool _showCard = false;
  math.Point<int>? _cardPoint;
  LatLng? _cardLatLng;

  String _cardPlaca = '';
  String _cardNombre = '';
  String _cardId = '';
  String _cardImage = '';
  bool _cardEmergency = false;

  // ====== BLINK (parpadeo) ======
  Timer? _blinkTimer;
  bool _blinkOn = true;
  List<QueryDocumentSnapshot>? _lastDocs;

  // ====== SONIDO (alarma) ======
  final Set<String> _prevEmergencyIds = <String>{};
  bool _soundEnabled = true;

  // ====== AUDIO ======
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _audioUnlocked = false;
  bool _isAlarmPlaying = false;

  // ====== PANEL IZQUIERDO: lista de emergencias ======
  // guardamos la info para mostrarla y poder centrar la cámara
  final Map<String, _EmergencyDriver> _emergencies = {};

  @override
  void initState() {
    super.initState();
    _loadIcons().then((_) {
      _startBlink();
      _preloadAlarm();
      _listenWorkingDrivers();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _blinkTimer?.cancel();
    _alarmPlayer.dispose();
    super.dispose();
  }


  Future<void> _preloadAlarm() async {
    try {
      await _alarmPlayer.setAsset('assets/audio/emergencia_tone.mp3');
    } catch (e) {
      if (kDebugMode) print('❌ Error preload alarm: $e');
    }
  }

  void _startBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _blinkOn = !_blinkOn;
      if (_lastDocs != null) {
        _rebuildMarkersFromDocs(_lastDocs!);
      }
    });
  }

  Future<void> _unlockAudioIfNeeded() async {
    if (_audioUnlocked) return;

    try {
      if (_alarmPlayer.audioSource == null) {
        await _alarmPlayer.setAsset('assets/audio/emergencia_tone.mp3');
      }

      await _alarmPlayer.setVolume(0.0);
      await _alarmPlayer.seek(Duration.zero);
      await _alarmPlayer.play();
      await _alarmPlayer.stop();
      await _alarmPlayer.setVolume(1.0);

      _audioUnlocked = true;
      if (kDebugMode) print('✅ Audio unlocked');

      // si ya hay una emergencia activa, suena al desbloquear
      if (_soundEnabled && _prevEmergencyIds.isNotEmpty) {
        await _playEmergencySound();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Audio unlock failed (try again on next tap): $e');
    }
  }

  Future<void> _playEmergencySound() async {
    if (!_soundEnabled) return;

    if (!_audioUnlocked) {
      if (kDebugMode) {
        print('🔇 Emergency detected but audio is locked (click map once).');
      }
      return;
    }

    if (_isAlarmPlaying) return;

    try {
      _isAlarmPlaying = true;

      await _alarmPlayer.stop();
      await _alarmPlayer.seek(Duration.zero);
      await _alarmPlayer.setVolume(1.0);
      await _alarmPlayer.play();
    } catch (e) {
      if (kDebugMode) print('❌ Error playing alarm: $e');
    } finally {
      _isAlarmPlaying = false;
    }
  }

  Future<void> _loadIcons() async {
    try {
      const cfg = ImageConfiguration(size: Size(40, 50), devicePixelRatio: 4.0);
      _taxiIconNormal =
      await BitmapDescriptor.fromAssetImage(cfg, 'assets/marker_conductores.png');
      _taxiIconEmergency = await BitmapDescriptor.fromAssetImage(
          cfg, 'assets/marker_conductores_emergencia.png');

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
      _lastDocs = snap.docs;
      await _rebuildMarkersFromDocs(snap.docs);

      if (_showCard) {
        await _repositionCard();
      }
    }, onError: (e) {
      if (kDebugMode) print('Locations listen error: $e');
    });
  }

  Future<void> _rebuildMarkersFromDocs(List<QueryDocumentSnapshot> docs) async {
    final markers = <Marker>{};
    final currentEmergencyIds = <String>{};

    // reconstruimos panel de emergencias desde cero
    final newEmergencies = <String, _EmergencyDriver>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final pos = data['position'];
      if (pos is! Map<String, dynamic>) continue;

      final placaRaw = pos['placa']?.toString() ?? 'SINPLACA';
      final placa = formatPlaca(placaRaw);

      final nombres = (pos['nombres'] ?? '').toString();
      final apellidos = (pos['apellidos'] ?? '').toString();
      final imageUrl = (pos['image'] ?? '').toString();

      final emergencyActive = data['emergency_active'] == true;

      final geo = pos['geopoint'];
      if (geo is! GeoPoint) continue;

      final heading = (pos['heading'] as num?)?.toDouble() ?? 0.0;
      final latLng = LatLng(geo.latitude, geo.longitude);

      if (emergencyActive) {
        currentEmergencyIds.add(doc.id);

        newEmergencies[doc.id] = _EmergencyDriver(
          id: doc.id,
          placa: placa,
          nombre: '${nombres.trim()} ${apellidos.trim()}'.trim(),
          imageUrl: imageUrl,
          latLng: latLng,
        );
      }

      // icono con titileo
      final icon = emergencyActive
          ? (_blinkOn
          ? (_taxiIconEmergency ?? BitmapDescriptor.defaultMarker)
          : (_taxiIconNormal ?? BitmapDescriptor.defaultMarker))
          : (_taxiIconNormal ?? BitmapDescriptor.defaultMarker);

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

    // sonido: nuevas emergencias
    final newOnes = currentEmergencyIds.difference(_prevEmergencyIds);
    if (_soundEnabled && newOnes.isNotEmpty) {
      await _playEmergencySound();
    }

    _prevEmergencyIds
      ..clear()
      ..addAll(currentEmergencyIds);

    if (!mounted) return;
    setState(() {
      _markers = markers;

      // panel izquierdo
      _emergencies
        ..clear()
        ..addAll(newEmergencies);
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

  Future<void> _focusDriver(LatLng latLng) async {
    if (_gmap == null) return;
    await _gmap!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: latLng,
          zoom: 16.5,
        ),
      ),
    );
  }

  // ===== UI: Panel Izquierdo =====
  Widget _leftPanel() {
    final list = _emergencies.values.toList()
      ..sort((a, b) => a.placa.compareTo(b.placa));

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.red.shade100),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'EMERGENCIAS',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${list.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (list.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Sin emergencias activas',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, i) {
                  final d = list[i];
                  return ListTile(
                    onTap: () async {
                      await _unlockAudioIfNeeded(); // por si no han tocado el mapa
                      await _focusDriver(d.latLng);
                    },
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: d.imageUrl.isNotEmpty ? NetworkImage(d.imageUrl) : null,
                      child: d.imageUrl.isEmpty
                          ? const Icon(Icons.person, size: 18, color: Colors.black54)
                          : null,
                    ),
                    title: Text(
                      d.placa,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      d.nombre.isEmpty ? 'Sin nombre' : d.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // puntito que “late” con el blink
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _blinkOn ? Colors.red : Colors.red.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ===== UI: Card sobre marker =====
  Widget _driverCard() {
    if (!_showCard || _cardPoint == null) return const SizedBox.shrink();

    final left = (_cardPoint!.x - 140).toDouble();
    final top = (_cardPoint!.y - 140).toDouble();

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
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Conductores trabajando', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              'general_page',
                  (route) => false,
            );
          },
        ),
      ),
      body: Row(
        children: [
          // ✅ panel izquierdo
          _leftPanel(),

          // ✅ mapa a la derecha
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initial,
                  onMapCreated: (c) {
                    _gmap = c;
                    if (!_mapController.isCompleted) _mapController.complete(c);
                  },
                  markers: _markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  onTap: (_) async {
                    await _unlockAudioIfNeeded();
                    _closeCard();
                  },
                  onCameraMove: (_) {
                    if (_showCard) _repositionCard();
                  },
                ),

                // ✅ tarjeta encima del marker
                _driverCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyDriver {
  final String id;
  final String placa;
  final String nombre;
  final String imageUrl;
  final LatLng latLng;

  _EmergencyDriver({
    required this.id,
    required this.placa,
    required this.nombre,
    required this.imageUrl,
    required this.latLng,
  });
}

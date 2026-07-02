import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../providers/operador_provider.dart';
import '../../src/color.dart';

class AdminDriversMapPage extends StatefulWidget {
  const AdminDriversMapPage({super.key});

  @override
  State<AdminDriversMapPage> createState() => _AdminDriversMapPageState();
}

class _AdminDriversMapPageState extends State<AdminDriversMapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GoogleMapController? _gmap;

  BitmapDescriptor? _taxiIconNormal;
  BitmapDescriptor? _taxiIconEmergency;
  BitmapDescriptor? _taxiIconWorking;

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
  final bool _soundEnabled = true;

  // ====== AUDIO ======
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _audioUnlocked = false;
  bool _isAlarmPlaying = false;

  // ====== PANEL IZQUIERDO: listas de control ======
  final Map<String, _EmergencyDriver> _emergencies = {};
  final Map<String, _DriverAvailable> _availableDrivers = {};
  final Map<String, _DriverWorking> _workingDrivers = {};

  String? _panelType; // 'emergency', 'working', 'available'
  bool _showPanel = false;
  double _mapPaddingLeft = 0;

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

  void _closePanel() {
    setState(() {
      _showPanel = false;
      _mapPaddingLeft = 0;
    });
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
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (!mounted) return;
      setState(() {
        _blinkOn = !_blinkOn;
      });
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

      if (_soundEnabled && _prevEmergencyIds.isNotEmpty) {
        await _playEmergencySound();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Audio unlock failed: $e');
    }
  }

  Future<void> _playEmergencySound() async {
    if (!_soundEnabled) return;
    if (!_audioUnlocked) return;
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
      const cfg = ImageConfiguration(size: Size(30, 40), devicePixelRatio: 4.0);
      _taxiIconNormal = await BitmapDescriptor.fromAssetImage(cfg, 'assets/marker_conductores.png');
      _taxiIconEmergency = await BitmapDescriptor.fromAssetImage(cfg, 'assets/marker_conductores_emergencia.png');
      _taxiIconWorking = await BitmapDescriptor.fromAssetImage(cfg, 'assets/marker_conductores_working.png');

      if (mounted) {
        setState(() {});
        if (_lastDocs != null) {
          _rebuildMarkersFromDocs(_lastDocs!);
        }
      }
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
    final hace15Minutos = DateTime.now().subtract(const Duration(minutes: 15));

    final q = FirebaseFirestore.instance
        .collection('Locations')
        .where('status', whereIn: ['driver_working', 'driver_available'])
        .where('position.updatedAt', isGreaterThan: Timestamp.fromDate(hace15Minutos));

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
    if (_taxiIconNormal == null || _taxiIconEmergency == null || _taxiIconWorking == null) {
      return;
    }

    final newMarkers = <Marker>{};
    final newAvailable = <String, _DriverAvailable>{};
    final newWorking = <String, _DriverWorking>{};
    final newEmergencies = <String, _EmergencyDriver>{};
    final currentEmergencyIds = <String>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pos = data['position'];
      if (pos is! Map<String, dynamic>) continue;

      final geo = pos['geopoint'];
      if (geo is! GeoPoint) continue;

      final latLng = LatLng(geo.latitude, geo.longitude);
      final status = data['status'];
      final emergencyActive = pos['emergency_active'] == true;
      final placa = formatPlaca(pos['placa']?.toString() ?? 'SINPLACA');
      final nombres = pos['nombres']?.toString() ?? '';
      final apellidos = pos['apellidos']?.toString() ?? '';
      final imageUrl = pos['image']?.toString() ?? '';
      final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
      final nombreCompleto = '${nombres.trim()} ${apellidos.trim()}'.trim();

      if (emergencyActive) {
        currentEmergencyIds.add(doc.id);
        newEmergencies[doc.id] = _EmergencyDriver(id: doc.id, placa: placa, nombre: nombreCompleto, imageUrl: imageUrl, latLng: latLng);
      } else if (status == 'driver_working') {
        newWorking[doc.id] = _DriverWorking(id: doc.id, placa: placa, nombre: nombreCompleto, imageUrl: imageUrl, latLng: latLng);
      } else {
        newAvailable[doc.id] = _DriverAvailable(id: doc.id, placa: placa, nombre: nombreCompleto, imageUrl: imageUrl, latLng: latLng);
      }

      BitmapDescriptor icon;
      if (emergencyActive) {
        icon = _taxiIconEmergency!;
      } else if (status == 'driver_working') {
        icon = _taxiIconWorking!;
      } else {
        icon = _taxiIconNormal!;
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: latLng,
          rotation: heading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: icon,
          onTap: () => _openDriverCard(id: doc.id, latLng: latLng, placa: placa, nombres: nombres, apellidos: apellidos, imageUrl: imageUrl, emergencyActive: emergencyActive),
        ),
      );
    }

    final newOnes = currentEmergencyIds.difference(_prevEmergencyIds);
    if (_soundEnabled && newOnes.isNotEmpty) await _playEmergencySound();

    _prevEmergencyIds.clear();
    _prevEmergencyIds.addAll(currentEmergencyIds);

    if (!mounted) return;

    setState(() {
      _markers = newMarkers;
      _emergencies..clear()..addAll(newEmergencies);
      _availableDrivers..clear()..addAll(newAvailable);
      _workingDrivers..clear()..addAll(newWorking);
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

  /// ✅ PANEL DINÁMICO IZQUIERDO CORREGIDO Y CONGELADO POR PLACA
  Widget _leftDynamicPanel() {
    if (!_showPanel) return const SizedBox.shrink();

    List list = [];
    Color color = Colors.green;
    String title = 'Disponibles';

    if (_panelType == 'emergency') {
      color = Colors.red;
      title = 'Emergencias';
      // Ordenamos alfabéticamente por placa para las emergencias
      list = _emergencies.values.toList()..sort((a, b) => a.placa.compareTo(b.placa));
    } else if (_panelType == 'working') {
      color = Colors.orange;
      title = 'En servicio';
      // Ordenamos alfabéticamente por placa para los que están en carrera
      list = _workingDrivers.values.toList()..sort((a, b) => a.placa.compareTo(b.placa));
    } else {
      // Ordenamos alfabéticamente por placa para los disponibles (Adiós baile de nombres)
      list = _availableDrivers.values.toList()..sort((a, b) => a.placa.compareTo(b.placa));
    }

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) {},
        onHorizontalDragStart: (_) {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(color: color.withOpacity(0.1)),
                child: Row(
                  children: [
                    Icon(Icons.list, color: color),
                    const SizedBox(width: 8),
                    Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: _closePanel)
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey.shade600)))
                    : ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final d = list[i];
                    return ListTile(
                      onTap: () => _focusDriver(d.latLng),
                      leading: CircleAvatar(
                        backgroundImage: d.imageUrl.isNotEmpty ? NetworkImage(d.imageUrl) : null,
                      ),
                      title: Text(d.placa),
                      subtitle: Text(d.nombre),
                      trailing: _panelType == 'emergency'
                          ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _blinkOn ? Colors.red : Colors.red.shade200,
                          shape: BoxShape.circle,
                        ),
                      )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26, offset: Offset(0, 6))],
            border: Border.all(color: _cardEmergency ? Colors.red : Colors.green, width: 2),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (_cardImage.isNotEmpty) ? NetworkImage(_cardImage) : null,
                child: (_cardImage.isEmpty) ? const Icon(Icons.person, color: Colors.black54) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Placa: $_cardPlaca', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
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
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _cardEmergency ? Colors.red : Colors.green),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: _closeCard, icon: const Icon(Icons.close))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Conductores trabajando', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final role = (context.read<OperadorProvider>().rolActual ?? '').trim();
            String backRoute;

            switch (role) {
              case 'operadorSeguimientoMap':
                backRoute = 'conductores_page';
                break;
              case 'operador2':
                backRoute = 'whatsapp_metax_page';
                break;
              default:
                backRoute = 'general_page';
            }

            Navigator.pushNamedAndRemoveUntil(context, backRoute, (route) => false);
          },
        ),
      ),
      body: Stack(
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(left: _mapPaddingLeft),
            child: GoogleMap(
              initialCameraPosition: _initial,
              onMapCreated: (c) {
                _gmap = c;
                if (!_mapController.isCompleted) {
                  _mapController.complete(c);
                }
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
          ),
          _topCards(),
          _leftDynamicPanel(),
          _driverCard(),
        ],
      ),
    );
  }

  Widget _topCards() {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusCard('Emergencias', _emergencies.length, Colors.red, Icons.warning, () => _openList('emergency')),
            const SizedBox(width: 10),
            _statusCard('En servicio', _workingDrivers.length, Colors.orange, Icons.local_taxi, () => _openList('working')),
            const SizedBox(width: 10),
            _statusCard('Disponibles', _availableDrivers.length, Colors.green, Icons.check_circle, () => _openList('available')),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(String title, int count, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '$count',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _openList(String type) {
    setState(() {
      _panelType = type;
      _showPanel = true;
      _mapPaddingLeft = 320;
    });
  }
}

class _EmergencyDriver {
  final String id;
  final String placa;
  final String nombre;
  final String imageUrl;
  final LatLng latLng;
  _EmergencyDriver({required this.id, required this.placa, required this.nombre, required this.imageUrl, required this.latLng});
}

class _DriverAvailable {
  final String id;
  final String placa;
  final String nombre;
  final String imageUrl;
  final LatLng latLng;
  _DriverAvailable({required this.id, required this.placa, required this.nombre, required this.imageUrl, required this.latLng});
}

class _DriverWorking {
  final String id;
  final String placa;
  final String nombre;
  final String imageUrl;
  final LatLng latLng;
  _DriverWorking({required this.id, required this.placa, required this.nombre, required this.imageUrl, required this.latLng});
}
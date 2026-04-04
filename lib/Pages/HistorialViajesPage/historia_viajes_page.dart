import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/main_layout.dart';

class TravelHistoryPage extends StatefulWidget {
  const TravelHistoryPage({Key? key}) : super(key: key);

  @override
  _TravelHistoryPageState createState() => _TravelHistoryPageState();
}

class _TravelHistoryPageState extends State<TravelHistoryPage> {
  DateTimeRange? selectedDateRange; // Rango de fechas seleccionado
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final numberFormat = NumberFormat("#,##0", "es_ES");

  //new para filtrado
  int? selectedYear;
  int? selectedMonth; // 1-12
  int? selectedDay;   // 1-31
  String placaQuery = "";
  String numeroViajeQuery = "";


  bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm a').format(dateTime); // Formato deseado
  }

  @override
  Widget build(BuildContext context) {
    final range = _rangeFromYMD();
    return MainLayout(
      pageTitle: 'Historial de Viajes',
      content: Column(
        children: [

          const SizedBox(height: 40),
          const Text("Buscar viajes por dia, placa o numero de viaje", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<int?>(
                    value: selectedYear,
                    decoration: InputDecoration(
                      labelText: "Año",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Selecciona"),
                      ),
                      ...List.generate(6, (i) => DateTime.now().year - i).map(
                            (y) => DropdownMenuItem<int?>(
                          value: y,
                          child: Text("$y"),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      selectedYear = v;
                      selectedMonth = null;
                      selectedDay = null;
                    }),
                  ),
                ),

                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<int?>(
                    value: selectedMonth,
                    decoration: InputDecoration(
                      labelText: "Mes",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Todos"),
                      ),
                      ...List.generate(12, (i) => i + 1).map(
                            (m) => DropdownMenuItem<int?>(
                          value: m,
                          child: Text("$m"),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      selectedMonth = v;
                      selectedDay = null;
                    }),
                  ),
                ),


                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<int?>(
                    value: selectedDay,
                    decoration: InputDecoration(
                      labelText: "Día",
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Todos"),
                      ),
                      ...List.generate(31, (i) => i + 1).map(
                            (d) => DropdownMenuItem<int?>(
                          value: d,
                          child: Text("$d"),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedDay = v),
                  ),
                ),

                SizedBox(
                  width: 220,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Placa",
                      hintText: "ABC123 o ABC-123",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onChanged: (v) => setState(() {
                      placaQuery = v.trim().toUpperCase();
                      print("PLACA QUERY: $placaQuery");
                    }),
                  ),
                ),

                SizedBox(
                  width: 220,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "N° Viaje",
                      hintText: "Ej: 2026-000001",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => numeroViajeQuery = v.trim()),
                  ),
                ),

                IconButton(
                  tooltip: "Limpiar filtros",
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {
                    selectedYear = null;
                    selectedMonth = null;
                    selectedDay = null;
                    placaQuery = "";
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: (range == null && placaQuery.isEmpty && numeroViajeQuery.isEmpty)
                ? const Center(
              child: Text(
                'Selecciona un año o escribe una placa / N° de viaje para ver el historial.',
                textAlign: TextAlign.center,
              ),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _getFilteredTravelHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay viajes en el historial.'));
                }

                final travelHistoryDocs =
                snapshot.data!.docs.cast<QueryDocumentSnapshot>();

                // ✅ normalizamos filtros
                final placaQ = _normPlaca(placaQuery);
                final numQ = numeroViajeQuery.trim().toLowerCase();

                // ✅ filtro combinado: placa + numeroViaje
                final filteredDocs = travelHistoryDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;


                  final placaNorm =
                  (data['placa'] ?? '').toString().toUpperCase();
                  final okPlaca =
                  placaQ.isEmpty ? true : placaNorm.contains(placaQ);

                  // numeroViaje (exacto del nodo)
                  final numeroViaje = (data['numeroViaje'] ?? '').toString();
                  final okNumero = numQ.isEmpty
                      ? true
                      : numeroViaje.toLowerCase().contains(numQ);

                  return okPlaca && okNumero;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No hay viajes con esos filtros en el rango seleccionado.'),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${filteredDocs.length} viajes encontrados',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: isDesktop(context)
                          ? _buildTable(filteredDocs)
                          : _buildCards(filteredDocs),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<QueryDocumentSnapshot> docs) {
    return Scrollbar(
      thumbVisibility: true,
        child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('N° Viaje', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Destino del viaje', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Cliente / Conductor', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Tarifa', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: docs.map((travelDoc) {
            final data = travelDoc.data() as Map<String, dynamic>;
      
            // ✅ OJO: en tu BD es numero_viaje (no numeroViaje)
            final numeroViaje = (data['numeroViaje'] ?? '—').toString();
      
            final idClient = data['idClient'];
            final idDriver = data['idDriver'];
      
            return DataRow(
              onSelectChanged: (_) => _openTravelDetailModal(travelDoc),
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        numeroViaje,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['solicitudViaje'] != null
                            ? formatTimestamp(data['solicitudViaje'])
                            : '—',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                DataCell(
                  SizedBox(
                    width: 250,
                    child: Text(
                      data['to'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
      
                // ✅ Cliente/Conductor consultando Firestore
                DataCell(
                  FutureBuilder<List<String>>(
                    future: Future.wait([
                      _getClientName(idClient),
                      _getDriverName(idDriver),
                    ]),
                    builder: (context, snap) {
                      final clientName = (snap.data != null && snap.data!.isNotEmpty)
                          ? snap.data![0]
                          : 'Cargando...';
                      final driverName = (snap.data != null && snap.data!.length > 1)
                          ? snap.data![1]
                          : 'Cargando...';
      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(clientName, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.directions_car, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(driverName, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                DataCell(
                  Text(
                    '\$${numberFormat.format((data['tarifa'] ?? 0))}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
        )
    );
  }

  void _openTravelDetailModal(QueryDocumentSnapshot travelDoc) {
    final data = travelDoc.data() as Map<String, dynamic>;

    final idClient = data['idClient'];
    final idDriver = data['idDriver'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: FutureBuilder<List<String>>(
              future: Future.wait([
                _getClientName(idClient),
                _getDriverName(idDriver),
              ]),
              builder: (context, snap) {
                final clientName =
                (snap.data != null && snap.data!.isNotEmpty) ? snap.data![0] : 'Cargando...';
                final driverName =
                (snap.data != null && snap.data!.length > 1) ? snap.data![1] : 'Cargando...';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalle del viaje ${data['numero_viaje'] ?? ''}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),

                      _detailRow('Origen', (data['from'] ?? '').toString()),
                      _detailRow('Destino', (data['to'] ?? '').toString()),

                      const Divider(),
                      _detailRow(
                        'Solicitud',
                        data['solicitudViaje'] != null ? formatTimestamp(data['solicitudViaje']) : '—',
                      ),
                      _detailRow(
                        'Inicio',
                        data['inicioViaje'] != null ? formatTimestamp(data['inicioViaje']) : '—',
                      ),
                      _detailRow(
                        'Final',
                        data['finalViaje'] != null ? formatTimestamp(data['finalViaje']) : '—',
                      ),

                      const Divider(),
                      _detailRow('Tarifa inicial', '\$${numberFormat.format((data['tarifaInicial'] ?? 0))}'),
                      _detailRow('Descuento', '\$${numberFormat.format((data['tarifaDescuento'] ?? 0))}'),
                      _detailRow('Tarifa final', '\$${numberFormat.format((data['tarifa'] ?? 0))}'),

                      const Divider(),
                      _detailRow('Calificación dada al cliente', '${data['calificacionAlCliente'] ?? 0} ⭐'),
                      _detailRow('Calificación dada al conductor', '${data['calificacionAlConductor'] ?? 0} ⭐'),

                      const Divider(),
                      // ✅ Nombres consultando BD
                      _detailRow('Cliente', clientName),
                      _detailRow('Conductor', driverName),

                      _detailRow('Placa', (data['placa_show'] ?? data['placa'] ?? '—').toString()),
                      _detailRow('Rol', (data['rol'] ?? '—').toString()),

                      const Divider(),
                      _detailRow('Apuntes', (data['apuntes'] ?? 'Sin apuntes').toString()),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }


  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }


  Widget _buildCards(List<QueryDocumentSnapshot> docs) {
    return Expanded(
      child: ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final travel = docs[index];

          final data = travel.data() as Map<String, dynamic>;

          final idClient = data['idClient'];
          final idDriver = data['idDriver'];

          final driverPlate = (data['placa'] ?? '').toString();

          return FutureBuilder(
            future: Future.wait([
              _getClientName(idClient),
              _getDriverName(idDriver),
            ]),
            builder: (context, snapshot) {
              final clientName = snapshot.data?[0] ?? '';
              final driverName = snapshot.data?[1] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// 🔥 NUMERO VIAJE + FECHA
                      Text(
                        data['numeroViaje'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['solicitudViaje'] != null
                            ? formatTimestamp(data['solicitudViaje'])
                            : '—',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const Divider(),

                      /// 📍 ORIGEN / DESTINO
                      _buildLabelValue('Origen:', data['from'] ?? ''),
                      _buildLabelValue('Destino:', data['to'] ?? ''),

                      const Divider(),

                      /// ⏱ TIEMPOS
                      _buildRow(
                        'Inicio:',
                        data['inicioViaje'] != null
                            ? formatTimestamp(data['inicioViaje'])
                            : '—',
                      ),
                      _buildRow(
                        'Final:',
                        data['finalViaje'] != null
                            ? formatTimestamp(data['finalViaje'])
                            : '—',
                      ),

                      const Divider(),

                      /// 💰 TARIFAS
                      _buildRow(
                        'Tarifa:',
                        '\$${numberFormat.format(data['tarifa'] ?? 0)}',
                        isBold: true,
                      ),
                      _buildRow(
                        'Descuento:',
                        '\$${numberFormat.format(data['tarifaDescuento'] ?? 0)}',
                      ),
                      _buildRow(
                        'Inicial:',
                        '\$${numberFormat.format(data['tarifaInicial'] ?? 0)}',
                      ),

                      const Divider(),

                      /// 👤 CLIENTE / 🚗 CONDUCTOR (CON ICONOS 🔥)
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(child: Text(clientName)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(child: Text(driverName)),
                        ],
                      ),

                      const Divider(),

                      /// ⭐ CALIFICACIONES
                      _buildRow(
                        'Cliente:',
                        '${data['calificacionAlCliente'] ?? 0} ⭐',
                      ),
                      _buildRow(
                        'Conductor:',
                        '${data['calificacionAlConductor'] ?? 0} ⭐',
                      ),

                      const Divider(),

                      /// 🚗 PLACA (opcional, puedes quitarla después)
                      _buildRow('Placa:', driverPlate),

                      /// 📝 APUNTES
                      if ((data['apuntes'] ?? '').toString().isNotEmpty)
                        _buildLabelValue('Apuntes:', data['apuntes']),

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  //new para filtrado

  String _normPlaca(String s) {
    return s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _safeGetString(QueryDocumentSnapshot doc, String key) {
    try {
      final v = doc.get(key);
      if (v == null) return '';
      return v.toString();
    } catch (_) {
      return '';
    }
  }


  DateTimeRange? _rangeFromYMD() {
    if (selectedYear == null) return null;

    // Año completo
    if (selectedMonth == null) {
      final start = DateTime(selectedYear!, 1, 1);
      final end = DateTime(selectedYear!, 12, 31, 23, 59, 59, 999);
      return DateTimeRange(start: start, end: end);
    }

    // Mes completo
    if (selectedDay == null) {
      final start = DateTime(selectedYear!, selectedMonth!, 1);
      final nextMonth = (selectedMonth! == 12)
          ? DateTime(selectedYear! + 1, 1, 1)
          : DateTime(selectedYear!, selectedMonth! + 1, 1);
      final end = nextMonth.subtract(const Duration(milliseconds: 1));
      return DateTimeRange(start: start, end: end);
    }

    // Día completo
    final start = DateTime(selectedYear!, selectedMonth!, selectedDay!, 0, 0, 0);
    final end = DateTime(selectedYear!, selectedMonth!, selectedDay!, 23, 59, 59, 999);
    return DateTimeRange(start: start, end: end);
  }



  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildRowBold(String label, String value, {bool isBold = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Stream<QuerySnapshot> _getFilteredTravelHistory() {
    Query query = _firestore.collection('TravelHistory');

    // ✅ rango construido desde año/mes/día
    final range = _rangeFromYMD();
    if (range != null) {
      final start = Timestamp.fromDate(range.start);
      final end = Timestamp.fromDate(range.end);
      query = query
          .where('solicitudViaje', isGreaterThanOrEqualTo: start)
          .where('solicitudViaje', isLessThanOrEqualTo: end);
    }

    // ✅ ordenar
    query = query.orderBy('solicitudViaje', descending: true);

    return query.snapshots();
  }


  Future<String> _getClientName(String clientId) async {
    try {
      final clientDoc = await _firestore.collection('Clients').doc(clientId).get();
      if (clientDoc.exists) {
        final clientData = clientDoc.data();
        return '${clientData?['01_Nombres']} ${clientData?['02_Apellidos']}';
      } else {
        return 'Cliente no encontrado';
      }
    } catch (e) {
      return 'Error al obtener cliente';
    }
  }

  Future<String> _getDriverName(dynamic driverIdValue) async {
    try {
      String driverId = '';

      if (driverIdValue is DocumentReference) {
        driverId = driverIdValue.id;
      } else if (driverIdValue is String) {
        driverId = driverIdValue.contains('/') ? driverIdValue.split('/').last : driverIdValue;
      } else {
        driverId = driverIdValue.toString();
      }

      final driverDoc = await _firestore.collection('Drivers').doc(driverId).get();
      if (driverDoc.exists) {
        final driverData = driverDoc.data();
        return '${driverData?['01_Nombres']} ${driverData?['02_Apellidos']}';
      } else {
        return 'Conductor no encontrado';
      }
    } catch (e) {
      return 'Error al obtener conductor';
    }
  }

}

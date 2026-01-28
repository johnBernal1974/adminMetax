import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/main_layout.dart';
import '../../common/travel_history_filters.dart';

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

  final Map<String, String> _plateCache = {}; // idDriver -> placa



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
          // Widget para los filtros (solo rango de fechas)
          TravelHistoryFilters(
            onFilterChange: (dateRange) {
              setState(() {
                selectedDateRange = dateRange;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: "Año"),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text("Selecciona")),
                      ...List.generate(6, (i) => DateTime.now().year - i).map(
                            (y) => DropdownMenuItem<int>(value: y, child: Text("$y")),
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
                  child: DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: const InputDecoration(labelText: "Mes"),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text("Todos")),
                      ...List.generate(12, (i) => i + 1).map(
                            (m) => DropdownMenuItem<int>(value: m, child: Text("$m")),
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
                  child: DropdownButtonFormField<int>(
                    value: selectedDay,
                    decoration: const InputDecoration(labelText: "Día"),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text("Todos")),
                      ...List.generate(31, (i) => i + 1).map(
                            (d) => DropdownMenuItem<int>(value: d, child: Text("$d")),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedDay = v),
                  ),
                ),

                SizedBox(
                  width: 220,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Placa",
                      hintText: "ABC123 o ABC-123",
                    ),
                    onChanged: (v) => setState(() {
                      placaQuery = v.trim().toUpperCase();
                      print("PLACA QUERY: $placaQuery");

                    }),
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
            child: (range == null && placaQuery.isEmpty)
                ? const Center(
              child: Text(
                'Selecciona un año o escribe una placa para ver el historial.',
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

                final travelHistoryDocs = snapshot.data!.docs.cast<QueryDocumentSnapshot>();

                final q = _normPlaca(placaQuery);

// ✅ filtro real por placa (primero placa_norm, si no existe usa placa_show/placa)
                final filteredDocs = (q.isEmpty)
                    ? travelHistoryDocs
                    : travelHistoryDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  print('🔥 TRAVEL DOC: $data');

                  final placaNorm = (data['placa_norm'] ?? '').toString().toUpperCase();
                  print('🔥 PLACA_NORM EN DOC: "$placaNorm"');
                  print('🔥 QUERY: "$q"');

                  return placaNorm.contains(q);
                }).toList();


// ✅ debug fuerte (mira consola)
                print("TOTAL=${travelHistoryDocs.length} | FILTRADOS=${filteredDocs.length} | q=$q");
                if (q.isNotEmpty && travelHistoryDocs.isNotEmpty) {
                  final sample = travelHistoryDocs.first;
                  print("SAMPLE placa_norm=${_safeGetString(sample, 'placa_norm')} placa_show=${_safeGetString(sample, 'placa_show')} placa=${_safeGetString(sample, 'placa')}");
                }



                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No hay viajes con esa placa en el rango seleccionado.'));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${filteredDocs.length} viajes encontrados',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final travel = filteredDocs[index];

                          final idClient = travel['idClient'];
                          final idDriver = travel['idDriver'];

                          // ✅ placa directa del TravelHistory
                          final driverPlate = (travel['placa_show'] ?? 'Placa no disponible').toString();

                          return FutureBuilder(
                            future: Future.wait([
                              _getClientName(idClient),
                              _getDriverName(idDriver), // ojo: si idDriver puede ser DocumentReference, te lo ajusto abajo
                            ]),
                            builder: (context, futureSnapshot) {
                              final clientName = futureSnapshot.data?[0] ?? 'Nombre no disponible';
                              final driverName = futureSnapshot.data?[1] ?? 'Nombre no disponible';

                              return Align(
                                alignment: Alignment.topLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 500),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildLabelValue('Origen:', '${travel['from']}'),
                                          _buildLabelValue('Destino:', '${travel['to']}'),
                                          const SizedBox(height: 8),
                                          const Divider(),
                                          _buildRow('Fecha de Solicitud:', formatTimestamp(travel['solicitudViaje'])),
                                          _buildRow('Inicio del Viaje:', formatTimestamp(travel['inicioViaje'])),
                                          _buildRow('Finalización del Viaje:', formatTimestamp(travel['finalViaje'])),
                                          const Divider(),
                                          _buildRow('Tarifa Inicial:', '\$${numberFormat.format(travel['tarifaInicial'])}'),
                                          _buildRow('Descuento:', '\$${numberFormat.format(travel['tarifaDescuento'])}'),
                                          _buildRow('Tarifa Final:', '\$${numberFormat.format(travel['tarifa'])}', isBold: true),
                                          const Divider(),
                                          _buildRow('Calificación al Cliente:', '${travel['calificacionAlCliente']}'),
                                          _buildRow('Calificación al Conductor:', '${travel['calificacionAlConductor']}'),
                                          const Divider(),
                                          _buildRowBold('Apuntes:', '${travel['apuntes'] ?? 'Sin apuntes'}'),
                                          _buildRow('Cliente:', clientName),
                                          _buildRow('Conductor:', driverName),
                                          _buildRow('Rol:', '${travel['rol']}'),
                                          _buildRow('Placa del Conductor:', driverPlate),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
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

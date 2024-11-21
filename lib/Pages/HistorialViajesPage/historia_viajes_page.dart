import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../common/main_layout.dart';
import '../../common/travel_history_filters.dart';
import '../../src/color.dart';

class TravelHistoryPage extends StatefulWidget {
  const TravelHistoryPage({Key? key}) : super(key: key);

  @override
  _TravelHistoryPageState createState() => _TravelHistoryPageState();
}

class _TravelHistoryPageState extends State<TravelHistoryPage> {
  DateTimeRange? selectedDateRange; // Rango de fechas seleccionado
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            // Stream para mostrar los viajes según los filtros
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredTravelHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay viajes en el historial.'));
                }

                final travelHistoryDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: travelHistoryDocs.length,
                  itemBuilder: (context, index) {
                    final travel = travelHistoryDocs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Origen:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${travel['from']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Destino:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${travel['to']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Fecha de Solicitud:', style: TextStyle(fontSize: 16)),
                                Text('${travel['solicitudViaje']}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Inicio del Viaje:', style: TextStyle(fontSize: 16)),
                                Text('${travel['inicioViaje']}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Finalización del Viaje:', style: TextStyle(fontSize: 16)),
                                Text('${travel['finalViaje']}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tarifa Inicial:', style: TextStyle(fontSize: 16)),
                                Text('\$${travel['tarifaInicial']}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Descuento:', style: TextStyle(fontSize: 16)),
                                Text('\$${travel['tarifaDescuento']}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tarifa Final:', style: TextStyle(fontSize: 16)),
                                Text('\$${travel['tarifa']}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Calificación al Cliente:', style: TextStyle(fontSize: 16)),
                                Text('${travel['calificacionAlCliente']}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Calificación al Conductor:', style: TextStyle(fontSize: 16)),
                                Text('${travel['calificacionAlConductor']}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Apuntes:', style: TextStyle(fontSize: 16)),
                                Text('${travel['apuntes'] ?? 'Sin apuntes'}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ID Cliente:', style: TextStyle(fontSize: 16)),
                                Text('${travel['idClient']}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ID Conductor:', style: TextStyle(fontSize: 16)),
                                Text('${travel['idDriver']}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Rol:', style: TextStyle(fontSize: 16)),
                                Text('${travel['rol']}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Servicio solicitado:', style: TextStyle(fontSize: 16)),
                                Text('${travel['tipoServicio']}'),
                              ],
                            ),
                          ],
                        ),

                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredTravelHistory() {
    // Base query para la colección TravelHistory
    Query query = _firestore.collection('TravelHistory');

    // Aplicar filtro por rango de fechas
    if (selectedDateRange != null) {
      final start = Timestamp.fromDate(selectedDateRange!.start);
      final end = Timestamp.fromDate(selectedDateRange!.end);
      query = query
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end);
    }

    return query.snapshots();
  }
}

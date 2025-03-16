import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final numberFormat = NumberFormat("#,##0", "es_ES");

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm a').format(dateTime); // Formato deseado
  }

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
            child: selectedDateRange == null
                ? const Center(
              child: Text(
                'Por favor, selecciona un rango de fechas para ver el historial de viajes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
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

                // Cantidad de documentos encontrados
                final documentCount = snapshot.data!.docs.length;

                final travelHistoryDocs = snapshot.data!.docs;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '$documentCount viajes encontrados', // Muestra la cantidad de documentos
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: travelHistoryDocs.length,
                        itemBuilder: (context, index) {
                          final travel = travelHistoryDocs[index];
                          final idClient = travel['idClient'];
                          final idDriver = travel['idDriver'];

                          return FutureBuilder(
                            future: Future.wait([
                              _getClientName(idClient), // Obtener nombre del cliente
                              _getDriverName(idDriver), // Obtener nombre del conductor
                              _getDriverPlate(idDriver), // Obtener placa del conductor
                            ]),
                            builder: (context, futureSnapshot) {
                              final clientName = futureSnapshot.data?[0] ?? 'Nombre no disponible';
                              final driverName = futureSnapshot.data?[1] ?? 'Nombre no disponible';
                              final driverPlate = futureSnapshot.data?[2] ?? 'Placa no disponible';

                              return Align(
                                alignment: Alignment.topLeft, // Alineación de las tarjetas a la izquierda
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 500),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Sección de Origen y Destino
                                          _buildLabelValue('Origen:', '${travel['from']}'),
                                          _buildLabelValue('Destino:', '${travel['to']}'),
                                          const SizedBox(height: 8),
                                          const Divider(),
                                          _buildRow(
                                            'Fecha de Solicitud:',
                                            formatTimestamp(travel['solicitudViaje']),
                                          ),
                                          _buildRow(
                                            'Inicio del Viaje:',
                                            formatTimestamp(travel['inicioViaje']),
                                          ),
                                          _buildRow(
                                            'Finalización del Viaje:',
                                            formatTimestamp(travel['finalViaje']),
                                          ),
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
                                          _buildRow('Placa del Conductor:', driverPlate), // Mostrar la placa aquí
                                          //_buildRow('Servicio solicitado:', '${travel['tipoServicio']}'),
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
    // Base query para la colección TravelHistory
    Query query = _firestore.collection('TravelHistory');

    // Aplicar filtro por rango de fechas
    if (selectedDateRange != null) {
      final start = Timestamp.fromDate(selectedDateRange!.start);
      final end = Timestamp.fromDate(
        selectedDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
      );
      query = query
          .where('solicitudViaje', isGreaterThanOrEqualTo: start) // Usar 'solicitudViaje' como campo de filtro
          .where('solicitudViaje', isLessThanOrEqualTo: end);
    }

    // Ordenar los resultados por 'solicitudViaje' en orden descendente
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

  Future<String> _getDriverName(String driverId) async {
    try {
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

  Future<String> _getDriverPlate(String driverId) async {
    try {
      final driverDoc = await _firestore.collection('Drivers').doc(driverId).get();
      if (driverDoc.exists) {
        final driverData = driverDoc.data();
        return driverData?['18_Placa'] ?? 'Placa no disponible';
      } else {
        return 'Placa no disponible';
      }
    } catch (e) {
      return 'Error al obtener placa';
    }
  }
}

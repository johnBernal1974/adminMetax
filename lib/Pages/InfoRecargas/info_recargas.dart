import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/main_layout.dart';

class RecargaPage extends StatefulWidget {
  @override
  _RecargaPageState createState() => _RecargaPageState();
}

class _RecargaPageState extends State<RecargaPage> {
  int totalRecarga = 0;
  int cantidadAutomovil = 0;
  int cantidadMotocicleta = 0;
  int totalRecargaAutomovil = 0;
  int totalRecargaMotocicleta = 0;
  String selectedInterval = 'Día'; // Intervalo inicial
  final NumberFormat currencyFormat = NumberFormat.currency(symbol: "\$", decimalDigits: 0);
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');


  @override
  void initState() {
    super.initState();
    _calcularTotales();
  }

  Future<void> _calcularTotales() async {
    DateTime now = DateTime.now();
    DateTime startDate;

    // Ajustar la fecha de inicio basada en el intervalo seleccionado
    switch (selectedInterval) {
      case 'Día':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Semana':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Mes':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Año':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recargas')
        .where('fecha_hora', isGreaterThanOrEqualTo: startDate)
        .get();

    int total = 0;
    int autos = 0;
    int motos = 0;
    int totalAutos = 0;
    int totalMotos = 0;

    for (var doc in snapshot.docs) {
      int recarga = doc['2nueva_recarga'] ?? 0;
      String tipoVehiculo = doc['tipoVehiculo'] ?? '';

      total += recarga;

      if (tipoVehiculo == 'Automovil') {
        autos++;
        totalAutos += recarga;
      } else if (tipoVehiculo == 'Motocicleta') {
        motos++;
        totalMotos += recarga;
      }
    }

    setState(() {
      totalRecarga = total;
      cantidadAutomovil = autos;
      cantidadMotocicleta = motos;
      totalRecargaAutomovil = totalAutos;
      totalRecargaMotocicleta = totalMotos;
    });
  }

  void _onIntervalChange(String? newInterval) {
    setState(() {
      selectedInterval = newInterval!;
    });
    _calcularTotales(); // Recalcular totales al cambiar el intervalo
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Historial de Recargas',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown para seleccionar el intervalo de tiempo
                DropdownButton<String>(
                  value: selectedInterval,
                  onChanged: _onIntervalChange,
                  items: <String>['Día', 'Semana', 'Mes', 'Año']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor Total general de recargas:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currencyFormat.format(totalRecarga),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Recargas de Automóviles:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.start,
                        ),
                        Text(
                          cantidadAutomovil.toString(),
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    Text(
                      'Valor Total recargas: ${currencyFormat.format(totalRecargaAutomovil)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Divider(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Recargas de Motocicletas:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.start,
                        ),
                        Text(
                          cantidadMotocicleta.toString(),
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                    Text(
                      'Valor Total recargas: ${currencyFormat.format(totalRecargaMotocicleta)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('recargas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 600;

                    if (isMobile) {
                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDataRow('idDriver', doc['idDriver']),
                                  _buildDataRow('Placa', doc['placa']),
                                  _buildDataRow('Tipo de Vehículo', doc['tipoVehiculo']),
                                  _buildDataRow('Saldo Anterior', currencyFormat.format(doc['1saldo_anterior'])),
                                  _buildDataRowNuevaRecarga('Nueva Recarga', currencyFormat.format(doc['2nueva_recarga'])),
                                  _buildDataRow('Saldo Total', currencyFormat.format(doc['3saldo_total'])),
                                  _buildDataRow('Fecha y Hora', (doc['fecha_hora'] as Timestamp).toDate().toString()),
                                  _buildDataRow('Operador', doc['operador']),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID del Conductor')),
                            DataColumn(label: Text('Placa')),
                            DataColumn(label: Text('Tipo de Vehículo')),
                            DataColumn(label: Text('Saldo Anterior')),
                            DataColumn(label: Text('Nueva Recarga')),
                            DataColumn(label: Text('Saldo Total')),
                            DataColumn(label: Text('Fecha y Hora')),
                            DataColumn(label: Text('Operador')),
                          ],
                          rows: (() {
                            // Create a copy of docs and sort it
                            List<QueryDocumentSnapshot> sortedDocs = List.from(snapshot.data!.docs);
                            sortedDocs.sort((a, b) => (b['fecha_hora'] as Timestamp).compareTo(a['fecha_hora'] as Timestamp));

                            // Map sortedDocs to DataRow
                            return sortedDocs.map((doc) {
                              return DataRow(cells: [
                                DataCell(Text(doc['idDriver'])),
                                DataCell(Text(doc['placa'])),
                                DataCell(Text(doc['tipoVehiculo'])),
                                DataCell(Text(currencyFormat.format(doc['1saldo_anterior']))),
                                DataCell(Text(currencyFormat.format(doc['2nueva_recarga']), style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text(currencyFormat.format(doc['3saldo_total']))),
                                DataCell(Text(dateFormat.format((doc['fecha_hora'] as Timestamp).toDate()))),
                                DataCell(Text(doc['operador'])),
                              ]);
                            }).toList();
                          })(),
                        ),

                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
          Text(value, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDataRowNuevaRecarga(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

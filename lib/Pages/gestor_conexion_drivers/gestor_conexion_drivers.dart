import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../common/main_layout.dart';
import '../../src/color.dart'; // Asegúrate de tener este import para el color 'primary'
import 'detalle_conexion_driver.dart';

class GestorConexionDriversPage extends StatefulWidget {
  const GestorConexionDriversPage({super.key});

  @override
  State<GestorConexionDriversPage> createState() => _GestorConexionDriversPageState();
}

class _GestorConexionDriversPageState extends State<GestorConexionDriversPage> {
  Key _listKey = UniqueKey();

  void _refresh() {
    setState(() {
      _listKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Gestión de Conductores",
      content: LayoutBuilder(builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        return Center(
          child: Container(
            width: isDesktop ? 700 : double.infinity,
            padding: const EdgeInsets.only(left: 20.0, top: 10.0, right: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Usamos Wrap para que el botón baje de línea si no hay espacio
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 10,
                  spacing: 10,
                  children: [
                    const Text(
                      "Gestión de conexión de conductores",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, color: Colors.black),
                      label: const Text("Actualizar", style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary, // Color primary
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    key: _listKey,
                    future: FirebaseFirestore.instance.collection('EstadisticasDiarias').get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No hay datos de conexión."));
                      }

                      Map<String, int> totales = {};
                      for (var doc in snapshot.data!.docs) {
                        String id = doc['idDriver'];
                        totales[id] = (totales[id] ?? 0) + (doc['totalSegundos'] as num).toInt();
                      }

                      var listaOrdenada = totales.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      return ListView.builder(
                        itemCount: listaOrdenada.length,
                        itemBuilder: (context, index) {
                          String driverId = listaOrdenada[index].key;
                          int totalSegundos = listaOrdenada[index].value;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('Drivers').doc(driverId).get(),
                            builder: (context, driverSnap) {
                              if (!driverSnap.hasData) return const SizedBox.shrink();

                              var data = driverSnap.data!.data() as Map<String, dynamic>? ?? {};
                              String nombre = "${data['01_Nombres'] ?? ''} ${data['02_Apellidos'] ?? ''}".trim();
                              String foto = data['image'] ?? '';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetalleConductorPage(
                                          driverId: driverId,
                                          nombre: nombre,
                                          fotoUrl: foto,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: index == 0 ? Colors.amber : Colors.blue.shade50,
                                          child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: index == 0 ? Colors.white : Colors.black)),
                                        ),
                                        const SizedBox(width: 15),
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                              Text("Total: ${_formatearTiempo(totalSegundos)}"),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatearTiempo(int totalSegundos) {
    int horas = totalSegundos ~/ 3600;
    int minutos = (totalSegundos % 3600) ~/ 60;
    return "$horas h ${minutos}m";
  }
}
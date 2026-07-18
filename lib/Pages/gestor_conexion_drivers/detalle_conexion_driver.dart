import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../common/main_layout.dart';

class DetalleConductorPage extends StatefulWidget {
  final String driverId;
  final String nombre;
  final String? fotoUrl;

  const DetalleConductorPage({super.key, required this.driverId, required this.nombre, this.fotoUrl});

  @override
  State<DetalleConductorPage> createState() => _DetalleConductorPageState();
}

class _DetalleConductorPageState extends State<DetalleConductorPage> {
  String _mesSeleccionado = "2026-07"; // Formato AAAA-MM

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Perfil: ${widget.nombre}",
      content: LayoutBuilder(builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        return Center(
          child: Container(
            width: isDesktop ? 700 : double.infinity,
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('EstadisticasDiarias')
                  .where('idDriver', isEqualTo: widget.driverId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                int totalHistorico = 0; // Acumulado del año actual
                int totalMes = 0;
                int totalSemana = 0;

                final now = DateTime.now();
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

                List<QueryDocumentSnapshot> docsMes = [];

                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  int segundos = (data['totalSegundos'] ?? 0).toInt();
                  String fechaStr = data['fecha'] ?? "";

                  try {
                    DateTime fechaDoc = DateTime.parse(fechaStr);

                    // ✅ DINÁMICO: Acumulado solo del año actual
                    if (fechaDoc.year == now.year) {
                      totalHistorico += segundos;
                    }

                    // Filtro para el mes seleccionado
                    if (fechaStr.startsWith(_mesSeleccionado)) {
                      totalMes += segundos;
                      docsMes.add(doc);
                    }

                    // Filtro para la semana
                    if (fechaDoc.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
                      totalSemana += segundos;
                    }
                  } catch (_) {}
                }

                // ✅ ORDENAMIENTO DESCENDENTE: Los de más tiempo primero
                docsMes.sort((a, b) {
                  int segA = ((a.data() as Map<String, dynamic>)['totalSegundos'] ?? 0).toInt();
                  int segB = ((b.data() as Map<String, dynamic>)['totalSegundos'] ?? 0).toInt();
                  return segB.compareTo(segA);
                });

                return Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 15),

                    // Tarjetas de Resumen
                    Row(
                      children: [
                        _buildCard("Histórico ${now.year}", totalHistorico, Colors.black),
                        _buildCard("Semana", totalSemana, Colors.black),
                        _buildCard("Mes", totalMes, Colors.black),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Historial diario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        DropdownButton<String>(
                          value: _mesSeleccionado,
                          items: ["2026-06", "2026-07"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) => setState(() => _mesSeleccionado = val!),
                        ),
                      ],
                    ),

                    // Lista Filtrada y Ordenada
                    Expanded(
                      child: ListView.builder(
                        itemCount: docsMes.length,
                        itemBuilder: (context, index) {
                          var data = docsMes[index].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              title: Text(data['fecha']),
                              trailing: Text(_formatearTiempo(data['totalSegundos']),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)]),
      child: Row(
        children: [
          CircleAvatar(radius: 40, backgroundImage: widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty ? NetworkImage(widget.fotoUrl!) : null, child: widget.fotoUrl == null || widget.fotoUrl!.isEmpty ? const Icon(Icons.person, size: 40) : null),
          const SizedBox(width: 20),
          Text(widget.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCard(String titulo, int segundos, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 5),
              Text(_formatearTiempo(segundos), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearTiempo(int totalSegundos) {
    int horas = totalSegundos ~/ 3600;
    int minutos = (totalSegundos % 3600) ~/ 60;
    return horas > 0 ? "$horas h ${minutos}m" : "$minutos m";
  }
}
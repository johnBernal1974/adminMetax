import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:html' as html;
import 'package:excel/excel.dart' as ex;

import '../common/main_layout.dart';

class DriversActivityAdminPage extends StatefulWidget {
  const DriversActivityAdminPage({super.key});

  @override
  State<DriversActivityAdminPage> createState() => _DriversActivityAdminPageState();
}

class _DriversActivityAdminPageState extends State<DriversActivityAdminPage> {
  String filtroSeleccionado = '';

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Actividad Conductores',
      content: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('system_metrics')
            .doc('drivers_status')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final activos = data['activos'] ?? 0;
          final dormidos = data['dormidos'] ?? 0;
          final sinLocation = data['sinLocation'] ?? 0;
          final totalActivados = data['totalActivados'] ?? 0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 700;

                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isMobile ? double.infinity : 250,
                              child: GestureDetector(
                                onTap: () => setState(() => filtroSeleccionado = 'activo'),
                                child: _buildCard('🟢 Activos', activos.toString(), Colors.green),
                              ),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : 250,
                              child: GestureDetector(
                                onTap: () => setState(() => filtroSeleccionado = 'dormido'),
                                child: _buildCard('🌙 Dormidos', dormidos.toString(), Colors.orange),
                              ),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : 250,
                              child: GestureDetector(
                                onTap: () => setState(() => filtroSeleccionado = 'sinLocation'),
                                child: _buildCard('❌ Sin Location', sinLocation.toString(), Colors.red),
                              ),
                            ),
                            SizedBox(
                              width: isMobile ? double.infinity : 250,
                              child: GestureDetector(
                                onTap: () => setState(() => filtroSeleccionado = 'todos'),
                                child: _buildCard('🚕 Activados', totalActivados.toString(), Colors.blue),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: exportarExcel,
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar Excel'),
                    ),
                    const SizedBox(height: 24),
                    if (filtroSeleccionado.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('Selecciona una categoría arriba'),
                        ),
                      )
                    else
                    /* * ✅ OPTIMIZACIÓN DE FLUJO: Usamos FutureBuilder para listas de control estático
                       * y añadimos un tope de seguridad de .limit(40) para evitar lecturas masivas.
                       */
                      FutureBuilder<QuerySnapshot>(
                        future: filtroSeleccionado == 'todos'
                            ? FirebaseFirestore.instance
                            .collection('drivers_inactivos')
                            .orderBy('diasInactivo', descending: true)
                            .limit(40) // 🛡️ Tope para no saturar lecturas
                            .get()
                            : FirebaseFirestore.instance
                            .collection('drivers_inactivos')
                            .where('estado', isEqualTo: filtroSeleccionado)
                            .limit(40) // 🛡️ Tope para no saturar lecturas
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData) {
                            return const Center(child: Text('Error al cargar datos'));
                          }

                          final docs = snapshot.data!.docs;

                          if (docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(30),
                                child: Text('No hay conductores en esta categoría'),
                              ),
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 700;

                              if (isMobile) {
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final data = docs[index].data() as Map<String, dynamic>;
                                    return _buildDriverCard(data);
                                  },
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 24,
                                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                                  columns: const [
                                    DataColumn(label: Text('Foto')),
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Celular')),
                                    DataColumn(label: Text('Estado')),
                                    DataColumn(label: Text('Contacto')),
                                    DataColumn(label: Text('Días')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: docs.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final nombre = '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}';
                                    final celular = data['celular'] ?? '';
                                    final estado = data['estado'] ?? '';
                                    final dias = data['diasInactivo'] ?? 0;
                                    final image = data['image'] ?? '';

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: image.toString().isNotEmpty ? NetworkImage(image) : null,
                                            child: image.toString().isEmpty ? const Icon(Icons.person) : null,
                                          ),
                                        ),
                                        DataCell(Text(nombre)),
                                        DataCell(Text(celular)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getEstadoColor(estado).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              estado,
                                              style: TextStyle(
                                                color: _getEstadoColor(estado),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Builder(
                                            builder: (_) {
                                              final ultimaPlantilla = data['ultimaPlantilla'];
                                              final cantidadMensajes = data['cantidadMensajes'] ?? 0;

                                              if (ultimaPlantilla == null) {
                                                return const Text('Sin contactar');
                                              }

                                              return Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    '✅ Contactado',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$cantidadMensajes mensajes',
                                                    style: const TextStyle(fontSize: 11),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        DataCell(Text(estado == 'sinLocation' ? 'Sin conexión' : dias.toString())),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.call, color: Colors.blue),
                                                onPressed: () async {
                                                  final url = 'tel:$celular';
                                                  await launchUrl(Uri.parse(url));
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.message, color: Colors.green),
                                                onPressed: () async {
                                                  String plantilla = '';
                                                  switch (estado) {
                                                    case 'activo':
                                                      plantilla = 'agradecimiento_conductores_activos';
                                                      break;
                                                    case 'dormido':
                                                      plantilla = 'reactivacion_conductores';
                                                      break;
                                                    case 'eliminable':
                                                      plantilla = 'seguimiento_conductores_inactivos';
                                                      break;
                                                    default:
                                                      plantilla = 'reactivacion_conductores';
                                                  }
                                                  await enviarPlantillaDriver(data: data, plantilla: plantilla);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> data) {
    final nombre = '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}';
    final celular = data['celular'] ?? '';
    final estado = data['estado'] ?? '';
    final dias = data['diasInactivo'] ?? 0;
    final image = data['image'] ?? '';

    return Card(
      color: Colors.grey.shade100,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: image.toString().isNotEmpty ? NetworkImage(image) : null,
              child: image.toString().isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('📱 $celular'),
                  Text(estado == 'sinLocation' ? '📡 Sin conexión' : '⏳ ${dias.toString()} días'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          await launchUrl(
                            Uri.parse('tel:$celular'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.call, color: Colors.blue, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () async {
                          String plantilla = '';
                          switch (estado) {
                            case 'activo':
                              plantilla = 'agradecimiento_conductores_activos';
                              break;
                            case 'dormido':
                              plantilla = 'reactivacion_conductores';
                              break;
                            case 'eliminable':
                              plantilla = 'seguimiento_conductores_inactivos';
                              break;
                            default:
                              plantilla = 'reactivacion_conductores';
                          }
                          await enviarPlantillaDriver(data: data, plantilla: plantilla);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.message, color: Colors.green, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activo': return Colors.green;
      case 'dormido': return Colors.orange;
      case 'eliminable': return Colors.red;
      case 'sinLocation': return Colors.grey;
      default: return Colors.blue;
    }
  }

  Future<void> exportarExcel() async {
    final excel = ex.Excel.createExcel();

    // ✅ OPTIMIZACIÓN EXTRA: Limitamos la exportación masiva de control a un tope alto (ej. 300) por sanidad
    final snapshot = await FirebaseFirestore.instance
        .collection('drivers_inactivos')
        .limit(300)
        .get();

    final docs = snapshot.docs;
    final activos = docs.where((d) => d['estado'] == 'activo');
    final dormidos = docs.where((d) => d['estado'] == 'dormido');
    final sinLocation = docs.where((d) => d['estado'] == 'sinLocation');

    void crearHoja(String nombreHoja, Iterable<QueryDocumentSnapshot> lista) {
      final sheet = excel[nombreHoja];
      sheet.appendRow([
        ex.TextCellValue('Nombres'),
        ex.TextCellValue('Apellidos'),
        ex.TextCellValue('Celular'),
        ex.TextCellValue('Documento'),
        ex.TextCellValue('Estado'),
        ex.TextCellValue('Dias'),
      ]);

      for (final doc in lista) {
        final data = doc.data() as Map<String, dynamic>;
        sheet.appendRow([
          ex.TextCellValue(data['nombres'] ?? ''),
          ex.TextCellValue(data['apellidos'] ?? ''),
          ex.TextCellValue(data['celular'] ?? ''),
          ex.TextCellValue(data['documento'] ?? ''),
          ex.TextCellValue(data['estado'] ?? ''),
          ex.TextCellValue('${data['diasInactivo'] ?? ''}'),
        ]);
      }
    }

    crearHoja('Activos', activos);
    crearHoja('Dormidos', dormidos);
    crearHoja('Sin Conexion', sinLocation);

    excel.delete('Sheet1');
    final bytes = excel.encode();
    if (bytes == null) return;

    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'conductores.xlsx')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  Future<void> enviarPlantillaDriver({
    required Map<String, dynamic> data,
    required String plantilla,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 15),
                Text("Enviando plantilla..."),
              ],
            ),
          );
        },
      );

      final callable = _functions.httpsCallable('enviarPlantillaConductores');
      await callable.call({
        "uid": data['uid'],
        "telefono": "57${data['celular']}",
        "nombre": data['nombres'] ?? '',
        "plantilla": plantilla,
      });

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("✅ Plantilla enviada")),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("❌ Error: $e")),
      );
    }
  }
}
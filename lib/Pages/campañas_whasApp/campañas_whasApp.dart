import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../common/main_layout.dart';

class CampanasWhatsAppPage extends StatefulWidget {
  const CampanasWhatsAppPage({super.key});

  @override
  State<CampanasWhatsAppPage> createState() => _CampanasWhatsAppPageState();
}

class _CampanasWhatsAppPageState extends State<CampanasWhatsAppPage> {

  final TextEditingController nombreController = TextEditingController();

  String plantillaSeleccionada = "expansion_conductores_2026_04";

  Future<void> enviarCampana() async {
    final nombre = nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa nombre de campaña")),
      );
      return;
    }

    try {

      final url = Uri.parse(
        'https://us-central1-apptaxi-e641d.cloudfunctions.net/enviarCampanaConductores',
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nombreCampana": nombre,
          "plantilla": plantillaSeleccionada,
        }),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Enviados: ${data['enviados']}"),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Campañas WhatsApp",
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Crear campaña",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre campaña",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: plantillaSeleccionada,
              items: const [
                DropdownMenuItem(
                  value: "expansion_conductores_2026_04",
                  child: Text("Expansión conductores"),
                ),
              ],
              onChanged: null, // 🔥 bloqueado (no se puede cambiar)
              decoration: const InputDecoration(
                labelText: "Plantilla",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: enviarCampana,
              icon: const Icon(Icons.campaign, color: Colors.black),
              label: const Text("Enviar campaña", style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold
              ),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Historial de campañas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('campañas_whatsapp')
                    .orderBy('fecha', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text("No hay campañas aún"));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {

                      final data = docs[index].data();

                      /// 🔥 obtener fecha
                      final timestamp = data['fecha'];
                      String fechaTexto = '';

                      if (timestamp != null) {
                        final date = timestamp.toDate();
                        fechaTexto = DateFormat('dd/MM/yyyy hh:mm a').format(date);
                      }

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.campaign, color: Colors.orange),
                          title: Text(data['nombre'] ?? ''),

                          /// 🔥 AQUÍ mostramos fecha + plantilla
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Plantilla: ${data['plantilla']}"),
                              const SizedBox(height: 4),
                              Text("📅 $fechaTexto"),
                            ],
                          ),

                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("✅ ${data['enviados']}"),
                              Text("❌ ${data['errores']}"),
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
      ),
    );
  }
}
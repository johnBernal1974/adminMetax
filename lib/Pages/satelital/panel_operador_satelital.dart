import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../common/main_layout.dart';

class PanelOperadoraPage extends StatefulWidget {
  const PanelOperadoraPage({super.key});

  @override
  State<PanelOperadoraPage> createState() => _PanelOperadoraPageState();
}

class _PanelOperadoraPageState extends State<PanelOperadoraPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _barrioController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _clienteController.dispose();
    _barrioController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  // 💾 1. Guardar datos en Firestore incluyendo versión en minúsculas para búsqueda insensible a mayúsculas
  Future<String?> _guardarServicio() async {
    try {
      final clienteTexto = _clienteController.text.trim();
      print("🔍 [FLUTTER] Intentando guardar servicio en Firestore (ManualServices)...");

      final docRef = await FirebaseFirestore.instance.collection('ManualServices').add({
        'cliente': clienteTexto,
        'cliente_lower': clienteTexto.toLowerCase(), // 👈 Clave para buscar sin importar mayúsculas/minúsculas
        'barrio': _barrioController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'tipo': 'manual_radio',
        'status': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("✅ [FLUTTER] ¡Servicio guardado con éxito! ID del documento: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ [FLUTTER] Error guardando servicio manual en Firestore: $e");
      return null;
    }
  }

  // 🚀 2. Enviar notificación a los drivers con logs detallados
  Future<void> _enviarSolicitudRadio() async {
    if (!_formKey.currentState!.validate()) {
      print("⚠️ [FLUTTER] Validación del formulario falló.");
      return;
    }

    setState(() => _isLoading = true);
    print("🚀 [FLUTTER] Iniciando proceso de envío por radio...");

    String? serviceId = await _guardarServicio();
    if (serviceId == null) {
      print("❌ [FLUTTER] Abortando envío: No se pudo guardar el documento en Firestore.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el servicio en la base de datos')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse('https://us-central1-apptaxi-e641d.cloudfunctions.net/broadcastManualService');

      final bodyData = {
        'serviceId': serviceId,
        'cliente': _clienteController.text.trim(),
        'barrio': _barrioController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'targetDriverId': 'dka103QPiqhk4cWDWBqBKeIzg9n2', // ID de prueba
      };

      print("🌐 [FLUTTER] Conectando con Cloud Function en: $url");
      print("📦 [FLUTTER] Payload enviado: ${jsonEncode(bodyData)}");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-metax-secret': 'para_enviar_notificaciones_2026_metax_user',
        },
        body: jsonEncode(bodyData),
      );

      print("📥 [FLUTTER] Respuesta recibida del servidor. Status Code: ${response.statusCode}");
      print("📄 [FLUTTER] Cuerpo de la respuesta: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ [FLUTTER] ¡Solicitud procesada correctamente por el servidor!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Servicio emitido por radio con éxito!')),
        );
        _clienteController.clear();
        _barrioController.clear();
        _direccionController.clear();
      } else {
        throw Exception('Código HTTP no exitoso: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ [FLUTTER] Excepción atrapada al hacer la petición HTTP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al enviar la notificación: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
      print("🏁 [FLUTTER] Proceso de envío finalizado.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'panel_operadora_page',
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        // 📐 Dividimos la pantalla en dos columnas (Izquierda: Formulario | Derecha: Listado en vivo)
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= COLUMNA IZQUIERDA: FORMULARIO =================
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const Text(
                        'Despacho de Servicios por Radio',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Busque un cliente frecuente o registre una nueva solicitud.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // 🔍 Buscador Autocomplete (Insensible a mayúsculas/minúsculas)
                      Autocomplete<Map<String, dynamic>>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          final queryText = textEditingValue.text.trim().toLowerCase();
                          if (queryText.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }

                          // Consultamos usando el campo auxiliar 'cliente_lower'
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection('ManualServices')
                              .orderBy('cliente_lower')
                              .startAt([queryText])
                              .endAt([queryText + '\uf8ff'])
                              .limit(5)
                              .get();

                          final Map<String, Map<String, dynamic>> unicos = {};
                          for (var doc in querySnapshot.docs) {
                            final data = doc.data();
                            final clienteNombre = data['cliente']?.toString() ?? '';
                            if (clienteNombre.isNotEmpty && !unicos.containsKey(clienteNombre)) {
                              unicos[clienteNombre] = {
                                'cliente': clienteNombre,
                                'barrio': data['barrio'] ?? '',
                                'direccion': data['direccion'] ?? '',
                              };
                            }
                          }
                          return unicos.values;
                        },
                        displayStringForOption: (option) => option['cliente'],
                        onSelected: (selection) {
                          setState(() {
                            _clienteController.text = selection['cliente'];
                            _barrioController.text = selection['barrio'];
                            _direccionController.text = selection['direccion'];
                          });
                          print("🔍 [FLUTTER] Cliente seleccionado: ${selection['cliente']}");
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          controller.text = _clienteController.text;
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Buscar Cliente (Mayúsculas/Minúsculas)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search, color: Colors.amber),
                            ),
                            onChanged: (value) {
                              _clienteController.text = value;
                            },
                            validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: Container(
                                width: 400,
                                color: Colors.white,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      leading: const Icon(Icons.person_pin, color: Colors.blueGrey),
                                      title: Text(option['cliente'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${option['barrio']} - ${option['direccion']}'),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _barrioController,
                        decoration: const InputDecoration(
                          labelText: 'Barrio / Sector',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección Exacta o Referencia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : () async {
                          await _guardarServicio();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Datos guardados localmente')),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Datos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _enviarSolicitudRadio,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Icon(Icons.podcasts, size: 24),
                        label: Text(_isLoading ? 'Transmitiendo...' : 'Lanzar solicitud por la app'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // ================= COLUMNA DERECHA: LISTADO EN VIVO DE SERVICIOS =================
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Servicios Solicitados (En Vivo)',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitoreo en tiempo real del estado de los servicios manuales.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('ManualServices')
                            .orderBy('createdAt', descending: true)
                            .limit(20)
                            .snapshots(),
                        builder: (context, snapshot) {
                          // ✅ Corrección: Usamos ConnectionState.waiting
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('No hay servicios registrados aún.', style: TextStyle(color: Colors.grey)),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final cliente = data['cliente'] ?? 'Sin nombre';
                              final barrio = data['barrio'] ?? '';
                              final direccion = data['direccion'] ?? '';
                              final status = data['status'] ?? 'pendiente';

                              // Formateamos la fecha y hora de Firestore (createdAt)
                              String fechaHoraFormateada = 'Reciente';
                              final timestamp = data['createdAt'];
                              if (timestamp != null && timestamp is Timestamp) {
                                final dateTime = timestamp.toDate();
                                final dia = dateTime.day.toString().padLeft(2, '0');
                                final mes = dateTime.month.toString().padLeft(2, '0');
                                final anio = dateTime.year;
                                final hora = dateTime.hour.toString().padLeft(2, '0');
                                final minuto = dateTime.minute.toString().padLeft(2, '0');

                                fechaHoraFormateada = '$dia/$mes/$anio - $hora:$minuto';
                              }

                              Color statusColor = Colors.orange;
                              if (status == 'aceptado') statusColor = Colors.green;
                              if (status == 'cancelado') statusColor = Colors.red;

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  // 🖱️ Evento al dar clic en la tarjeta de la derecha
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('Confirmar Reenvío de Servicio'),
                                          content: Text(
                                            '¿Quieres solicitar un servicio para este cliente?\n\n'
                                                '• Cliente: $cliente\n'
                                                '• Barrio: $barrio\n'
                                                '• Dirección: $direccion',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop(); // Cierra el alert
                                              },
                                              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop(); // Cierra el alert

                                                // Seteamos los datos en los controladores del formulario
                                                setState(() {
                                                  _clienteController.text = cliente;
                                                  _barrioController.text = barrio;
                                                  _direccionController.text = direccion;
                                                });

                                                // Ejecutamos la función de envío por radio de inmediato
                                                _enviarSolicitudRadio();
                                              },
                                              child: const Text('Solicitar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(cliente, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      Text(
                                        fechaHoraFormateada,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text('Barrio: $barrio\nDir: $direccion'),
                                  isThreeLine: true,
                                  trailing: Chip(
                                    label: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: statusColor,
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
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/foundation.dart';
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

  // 🧠 Lista en memoria para guardar los clientes frecuentes sin gastar lecturas
  List<Map<String, dynamic>> _listaClientesFrecuentes = [];
  bool _cargandoClientes = true;


  @override
  void initState() {
    super.initState();
    _cargarClientesFrecuentes(); // 📥 Cargamos de la BD una sola vez al abrir la página
  }

  // 📥 Función para leer la base de datos solo una vez
  Future<void> _cargarClientesFrecuentes() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ManualServices')
          .orderBy('createdAt', descending: true)
          .get();

      final Map<String, Map<String, dynamic>> clientesUnicos = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final nombre = data['cliente']?.toString().trim() ?? '';
        if (nombre.isNotEmpty && !clientesUnicos.containsKey(nombre)) {
          clientesUnicos[nombre] = {
            'cliente': nombre,
            'barrio': data['barrio'] ?? '',
            'direccion': data['direccion'] ?? '',
          };
        }
      }

      if (mounted) {
        setState(() {
          _listaClientesFrecuentes = clientesUnicos.values.toList();
          _cargandoClientes = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error cargando clientes frecuentes: $e');
      if (mounted) setState(() => _cargandoClientes = false);
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _barrioController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitudRadio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final travelRef = FirebaseFirestore.instance.collection('TravelInfo').doc();
      final travelId = travelRef.id;

      final cliente = _clienteController.text.trim();
      final barrio = _barrioController.text.trim();
      final direccion = _direccionController.text.trim();

      // 1. Guardamos en TravelInfo
      await travelRef.set({
        'id': travelId,
        'idClient': travelId,
        'cliente': cliente,
        'barrio': barrio,
        'direccion': direccion,
        'origin': '$barrio, $direccion',
        'destination': 'Servicio por Radio Operador',
        'fromLat': 4.1420,
        'fromLng': -73.6266,
        'toLat': 4.1420,
        'toLng': -73.6266,
        'tarifa': 0.0,
        'tarifaInicial': 0.0,
        'tarifaDescuento': 0.0,
        'totalClientePaga': 0.0,
        'metodo_pago': 'Efectivo',
        'apuntes': 'Barrio: $barrio - Dir: $direccion (Vía Operador)',
        'tipo_servicio': 'radio',
        'status': 'created',
        'idDriver': '',
        'distancia': 0.0,
        'tiempoViaje': 0.0,
        'horaSolicitudViaje': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Guardamos en ManualServices para el panel derecho e historial del menú
      await FirebaseFirestore.instance.collection('ManualServices').add({
        'travelId': travelId,
        'cliente': cliente,
        'cliente_lower': cliente.toLowerCase(),
        'barrio': barrio,
        'direccion': direccion,
        'status': 'enviado',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. 🔄 Recargamos la lista en memoria al instante para que el cliente quede disponible en el Dropdown
      await _cargarClientesFrecuentes();

      // 4. Disparamos la Cloud Function para la push
      final url = Uri.parse('https://us-central1-apptaxi-e641d.cloudfunctions.net/broadcastManualService');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-metax-secret': 'para_enviar_notificaciones_2026_metax_user',
        },
        body: jsonEncode({
          'serviceId': travelId,
          'cliente': cliente,
          'barrio': barrio,
          'direccion': direccion,
          'targetDriverId': 'dka103QPiqhk4cWDWBqBKeIzg9n2',
          'tipo_servicio': 'radio',
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ ¡Servicio de radio emitido con éxito!'), backgroundColor: Colors.green),
      );

      _clienteController.clear();
      _barrioController.clear();
      _direccionController.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
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
                        'Seleccione un cliente frecuente o registre una nueva solicitud.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // 📋 MENÚ DESPLEGABLE USANDO LA MEMORIA LOCAL
                      _cargandoClientes
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<String>(
                        value: _clienteController.text.isNotEmpty &&
                            _listaClientesFrecuentes.any((element) => element['cliente'] == _clienteController.text)
                            ? _clienteController.text
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar Cliente Frecuente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_search, color: Colors.amber),
                        ),
                        hint: const Text('-- Seleccione un cliente --'),
                        isExpanded: true,
                        items: _listaClientesFrecuentes.map((item) {
                          final nombreCliente = item['cliente'] as String;
                          return DropdownMenuItem<String>(
                            value: nombreCliente,
                            child: Text(nombreCliente, style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (String? nuevoValor) {
                          if (nuevoValor != null) {
                            final clienteEncontrado = _listaClientesFrecuentes.firstWhere(
                                  (element) => element['cliente'] == nuevoValor,
                              orElse: () => {},
                            );
                            if (clienteEncontrado.isNotEmpty) {
                              // 🪄 Autocompletamos al instante desde la memoria
                              setState(() {
                                _clienteController.text = clienteEncontrado['cliente'];
                                _barrioController.text = clienteEncontrado['barrio'];
                                _direccionController.text = clienteEncontrado['direccion'];
                              });
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // 📋 2. CAJA DE TEXTO DEL CLIENTE
                      TextFormField(
                        controller: _clienteController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      // 📋 3. CAJA DE TEXTO DEL BARRIO
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

                      // 📋 4. CAJA DE TEXTO DE LA DIRECCIÓN
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección Exacta o Referencia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                      ), const SizedBox(height: 24),
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
                  const Divider(height: 40, thickness: 2), // ➗ Separador para la sección de historial de radio

                  // 📜 SECCIÓN DE HISTORIAL DE SERVICIOS DE RADIO FINALIZADOS
                  const Text(
                    'Historial de Servicios de Radio (Finalizados)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Últimos servicios de radio completados con éxito.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                      SizedBox(
                        height: 250, // Altura fija para el listado del historial en la columna izquierda
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('TravelHistory')
                              .where('to', isEqualTo: 'Servicio por Radio Operador')
                              .limit(20)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text('No hay servicios de radio finalizados.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              );
                            }

                            final docs = snapshot.data!.docs;

                            // 🔄 Ordenamos localmente por 'finalViaje' para evitar requerir un índice compuesto en Firestore
                            docs.sort((a, b) {
                              var aTime = (a.data() as Map<String, dynamic>)['finalViaje'] as Timestamp?;
                              var bTime = (b.data() as Map<String, dynamic>)['finalViaje'] as Timestamp?;
                              if (aTime == null || bTime == null) return 0;
                              return bTime.compareTo(aTime);
                            });

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data = docs[index].data() as Map<String, dynamic>;
                                final cliente = data['usuario'] ?? data['cliente'] ?? 'Cliente';
                                final barrio = data['barrio'] ?? '';
                                final direccion = data['direccion'] ?? '';
                                final placa = data['placa'] ?? 'S/P';

                                // Formatear fecha de finalización (finalViaje)
                                String fechaFinStr = 'N/A';
                                final finalViaje = data['finalViaje'];
                                if (finalViaje != null && finalViaje is Timestamp) {
                                  final dt = finalViaje.toDate();
                                  fechaFinStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                }

                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    dense: true,
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(cliente, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.black54, width: 0.8),
                                          ),
                                          child: Text(
                                            placa.length >= 6 ? '${placa.substring(0, 3)}-${placa.substring(3)}' : placa,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$barrio - $direccion', style: const TextStyle(fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text('Finalizado: $fechaFinStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                              final travelId = data['travelId'] ?? '';
                              final cliente = data['cliente'] ?? 'Sin nombre';
                              final barrio = data['barrio'] ?? '';
                              final direccion = data['direccion'] ?? '';

                              // 🔄 StreamBuilder hijo para escuchar en tiempo real status, placa y tiempos en TravelInfo
                              return StreamBuilder<DocumentSnapshot>(
                                stream: travelId.isNotEmpty
                                    ? FirebaseFirestore.instance.collection('TravelInfo').doc(travelId).snapshots()
                                    : const Stream.empty(),
                                builder: (context, travelSnapshot) {
                                  String statusReal = data['status'] ?? 'pendiente';
                                  String placaVehiculo = '';
                                  Timestamp? acceptedAtTimestamp;
                                  Timestamp? horaInicioViajeTimestamp;
                                  Timestamp? finishedAtTimestamp;

                                  if (travelSnapshot.hasData && travelSnapshot.data!.exists) {
                                    final travelData = travelSnapshot.data!.data() as Map<String, dynamic>?;
                                    if (travelData != null) {
                                      statusReal = travelData['status'] ?? statusReal;
                                      placaVehiculo = travelData['placa'] ?? '';
                                      acceptedAtTimestamp = travelData['acceptedAt'] as Timestamp?;
                                      horaInicioViajeTimestamp = travelData['horaInicioViaje'] as Timestamp?;
                                      finishedAtTimestamp = travelData['finishedAt'] as Timestamp?;
                                    }
                                  }

                                  // 🚫 FILTRO: Si el estado real es 'finished' (o 'cancelled'), ocultamos completamente la tarjeta de la columna derecha
                                  if (statusReal == 'finished' || statusReal == 'cancelled') {
                                    return const SizedBox.shrink();
                                  }

                                  // 🎨 Traducción de estados a textos y colores amigables
                                  String textoEstado = 'Pendiente';
                                  Color statusColor = Colors.orange;

                                  switch (statusReal) {
                                    case 'created':
                                    case 'enviado':
                                      textoEstado = 'Enviado';
                                      statusColor = Colors.orange;
                                      break;
                                    case 'accepted':
                                      textoEstado = 'Aceptado';
                                      statusColor = Colors.blue;
                                      break;
                                    case 'driver_is_waiting':
                                      textoEstado = 'En la puerta';
                                      statusColor = Colors.purple;
                                      break;
                                    case 'started':
                                      textoEstado = 'Iniciado';
                                      statusColor = Colors.green;
                                      break;
                                    default:
                                      textoEstado = statusReal.toUpperCase();
                                      statusColor = Colors.blueGrey;
                                  }

                                  // 🕒 Formateador de fechas y horas con año
                                  String formatearTimestamp(dynamic timestamp) {
                                    if (timestamp != null && timestamp is Timestamp) {
                                      final dateTime = timestamp.toDate();
                                      final dia = dateTime.day.toString().padLeft(2, '0');
                                      final mes = dateTime.month.toString().padLeft(2, '0');
                                      final anio = dateTime.year;
                                      final hora = dateTime.hour.toString().padLeft(2, '0');
                                      final minuto = dateTime.minute.toString().padLeft(2, '0');
                                      return '$dia/$mes/$anio - $hora:$minuto';
                                    }
                                    return 'N/A';
                                  }

                                  final horaSolicitudStr = formatearTimestamp(data['createdAt']);
                                  final horaAceptacionStr = acceptedAtTimestamp != null ? formatearTimestamp(acceptedAtTimestamp) : null;
                                  final horaInicioStr = horaInicioViajeTimestamp != null ? formatearTimestamp(horaInicioViajeTimestamp) : null;
                                  final horaFinStr = finishedAtTimestamp != null ? formatearTimestamp(finishedAtTimestamp) : null;

                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: InkWell(
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
                                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                                                  onPressed: () {
                                                    Navigator.of(dialogContext).pop();
                                                    setState(() {
                                                      _clienteController.text = cliente;
                                                      _barrioController.text = barrio;
                                                      _direccionController.text = direccion;
                                                    });
                                                    _enviarSolicitudRadio();
                                                  },
                                                  child: const Text('Solicitar'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 📋 COLUMNA IZQUIERDA: Información del servicio
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(cliente, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                  const SizedBox(height: 4),
                                                  Text('Barrio: $barrio\nDir: $direccion', style: const TextStyle(fontSize: 10)),
                                                  const Divider(height: 16, thickness: 1),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text('Hora de solicitud:', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w400)),
                                                      Text(horaSolicitudStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black)),
                                                    ],
                                                  ),
                                                  if (horaAceptacionStr != null) ...[
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        const Text('Hora de aceptación:', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w400)),
                                                        Text(horaAceptacionStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black)),
                                                      ],
                                                    ),
                                                  ],
                                                  if (horaInicioStr != null) ...[
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        const Text('Hora de inicio:', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w400)),
                                                        Text(horaInicioStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black)),
                                                      ],
                                                    ),
                                                  ],
                                                  if (horaFinStr != null) ...[
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        const Text('Hora de finalización:', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w400)),
                                                        Text(horaFinStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black)),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // 🔲 COLUMNA DERECHA: Estado y Placa
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Chip(
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                                  label: Text(
                                                    textoEstado,
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                  backgroundColor: statusColor,
                                                ),
                                                if (placaVehiculo.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.black, width: 1.0),
                                                    ),
                                                    child: Text(
                                                      placaVehiculo.length >= 6
                                                          ? '${placaVehiculo.substring(0, 3)}-${placaVehiculo.substring(3)}'
                                                          : placaVehiculo,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                        fontSize: 13,
                                                        letterSpacing: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
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
            ),
          ],
        ),
      ),
    );
  }
}
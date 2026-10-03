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

  // 🔎 BUSCADOR DE CLIENTES FRECUENTES
  final TextEditingController _buscarClienteController =
  TextEditingController();
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _barrioController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

// 💳 FORMA DE PAGO DEL SERVICIO DE RADIO
  String _metodoPagoSeleccionado = 'Efectivo';

// 🚕 REQUERIMIENTOS ESPECIALES DEL SERVICIO DE RADIO
  final Set<String> _requerimientosSeleccionados = {};

  // 🏢 INDICA SI EL CONDUCTOR DEBE DEJAR $1.000 EN PORTERÍA
  bool _dejarDineroPorteria = false;

  bool _isLoading = false;
  bool _isSaving = false;

// ✏️ ID del cliente cuando estamos editándolo
  String? _editingClientId;

// 👤 Cliente frecuente seleccionado para solicitar un servicio
  String? _clienteFrecuenteSeleccionadoId;

// 🆕 Indica que estamos creando un cliente nuevo
  bool _creandoClienteNuevo = false;

  // 🧠 Lista en memoria para guardar los clientes frecuentes sin gastar lecturas
  List<Map<String, dynamic>> _listaClientesFrecuentes = [];
  bool _cargandoClientes = true;

  @override
  void initState() {
    super.initState();
    _cargarClientesFrecuentes(); // 📥 Cargamos de la BD una sola vez al abrir la página
  }

  // 📥 Función para leer los clientes frecuentes desde 'ManualClients'
  Future<void> _cargarClientesFrecuentes() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ManualClients')
          .orderBy('cliente', descending: false)
          .get();

      final List<Map<String, dynamic>> listaCargada = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        listaCargada.add({
          'id': doc.id,
          'cliente': data['cliente'] ?? '',
          'barrio': data['barrio'] ?? '',
          'direccion': data['direccion'] ?? '',
          'celular': data['celular'] ?? '',
          'dejarDineroPorteria': data['dejarDineroPorteria'] ?? false,
        });
      }

      if (mounted) {
        setState(() {
          _listaClientesFrecuentes = listaCargada;
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
    _buscarClienteController.dispose();
    _clienteController.dispose();
    _barrioController.dispose();
    _direccionController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitudRadio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final travelRef =
      FirebaseFirestore.instance.collection('TravelInfo').doc();
      final travelId = travelRef.id;

      final cliente = _clienteController.text.trim();
      final barrio = _barrioController.text.trim();
      final direccion = _direccionController.text.trim();
      final celular = _celularController.text.trim();

      // =====================================================
// 👤 SI ES CLIENTE NUEVO, LO GUARDAMOS AUTOMÁTICAMENTE
// AL MISMO TIEMPO QUE SE LANZA EL SERVICIO
// =====================================================
      if (_creandoClienteNuevo) {
        await FirebaseFirestore.instance
            .collection('ManualClients')
            .add({
          'cliente': cliente,
          'cliente_lower': cliente.toLowerCase(),
          'barrio': barrio,
          'direccion': direccion,
          'celular': celular,
          'dejarDineroPorteria': _dejarDineroPorteria,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }


      // 1. Guardamos en TravelInfo
      await travelRef.set({
        'id': travelId,
        'idClient': travelId,
        'cliente': cliente,
        'barrio': barrio,
        'direccion': direccion,
        'celular': celular,
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

        // 💳 Forma de pago
        'metodo_pago': _metodoPagoSeleccionado,

        // 🚕 Requerimientos especiales
        'requerimientos': _requerimientosSeleccionados.toList(),

        // 🏢 Configuración de portería
        'dejarDineroPorteria': _dejarDineroPorteria,

        'apuntes': '',
        'tipo_servicio': 'radio',
        'status': 'created',
        'idDriver': '',
        'distancia': 0.0,
        'tiempoViaje': 0.0,
        'horaSolicitudViaje': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Guardamos en ManualServices
      await FirebaseFirestore.instance.collection('ManualServices').add({
        'travelId': travelId,
        'cliente': cliente,
        'cliente_lower': cliente.toLowerCase(),
        'barrio': barrio,
        'direccion': direccion,
        'celular': celular,

        // 💳🚕 Datos específicos de este servicio
        'metodo_pago': _metodoPagoSeleccionado,
        'requerimientos': _requerimientosSeleccionados.toList(),

        // 🏢 Configuración guardada del cliente
        'dejarDineroPorteria': _dejarDineroPorteria,

        'status': 'enviado',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _cargarClientesFrecuentes();

      // 3. Cloud Function de notificación push
      final url = Uri.parse(
        'https://us-central1-apptaxi-e641d.cloudfunctions.net/broadcastManualService',
      );

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
          'celular': celular,

          // 💳🚕 Datos del servicio
          'metodo_pago': _metodoPagoSeleccionado,
          'requerimientos': _requerimientosSeleccionados.toList(),

          // 🏢 Configuración del cliente
          'dejarDineroPorteria': _dejarDineroPorteria,
          'tipo_servicio': 'radio',
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Servicio de radio emitido con éxito!'),
          backgroundColor: Colors.green,
        ),
      );

      // 🧹 Después de lanzar el servicio volvemos al estado inicial
      setState(() {
        // Ningún cliente seleccionado ni en edición
        _editingClientId = null;
        _clienteFrecuenteSeleccionadoId = null;
        _creandoClienteNuevo = false;

        // Limpiamos los datos del cliente
        _clienteController.clear();
        _barrioController.clear();
        _direccionController.clear();
        _celularController.clear();

        // Reiniciamos las condiciones del servicio
        _metodoPagoSeleccionado = 'Efectivo';
        _requerimientosSeleccionados.clear();
        _dejarDineroPorteria = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =====================================================
// 🔎 SELECCIONAR CLIENTE DESDE EL BUSCADOR RÁPIDO
// =====================================================
  void _seleccionarClienteDesdeBuscador(Map<String, dynamic> cliente) {
    setState(() {
      _clienteFrecuenteSeleccionadoId = cliente['id']?.toString();
      _creandoClienteNuevo = false;
      _editingClientId = null;

      _clienteController.text =
          (cliente['cliente'] ?? '').toString();

      _barrioController.text =
          (cliente['barrio'] ?? '').toString();

      _direccionController.text =
          (cliente['direccion'] ?? '').toString();

      _celularController.text =
          (cliente['celular'] ?? '').toString();

      _dejarDineroPorteria =
          cliente['dejarDineroPorteria'] == true;

      // Limpiamos la búsqueda después de seleccionar
      _buscarClienteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Despacho de servicios',
      content: Padding(
        padding: const EdgeInsets.all(24.0),
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
                        'DESPACHO DE SERVICIOS POR OPERADORA',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

// =====================================================
// 👤 ACCIONES DEL CLIENTE
// =====================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [

                          // 🆕 NUEVO CLIENTE
                          if (!_creandoClienteNuevo && _editingClientId == null) ...[
                            TextButton.icon(
                              onPressed: () {
                                _limpiarFormularioEdicion();
                              },
                              icon: const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.blueGrey,
                              ),
                              label: const Text(
                                'Nuevo cliente',
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],

                          if (_creandoClienteNuevo || _editingClientId != null) ...[
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  // Volvemos al estado inicial
                                  _editingClientId = null;
                                  _clienteFrecuenteSeleccionadoId = null;
                                  _creandoClienteNuevo = false;

                                  // Limpiamos los datos cargados
                                  _clienteController.clear();
                                  _barrioController.clear();
                                  _direccionController.clear();
                                  _celularController.clear();

                                  // Reiniciamos portería
                                  _dejarDineroPorteria = false;
                                });
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.grey,
                              ),
                              label: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                          ],

                          // 💾 GUARDAR / ACTUALIZAR CLIENTE
                          if (_creandoClienteNuevo || _editingClientId != null)
                            OutlinedButton.icon(
                              onPressed: (_isSaving ||
                                  _isLoading ||
                                  _clienteController.text.trim().isEmpty ||
                                  _barrioController.text.trim().isEmpty ||
                                  _direccionController.text.trim().isEmpty ||
                                  _celularController.text.trim().isEmpty)
                                  ? null
                                  : _guardarClienteFrecuente,
                              icon: _isSaving
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Icon(
                                _editingClientId != null
                                    ? Icons.save_as
                                    : Icons.person_add,
                                size: 22,
                              ),
                              label: Text(
                                _isSaving
                                    ? 'Guardando...'
                                    : (_editingClientId != null
                                    ? 'Actualizar Cliente'
                                    : 'Guardar Cliente'),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _editingClientId != null
                                    ? Colors.blue[800]
                                    : Colors.green[800],
                                side: BorderSide(
                                  color: _editingClientId != null
                                      ? Colors.blue.shade700
                                      : Colors.green.shade700,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

// =====================================================
// 👤 SELECTOR DE CLIENTE FRECUENTE
// =====================================================

                      // =====================================================
// 🔎 BUSCADOR DE CLIENTES FRECUENTES
// =====================================================


                    if (!_creandoClienteNuevo) ...[
                        TextField(
                        controller: _buscarClienteController,
                        decoration: InputDecoration(
                          labelText: 'Buscar cliente frecuente',
                          hintText: 'Ej: conjunto, acacias...',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.blueGrey,
                          ),
                          suffixIcon: _buscarClienteController.text.isNotEmpty
                              ? IconButton(
                            tooltip: 'Limpiar búsqueda',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _buscarClienteController.clear();
                              });
                            },
                          )
                              : null,
                        ),
                        onChanged: (valor) {
                          setState(() {});
                        },
                      ),

                      // =====================================================
// 🔎 RESULTADOS RÁPIDOS DEL BUSCADOR
// =====================================================
                      if (_buscarClienteController.text.trim().isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final busqueda =
                            _buscarClienteController.text.trim().toLowerCase();

                            final resultados = _listaClientesFrecuentes.where((cliente) {
                              final nombre =
                              (cliente['cliente'] ?? '').toString().toLowerCase();

                              return nombre.contains(busqueda);
                            }).toList();

                            if (resultados.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'No se encontraron clientes',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }

                            return Container(
                              constraints: const BoxConstraints(
                                maxHeight: 220,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: resultados.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final cliente = resultados[index];

                                  final nombre =
                                  (cliente['cliente'] ?? '').toString();

                                  final direccion =
                                  (cliente['direccion'] ?? '').toString();

                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.person_outline,
                                      color: Colors.blueGrey,
                                    ),
                                    title: Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: direccion.isNotEmpty
                                        ? Text(direccion)
                                        : null,
                                    onTap: () {
                                      _seleccionarClienteDesdeBuscador(cliente);
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 12),



                    Builder(
                        builder: (context) {
                          final textoBusqueda =
                          _buscarClienteController.text.trim().toLowerCase();

                          final clientesFiltrados = textoBusqueda.isEmpty
                              ? _listaClientesFrecuentes
                              : _listaClientesFrecuentes.where((cliente) {
                            final nombre =
                            (cliente['cliente'] ?? '').toString().toLowerCase();

                            return nombre.contains(textoBusqueda);
                          }).toList();

                          return _cargandoClientes
                              ? const LinearProgressIndicator()
                              : DropdownButtonFormField<String>(
                            value: clientesFiltrados.any(
                                    (element) => element['cliente'] == _clienteController.text)
                                ? clientesFiltrados.firstWhere(
                                  (element) => element['cliente'] == _clienteController.text,
                              orElse: () => {},
                            )['id']
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar Cliente Frecuente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_search, color: Colors.amber),
                        ),
                        hint: const Text('-- Seleccione un cliente --'),
                        isExpanded: true,

// 👁️ Así se muestra el cliente cuando el dropdown está CERRADO.
// No mostramos aquí los botones editar/eliminar.
                        selectedItemBuilder: (BuildContext context) {
                          return _listaClientesFrecuentes.map<Widget>((item) {
                            final nombreCliente = item['cliente'] as String;
                            final direccion = item['direccion'] as String;

                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$nombreCliente ($direccion)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },

                          items: clientesFiltrados.map((item) {
                          final idDoc = item['id'] as String;
                          final nombreCliente = item['cliente'] as String;
                          final direccion = item['direccion'] as String;

                          return DropdownMenuItem<String>(
                            value: idDoc,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '$nombreCliente ($direccion)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Estos botones aparecerán únicamente al abrir el dropdown
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                      tooltip: 'Editar cliente',
                                      onPressed: () {
                                        Navigator.of(context).pop();

                                        setState(() {
                                          // ✏️ Entramos explícitamente en modo edición
                                          _editingClientId = idDoc;
                                          _clienteFrecuenteSeleccionadoId = idDoc;
                                          _creandoClienteNuevo = false;

                                          _clienteController.text = nombreCliente;
                                          _barrioController.text = item['barrio'] ?? '';
                                          _direccionController.text = direccion;
                                          _celularController.text = item['celular'] ?? '';

                                          _dejarDineroPorteria =
                                              item['dejarDineroPorteria'] == true;
                                        });
                                      },
                                    ),

                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                      tooltip: 'Eliminar cliente',
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _confirmarYEliminarCliente(idDoc, nombreCliente);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? nuevoId) {
                          if (nuevoId != null) {
                            final clienteEncontrado = _listaClientesFrecuentes.firstWhere(
                                  (element) => element['id'] == nuevoId,
                              orElse: () => {},
                            );

                            if (clienteEncontrado.isNotEmpty) {
                              setState(() {
                                // 👤 Cliente frecuente seleccionado para solicitar servicio
                                _clienteFrecuenteSeleccionadoId = nuevoId;
                                _creandoClienteNuevo = false;

                                // No estamos editando
                                _editingClientId = null;

                                // Conservamos internamente los datos porque se necesitan
                                // para lanzar la solicitud de radio
                                _clienteController.text =
                                    clienteEncontrado['cliente'] ?? '';
                                _barrioController.text =
                                    clienteEncontrado['barrio'] ?? '';
                                _direccionController.text =
                                    clienteEncontrado['direccion'] ?? '';
                                _celularController.text =
                                    clienteEncontrado['celular'] ?? '';

                                _dejarDineroPorteria =
                                    clienteEncontrado['dejarDineroPorteria'] == true;
                              });
                            }
                          }
                        },
                          );
                        },
                    ),

                    ],

                      const SizedBox(height: 16),

                      if (_creandoClienteNuevo || _editingClientId != null) ...[

                      TextFormField(
                        controller: _clienteController,
                        onChanged: (value) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _barrioController,
                        onChanged: (value) => setState(() {}),
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
                        onChanged: (value) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Dirección Exacta o Referencia',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _celularController,
                        onChanged: (value) => setState(() {}),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Número de Celular',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 24),
                    ],
// =====================================================
// 👤 DATOS DEL CLIENTE FRECUENTE SELECCIONADO
// =====================================================
                      if (!_creandoClienteNuevo &&
                          _editingClientId == null &&
                          _clienteFrecuenteSeleccionadoId != null) ...[

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Datos del cliente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  const Icon(Icons.person, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _clienteController.text,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(Icons.location_city, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _barrioController.text,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(Icons.home, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _direccionController.text,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _celularController.text,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(),
                              const SizedBox(height: 6),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _dejarDineroPorteria,
                                    onChanged: null,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _dejarDineroPorteria
                                          ? 'Se tienen que dejar \$1.000 en portería.'
                                          : 'No se deben dejar \$1.000 en portería.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _dejarDineroPorteria
                                            ? Colors.orange.shade800
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
/// =====================================================
// 🏢 PAGO EN PORTERÍA
// =====================================================

// ✏️ SOLO NUEVO CLIENTE O CLIENTE EN EDICIÓN
// En estos dos casos sí permitimos modificar la portería.
                      if (_creandoClienteNuevo || _editingClientId != null) ...[
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'El conductor debe dejar \$1.000 en portería',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Marque esta opción únicamente cuando aplique.',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _dejarDineroPorteria,
                          onChanged: (valor) {
                            setState(() {
                              _dejarDineroPorteria = valor ?? false;
                            });
                          },
                        ),
                      ],
    const SizedBox(height: 24),

// =====================================================
// 🚕 TARJETA - SOLICITUD DEL SERVICIO
// =====================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const Text(
                              'SOLICITAR SERVICIO',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // =====================================================
                            // 💳 FORMA DE PAGO
                            // =====================================================
                            const Text(
                              'Forma de pago',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Efectivo',
                          'Nequi',
                          'Daviplata',
                          'Llave',
                        ].map((opcion) {
                          return ChoiceChip(
                            label: Text(
                              opcion,
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                            selected: _metodoPagoSeleccionado == opcion,
                            onSelected: (seleccionado) {
                              if (seleccionado) {
                                setState(() {
                                  _metodoPagoSeleccionado = opcion;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

// =====================================================
// 🚕 REQUERIMIENTOS ESPECIALES
// =====================================================
                      const Text(
                        'Requerimientos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Con Baúl',
                          'Portabicicletas',
                          'Silla de ruedas',
                          'Mascotas',
                          'Aire acondicionado',
                          'Cables de inicio',
                          'Compresor',
                        ].map((opcion) {
                          final seleccionado =
                          _requerimientosSeleccionados.contains(opcion);

                          return FilterChip(
                            label: Text(
                              opcion,
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                            selected: seleccionado,
                            onSelected: (valor) {
                              setState(() {
                                if (valor) {
                                  _requerimientosSeleccionados.add(opcion);
                                } else {
                                  _requerimientosSeleccionados.remove(opcion);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: (_isLoading || _isSaving || _clienteController.text.trim().isEmpty || _barrioController.text.trim().isEmpty || _direccionController.text.trim().isEmpty || _celularController.text.trim().isEmpty)
                                ? null
                                : _enviarSolicitudRadio,
                            icon: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Icon(Icons.podcasts, size: 24),
                            label: Text(_isLoading ? 'Transmitiendo...' : 'Lanzar servicio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        ],
                      ),
                    ),

                      const SizedBox(height: 24),

                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // ================= COLUMNA DERECHA: LISTADO EN VIVO DE SERVICIOS =================
            Expanded(
              flex: 1,
              child: _ServiciosEnVivoPanel(
                onRelanzarServicio: _relanzarServicioExistente,
                onCancelarServicio: _cancelarServicioManual,
                onOcultarServicio: _ocultarServicioManual,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🗑️ Función para eliminar un cliente frecuente de 'ManualClients'
  Future<void> _eliminarClienteFrecuente(String idDoc, String nombreCliente) async {
    try {
      await FirebaseFirestore.instance.collection('ManualClients').doc(idDoc).delete();

      // Recargamos la lista para que desaparezca del menú
      await _cargarClientesFrecuentes();

      // Si el formulario tenía los datos de este cliente, lo limpiamos opcionalmente
      if (_clienteController.text == nombreCliente) {
        _clienteController.clear();
        _barrioController.clear();
        _direccionController.clear();
        _celularController.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🗑️ Cliente "$nombreCliente" eliminado'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🗑️ Función para confirmar y eliminar un cliente frecuente de 'ManualClients'
  Future<void> _confirmarYEliminarCliente(String idDoc, String nombreCliente) async {
    // Mostramos primero el diálogo de confirmación
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Cliente Frecuente'),
          content: Text('¿Estás seguro de que deseas eliminar a "$nombreCliente"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), // Retorna falso
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true), // Retorna verdadero
              child: const Text('Sí, eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    // Si el usuario confirma (presiona "Sí, eliminar"), procedemos con el borrado
    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection('ManualClients').doc(idDoc).delete();

        // Recargamos la lista para que desaparezca del menú
        await _cargarClientesFrecuentes();

        // Si el formulario tenía los datos de este cliente, lo limpiamos
        if (_clienteController.text == nombreCliente) {
          _clienteController.clear();
          _barrioController.clear();
          _direccionController.clear();
          _celularController.clear();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🗑️ Cliente "$nombreCliente" eliminado'), backgroundColor: Colors.redAccent),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _relanzarServicioExistente(
      String travelId,
      String cliente,
      String barrio,
      String direccion,
      String celular,
      ) async {
    try {
      // 🔄 Recuperar las condiciones originales del servicio
      final travelDoc = await FirebaseFirestore.instance
          .collection('TravelInfo')
          .doc(travelId)
          .get();

      final travelData = travelDoc.data() ?? {};

      final metodoPago =
      (travelData['metodo_pago'] ?? 'Efectivo').toString();

      final requerimientos =
      List<String>.from(travelData['requerimientos'] ?? []);

      final dejarDineroPorteria =
          travelData['dejarDineroPorteria'] == true;

      // 🔄 Reactivar el viaje para que pueda ser aceptado nuevamente
      await FirebaseFirestore.instance
          .collection('TravelInfo')
          .doc(travelId)
          .update({
        'status': 'created',
        'idDriver': '',
        'placa': FieldValue.delete(),
        'acceptedAt': FieldValue.delete(),
        'driverWaitingAt': FieldValue.delete(),
        'horaInicioViaje': FieldValue.delete(),
        'cancelledAt': FieldValue.delete(),
        'cancelledBy': FieldValue.delete(),
        'cancelReason': FieldValue.delete(),
      });

      // 📡 Relanzar el mismo servicio
      final url = Uri.parse(
        'https://us-central1-apptaxi-e641d.cloudfunctions.net/broadcastManualService',
      );

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
          'celular': celular,

          // 💳🚕 Conservamos las condiciones originales
          'metodo_pago': metodoPago,
          'requerimientos': requerimientos,
          'dejarDineroPorteria': dejarDineroPorteria,
          'tipo_servicio': 'radio',
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 ¡Servicio retransmitido con éxito!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al relanzar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // 👁️ OCULTAR TARJETA DE UN SERVICIO CANCELADO POR EL CONDUCTOR
  Future<void> _ocultarServicioManual(String manualDocId) async {
    try {
      if (manualDocId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('ManualServices')
          .doc(manualDocId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio ocultado de la lista'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al ocultar el servicio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _cancelarServicioManual(String travelId, String manualDocId) async {
    try {
      if (travelId.isNotEmpty) {
        final travelRef = FirebaseFirestore.instance.collection('TravelInfo').doc(travelId);
        final docSnapshot = await travelRef.get();

        if (docSnapshot.exists) {
          await travelRef.update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });
        } else {
          await travelRef.set({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      if (manualDocId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('ManualServices').doc(manualDocId).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Solicitud cancelada y removida'), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al cancelar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _guardarClienteFrecuente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (kDebugMode) {
        print('✏️ ID CLIENTE EN EDICIÓN: $_editingClientId');
      }

      final cliente = _clienteController.text.trim();
      final barrio = _barrioController.text.trim();
      final direccion = _direccionController.text.trim();
      final celular = _celularController.text.trim();

      if (_editingClientId != null) {
        // ✏️ Si estamos editando, actualizamos el documento existente
        await FirebaseFirestore.instance.collection('ManualClients').doc(_editingClientId).update({
          'cliente': cliente,
          'cliente_lower': cliente.toLowerCase(),
          'barrio': barrio,
          'direccion': direccion,
          'celular': celular,
          'dejarDineroPorteria': _dejarDineroPorteria,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Cliente frecuente actualizado con éxito!'), backgroundColor: Colors.blue),
        );
      } else {
        // ➕ Si no hay ID en edición, creamos uno nuevo
        await FirebaseFirestore.instance.collection('ManualClients').add({
          'cliente': cliente,
          'cliente_lower': cliente.toLowerCase(),
          'barrio': barrio,
          'direccion': direccion,
          'celular': celular,
          'dejarDineroPorteria': _dejarDineroPorteria,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Cliente frecuente guardado con éxito!'), backgroundColor: Colors.green),
        );
      }

      // ✅ Después de guardar/actualizar volvemos al estado inicial
      setState(() {
        _editingClientId = null;
        _clienteFrecuenteSeleccionadoId = null;
        _creandoClienteNuevo = false;

        _clienteController.clear();
        _barrioController.clear();
        _direccionController.clear();
        _celularController.clear();

        _dejarDineroPorteria = false;
      });

      await _cargarClientesFrecuentes();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

// Función auxiliar para limpiar y salir del modo edición
  void _limpiarFormularioEdicion() {
    setState(() {
      // Ya no estamos editando ningún cliente
      _editingClientId = null;

      // Ya no hay un cliente frecuente seleccionado
      _clienteFrecuenteSeleccionadoId = null;

      // Entramos al modo NUEVO CLIENTE
      _creandoClienteNuevo = true;

      // Limpiamos los datos
      _clienteController.clear();
      _barrioController.clear();
      _direccionController.clear();
      _celularController.clear();

      // Valor inicial para un cliente nuevo
      _dejarDineroPorteria = false;
    });
  }
}

class _ServiciosEnVivoPanel extends StatefulWidget {
  final Future<void> Function(
      String travelId,
      String cliente,
      String barrio,
      String direccion,
      String celular,
      ) onRelanzarServicio;

  final Future<void> Function(
      String travelId,
      String manualDocId,
      ) onCancelarServicio;

  final Future<void> Function(
      String manualDocId,
      ) onOcultarServicio;

  const _ServiciosEnVivoPanel({
    required this.onRelanzarServicio,
    required this.onCancelarServicio,
    required this.onOcultarServicio,
  });

  @override
  State<_ServiciosEnVivoPanel> createState() =>
      _ServiciosEnVivoPanelState();
}

class _ServiciosEnVivoPanelState
    extends State<_ServiciosEnVivoPanel> {

  late final Stream<QuerySnapshot> _manualServicesStream;

  @override
  void initState() {
    super.initState();

    // Este stream se crea UNA SOLA VEZ.
    // Los setState de la columna izquierda ya no lo reinician.
    _manualServicesStream = FirebaseFirestore.instance
        .collection('ManualServices')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios Solicitados (En Vivo)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Monitoreo en tiempo real del estado de los servicios manuales.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),

          const Divider(height: 24),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _manualServicesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay servicios registrados aún.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;

                    final travelId =
                    (data['travelId'] ?? '').toString();

                    final cliente =
                    (data['cliente'] ?? 'Sin nombre').toString();

                    final barrio =
                    (data['barrio'] ?? '').toString();

                    final direccion =
                    (data['direccion'] ?? '').toString();

                    return _ServicioEnVivoCard(
                      key: ValueKey(docs[index].id),
                      manualDocId: docs[index].id,
                      travelId: travelId,
                      cliente: cliente,
                      barrio: barrio,
                      direccion: direccion,
                      celular: (data['celular'] ?? '').toString(),
                      createdAt: data['createdAt'],
                      statusManual:
                      (data['status'] ?? 'pendiente').toString(),
                      onRelanzarServicio:
                      widget.onRelanzarServicio,
                      onCancelarServicio:
                      widget.onCancelarServicio,
                      onOcultarServicio:
                      widget.onOcultarServicio,
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
}


// =====================================================
// 🚕 TARJETA INDIVIDUAL DEL SERVICIO EN VIVO
// =====================================================

class _ServicioEnVivoCard extends StatefulWidget {
  final String manualDocId;
  final String travelId;
  final String cliente;
  final String barrio;
  final String direccion;
  final String celular;
  final dynamic createdAt;
  final String statusManual;

  final Future<void> Function(
      String travelId,
      String cliente,
      String barrio,
      String direccion,
      String celular,
      ) onRelanzarServicio;

  final Future<void> Function(
      String travelId,
      String manualDocId,
      ) onCancelarServicio;

// 👁️ OCULTAR SERVICIO
  final Future<void> Function(
      String manualDocId,
      ) onOcultarServicio;

  const _ServicioEnVivoCard({
    super.key,
    required this.manualDocId,
    required this.travelId,
    required this.cliente,
    required this.barrio,
    required this.direccion,
    required this.celular,
    required this.createdAt,
    required this.statusManual,
    required this.onRelanzarServicio,
    required this.onCancelarServicio,
    required this.onOcultarServicio,
  });

  @override
  State<_ServicioEnVivoCard> createState() =>
      _ServicioEnVivoCardState();
}

class _ServicioEnVivoCardState
    extends State<_ServicioEnVivoCard> {

  Stream<DocumentSnapshot>? _travelStream;

  @override
  void initState() {
    super.initState();
    _crearTravelStream();
  }

  void _crearTravelStream() {
    if (widget.travelId.isEmpty) {
      _travelStream = null;
      return;
    }

    _travelStream = FirebaseFirestore.instance
        .collection('TravelInfo')
        .doc(widget.travelId)
        .snapshots();
  }

  @override
  void didUpdateWidget(covariant _ServicioEnVivoCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Solo cambiamos la suscripción si realmente cambió el viaje.
    if (oldWidget.travelId != widget.travelId) {
      _crearTravelStream();
    }
  }

  String _formatearTimestamp(dynamic timestamp) {
    if (timestamp != null && timestamp is Timestamp) {
      final dateTime = timestamp.toDate();

      final dia =
      dateTime.day.toString().padLeft(2, '0');

      final mes =
      dateTime.month.toString().padLeft(2, '0');

      final anio = dateTime.year;

      final hora =
      dateTime.hour.toString().padLeft(2, '0');

      final minuto =
      dateTime.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$anio - $hora:$minuto';
    }

    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    // Si por alguna razón no existe travelId,
    // usamos solamente los datos de ManualServices.
    if (_travelStream == null) {
      return _construirTarjeta(
        statusReal: widget.statusManual,
        placaVehiculo: '',
        acceptedAtTimestamp: null,
        horaInicioViajeTimestamp: null,
        finishedAtTimestamp: null,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _travelStream,
      builder: (context, travelSnapshot) {
        // Mientras llega la primera respuesta no mostramos
        // una tarjeta incompleta.
        if (!travelSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        String statusReal = widget.statusManual;
        String placaVehiculo = '';

        Timestamp? acceptedAtTimestamp;
        Timestamp? horaInicioViajeTimestamp;
        Timestamp? finishedAtTimestamp;

        if (travelSnapshot.data!.exists) {
          final travelData =
          travelSnapshot.data!.data()
          as Map<String, dynamic>?;

          if (travelData != null) {
            statusReal =
                (travelData['status'] ?? statusReal)
                    .toString();

            placaVehiculo =
                (travelData['placa'] ?? '').toString();

            acceptedAtTimestamp =
            travelData['acceptedAt'] as Timestamp?;

            horaInicioViajeTimestamp =
            travelData['horaInicioViaje'] as Timestamp?;

            finishedAtTimestamp =
            travelData['finishedAt'] as Timestamp?;
          }
        }

        return _construirTarjeta(
          statusReal: statusReal,
          placaVehiculo: placaVehiculo,
          acceptedAtTimestamp: acceptedAtTimestamp,
          horaInicioViajeTimestamp:
          horaInicioViajeTimestamp,
          finishedAtTimestamp: finishedAtTimestamp,
        );
      },
    );
  }

  Widget _construirTarjeta({
    required String statusReal,
    required String placaVehiculo,
    required Timestamp? acceptedAtTimestamp,
    required Timestamp? horaInicioViajeTimestamp,
    required Timestamp? finishedAtTimestamp,
  }) {

    // Servicios terminados o cancelados no se muestran.
    if (statusReal == 'finished' ||
        statusReal == 'cancelled') {
      return const SizedBox.shrink();
    }

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

    // ❌ CANCELADO POR EL CONDUCTOR
      case 'cancelByDriverAfterAccepted':
        textoEstado = 'Cancelado por conductor';
        statusColor = Colors.red;
        break;

    // ⏱️ CANCELADO POR TIEMPO DE ESPERA
      case 'cancelTimeIsOver':
        textoEstado = 'Cancelado por tiempo de espera';
        statusColor = Colors.red;
        break;

      default:
        textoEstado = statusReal.toUpperCase();
        statusColor = Colors.blueGrey;
    }

    final horaSolicitudStr =
    _formatearTimestamp(widget.createdAt);

    final horaAceptacionStr =
    acceptedAtTimestamp != null
        ? _formatearTimestamp(
      acceptedAtTimestamp,
    )
        : null;

    final horaInicioStr =
    horaInicioViajeTimestamp != null
        ? _formatearTimestamp(
      horaInicioViajeTimestamp,
    )
        : null;

    final horaFinStr =
    finishedAtTimestamp != null
        ? _formatearTimestamp(
      finishedAtTimestamp,
    )
        : null;

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            // ============================================
            // DATOS DEL SERVICIO
            // ============================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cliente,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Barrio: ${widget.barrio}\n'
                        'Dir: ${widget.direccion}',
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),

                  const Divider(
                    height: 16,
                    thickness: 1,
                  ),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hora de solicitud:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontWeight:
                          FontWeight.w400,
                        ),
                      ),
                      Text(
                        horaSolicitudStr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  if (horaAceptacionStr != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          'Hora de aceptación:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontWeight:
                            FontWeight.w400,
                          ),
                        ),
                        Text(
                          horaAceptacionStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (horaInicioStr != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          'Hora de inicio:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontWeight:
                            FontWeight.w400,
                          ),
                        ),
                        Text(
                          horaInicioStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (horaFinStr != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        const Text(
                          'Hora de finalización:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontWeight:
                            FontWeight.w400,
                          ),
                        ),
                        Text(
                          horaFinStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 30),

            // ============================================
            // ESTADO / PLACA / ACCIONES
            // ============================================

            Column(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    textoEstado,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (placaVehiculo.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  const Text(
                    'Placa',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.black87,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      placaVehiculo.length >= 6
                          ? '${placaVehiculo.substring(0, 3)}-${placaVehiculo.substring(3)}'
                          : placaVehiculo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        fontSize: 14,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // 🔄 RELANZAR

                    if ((statusReal == 'created' ||
                        statusReal == 'cancelByDriverAfterAccepted' ||
                        statusReal == 'cancelTimeIsOver') &&
                        widget.travelId.isNotEmpty) ...[
                      Tooltip(
                        message:
                        'Re-lanzar servicio',
                        child: InkWell(
                          onTap: () =>
                              widget.onRelanzarServicio(
                                widget.travelId,
                                widget.cliente,
                                widget.barrio,
                                widget.direccion,
                                widget.celular,
                              ),
                          child: Container(
                            padding:
                            const EdgeInsets.all(
                                4),
                            decoration:
                            BoxDecoration(
                              color:
                              Colors.orange[800],
                              borderRadius:
                              BorderRadius
                                  .circular(6),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),
                    ],

// 👁️ OCULTAR SERVICIO CANCELADO POR EL CONDUCTOR
                    if ((statusReal == 'cancelByDriverAfterAccepted' ||
                        statusReal == 'cancelTimeIsOver') &&
                        widget.manualDocId.isNotEmpty) ...[
                      Tooltip(
                        message: 'Ocultar servicio',
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Ocultar servicio'),
                                content: Text(
                                  '¿Desea ocultar de la lista el servicio de "${widget.cliente}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(dialogCtx);

                                      widget.onOcultarServicio(
                                        widget.manualDocId,
                                      );
                                    },
                                    child: const Text(
                                      'Sí, ocultar',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.visibility_off_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),
                    ],

                    // ❌ CANCELAR
// No se muestra si el viaje ya inició
// o si ya fue cancelado por el conductor.
                    if (statusReal != 'started' &&
                        statusReal != 'cancelByDriverAfterAccepted' &&
                        statusReal != 'cancelTimeIsOver')
                      Tooltip(
                        message:
                        'Cancelar y ocultar solicitud',
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) =>
                                AlertDialog(
                                  title: const Text(
                                    'Cancelar Solicitud',
                                  ),
                                  content: Text(
                                    '¿Desea cancelar y remover la tarjeta de "${widget.cliente}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              dialogCtx),
                                      child:
                                      const Text('No'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton
                                          .styleFrom(
                                        backgroundColor:
                                        Colors.red,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(
                                            dialogCtx);

                                        widget
                                            .onCancelarServicio(
                                          widget.travelId,
                                          widget.manualDocId,
                                        );
                                      },
                                      child: const Text(
                                        'Sí, cancelar',
                                        style: TextStyle(
                                          color:
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                        child: Container(
                          padding:
                          const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red[700],
                            borderRadius:
                            BorderRadius.circular(
                                4),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
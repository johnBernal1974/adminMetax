import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../common/main_layout.dart';
import '../../providers/prices_provider.dart';

class PricesPage extends StatefulWidget {
  const PricesPage({Key? key}) : super(key: key);

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  final PricesProvider _pricesProvider = PricesProvider();

  // Controllers persistentes
  final Map<String, TextEditingController> _controllers = {};

  // dropdowns / switches
  String? selectedMantenimientoConductores;
  String? selectedMantenimientoUsuarios;
  double? selectedDinamica;
  bool? selectedCedula;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('Prices').doc('info');

  TextEditingController _c(String key, String initial) {
    return _controllers.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(String key, dynamic value) async {
    try {
      await _pricesProvider.updatePrice(key, value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Guardado: $key")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error guardando $key: $e")),
      );
    }
  }

  Future<void> _saveInt(String key, TextEditingController controller) async {
    final v = int.tryParse(controller.text.trim());
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, escribe un número válido")),
      );
      return;
    }
    await _save(key, v);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _doc.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snap.data!.data() ?? {};

        // Sync dropdowns/switch desde Firestore
        selectedMantenimientoConductores = (data["mantenimiento_conductores"] ?? "").toString();
        selectedMantenimientoUsuarios = (data["mantenimiento_usuarios"] ?? "").toString();

        final dyn = data["dinamica"];
        selectedDinamica ??= dyn is num ? dyn.toDouble() : 1.0;

        selectedCedula = (data["cedula"] is bool) ? data["cedula"] as bool : false;

        final isMobile = MediaQuery.of(context).size.width < 900;
        final cardWidth = isMobile ? double.infinity : 520.0;

        return MainLayout(
          pageTitle: "Configuraciones",
          content: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: cardWidth, child: _cardContacto(data)),
                SizedBox(width: cardWidth, child: _cardTarifas(data)),
                SizedBox(width: cardWidth, child: _cardKm(data)),
                SizedBox(width: cardWidth, child: _cardMin(data)),
                SizedBox(width: cardWidth, child: _cardCancelaciones(data)),
                SizedBox(width: cardWidth, child: _cardBusquedaEspera(data)),
                SizedBox(width: cardWidth, child: _cardRecargas(data)),
                SizedBox(width: cardWidth, child: _cardCedula(data)),
                SizedBox(width: cardWidth, child: _cardMantenimiento()),
                SizedBox(width: cardWidth, child: _cardDinamica()),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== CARDS =====================

  Widget _cardBase(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _cardContacto(Map<String, dynamic> d) {
    return _cardBase("Info de contacto", Icons.support_agent, [
      _fieldText("celular_atencion_conductores", "Celular conductores", d),
      _fieldText("celular_atencion_usuarios", "Celular usuarios", d),

      // ✅ NUEVOS
      _fieldText("correo_conductores", "Correo conductores", d),
      _fieldText("correo_usuarios", "Correo usuarios", d),
      _fieldText("link_descarga_driver", "Link descarga driver", d),
      _fieldText("link_descarga_client", "Link descarga client", d),

      _fieldText("link_cancelar_cuenta", "Link cancelación cuenta", d),
      _fieldText("link_politicas_privacidad", "Link políticas privacidad", d),
    ]);
  }

  Widget _cardTarifas(Map<String, dynamic> d) {
    return _cardBase("Tarifas", Icons.payments, [
      _fieldInt("tarifa_aeropuerto", "Tarifa aeropuerto", d),
      _fieldInt("tarifa_minima_regular", "Tarifa mínima regular", d),

      // ✅ NUEVOS
      _fieldInt("tarifa_minima_hotel", "Tarifa mínima hotel", d),
      _fieldInt("tarifa_minima_turismo", "Tarifa mínima turismo", d),

      _fieldInt("distancia_tarifa_minima", "Distancia tarifa mínima", d),
      _fieldInt("comision", "Comisión %", d),
      _fieldInt("descuento_porteria", "Comisión porterias", d),
    ]);
  }

  Widget _cardKm(Map<String, dynamic> d) {
    return _cardBase("Valores por km", Icons.route, [
      _fieldInt("valor_km_regular", "Valor km regular", d),

      // ✅ NUEVOS
      _fieldInt("valor_km_hotel", "Valor km hotel", d),
      _fieldInt("valor_km_turismo", "Valor km turismo", d),
    ]);
  }

  Widget _cardMin(Map<String, dynamic> d) {
    return _cardBase("Valores por minuto", Icons.timer, [
      _fieldInt("valor_min_regular", "Valor min regular", d),

      // ✅ NUEVOS
      _fieldInt("valor_min_hotel", "Valor min hotel", d),
      _fieldInt("valor_min_turismo", "Valor min turismo", d),
    ]);
  }

  Widget _cardCancelaciones(Map<String, dynamic> d) {
    return _cardBase("Cancelaciones", Icons.block, [
      _fieldInt("numero_cancelaciones_conductor", "Max cancelaciones conductor", d),
      _fieldInt("numero_cancelaciones_usuario", "Max cancelaciones usuario", d),
      _fieldInt("tiempo_de_bloqueo", "Tiempo de bloqueo", d),
    ]);
  }

  Widget _cardBusquedaEspera(Map<String, dynamic> d) {
    return _cardBase("Búsqueda y espera", Icons.radar, [
      _fieldDouble("radio_de_busqueda", "Radio de búsqueda (km)", d),

      // ✅ NUEVO
      _fieldInt("tiempo_busqueda", "Tiempo de búsqueda", d),

      _fieldInt("tiempo_de_espera", "Tiempo de espera", d),
    ]);
  }

  Widget _cardRecargas(Map<String, dynamic> d) {
    return _cardBase("Recargas", Icons.account_balance_wallet, [
      // ✅ FIX KEY: recarga_inicial (NO recarga_Inicial)
      _fieldInt("recarga_inicial", "Recarga inicial", d),

      // ✅ NUEVO
      _fieldText("numero_cuenta_recargas", "Número cuenta recargas", d),
    ]);
  }

  Widget _cardCedula(Map<String, dynamic> d) {
    return _cardBase("Cédula", Icons.badge, [
      Row(
        children: [
          Expanded(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Pedir cédula"),
              value: selectedCedula ?? false,
              onChanged: (v) async {
                setState(() => selectedCedula = v);
                await _save("cedula", v);
              },
            ),
          ),
        ],
      ),

      // ✅ NUEVO
      _fieldInt("cedula_despues_de_viajes", "Cédula después de viajes", d),
    ]);
  }

  Widget _cardMantenimiento() {
    return _cardBase("Mantenimiento", Icons.build, [
      _dropString(
        title: "Conductores",
        value: selectedMantenimientoConductores ?? "",
        onChanged: (v) => setState(() => selectedMantenimientoConductores = v),
        onSave: () => _save("mantenimiento_conductores", selectedMantenimientoConductores ?? ""),
      ),
      const SizedBox(height: 8),
      _dropString(
        title: "Usuarios",
        value: selectedMantenimientoUsuarios ?? "",
        onChanged: (v) => setState(() => selectedMantenimientoUsuarios = v),
        onSave: () => _save("mantenimiento_usuarios", selectedMantenimientoUsuarios ?? ""),
      ),
    ]);
  }

  Widget _cardDinamica() {
    const List<double> options = [
      1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9,
      2.0, 2.1, 2.2, 2.3, 2.4, 2.5, 3.0
    ];

    return _cardBase("Dinámica", Icons.trending_up, [
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<double>(
              value: selectedDinamica ?? 1.0,
              items: options
                  .map((double v) =>
                  DropdownMenuItem<double>(value: v, child: Text(v.toString())))
                  .toList(),
              onChanged: (double? v) => setState(() => selectedDinamica = v),
              decoration: InputDecoration(
                labelText: "Dinámica",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _save("dinamica", selectedDinamica ?? 1.0),
          )
        ],
      ),
    ]);
  }

  // ===================== FIELDS =====================

  Widget _fieldText(String key, String label, Map<String, dynamic> d) {
    final initial = (d[key] ?? "").toString();
    final controller = _c(key, initial);

    // si Firestore cambia, actualiza el controller sin romper el cursor (solo si no está editando)
    if (!controller.value.isComposingRangeValid && controller.text != initial) {
      controller.text = initial;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _save(key, controller.text.trim()),
          ),
        ),
      ),
    );
  }

  Widget _fieldInt(String key, String label, Map<String, dynamic> d) {
    final initial = (d[key] ?? 0).toString();
    final controller = _c(key, initial);

    if (!controller.value.isComposingRangeValid && controller.text != initial) {
      controller.text = initial;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveInt(key, controller),
          ),
        ),
      ),
    );
  }

  Widget _fieldDouble(String key, String label, Map<String, dynamic> d) {
    final initial = (d[key] ?? 0.0).toString();
    final controller = _c(key, initial);

    if (!controller.value.isComposingRangeValid && controller.text != initial) {
      controller.text = initial;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final v = double.tryParse(controller.text.trim());
              if (v == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Número decimal inválido")),
                );
                return;
              }
              await _save(key, v);
            },
          ),
        ),
      ),
    );
  }

  Widget _dropString({
    required String title,
    required String value,
    required void Function(String?) onChanged,
    required VoidCallback onSave,
  }) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value.isEmpty ? "" : value,
            items: const [
              DropdownMenuItem(value: "", child: Text("")),
              DropdownMenuItem(value: "Si", child: Text("Si")),
              DropdownMenuItem(value: "No", child: Text("No")),
            ],
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.save), onPressed: onSave),
      ],
    );
  }
}
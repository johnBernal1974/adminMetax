import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/main_layout.dart';
import '../../models/conductor_model.dart';
import '../../models/usuario_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';
import 'dart:html' as html;

import '../travel_status_admin_widget.dart';

class GeneralPage extends StatefulWidget {
  const GeneralPage({Key? key}) : super(key: key);

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {

  int totalConductores = 0;
  int totalClientes = 0;
  int totalUsuarios = 0;
  int totalElites = 0; // ⭐️ NUEVA VARIABLE PARA ÉLITES
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSoloCantidades();
    });
  }

  Future<void> _cargarSoloCantidades() async {
    setState(() => _isLoading = true);

    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

    // 🟢 Ejecutamos los conteos en paralelo (Incluyendo el conteo ultra-liviano de Élites)
    final resultados = await Future.wait([
      driverProvider.obtenerConteoConductoresCarroSencillo(),
      clientProvider.obtenerConteoClientesSencillo(),
      _obtenerConteoElites(), // Método de conteo directo sin traer listas pesadas
    ]);

    totalConductores = resultados[0];
    totalClientes = resultados[1];
    totalElites = resultados[2];
    totalUsuarios = totalConductores + totalClientes;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ⭐️ Consulta rápida y económica de Firestore para saber cuántos Élite existen (is_elite == true)
  Future<int> _obtenerConteoElites() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Drivers')
          .where('is_elite', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print("Error contando conductores élite: $e");
      return 0;
    }
  }

  // 🔒 Valida permisos según los campos de OperadorProvider
  bool _tienePermisoElite(BuildContext context) {
    try {
      final operadorProvider = Provider.of<OperadorProvider>(context, listen: false);

      // Validamos que el operador esté activo
      if (!operadorProvider.activoActual) return false;

      // Obtenemos el rol actual del getter
      final String rol = (operadorProvider.rolActual ?? "").trim().toLowerCase();

      // Lista de roles con permiso
      final rolesPermitidos = ["master", "operadorfull", "contador"];

      return rolesPermitidos.contains(rol);
    } catch (e) {
      print("Error al comprobar permisos de operador: $e");
      return false;
    }
  }

  void _refreshData() {
    _cargarSoloCantidades();
  }

  @override
  Widget build(BuildContext context) {
    final isMobileOrTablet = MediaQuery.of(context).size.width <= 800;

    return PopScope(
      canPop: false,
      child: MainLayout(
        pageTitle: 'General',
        content: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(
          context,
          isMobileOrTablet,
          totalConductores: totalConductores,
          totalClientes: totalClientes,
          totalUsuarios: totalUsuarios,
          totalElites: totalElites,
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      bool isMobileOrTablet, {
        required int totalConductores,
        required int totalClientes,
        required int totalUsuarios,
        required int totalElites,
      }) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
          margin: const EdgeInsets.all(7),
          child: Column(
            children: [
              const Text('Información General', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              /// 🔥 BOTÓN DE REFRESCAR
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refrescar datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: isMobileOrTablet
                    ? _buildMobileContainers(context, totalConductores, totalClientes, totalUsuarios, totalElites)
                    : _buildDesktopContainers(context, totalConductores, totalClientes, totalUsuarios, totalElites),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMobileContainers(
      BuildContext context,
      int conductores,
      int clientes,
      int totalUsuarios,
      int elites
      ) {
    final bool puedeVerElite = _tienePermisoElite(context);

    return [
      GestureDetector(
          onTap: () => Navigator.pushNamed(context, 'conductores_page'),
          child: _buildInfoContainerMobil(context, 'Conductores', Icons.directions_car, conductores.toString(), Colors.lightBlue.shade300)),
      GestureDetector(
          onTap: () => Navigator.pushNamed(context, 'usuarios_page'),
          child: _buildInfoContainerMobil(context, 'Clientes', Icons.person, clientes.toString(), Colors.green.shade300)),

      // ⭐️ SOLO SE RENDERIZA SI EL ROL TIENE PERMISO
      if (puedeVerElite)
        GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'conductores_page', arguments: {'tab': 'elites'}),
            child: _buildInfoContainerMobil(context, 'Élites (MetaX)', Icons.stars_rounded, "$elites/60", Colors.amber.shade400)),

      _buildInfoContainerMobil(context, 'Usuarios Totales', Icons.people_alt, totalUsuarios.toString(), Colors.grey),
    ];
  }

  List<Widget> _buildDesktopContainers(
      BuildContext context,
      int conductores,
      int clientes,
      int totalUsuarios,
      int elites
      ) {
    final bool puedeVerElite = _tienePermisoElite(context);

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, 'conductores_page'),
                child: _buildInfoContainer(context, 'Conductores', Icons.directions_car, conductores.toString(), Colors.lightBlue.shade300)),
          ),
          Expanded(
            child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, 'usuarios_page'),
                child: _buildInfoContainer(context, 'Clientes', Icons.person, clientes.toString(), Colors.green.shade300)),
          ),

          // ⭐️ SOLO SE RENDERIZA SI EL ROL ES: Master, operadorFull o contador
          if (puedeVerElite)
            Expanded(
              child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, 'conductores_page', arguments: {'tab': 'elites'}),
                  child: _buildInfoContainer(context, 'Conductores Élite', Icons.stars_rounded, "$elites / 60", Colors.amber.shade400)),
            ),

          Expanded(
            child: _buildInfoContainer(context, 'Usuarios Totales', Icons.people_alt, totalUsuarios.toString(), Colors.grey.shade400),
          ),
        ],
      ),
    ];
  }

  Widget _buildInfoContainer(BuildContext context, String title, IconData icon, String value, Color color) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final containerWidth = isDesktop ? MediaQuery.of(context).size.width * 0.10 : MediaQuery.of(context).size.width * 0.2;
    final horizontalMargin = isDesktop ? 10.0 : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: horizontalMargin),
      width: containerWidth,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainerMobil(BuildContext context, String title, IconData icon, String value, Color color) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final containerWidth = isDesktop ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.42;
    final horizontalMargin = isDesktop ? 10.0 : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: horizontalMargin),
      width: containerWidth,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ExportarUsuariosButton extends StatelessWidget {
  const ExportarUsuariosButton({super.key});

  Future<void> exportarUsuarios() async {
    List<List<String>> rows = [];

    rows.add(["Tipo", "Nombres", "Apellidos", "Celular"]);

    final clientesSnapshot =
    await FirebaseFirestore.instance.collection('Clients').get();

    for (var doc in clientesSnapshot.docs) {
      final data = doc.data();

      rows.add([
        "Cliente",
        (data["01_Nombres"] ?? "").toString(),
        (data["02_Apellidos"] ?? "").toString(),
        (data["07_Celular"] ?? "").toString(),
      ]);
    }

    final driversSnapshot =
    await FirebaseFirestore.instance.collection('Drivers').get();

    for (var doc in driversSnapshot.docs) {
      final data = doc.data();

      rows.add([
        "Conductor",
        (data["01_Nombres"] ?? "").toString(),
        (data["02_Apellidos"] ?? "").toString(),
        (data["07_Celular"] ?? "").toString(),
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "usuarios_metax.csv")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: exportarUsuarios,
      icon: const Icon(Icons.download),
      label: const Text("Descargar usuarios"),
    );
  }
}
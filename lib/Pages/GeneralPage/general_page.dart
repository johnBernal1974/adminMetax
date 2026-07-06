
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

    // Ejecutamos ambos conteos en paralelo para que sea inmediato
    final resultados = await Future.wait([
      driverProvider.obtenerConteoConductoresCarroSencillo(),
      clientProvider.obtenerConteoClientesSencillo(),
    ]);

    totalConductores = resultados[0];
    totalClientes = resultados[1];
    totalUsuarios = totalConductores + totalClientes;

    if (mounted) {
      setState(() => _isLoading = false);
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
              const SizedBox(height: 10), // Un pequeño espacio

              /// 🔥 NUEVO BOTÓN DE REFRESCAR
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refrescar datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary, // Color llamativo
                  foregroundColor: Colors.black,         // Color del texto e icono
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: isMobileOrTablet
                    ? _buildMobileContainers(context, totalConductores, totalClientes, totalUsuarios)
                    : _buildDesktopContainers(context, totalConductores, totalClientes, totalUsuarios),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMobileContainers(BuildContext context, int conductores, int clientes, int totalUsuarios) {
    return [
      GestureDetector(
          onTap: () => Navigator.pushNamed(context, 'conductores_page'),
          child: _buildInfoContainerMobil(context, 'Conductores', Icons.directions_car, conductores.toString(), Colors.lightBlue.shade300)),
      GestureDetector(
          onTap: () => Navigator.pushNamed(context, 'usuarios_page'),
          child: _buildInfoContainerMobil(context, 'Clientes', Icons.person, clientes.toString(), Colors.green.shade300)),
      _buildInfoContainerMobil(context, 'Usuarios Totales', Icons.people_alt, totalUsuarios.toString(), Colors.grey),
    ];
  }

  List<Widget> _buildDesktopContainers(BuildContext context, int conductores, int clientes, int totalUsuarios) {
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
    final horizontalMargin = isDesktop ? 20.0 : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: horizontalMargin),
      width: containerWidth,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 25),
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
              fontSize: 16,
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
    final containerWidth = isDesktop ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.4;
    final horizontalMargin = isDesktop ? 20.0 : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: horizontalMargin),
      width: containerWidth,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 16),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
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

    /// 🔥 ENCABEZADOS
    rows.add(["Tipo", "Nombres", "Apellidos", "Celular"]);

    /// =========================
    /// CLIENTES
    /// =========================
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

    /// =========================
    /// DRIVERS
    /// =========================
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

    /// 🔥 CONVERTIR A CSV
    String csv = const ListToCsvConverter().convert(rows);

    /// 🔥 DESCARGAR ARCHIVO
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

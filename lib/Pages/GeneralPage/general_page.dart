
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
import '../../src/color.dart';
import 'dart:html' as html;

class GeneralPage extends StatefulWidget {
  const GeneralPage({Key? key}) : super(key: key);

  @override
  State<GeneralPage> createState() => _GeneralPageState();
}

class _GeneralPageState extends State<GeneralPage> {

  int totalClientes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false)
          .fetchDrivers();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);

      totalClientes = await clientProvider.fetchTotalClients();

      setState(() {});
    });


  }

  void _refreshData() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);

    await driverProvider.fetchDrivers();
    await clientProvider.fetchClients();
    driverProvider.fetchTravelHistoryCount();

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos actualizados'),
        duration: Duration(seconds: 2), // Ajusta la duración según sea necesario
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobileOrTablet = MediaQuery.of(context).size.width <= 800;
    final driverProvider = Provider.of<DriverProvider>(context);
    final clientProvider = Provider.of<ClientProvider>(context);
    final List<Driver> conductores = driverProvider.getDriversByRole('carro');
    final List<Driver> motociclistas = driverProvider.getDriversByRole('moto');
    final List<Driver> conductoresIsWorking =
    driverProvider.getDriversByRoleAndWorkingStatus('carro', true);
    final List<Driver> motociclistasIsWorking =
    driverProvider.getDriversByRoleAndWorkingStatus('moto', true);
    final List<Driver> conductoresisActive =
    driverProvider.getDriversByRoleAndActiveStatus('carro', true);
    final List<Driver> motociclistasisActive =
    driverProvider.getDriversByRoleAndActiveStatus('moto', true);
    final List<Client> clientesActivos = clientProvider.clients;
    final int totalUsuarios =
        conductores.length + motociclistas.length + clientesActivos.length;

    return PopScope(
      canPop: false,
      child: Consumer<DriverProvider>(
        builder: (context, driverProvider, _) {
          return MainLayout(
            content: _buildContent(
              context,
              isMobileOrTablet,
              driverProvider,
              clientProvider,
              conductores,
              motociclistas,
              clientesActivos,
              totalUsuarios,
              conductoresIsWorking,
              motociclistasIsWorking,
              conductoresisActive,
              motociclistasisActive,
            ),
            pageTitle: 'General',
          );
        },
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      bool isMobileOrTablet,
      DriverProvider driverProvider,
      ClientProvider clientProvider,
      List<Driver> conductores,
      List<Driver> motociclistas,
      List<Client> clientesActivos,
      int totalUsuarios,
      List<Driver> conductoresIsWorking,
      List<Driver> motociclistasIsWorking,
      List<Driver> conductoresisActive,
      List<Driver> motociclistasisActive ) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          margin: const EdgeInsets.all(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const Padding(
                padding: EdgeInsets.all(6.0),
                child: Text(
                  'Información General',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
              ),
              const SizedBox(height: 10),
              const ExportarUsuariosButton(),
              const SizedBox(height: 10),

              // ElevatedButton.icon(
              //   onPressed: () async {
              //
              //     final confirm = await showDialog(
              //       context: context,
              //       builder: (_) => AlertDialog(
              //         title: const Text("Confirmar envío"),
              //         content: const Text("¿Enviar mensaje a todos los conductores?"),
              //         actions: [
              //           TextButton(
              //             onPressed: () => Navigator.pop(context, false),
              //             child: const Text("No"),
              //           ),
              //           TextButton(
              //             onPressed: () => Navigator.pop(context, true),
              //             child: const Text("Sí"),
              //           ),
              //         ],
              //       ),
              //     );
              //
              //     if (confirm != true) return;
              //
              //     /// 🔥 AQUÍ VA TU FUNCTION
              //     try {
              //
              //       final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
              //
              //       final response = await functions
              //           .httpsCallable('enviarMensajeMasivoConductores')
              //           .call();
              //
              //       final enviados = response.data['enviados'];
              //       final errores = response.data['errores'];
              //
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(
              //           content: Text("✅ Enviados: $enviados | ❌ Errores: $errores"),
              //         ),
              //       );
              //
              //     } catch (e) {
              //
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(
              //           content: Text("❌ Error: $e"),
              //         ),
              //       );
              //     }
              //   },
              //   icon: const Icon(Icons.campaign),
              //   label: const Text("Enviar mensaje a conductores"),
              // ),


              Wrap(
                spacing: 10, // Espacio horizontal entre los contenedores
                // Espacio vertical entre las filas de contenedores
                alignment: WrapAlignment.center, // Alinea los contenedores al centro
                children: isMobileOrTablet
                    ? _buildMobileContainers(context, driverProvider, conductores.length, motociclistas.length, clientesActivos.length, totalUsuarios)
                    : _buildDesktopContainers(context, driverProvider, conductores.length, motociclistas.length, clientesActivos.length, totalUsuarios),
              ),
              const SizedBox(height: 20),
              const Divider(
                color: Colors.grey,
                height: 3,
              ),
              const SizedBox(height: 20),

              /////para configurar en mobil
              isMobileOrTablet
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildColumnContent(driverProvider, conductoresisActive, conductoresIsWorking, motociclistasisActive, motociclistasIsWorking),
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildRowContent(driverProvider, conductoresisActive, conductoresIsWorking, motociclistasisActive, motociclistasIsWorking),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildColumnContent(DriverProvider driverProvider, List<Driver> conductoresisActive, List<Driver> conductoresIsWorking, List<Driver> motociclistasisActive, List<Driver> motociclistasIsWorking) {
    return [
      _buildInfoCard(
        'Estado de Conexión',
        [
          _buildDataRow('Vehículos conectados:', conductoresisActive.length.toString()),
          _buildDataRow('Vehículos en servicio:', conductoresIsWorking.length.toString()),

        ],
      ),
      const SizedBox(height: 30),
      _buildInfoCard(
        'Viajes realizados',
        [
          _buildDataRow('Total viajes:', driverProvider.travelHistoryCount.toString()),
        ],
      ),
      const SizedBox(height: 30),
      // _buildInfoCard(
      //   'Recargas realizadas',
      //   [
      //     _buildDataRow('Conductores:', "0"),
      //     _buildDataRow('Motociclistas:', "0"),
      //     _buildDataRow('Total recargas:', "0"),
      //   ],
      // ),
      // const SizedBox(height: 30),
      // _buildInfoCard(
      //   'Bonos',
      //   [
      //     _buildDataRow('Asignados:', "0"),
      //     _buildDataRow('Usados:', "0"),
      //     _buildDataRow('Bonos usados:', "\$0"),
      //   ],
      // ),
    ];
  }

  List<Widget> _buildRowContent(DriverProvider driverProvider, List<Driver> conductoresisActive, List<Driver> conductoresIsWorking, List<Driver> motociclistasisActive, List<Driver> motociclistasIsWorking) {
    return [
      Expanded(
        flex: 2,
        child: _buildInfoCard(
          'Estado de Conexión',
          [
            _buildDataRow('Vehículos conectados:', conductoresisActive.length.toString()),
            _buildDataRow('Vehículos en servicio:', conductoresIsWorking.length.toString()),
          ],
        ),
      ),
      const SizedBox(width: 30),
      Expanded(
        flex: 2,
        child: _buildInfoCard(
          'Viajes realizados',
          [
            _buildDataRow('Total viajes:', driverProvider.travelHistoryCount.toString()),
          ],
        ),
      ),
      const SizedBox(width: 30),
      // Expanded(
      //   flex: 2,
      //   child: _buildInfoCard(
      //     'Recargas realizadas',
      //     [
      //       _buildDataRow('Conductores:', "0"),
      //       _buildDataRow('Motociclistas:', "0"),
      //       _buildDataRow('Total recargas:', "0"),
      //     ],
      //   ),
      // ),
      // const SizedBox(width: 30),
      // Expanded(
      //   flex: 2,
      //   child: _buildInfoCard(
      //     'Bonos',
      //     [
      //       _buildDataRow('Asignados:', "0"),
      //       _buildDataRow('Usados:', "0"),
      //       _buildDataRow('Bonos usados:', "\$0"),
      //     ],
      //   ),
      // ),
    ];
  }

  Widget _buildInfoCard(String title, List<Widget> content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blancoCards,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          ...content,
        ],
      ),
    );
  }

  Widget _buildDataRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 20),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  List<Widget> _buildMobileContainers(BuildContext context, DriverProvider driverProvider, int conductores, int motociclistas, int clientes, int totalUsuarios) {
    return [

      GestureDetector(
          onTap: () => Navigator.pushNamed(context, 'conductores_page'),
          child: _buildInfoContainerMobil(context, 'Conductores', Icons.directions_car, conductores.toString(), Colors.lightBlue.shade300)),
      GestureDetector(
          onTap: () => Navigator.pushNamed(context, 'usuarios_page'),
          child: _buildInfoContainerMobil(context, 'Clientes', Icons.person, totalClientes.toString(), Colors.green.shade300)),
      _buildInfoContainerMobil(context, 'Usuarios Totales', Icons.people_alt, totalUsuarios.toString(), Colors.grey),
      //_buildInfoContainerMobil(context, 'Viajes', Icons.info_outline,  driverProvider.travelHistoryCount.toString(), Colors.purple.shade300),
      // Agregar más contenedores según sea necesario
    ];
  }

  List<Widget> _buildDesktopContainers(BuildContext context, DriverProvider driverProvider, int conductores, int motociclistas, int clientes, int totalUsuarios) {
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
                child: _buildInfoContainer(context, 'Clientes', Icons.person, totalClientes.toString(), Colors.green.shade300)),
          ),
          Expanded(
            child: _buildInfoContainer(context, 'Usuarios Totales', Icons.people_alt, totalUsuarios.toString(), Colors.grey.shade400),
          ),
          // Expanded(
          //   child: _buildInfoContainer(context, 'Viajes', Icons.add_chart_rounded, driverProvider.travelHistoryCount.toString(), Colors.purple.shade300),
          // ),
          // Agregar más contenedores según sea necesario
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../common/main_layout.dart';
import '../../models/conductor_model.dart';
import '../../models/operador_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';
import '../DriverDetailPage/driver_detail_page.dart';
import 'package:intl/intl.dart';


class ConductoresPage extends StatefulWidget {
  ConductoresPage({Key? key}) : super(key: key);

  @override
  _ConductoresPageState createState() => _ConductoresPageState();
}

class _ConductoresPageState extends State<ConductoresPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  int totalDrivers = 0;
  Operador? operador;
  Driver? driver;
  OperadorProvider _operadorProvider = OperadorProvider();
  MyAuthProvider _authProvider = MyAuthProvider();


  String filterVigencia = ""; // "", "vencido", "porVencer", "sinFecha", "vigente"


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false)
          .fetchDriversInicial();
    });
  }


  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final conductores = driverProvider.drivers;
    final isMobileOrTablet = MediaQuery
        .of(context)
        .size
        .width <= 600;

    Color getStatusColor(driver) {
      if (driver?.verificacionStatus == "registrado") {
        return Colors.blueGrey;
      } else if (driver?.verificacionStatus == "foto_tomada") {
        return Colors.amber;
      } else if (driver?.the29FotoPerfil == 'corregida' &&
          driver?.verificacionStatus == 'Procesando') {
        return Colors.purple;
      } else if (driver?.verificacionStatus == 'Procesando') {
        return Colors.blueAccent;
      } else if (driver?.verificacionStatus == 'activado') {
        return Colors.green;
      } else if (driver?.verificacionStatus == 'bloqueado') {
        return Colors.red.shade900;
      } else if (driver?.verificacionStatus == 'bloqueo_AJ') {
        return Colors.deepOrange;
      } else if (driver?.verificacionStatus == 'rechazada') {
        return Colors.brown.shade900;
      } else if (driver?.verificacionStatus == 'suspendido') {
        return Colors.black;
      } else {
        return Colors.grey;
      }
    }

    List filteredConductores = conductores.where((driver) {
      if (driver.rol.isNotEmpty) {
        return driver.rol == "carro";
      }
      return true;
    }).toList();
    totalDrivers = filteredConductores.length;


    return MainLayout(
      content: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                margin: const EdgeInsets.all(7),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth <= 600) {
                      return _buildMobileLayout(
                        context,
                        driverProvider,
                        filteredConductores,
                        getStatusColor,
                      );
                    } else {
                      return _buildDesktopLayout(
                        context,
                        driverProvider,
                        filteredConductores,
                        getStatusColor,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      pageTitle: 'Conductores',
    );
  }





  Widget _buildMobileLayout(
      BuildContext context,
      DriverProvider driverProvider,
      List filteredConductores,
      Color Function(dynamic) getStatusColor
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Total de Conductores:\n$totalDrivers',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.refresh),
              color: Theme
                  .of(context)
                  .primaryColor,
              onPressed: () {
                driverProvider.fetchDrivers();
              },
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 20, thickness: 2),
        _buildSearchField(),
        const SizedBox(height: 30),
        const SizedBox(height: 10),
        const Divider(height: 1, color: grisMedio),
        const SizedBox(height: 10),
        const Text("Filtrado vigencia documentos", style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Divider(height: 1, color: grisMedio),
        const SizedBox(height: 10),
        _buildDriverTable(filteredConductores, getStatusColor),
      ],
    );
  }


  Widget _buildDesktopLayout(
      BuildContext context,
      DriverProvider driverProvider,
      List filteredConductores,
      Color Function(dynamic) getStatusColor
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Total de Conductores:\n$totalDrivers',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 100),
            ElevatedButton(
              onPressed: () {
                driverProvider.fetchDrivers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme
                    .of(context)
                    .primaryColor,
              ),
              child: const Text(
                  'Cargar Conductores', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 20, thickness: 2),
        _buildSearchField(),
        const SizedBox(height: 30),
        const Divider(height: 1, color: grisMedio),
        const SizedBox(height: 10),

        const SizedBox(height: 10),
        _buildDriverTable(filteredConductores, getStatusColor),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 350,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Buscar por cédula o placa',
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final query = searchController.text.trim();

              Provider.of<DriverProvider>(context, listen: false)
                  .buscarDriver(query);
            },
          ),
        ),

        /// 🔥 SOLO ENTER
        onSubmitted: (value) {
          Provider.of<DriverProvider>(context, listen: false)
              .buscarDriver(value.trim());
        },
      ),
    );
  }

  Widget _buildDriverTable(List filteredConductores, Color Function(dynamic) getStatusColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 20.0,
          headingRowHeight: 56.0,
          dataRowHeight: 70.0,
          columns: const [
            DataColumn(
              label: Text(
                'Estado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Imagen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Nombre',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Apellidos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Identificación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Correo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            DataColumn(
              label: Text(
                'Celular',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Center(
                child: Text(
                  'Vigencia documentos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Acción',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: filteredConductores.map((driver) {
            return DataRow(
              onSelectChanged: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverDetailPage(driver: driver),
                  ),
                );
              },
              cells: [
                DataCell(
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: getStatusColor(driver),
                    ),
                  ),
                ),
                DataCell(
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: driver.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
                DataCell(Text(driver.the01Nombres ?? "Nombre no disponible", style: TextStyle(color: Colors.black))),
                DataCell(Text(driver.the02Apellidos ?? "Apellidos no disponibles", style: TextStyle(color: Colors.black))),
                DataCell(Text(driver.the03NumeroDocumento ?? "Documento no disponible")),
                DataCell(Text(driver.the06Email ?? "Email no disponible")),
                DataCell(Text(driver.the07Celular ?? "Celular no disponible")),
                DataCell(
                  Center(
                    child: vigenciaCell(driver),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.double_arrow_outlined, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverDetailPage(driver: driver),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

}

DateTime? _parseFechaCO(String? s) {
  if (s == null) return null;
  final t = s.trim();
  if (t.isEmpty) return null;
  try {
    return DateFormat('dd/MM/yyyy').parseStrict(t);
  } catch (_) {
    return null;
  }
}

// PARA VER VIGENCIA DE DOCUMENTOS

// Regla: vence un día antes de la fecha en BD
DateTime? _venceDiaAntes(String? fechaBd) {
  final f = _parseFechaCO(fechaBd);
  if (f == null) return null;
  return DateTime(f.year, f.month, f.day).subtract(const Duration(days: 1));
}

enum _VigEstado { sinFecha, vencido, porVencer, vigente }

_VigEstado _estadoVig(DateTime? vence, {int diasAlerta = 30}) {
  if (vence == null) return _VigEstado.sinFecha;

  final now = DateTime.now();
  final hoy = DateTime(now.year, now.month, now.day);
  final v = DateTime(vence.year, vence.month, vence.day);
  final diff = v.difference(hoy).inDays;

  if (diff < 0) return _VigEstado.vencido;
  if (diff <= diasAlerta) return _VigEstado.porVencer;
  return _VigEstado.vigente;
}

_VigEstado _peorEstado(List<_VigEstado> estados) {
  if (estados.contains(_VigEstado.vencido)) return _VigEstado.vencido;
  if (estados.contains(_VigEstado.porVencer)) return _VigEstado.porVencer;
  if (estados.contains(_VigEstado.sinFecha)) return _VigEstado.sinFecha;
  return _VigEstado.vigente;
}

Color _colorVig(_VigEstado e) {
  switch (e) {
    case _VigEstado.vencido:
      return Colors.red;
    case _VigEstado.porVencer:
      return Colors.orange;
    case _VigEstado.vigente:
      return Colors.green;
    case _VigEstado.sinFecha:
      return Colors.grey;
  }
}

String _tooltipVig(_VigEstado e) {
  switch (e) {
    case _VigEstado.vencido:
      return 'Hay documentos vencidos';
    case _VigEstado.porVencer:
      return 'Hay documentos por vencer (≤ 30 días)';
    case _VigEstado.vigente:
      return 'Documentos vigentes';
    case _VigEstado.sinFecha:
      return 'Faltan fechas de vigencia';
  }
}

_VigEstado _vigenciaGlobalDriver(driver) {
  return _VigEstado.sinFecha;
}

Widget vigenciaCell(driver) {
  return Tooltip(
    message: "Pendiente migración",
    child: Center(
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

String vigenciaEstadoTexto(driver) {
  final estado = _vigenciaGlobalDriver(driver);

  switch (estado) {
    case _VigEstado.vencido:
      return "vencido";
    case _VigEstado.porVencer:
      return "porVencer";
    case _VigEstado.vigente:
      return "vigente";
    case _VigEstado.sinFecha:
      return "sinFecha";
  }
}


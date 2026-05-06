import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/main_layout.dart';
import '../../models/conductor_model.dart';
import '../../models/operador_model.dart';
import '../../providers/driver_provider.dart';
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
  Map<String, String> driversEstadoVehiculo = {};

  bool mostrarSoloActivosBloqueados = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false)
          .fetchDriversInicial();
    });
    cargarErroresVehiculos();
  }

  int getPrioridad(Driver driver) {
    final estado = driver.verificacionStatus;

    if (estado == "procesando") return 0;
    if (estado == "registrado") return 1;

    if (tieneCorregida(driver)) return 2;
    if (tieneRechazada(driver)) return 3;

    return 4; // otros (activado, bloqueado)
  }

  bool tienePendiente(Driver driver) {
    return (driver.the29FotoPerfil ?? "") == "corregida" ||
        (driver.the29FotoPerfil ?? "") == "rechazada" ||

        (driver.the25CedulaDelanteraFoto ?? "") == "corregida" ||
        (driver.the25CedulaDelanteraFoto ?? "") == "rechazada" ||

        (driver.the26CedulaTraseraFoto ?? "") == "corregida" ||
        (driver.the26CedulaTraseraFoto ?? "") == "rechazada";
  }

  bool tieneCorregida(Driver driver) {
    return (driver.the29FotoPerfil ?? "") == "corregida" ||
        (driver.the25CedulaDelanteraFoto ?? "") == "corregida" ||
        (driver.the26CedulaTraseraFoto ?? "") == "corregida";
  }

  bool tieneRechazada(Driver driver) {
    return (driver.the29FotoPerfil ?? "") == "rechazada" ||
        (driver.the25CedulaDelanteraFoto ?? "") == "rechazada" ||
        (driver.the26CedulaTraseraFoto ?? "") == "rechazada";
  }

  //vehiculos
  Future<void> cargarErroresVehiculos() async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup("vehiculos")
        .get();

    Map<String, String> mapa = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      String estado = "";

      if ((data["27_Tarjeta_Propiedad_Delantera_foto"] ?? "") == "corregida" ||
          (data["28_Tarjeta_Propiedad_Trasera_foto"] ?? "") == "corregida") {
        estado = "corregida";
      } else if ((data["27_Tarjeta_Propiedad_Delantera_foto"] ?? "") == "rechazada" ||
          (data["28_Tarjeta_Propiedad_Trasera_foto"] ?? "") == "rechazada") {
        estado = "rechazada";
      }

      if (estado.isNotEmpty) {
        final driverId = data["driverId"];
        mapa[driverId] = estado;
      }
    }

    setState(() {
      driversEstadoVehiculo = mapa;
    });
  }

  bool tieneErrorTotal(Driver driver) {
    return tienePendiente(driver) ||
        driversEstadoVehiculo [driver.id] == true;
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

      final estadoVehiculo = driversEstadoVehiculo[driver.id];

      /// 🔥 PRIORIDAD 1: CORREGIDA (driver o vehículo)
      if (tieneCorregida(driver) || estadoVehiculo == "corregida") {
        return Colors.purple;
      }

      /// 🔥 PRIORIDAD 2: RECHAZADA
      if (tieneRechazada(driver) || estadoVehiculo == "rechazada") {
        return Colors.orange;
      }

      switch (driver?.verificacionStatus) {
        case "registrado":
          return Colors.blueGrey;
        case "procesando":
          return Colors.blueAccent;
        case "activado":
          return Colors.green;
        case "bloqueado":
          return Colors.red.shade900;
        default:
          return Colors.grey;
      }
    }

    List filteredConductores = conductores.where((driver) {

      if (driver.rol.isNotEmpty && driver.rol != "carro") {
        return false;
      }

      final estado = (driver.verificacionStatus ?? "")
          .toString()
          .trim()
          .toLowerCase();

      print("👉 estado limpio: [$estado]"); // DEBUG

      if (mostrarSoloActivosBloqueados) {
        return estado.contains("activado") ||
            estado.contains("bloqueado");
      } else {
        return estado.contains("registrado") ||
            estado.contains("procesando");
      }

    }).toList();

    filteredConductores.sort((a, b) {
      int prioridadA = getPrioridad(a);
      int prioridadB = getPrioridad(b);

      /// 1️⃣ PRIORIDAD
      if (prioridadA != prioridadB) {
        return prioridadA.compareTo(prioridadB);
      }

      /// 2️⃣ FECHA
      final fechaA = a.the10FechaRegistroTimestamp;
      final fechaB = b.the10FechaRegistroTimestamp;

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;

      return fechaB.compareTo(fechaA);
    });


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
            Expanded(
              child: Text(
                mostrarSoloActivosBloqueados
                    ? 'Total de Conductores activos/bloqueados:\n$totalDrivers'
                    : 'Total de Conductores pendientes por activar:\n$totalDrivers',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                driverProvider.fetchDriversInicial();
              },
            ),
          ],
        ),

        const Divider(color: Colors.grey, height: 20, thickness: 2),

        Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  mostrarSoloActivosBloqueados =
                  !mostrarSoloActivosBloqueados;
                });
              },
              icon: Icon(
                mostrarSoloActivosBloqueados
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white,
              ),
              label: Text(
                mostrarSoloActivosBloqueados
                    ? "Ver pendientes"
                    : "Ver activados/bloqueados",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(height: 1, color: grisMedio),
        const SizedBox(height: 10),

        /// 🔥 CONTENIDO PRINCIPAL
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ✅ MODO ACTIVADOS/BLOQUEADOS
            if (mostrarSoloActivosBloqueados) ...[
              const SizedBox(height: 10),
              const Text(
                "Conductores activos y bloqueados",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildDriverTable(filteredConductores, getStatusColor),
            ]

            /// ✅ MODO PENDIENTES
            else ...[

              /// 🔥 PRIORIDAD
              if (filteredConductores.any((d) => getPrioridad(d) < 2)) ...[
                const SizedBox(height: 10),
                const Text(
                  "🚨 Prioridad (requieren atención)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildDriverTable(
                  filteredConductores
                      .where((d) => getPrioridad(d) < 2)
                      .toList(),
                  getStatusColor,
                ),
              ],

              /// 🔹 RESTO
              if (filteredConductores.any((d) => getPrioridad(d) >= 2)) ...[
                const SizedBox(height: 20),
                const Text(
                  "Conductores",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildDriverTable(
                  filteredConductores
                      .where((d) => getPrioridad(d) >= 2)
                      .toList(),
                  getStatusColor,
                ),
              ],
            ],
          ],
        ),
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
            Text(
              mostrarSoloActivosBloqueados
                  ? 'Total de Conductores activos/bloqueados:\n$totalDrivers'
                  : 'Total de Conductores pendientes por activar:\n$totalDrivers',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 100),
            ElevatedButton(
              onPressed: () {
                driverProvider.fetchDriversInicial();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Cargar Conductores',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),

        const Divider(color: Colors.grey, height: 20, thickness: 2),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSearchField(),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  mostrarSoloActivosBloqueados =
                  !mostrarSoloActivosBloqueados;
                });
              },
              icon: Icon(
                mostrarSoloActivosBloqueados
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.black,
              ),
              label: Text(
                mostrarSoloActivosBloqueados
                    ? "Ver pendientes"
                    : "Ver activados/bloqueados",
                style: const TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
        const Divider(height: 1, color: grisMedio),
        const SizedBox(height: 10),

        /// 🔥 CONTENIDO PRINCIPAL
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ✅ MODO ACTIVADOS/BLOQUEADOS
            if (mostrarSoloActivosBloqueados) ...[
              const SizedBox(height: 10),
              const Text(
                "Conductores activos y bloqueados",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              _buildDriverTable(filteredConductores, getStatusColor),
            ]

            /// ✅ MODO PENDIENTES (con prioridad)
            else ...[

              /// 🔥 PRIORIDAD
              if (filteredConductores.any((d) => getPrioridad(d) < 2)) ...[
                const SizedBox(height: 10),
                const Text(
                  "🚨 Prioridad (requieren atención)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildDriverTable(
                  filteredConductores
                      .where((d) => getPrioridad(d) < 2)
                      .toList(),
                  getStatusColor,
                ),
              ],

              /// 🔹 RESTO (IMPORTANTE 🔥)
              if (filteredConductores.any((d) => getPrioridad(d) >= 2)) ...[
                const SizedBox(height: 20),
                const Text(
                  "Conductores",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildDriverTable(
                  filteredConductores
                      .where((d) => getPrioridad(d) >= 2)
                      .toList(),
                  getStatusColor,
                ),
              ],
            ],
          ],
        )
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

        /// 🔥 SOLO PARA DETECTAR VACÍO (no para buscar)
        onChanged: (value) {
          if (value.trim().isEmpty) {
            Provider.of<DriverProvider>(context, listen: false)
                .fetchDriversInicial();
          }
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
                'Celular',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            DataColumn(
              label: Text(
                'Fecha registro',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      /// 👤 NOMBRE
                      Text(
                        driver.the01Nombres ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      /// 🏷️ ETIQUETA
                      if (tieneCorregida(driver))
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Corregido",
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (!tieneCorregida(driver) && tieneRechazada(driver))
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Rechazado",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                DataCell(Text(driver.the02Apellidos ?? "Apellidos no disponibles", style: const TextStyle(color: Colors.black))),
                DataCell(Text(driver.the03NumeroDocumento ?? "Documento no disponible")),
                DataCell(Text(driver.the07Celular ?? "Celular no disponible")),
                DataCell(
                  Builder(
                    builder: (_) {

                      // 🔥 CASO 1: Timestamp
                      if (driver.the10FechaRegistroTimestamp != null) {
                        return Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(driver.the10FechaRegistroTimestamp!.toDate()),
                        );
                      }

                      // 🔥 CASO 2: String
                      if (driver.the10FechaRegistroString != null &&
                          driver.the10FechaRegistroString!.isNotEmpty) {
                        return Text(driver.the10FechaRegistroString!);
                      }

                      return const Text("no disponible");
                    },
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

DateTime? parseFechaColombia(String input) {
  try {
    final partes = input.split(" - ");
    if (partes.length != 2) return null;

    final fechaParte = partes[0]; // "6 de abril/2026"
    final horaParte = partes[1];  // "16:01:21"

    final fechaSplit = fechaParte.split(" de ");
    if (fechaSplit.length != 2) return null;

    final dia = int.parse(fechaSplit[0]);

    final mesAnio = fechaSplit[1].split("/");
    final mesTexto = mesAnio[0].toLowerCase();
    final anio = int.parse(mesAnio[1]);

    final meses = {
      "enero": 1,
      "febrero": 2,
      "marzo": 3,
      "abril": 4,
      "mayo": 5,
      "junio": 6,
      "julio": 7,
      "agosto": 8,
      "septiembre": 9,
      "octubre": 10,
      "noviembre": 11,
      "diciembre": 12,
    };

    final mes = meses[mesTexto];
    if (mes == null) return null;

    final horaSplit = horaParte.split(":");
    final hora = int.parse(horaSplit[0]);
    final minuto = int.parse(horaSplit[1]);
    final segundo = int.parse(horaSplit[2]);

    return DateTime(anio, mes, dia, hora, minuto, segundo);
  } catch (_) {
    return null;
  }
}


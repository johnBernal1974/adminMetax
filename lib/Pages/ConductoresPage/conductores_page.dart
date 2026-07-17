import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/main_layout.dart';
import '../../models/conductor_model.dart';
import '../../models/operador_model.dart';
import '../../providers/driver_provider.dart';
import '../../src/color.dart';
import '../DriverDetailPage/driver_detail_page.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:convert';

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

  // Almacenamiento local aislado para Activos
  List<Driver> listaConductoresActivosLocal = [];
  bool cargandoActivosLocal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Carga los pendientes en el Provider de MetaX
      Provider.of<DriverProvider>(context, listen: false).fetchPendientesServidor();
      // 2. Ejecuta las consultas locales de soporte
      cargarErroresVehiculos();
      _cargarActivosDeFormaAislada();
    });
  }

  // Consulta única al iniciar la página para evitar retrasos al cambiar de pestaña
  Future<void> _cargarActivosDeFormaAislada() async {
    if (!mounted) return;
    setState(() {
      cargandoActivosLocal = true;
    });

    try {
      // Consulta directa y limpia sin filtros de rol
      final snapshotActivos = await FirebaseFirestore.instance
          .collection("Drivers")
          .where("Verificacion_Status", isEqualTo: "activado")
          .get();

      print("🟢 Conductores activados encontrados en Firestore: ${snapshotActivos.docs.length}");

      List<Driver> temporales = snapshotActivos.docs.map((doc) {
        final data = doc.data();
        data["id"] = doc.id;
        return Driver.fromJson(data);
      }).toList();

      if (mounted) {
        setState(() {
          listaConductoresActivosLocal = temporales;
          cargandoActivosLocal = false;
        });
      }
    } catch (e) {
      print("❌ Error obteniendo activos: $e");
      if (mounted) {
        setState(() {
          cargandoActivosLocal = false;
        });
      }
    }
  }

  int getPrioridad(Driver driver) {
    if (driver.the38EstaBloqueado == true) return 0;
    if (tieneCorregida(driver)) return 1;
    final estado = (driver.verificacionStatus ?? "").toLowerCase().trim();
    if (estado == "registrado") return 2;
    if (tieneRechazada(driver)) return 3;
    if (estado == "procesando") return 4;
    return 5;
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

  Future<void> cargarErroresVehiculos() async {
    final snapshot = await FirebaseFirestore.instance.collectionGroup("vehiculos").get();
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

  List ordenarConductores(List lista) {
    lista.sort((a, b) {
      final fechaA = a.the10FechaRegistroTimestamp;
      final fechaB = b.the10FechaRegistroTimestamp;

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;

      return fechaB.compareTo(fechaA);
    });
    return lista;
  }

  Color getStatusColor(dynamic driver) {
    final estadoVehiculo = driversEstadoVehiculo[driver.id];

    if (driver.the38EstaBloqueado == true) return Colors.red;
    if (tieneCorregida(driver) || estadoVehiculo == "corregida") return Colors.purple;
    if (tieneRechazada(driver) || estadoVehiculo == "rechazada") return Colors.orange;

    switch (driver?.verificacionStatus) {
      case "registrado": return Colors.blueGrey;
      case "procesando": return Colors.blueAccent;
      case "activado": return Colors.green;
      case "bloqueado": return Colors.red.shade900;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final conductores = driverProvider.drivers;

    List filteredConductores = conductores;

    // 1. REGISTRADOS
    final registrados = ordenarConductores(filteredConductores.where((d) {
      final estado = (d.verificacionStatus ?? "").toLowerCase().trim();
      return estado == "registrado" && !tieneCorregida(d) && !tieneRechazada(d);
    }).toList());

    // 2. CORREGIDOS
    final corregidos = ordenarConductores(filteredConductores.where((d) {
      final estado = (d.verificacionStatus ?? "").toLowerCase().trim();
      final estadoVehiculo = driversEstadoVehiculo[d.id];
      if (estado == "bloqueado" || d.the38EstaBloqueado == true) return false;
      return tieneCorregida(d) || estadoVehiculo == "corregida";
    }).toList());

    // 3. RECHAZADOS
    final rechazados = ordenarConductores(filteredConductores.where((d) {
      final estado = (d.verificacionStatus ?? "").toLowerCase().trim();
      if (estado == "bloqueado" || d.the38EstaBloqueado == true) return false;
      return tieneRechazada(d) && !tieneCorregida(d);
    }).toList());

    // 4. PROCESANDO
    final procesando = ordenarConductores(filteredConductores.where((d) {
      final estado = (d.verificacionStatus ?? "").toLowerCase().trim();
      final estadoVehiculo = driversEstadoVehiculo[d.id];
      if (estado == "bloqueado" || d.the38EstaBloqueado == true) return false;
      if (tieneCorregida(d) || estadoVehiculo == "corregida") return false;
      return estado == "procesando" && !tieneRechazada(d);
    }).toList());

    // 5. ACTIVADOS
    final activados = ordenarConductores(listaConductoresActivosLocal.where((d) {
      if (d.the38EstaBloqueado == true) return false;
      return true;
    }).toList());

    // 6. BLOQUEADOS
    final bloqueados = ordenarConductores([
      ...filteredConductores,
      ...listaConductoresActivosLocal,
    ].where((d) {
      final estado = (d.verificacionStatus ?? "").toLowerCase().trim();
      return estado == "bloqueado" || d.the38EstaBloqueado == true;
    }).toList().toSet().toList());

    totalDrivers = filteredConductores.length + activados.length;

    return MainLayout(
      pageTitle: 'Conductores',
      content: DefaultTabController(
        length: 6,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),

            // FILA SUPERIOR CORREGIDA (Sin duplicaciones anidadas)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                children: [
                  _buildSearchField(),
                  const Spacer(),

                  // 🔥 BOTÓN 1: Vencidos pero ya ACTIVADOS (App Funcional en la calle)
                  _buildBotonSegmentado(
                    context: context,
                    titulo: 'Activos Vencidos',
                    conductores: listaConductoresActivosLocal,
                    color: Colors.red,
                    icono: Icons.gpp_maybe_rounded,
                  ),
                  const SizedBox(width: 10),

                  // 🔥 BOTÓN 2: Vencidos en proceso de registro (Sin Activar)
                  _buildBotonSegmentado(
                    context: context,
                    titulo: 'Pendientes Vencidos',
                    conductores: filteredConductores,
                    color: Colors.orange,
                    icono: Icons.folder_zip_outlined,
                  ),
                  const SizedBox(width: 10),

                  IconButton(
                    icon: const Icon(Icons.refresh, size: 26),
                    color: Theme.of(context).primaryColor,
                    onPressed: () async {
                      driverProvider.limpiarCache();
                      driverProvider.fetchPendientesServidor();
                      await _cargarActivosDeFormaAislada();
                      await cargarErroresVehiculos();
                    },
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              width: double.infinity,
              child: TabBar(
                isScrollable: true,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: [
                  Tab(text: "🆕 Registrados (${registrados.length})"),
                  Tab(text: "🛠️ Corregidos (${corregidos.length})"),
                  Tab(text: "⏳ Procesando (${procesando.length})"),
                  Tab(text: "🚫 Rechazados (${rechazados.length})"),
                  Tab(text: "🟢 Activos (${activados.length})"),
                  Tab(text: "🔴 Bloqueados (${bloqueados.length})"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                margin: const EdgeInsets.all(7),
                child: TabBarView(
                  children: [
                    _buildTabContent(registrados, false),
                    _buildTabContent(corregidos, false),
                    _buildTabContent(procesando, false),
                    _buildTabContent(rechazados, false),
                    _buildTabContent(activados, cargandoActivosLocal),
                    _buildTabContent(bloqueados, false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Construye el botón compacto dinámico segmentado
  Widget _buildBotonSegmentado({
    required BuildContext context,
    required String titulo,
    required List<dynamic> conductores,
    required Color color,
    required IconData icono,
  }) {
    final filtrados = conductores.where((driver) => _vigenciaGlobalDriver(driver) == _VigEstado.vencido).toList();
    if (filtrados.isEmpty) return const SizedBox.shrink();

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.06),
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icono, color: color, size: 20),
      label: Text(
        '$titulo: ${filtrados.length}',
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
      ),
      onPressed: () {
        // Solución al error de mouse_tracker en Flutter Web posponiendo el renderizado
        Future.delayed(Duration.zero, () {
          if (context.mounted) {
            _mostrarPanelLateralVencidos(context, titulo, filtrados, color);
          }
        });
      },
    );
  }

  // 🔥 Muestra un contenedor lateral expandido (Sheet amplio) elegante para web desktop
  void _mostrarPanelLateralVencidos(BuildContext context, String titulo, List<dynamic> lista, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 500,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2)],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.warning_amber_rounded, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final driver = lista[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          title: Text(
                            '${driver.the01Nombres} ${driver.the02Apellidos}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Row(
                              children: [
                                Icon(Icons.credit_card_outlined, size: 13, color: color.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    documentosVencidosTexto(driver),
                                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                          onTap: () {
                            Navigator.pop(context);
                            _irADetalleConductor(driver);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(List listaConductores, bool estaCargandoPestana) {
    if (estaCargandoPestana) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (listaConductores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "No hay conductores disponibles en esta sección.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildDriverTable(listaConductores, getStatusColor),
      ),
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
                  .buscarDriver(query, mostrarSoloActivosBloqueados);
            },
          ),
        ),
        onSubmitted: (value) {
          Provider.of<DriverProvider>(context, listen: false)
              .buscarDriver(value.trim(), mostrarSoloActivosBloqueados);
        },
        onChanged: (value) {
          if (value.trim().isEmpty) {
            Provider.of<DriverProvider>(context, listen: false)
                .buscarDriver("", mostrarSoloActivosBloqueados);
          }
        },
      ),
    );
  }

  Widget _buildDriverTable(List filteredConductores, Color Function(dynamic) getStatusColor) {
    return DataTable(
      columnSpacing: 20.0,
      headingRowHeight: 56.0,
      dataRowHeight: 70.0,
      columns: const [
        DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Revisión', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Apellidos', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Identificación', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Celular', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Fecha registro', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: filteredConductores.map((driver) {
        return DataRow(
          onSelectChanged: (_) => _irADetalleConductor(driver),
          cells: [
            DataCell(
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, color: getStatusColor(driver)),
              ),
            ),
            DataCell(
              Builder(
                builder: (_) {
                  final revisado = driver.revisionEstado == "revisado";
                  final comentario = (driver.revisionComentario ?? "").isNotEmpty;
                  final activado = (driver.verificacionStatus ?? "").toLowerCase().trim() == "activado";

                  if (activado && driver.the38EstaBloqueado != true) {
                    return _buildBadge("Activado", Colors.green);
                  }
                  if (driver.the38EstaBloqueado == true || driver.verificacionStatus == "bloqueado") {
                    return _buildBadge("Bloqueado", Colors.red.shade900);
                  }
                  if (comentario) {
                    return Tooltip(
                      message: driver.revisionComentario ?? "",
                      preferBelow: false,
                      child: _buildBadge("Comentario", Colors.orange),
                    );
                  }
                  if (revisado) return _buildBadge("Revisado", Colors.black);
                  return _buildBadge("Pendiente", Colors.red);
                },
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(driver.the01Nombres ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (tieneCorregida(driver)) _buildMiniBadge("Corregido", Colors.purple),
                  if (!tieneCorregida(driver) && tieneRechazada(driver)) _buildMiniBadge("Rechazado", Colors.orange),
                ],
              ),
            ),
            DataCell(Text(driver.the02Apellidos ?? "Apellidos no disponibles", style: const TextStyle(color: Colors.black))),
            DataCell(Text(driver.the03NumeroDocumento ?? "Documento no disponible")),
            DataCell(Text(driver.the07Celular ?? "Celular no disponible")),
            DataCell(
              Builder(
                builder: (_) {
                  if (driver.the10FechaRegistroTimestamp != null) {
                    return Text(DateFormat('dd/MM/yyyy HH:mm').format(driver.the10FechaRegistroTimestamp!.toDate()));
                  }
                  return const Text("no disponible");
                },
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.double_arrow_outlined, color: Colors.black),
                onPressed: () => _irADetalleConductor(driver),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBadge(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildMiniBadge(String texto, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _irADetalleConductor(dynamic driver) async {
    await FirebaseFirestore.instance.collection("Drivers").doc(driver.id).update({
      "revision_estado": "revisado",
      "revision_fecha": FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => DriverDetailPage(driver: driver)));
    }
  }
}

// --- Métodos Auxiliares y Parsing de Fechas ---

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
  final diff = DateTime(vence.year, vence.month, vence.day).difference(hoy).inDays;
  if (diff < 0) return _VigEstado.vencido;
  return _VigEstado.vigente;
}

_VigEstado _peorEstado(List<_VigEstado> estados) {
  if (estados.contains(_VigEstado.vencido)) return _VigEstado.vencido;
  return _VigEstado.vigente;
}

_VigEstado _vigenciaGlobalDriver(dynamic driver) {
  final estados = <_VigEstado>[];

  final licenciaVence = _venceDiaAntes(driver.licenciaVigencia);
  estados.add(_estadoVig(licenciaVence));

  final soatVence = _venceDiaAntes(driver.soatVigencia);
  estados.add(_estadoVig(soatVence));

  final tecnoVence = _venceDiaAntes(driver.tecnoVigencia);
  estados.add(_estadoVig(tecnoVence));

  return _peorEstado(estados);
}

String documentosVencidosTexto(dynamic driver) {
  List<String> vencidos = [];
  if (_estadoVig(_venceDiaAntes(driver.licenciaVigencia)) == _VigEstado.vencido) vencidos.add('Licencia');
  if (_estadoVig(_venceDiaAntes(driver.soatVigencia)) == _VigEstado.vencido) vencidos.add('SOAT');
  if (_estadoVig(_venceDiaAntes(driver.tecnoVigencia)) == _VigEstado.vencido) vencidos.add('Tecnomecánica');
  return vencidos.join(' • ');
}
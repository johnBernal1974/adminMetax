import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/conductor_model.dart';

class EliteGroupTab extends StatefulWidget {
  final List<Driver> conductoresElite;
  final Function() onRefresh;

  const EliteGroupTab({
    Key? key,
    required this.conductoresElite,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _EliteGroupTabState createState() => _EliteGroupTabState();
}

class _EliteGroupTabState extends State<EliteGroupTab> {
  // 🎯 VALORES METAS CONFIGURABLES
  double _metaHoras = 208.0;
  int _metaUsuarios = 650;
  int _metaConductores = 10;
  bool _cargandoMetas = true;

  final List<Map<String, dynamic>> _mesesDisponibles = [
    {"label": "Julio 2026", "year": 2026, "month": 7},
    {"label": "Agosto 2026", "year": 2026, "month": 8},
    {"label": "Septiembre 2026", "year": 2026, "month": 9},
    {"label": "Octubre 2026", "year": 2026, "month": 10},
    {"label": "Noviembre 2026", "year": 2026, "month": 11},
    {"label": "Diciembre 2026", "year": 2026, "month": 12},
  ];

  late Map<String, dynamic> _mesSeleccionado;

  // 🟢 CACHÉ EN MEMORIA
  final Map<String, Map<String, dynamic>> _cacheMetricas = {};

  @override
  void initState() {
    super.initState();
    _mesSeleccionado = _mesesDisponibles[0];

    // 🔔 Escucha cambios en vivo de las metas
    FirebaseFirestore.instance
        .collection("ParametrosElite")
        .doc("configuracion_actual")
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (mounted) {
          setState(() {
            _metaHoras = (data["metaHoras"] as num?)?.toDouble() ?? 208.0;
            _metaUsuarios = (data["metaUsuarios"] as num?)?.toInt() ?? 650;
            _metaConductores = (data["metaConductores"] as num?)?.toInt() ?? 10;
            _cargandoMetas = false;

            _cacheMetricas.clear();
          });
        }
      }
    });
  }

  // 🕒 FUNCIÓN PARA FORMATEAR LAS HORAS Y MINUTOS
  String _formatearTiempoDesdeHoras(double horasDecimales) {
    int horas = horasDecimales.floor();
    int minutos = ((horasDecimales - horas) * 60).round();

    if (horas > 0 && minutos > 0) {
      return "$horas h, $minutos min";
    } else if (horas > 0 && minutos == 0) {
      return "$horas h";
    } else {
      return "$minutos min";
    }
  }

  // --- FÓRMULAS DE CÁLCULO DE PUNTOS ---
  double _calcularPuntosHoras(double horas) => ((horas / _metaHoras) * 40).clamp(0.0, 40.0);
  double _calcularPuntosUsuarios(int usuarios) => ((usuarios / _metaUsuarios) * 40).clamp(0.0, 40.0);
  double _calcularPuntosConductores(int conductores) => ((conductores / _metaConductores) * 20).clamp(0.0, 20.0);

  double _calcularPuntajeTotal(double horas, int usuarios, int conductores) {
    return _calcularPuntosHoras(horas) +
        _calcularPuntosUsuarios(usuarios) +
        _calcularPuntosConductores(conductores);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoMetas) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 10.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSelectorMes(isMobile),
              const SizedBox(height: 20),
              _buildRankingEscuadrones(isMobile),
              const SizedBox(height: 20),
              Text(
                "Matriz de Liquidación Individual (${widget.conductoresElite.length}/60)",
                style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTablaLiquidacion(isMobile),
            ],
          ),
        );
      },
    );
  }

  // 🏆 HEADER SELECTOR DE MES
  Widget _buildHeaderSelectorMes(bool isMobile) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade900,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile)
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    "Seguimiento Grupo Élite",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _mesSeleccionado,
                        dropdownColor: Colors.grey.shade900,
                        icon: const Icon(Icons.calendar_month, color: Colors.amber),
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                        onChanged: (Map<String, dynamic>? nuevoMes) {
                          if (nuevoMes != null) {
                            setState(() {
                              _mesSeleccionado = nuevoMes;
                              _cacheMetricas.clear();
                            });
                          }
                        },
                        items: _mesesDisponibles.map((mes) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: mes,
                            child: Text(mes["label"]),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Seguimiento Grupo Élite",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade700),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Map<String, dynamic>>(
                            value: _mesSeleccionado,
                            dropdownColor: Colors.grey.shade900,
                            icon: const Icon(Icons.calendar_month, color: Colors.amber, size: 18),
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                            onChanged: (Map<String, dynamic>? nuevoMes) {
                              if (nuevoMes != null) {
                                setState(() {
                                  _mesSeleccionado = nuevoMes;
                                  _cacheMetricas.clear();
                                });
                              }
                            },
                            items: _mesesDisponibles.map((mes) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: mes,
                                child: Text(mes["label"]),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const Divider(color: Colors.white24, height: 24),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Metas Configuradas: ${_metaHoras.toStringAsFixed(0)}h / ${_metaUsuarios} Clientes / ${_metaConductores} Conds",
                      style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 12),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // 2. TARJETAS RESUMEN DE ESCUADRONES
  Widget _buildRankingEscuadrones(bool isMobile) {
    if (!isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(6, (index) {
              final escuadronNum = index + 1;
              final miembros = widget.conductoresElite
                  .where((d) => d.escuadronId == escuadronNum)
                  .toList();
              final tieneMiembros = miembros.isNotEmpty;

              return InkWell(
                onTap: () {
                  _mostrarDetalleEscuadron(escuadronNum, miembros, isMobile);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: (constraints.maxWidth / 3) - 12,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tieneMiembros ? Colors.white : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tieneMiembros ? Colors.amber.shade300 : Colors.grey.shade200,
                    ),
                    boxShadow: tieneMiembros
                        ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]
                        : [],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: tieneMiembros ? Colors.amber.shade100 : Colors.grey.shade200,
                        child: Text(
                          "$escuadronNum",
                          style: TextStyle(
                            color: tieneMiembros ? Colors.amber.shade900 : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Escuadrón $escuadronNum",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: tieneMiembros ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            Text(
                              "${miembros.length}/10 Integrantes",
                              style: TextStyle(
                                color: tieneMiembros ? Colors.grey.shade700 : Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!tieneMiembros)
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("0.00 Pts", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text("Vacío", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        )
                      else
                        FutureBuilder<double>(
                          future: _calcularPromedioRealEscuadron(miembros),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }

                            final promedioReal = snapshot.data ?? 0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${promedioReal.toStringAsFixed(2)} Pts",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const Text("Promedio", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          final escuadronNum = index + 1;
          final miembros = widget.conductoresElite.where((d) => d.escuadronId == escuadronNum).toList();
          final tieneMiembros = miembros.isNotEmpty;

          return InkWell(
            onTap: () {
              _mostrarDetalleEscuadron(escuadronNum, miembros, isMobile);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tieneMiembros ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tieneMiembros ? Colors.amber.shade400 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: tieneMiembros ? Colors.amber.shade100 : Colors.grey.shade300,
                    child: Text(
                      "$escuadronNum",
                      style: TextStyle(
                        color: tieneMiembros ? Colors.amber.shade900 : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Escuadrón $escuadronNum",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${miembros.length}/10 Miembros",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (!tieneMiembros)
                    const Text("0.00", style: TextStyle(fontSize: 11, color: Colors.grey))
                  else
                    FutureBuilder<double>(
                      future: _calcularPromedioRealEscuadron(miembros),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        final promedioReal = snapshot.data ?? 0.0;
                        return Text(
                          "${promedioReal.toStringAsFixed(2)}p",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<double> _calcularPromedioRealEscuadron(List<Driver> miembros) async {
    if (miembros.isEmpty) return 0.0;
    double sumaPuntajes = 0.0;

    for (var driver in miembros) {
      final data = await obtenerMetricasRealesDriver(
        driver.id,
        _mesSeleccionado["year"] as int,
        _mesSeleccionado["month"] as int,
      );

      double horas = (data["horas"] as num).toDouble();
      int usuarios = data["usuarios"] as int;
      int conductores = data["conductores"] as int;

      sumaPuntajes += _calcularPuntajeTotal(horas, usuarios, conductores);
    }

    return sumaPuntajes / miembros.length;
  }

  // 3. TABLA MATRIZ DE LIQUIDACIÓN
  Widget _buildTablaLiquidacion(bool isMobile) {
    if (widget.conductoresElite.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(30.0),
          child: Center(child: Text("Aún no has marcado conductores como Élite.")),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        columnSpacing: isMobile ? 14 : 20,
        columns: [
          DataColumn(label: Text("Conductor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
          DataColumn(label: Text("Escuadrón", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
          DataColumn(label: Text("Horas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
          DataColumn(label: Text("Clientes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
          DataColumn(label: Text("Conds", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
          DataColumn(label: Text("Total Pts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
          DataColumn(label: Text("Estado 70%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14))),
        ],
        rows: widget.conductoresElite.map((driver) {
          final String fotoUrl = driver.image;

          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 16 : 18,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: (fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
                      child: (fotoUrl.isEmpty) ? const Icon(Icons.person, size: 18, color: Colors.grey) : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${driver.the01Nombres} ${driver.the02Apellidos}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14)),
                        Text("C.C. ${driver.the03NumeroDocumento}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(driver.escuadronId != null ? "E-${driver.escuadronId}" : "Sin E.", style: TextStyle(fontSize: isMobile ? 12 : 14))),
              ...List.generate(5, (indexCell) {
                return DataCell(
                  FutureBuilder<Map<String, dynamic>>(
                    future: obtenerMetricasRealesDriver(
                      driver.id,
                      _mesSeleccionado["year"] as int,
                      _mesSeleccionado["month"] as int,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return indexCell == 0
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("...", style: TextStyle(color: Colors.grey));
                      }

                      final data = snapshot.data ?? {"horas": 0.0, "usuarios": 0, "conductores": 0};

                      double horasReales = (data["horas"] as num).toDouble();
                      int usuariosReales = data["usuarios"] as int;
                      int condsReales = data["conductores"] as int;

                      double ptsHoras = _calcularPuntosHoras(horasReales);
                      double ptsUsers = _calcularPuntosUsuarios(usuariosReales);
                      double ptsConds = _calcularPuntosConductores(condsReales);

                      double scoreTotal = ptsHoras + ptsUsers + ptsConds;
                      bool califica = scoreTotal >= 70.0;

                      switch (indexCell) {
                        case 0:
                        // ⏰ Horas y debajo sus Puntos
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_formatearTiempoDesdeHoras(horasReales), style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w600)),
                              Text("Puntos: ${ptsHoras.toStringAsFixed(2)}", style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                            ],
                          );
                        case 1:
                        // 👥 Clientes (Solo número) y debajo sus Puntos
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("$usuariosReales", style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w600)),
                              Text("Puntos: ${ptsUsers.toStringAsFixed(2)}", style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                            ],
                          );
                        case 2:
                        // 🚗 Conductores (Solo número) y debajo sus Puntos
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("$condsReales", style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w600)),
                              Text("Puntos: ${ptsConds.toStringAsFixed(2)}", style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                            ],
                          );
                        case 3:
                        // Total Pts
                          return Text(
                            scoreTotal.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 12 : 14,
                              color: califica ? Colors.green.shade800 : Colors.red,
                            ),
                          );
                        case 4:
                        // Estado 70% (Sin la palabra reprobado)
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: califica ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              califica ? "✅ CALIFICA" : "⚠️ NO CALIFICA",
                              style: TextStyle(
                                color: califica ? Colors.green.shade800 : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        default:
                          return const Text("");
                      }
                    },
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  // 🟢 CONSULTA REAL DE MÉTRICAS
  Future<Map<String, dynamic>> obtenerMetricasRealesDriver(
      String driverId,
      int anio,
      int mes,
      ) async {
    final String uidLimpia = driverId.trim();
    final String keyCache = "${uidLimpia}_${anio}_$mes";

    if (_cacheMetricas.containsKey(keyCache)) {
      return _cacheMetricas[keyCache]!;
    }

    double horasTotales = 0.0;
    int clientesReferidos = 0;
    int conductoresReferidos = 0;

    try {
      final snapshotEstadisticas = await FirebaseFirestore.instance
          .collection("EstadisticasDiarias")
          .where("idDriver", isEqualTo: uidLimpia)
          .get();

      int segundosAcumulados = 0;
      for (var doc in snapshotEstadisticas.docs) {
        final data = doc.data();
        DateTime? fechaDocParsed;
        dynamic fechaRaw = data["fecha"] ?? data["createdAt"] ?? data["timestamp"];

        if (fechaRaw is Timestamp) {
          fechaDocParsed = fechaRaw.toDate();
        } else if (fechaRaw is String) {
          fechaDocParsed = DateTime.tryParse(fechaRaw);
        }

        if (fechaDocParsed != null) {
          if (fechaDocParsed.year == anio && fechaDocParsed.month == mes) {
            segundosAcumulados += (data["totalSegundos"] ?? 0) as int;
          }
        } else if (fechaRaw is String) {
          final partes = fechaRaw.split('-');
          if (partes.length >= 2) {
            int? a = int.tryParse(partes[0]);
            int? m = int.tryParse(partes[1]);
            if (a == anio && m == mes) {
              segundosAcumulados += (data["totalSegundos"] ?? 0) as int;
            }
          }
        }
      }
      horasTotales = segundosAcumulados / 3600.0;

      final snapshotClients = await FirebaseFirestore.instance
          .collection("Clients")
          .where("idInvitadoPor", isEqualTo: uidLimpia)
          .get();

      for (var doc in snapshotClients.docs) {
        final data = doc.data();
        dynamic fechaRaw = data["21_Fecha_de_registro"] ?? data["createdAt"] ?? data["fechaRegistro"];
        DateTime? fechaRegistro = _parsearFechaEspecial(fechaRaw);

        if (fechaRegistro != null) {
          if (fechaRegistro.year == anio && fechaRegistro.month == mes) {
            clientesReferidos++;
          }
        }
      }

      final snapshotDrivers = await FirebaseFirestore.instance
          .collection("Drivers")
          .where("idInvitadoPor", isEqualTo: uidLimpia)
          .get();

      for (var doc in snapshotDrivers.docs) {
        final data = doc.data();
        final bool estaActivadoBool = data["11_Esta_activado"] == true;
        final String statusStr = (data["Verificacion_Status"] ?? "").toString().toLowerCase();

        if (estaActivadoBool || statusStr == "activado") {
          dynamic fechaRaw = data["10_Fecha_Registro_Timestamp"] ??
              data["10_Fecha_Registro_timestamp"] ??
              data["12_Fecha_Activacion"] ??
              data["createdAt"];

          DateTime? fechaRegistro = _parsearFechaEspecial(fechaRaw);

          if (fechaRegistro != null) {
            if (fechaRegistro.year == anio && fechaRegistro.month == mes) {
              conductoresReferidos++;
            }
          }
        }
      }

    } catch (e) {
      print("❌ Error consultando métricas reales del driver $uidLimpia: $e");
    }

    final resultado = {
      "horas": horasTotales,
      "usuarios": clientesReferidos,
      "conductores": conductoresReferidos,
    };

    _cacheMetricas[keyCache] = resultado;

    return resultado;
  }

  // 🛠️ PARSER INTELIGENTE DE FECHAS
  DateTime? _parsearFechaEspecial(dynamic fechaRaw) {
    if (fechaRaw == null) return null;

    if (fechaRaw is Timestamp) {
      return fechaRaw.toDate();
    }

    if (fechaRaw is String) {
      DateTime? parsedStd = DateTime.tryParse(fechaRaw);
      if (parsedStd != null) return parsedStd;

      try {
        final str = fechaRaw.toLowerCase();
        int anio = 0;
        int mes = 0;

        final regAnio = RegExp(r'20\d{2}');
        final matchAnio = regAnio.firstMatch(str);
        if (matchAnio != null) {
          anio = int.parse(matchAnio.group(0)!);
        }

        if (str.contains('enero')) mes = 1;
        else if (str.contains('febrero')) mes = 2;
        else if (str.contains('marzo')) mes = 3;
        else if (str.contains('abril')) mes = 4;
        else if (str.contains('mayo')) mes = 5;
        else if (str.contains('junio')) mes = 6;
        else if (str.contains('julio')) mes = 7;
        else if (str.contains('agosto')) mes = 8;
        else if (str.contains('septiembre')) mes = 9;
        else if (str.contains('octubre')) mes = 10;
        else if (str.contains('noviembre')) mes = 11;
        else if (str.contains('diciembre')) mes = 12;

        if (anio > 0 && mes > 0) {
          return DateTime(anio, mes, 1);
        }
      } catch (_) {}
    }

    return null;
  }

  // 🪟 MODAL DETALLE DE ESCUADRÓN
  void _mostrarDetalleEscuadron(int escuadronNum, List<Driver> miembros, bool isMobile) {
    if (!isMobile) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  child: Text("$escuadronNum", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Escuadrón $escuadronNum", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("${miembros.length}/10 Integrantes | Mes: ${_mesSeleccionado['label']}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const Spacer(),

                if (miembros.isNotEmpty)
                  FutureBuilder<double>(
                    future: _calcularPromedioRealEscuadron(miembros),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      final promedio = snapshot.data ?? 0.0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text("Promedio Escuadrón", style: TextStyle(fontSize: 10, color: Colors.indigo)),
                            Text(
                              "${promedio.toStringAsFixed(2)} Pts",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: miembros.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: Text("Este escuadrón no tiene integrantes asignados actualmente.")),
              )
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.amber.shade50),
                  columns: const [
                    DataColumn(label: Text("Conductor", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Cédula", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Horas", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Clientes", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Conds", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Total Pts", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Estado", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: miembros.map((driver) {
                    final String fotoUrl = driver.image;

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: (fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
                                child: (fotoUrl.isEmpty) ? const Icon(Icons.person, size: 16, color: Colors.grey) : null,
                              ),
                              const SizedBox(width: 8),
                              Text("${driver.the01Nombres} ${driver.the02Apellidos}",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(Text(driver.the03NumeroDocumento ?? "S/N")),

                        ...List.generate(5, (indexCell) {
                          return DataCell(
                            FutureBuilder<Map<String, dynamic>>(
                              future: obtenerMetricasRealesDriver(
                                driver.id,
                                _mesSeleccionado["year"] as int,
                                _mesSeleccionado["month"] as int,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                      width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2));
                                }

                                final data = snapshot.data ?? {"horas": 0.0, "usuarios": 0, "conductores": 0};

                                double horas = (data["horas"] as num).toDouble();
                                int usuarios = data["usuarios"] as int;
                                int conds = data["conductores"] as int;

                                double ptsH = _calcularPuntosHoras(horas);
                                double ptsU = _calcularPuntosUsuarios(usuarios);
                                double ptsC = _calcularPuntosConductores(conds);

                                double total = ptsH + ptsU + ptsC;
                                bool califica = total >= 70.0;

                                switch (indexCell) {
                                  case 0:
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(_formatearTiempoDesdeHoras(horas), style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text("Puntos: ${ptsH.toStringAsFixed(2)}", style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                                      ],
                                    );
                                  case 1:
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("$usuarios", style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text("Puntos: ${ptsU.toStringAsFixed(2)}", style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                                      ],
                                    );
                                  case 2:
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("$conds", style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text("Puntos: ${ptsC.toStringAsFixed(2)}", style: TextStyle(fontSize: 10, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                                      ],
                                    );
                                  case 3:
                                    return Text(
                                      total.toStringAsFixed(2),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: califica ? Colors.green.shade800 : Colors.red),
                                    );
                                  case 4:
                                    return Text(
                                      califica ? "✅ CALIFICA" : "⚠️ NO CALIFICA",
                                      style: TextStyle(
                                          color: califica ? Colors.green.shade800 : Colors.orange.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11),
                                    );
                                  default:
                                    return const Text("");
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar", style: TextStyle(color: Colors.white)),
              )
            ],
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: Text("$escuadronNum", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Escuadrón $escuadronNum", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${miembros.length}/10 Integrantes | ${_mesSeleccionado['label']}",
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (miembros.isNotEmpty)
                      FutureBuilder<double>(
                        future: _calcularPromedioRealEscuadron(miembros),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final promedio = snapshot.data ?? 0.0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Text(
                              "${promedio.toStringAsFixed(2)} Pts",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(height: 20),
                Expanded(
                  child: miembros.isEmpty
                      ? const Center(child: Text("Este escuadrón no tiene integrantes asignados."))
                      : ListView.builder(
                    itemCount: miembros.length,
                    itemBuilder: (context, index) {
                      final driver = miembros[index];
                      final String fotoUrl = driver.image;

                      return FutureBuilder<Map<String, dynamic>>(
                        future: obtenerMetricasRealesDriver(
                          driver.id,
                          _mesSeleccionado["year"] as int,
                          _mesSeleccionado["month"] as int,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: LinearProgressIndicator(),
                              ),
                            );
                          }

                          final data = snapshot.data ?? {"horas": 0.0, "usuarios": 0, "conductores": 0};

                          double horas = (data["horas"] as num).toDouble();
                          int usuarios = data["usuarios"] as int;
                          int conds = data["conductores"] as int;

                          double ptsH = _calcularPuntosHoras(horas);
                          double ptsU = _calcularPuntosUsuarios(usuarios);
                          double ptsC = _calcularPuntosConductores(conds);

                          double total = ptsH + ptsU + ptsC;
                          bool califica = total >= 70.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage: (fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
                                        child: (fotoUrl.isEmpty) ? const Icon(Icons.person, size: 18, color: Colors.grey) : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${driver.the01Nombres} ${driver.the02Apellidos}",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text("C.C. ${driver.the03NumeroDocumento ?? 'S/N'}",
                                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: califica ? Colors.green.shade50 : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          califica ? "CALIFICA" : "NO CALIFICA",
                                          style: TextStyle(
                                            color: califica ? Colors.green.shade800 : Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("⏰ ${_formatearTiempoDesdeHoras(horas)} (${ptsH.toStringAsFixed(2)}p)",
                                          style: const TextStyle(fontSize: 11)),
                                      Text("👥 $usuarios (${ptsU.toStringAsFixed(2)}p)",
                                          style: const TextStyle(fontSize: 11)),
                                      Text("🚗 $conds (${ptsC.toStringAsFixed(2)}p)",
                                          style: const TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Puntaje: ${total.toStringAsFixed(2)} Pts",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: califica ? Colors.green.shade800 : Colors.red,
                                          )),
                                    ],
                                  ),
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
          );
        },
      );
    }
  }
}
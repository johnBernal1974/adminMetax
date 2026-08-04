import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _utilidadesController = TextEditingController(text: "15800000");
  double bolsaTotal = 15800000;

  final NumberFormat _copFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  // 🎯 VALORES METAS CONFIGURABLES (Valores por defecto mientras carga BD)
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

  // 🟢 CACHÉ EN MEMORIA: Evita duplicar lecturas en Firestore por cada render
  final Map<String, Map<String, dynamic>> _cacheMetricas = {};

  // ⚙️ EN LUGAR DE AWAIT .get(), USA UN STREAM LISTENER EN initState()
  @override
  void initState() {
    super.initState();
    _mesSeleccionado = _mesesDisponibles[0];

    _utilidadesController.addListener(() {
      final text = _utilidadesController.text.replaceAll(RegExp(r'[^0-9]'), '');
      setState(() {
        bolsaTotal = double.tryParse(text) ?? 0;
      });
    });

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

            _cacheMetricas.clear(); // 🧹 Limpia caché al recibir nuevos valores
          });
        }
      }
    });
  }


  // ⚙️ CARGA DINÁMICA DE METAS DESDE FIRESTORE
  Future<void> _cargarParametrosMetas() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection("ParametrosElite")
          .doc("configuracion_actual")
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (mounted) {
          setState(() {
            _metaHoras = (data["metaHoras"] as num?)?.toDouble() ?? 208.0;
            _metaUsuarios = (data["metaUsuarios"] as num?)?.toInt() ?? 650;
            _metaConductores = (data["metaConductores"] as num?)?.toInt() ?? 10;
            _cargandoMetas = false;

            // 🧹 LIMPIAMOS EL CACHÉ PARA RECALCULAR LOS PUNTAJES CON LAS NUEVAS METAS
            _cacheMetricas.clear();
          });
        }
      } else {
        if (mounted) setState(() => _cargandoMetas = false);
      }
    } catch (e) {
      print("❌ Error cargando parámetros de metas desde Firestore: $e");
      if (mounted) setState(() => _cargandoMetas = false);
    }
  }

  // --- FÓRMULAS DE CÁLCULO DE PUNTOS (USANDO LAS METAS DINÁMICAS) ---
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

    final bolsaGeneral80 = bolsaTotal * 0.80;
    final bolsaCampeones20 = bolsaTotal * 0.20;

    double sumaPuntosAprobados = 100; // Valor de respaldo
    final valorPorPunto = sumaPuntosAprobados > 0 ? (bolsaGeneral80 / sumaPuntosAprobados) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderFinanciero(bolsaGeneral80, bolsaCampeones20, valorPorPunto),
          const SizedBox(height: 20),
          _buildRankingEscuadrones(valorPorPunto, bolsaCampeones20),
          const SizedBox(height: 20),
          Text(
            "Matriz de Liquidación Individual (${widget.conductoresElite.length}/60)",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildTablaLiquidacion(valorPorPunto, bolsaCampeones20),
        ],
      ),
    );
  }

  Widget _buildHeaderFinanciero(double bolsa80, double bolsa20, double valorPunto) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                const Text(
                  "Liquidación de Bolsa",
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
                            _cacheMetricas.clear(); // Limpia caché al cambiar de mes
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
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _utilidadesController,
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Bolsa Total (\$)",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixText: "\$ ",
                      prefixStyle: const TextStyle(color: Colors.amber),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard("Bolsa General (80%)", _copFormat.format(bolsa80), Colors.greenAccent),
                _buildMetricCard("Bolsa Campeones (20%)", _copFormat.format(bolsa20), Colors.amberAccent),
                _buildMetricCard("Valor por Punto", _copFormat.format(valorPunto), Colors.cyanAccent),
              ],
            ),
            const SizedBox(height: 12),

            // ℹ️ RESUMEN VISUAL DE LAS METAS VIGENTES
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
                  Text(
                    "Metas Configurada: ${_metaHoras.toStringAsFixed(0)}h / ${_metaUsuarios} Clientes / ${_metaConductores} Conds",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String amount, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // 2. TARJETAS RESUMEN DE ESCUADRONES (1 al 6)
  Widget _buildRankingEscuadrones(double valorPorPunto, double bolsa20) {
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
                _mostrarDetalleEscuadron(
                  escuadronNum,
                  miembros,
                  valorPorPunto,
                  bolsa20,
                );
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
                          Text("0.0 Pts", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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
                                "${promedioReal.toStringAsFixed(1)} Pts",
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

  Widget _buildTablaLiquidacion(double valorPorPunto, double bolsa20) {
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
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text("Conductor", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Escuadrón", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Horas (40pts)", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Clientes (40pts)", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Conds (20pts)", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Total Pts", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Estado 70%", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Pago 80%", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Bono #1", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("TOTAL A PAGAR", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: widget.conductoresElite.map((driver) {
          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${driver.the01Nombres} ${driver.the02Apellidos}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("C.C. ${driver.the03NumeroDocumento}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              DataCell(Text(driver.escuadronId != null ? "E-${driver.escuadronId}" : "Sin E.")),
              ...List.generate(8, (indexCell) {
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

                      double pagoBolsa80 = califica ? (scoreTotal * valorPorPunto) : 0.0;
                      bool esDelGanador = driver.escuadronId == 1;
                      int integrantesEscuadron1 = widget.conductoresElite.where((d) => d.escuadronId == 1).length;

                      double bonoCampeon = (califica && esDelGanador && integrantesEscuadron1 > 0)
                          ? (bolsa20 / 3) / integrantesEscuadron1
                          : 0.0;

                      double totalCheque = pagoBolsa80 + bonoCampeon;

                      switch (indexCell) {
                        case 0:
                          return Text("${horasReales.toStringAsFixed(1)} h (${ptsHoras.toStringAsFixed(1)})");
                        case 1:
                          return Text("$usuariosReales (${ptsUsers.toStringAsFixed(1)})");
                        case 2:
                          return Text("$condsReales (${ptsConds.toStringAsFixed(1)})");
                        case 3:
                          return Text(
                            scoreTotal.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: califica ? Colors.green.shade800 : Colors.red,
                            ),
                          );
                        case 4:
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: califica ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              califica ? "✅ CALIFICA" : "❌ REPROBADO",
                              style: TextStyle(
                                color: califica ? Colors.green.shade800 : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          );
                        case 5:
                          return Text(_copFormat.format(pagoBolsa80));
                        case 6:
                          return Text(_copFormat.format(bonoCampeon), style: const TextStyle(color: Colors.amber));
                        case 7:
                          return Text(
                            _copFormat.format(totalCheque),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                              fontSize: 14,
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

  // 🟢 FUNCIÓN CON CACHÉ DE MEMORIA
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

    final DateTime primerDia = DateTime(anio, mes, 1);
    final DateTime ultimoDia = DateTime(anio, mes + 1, 0);

    final String mesInicioStr = DateFormat('yyyy-MM-dd').format(primerDia);
    final String mesFinStr = DateFormat('yyyy-MM-dd').format(ultimoDia);

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
        final String? fechaDoc = data["fecha"];

        if (fechaDoc != null &&
            fechaDoc.compareTo(mesInicioStr) >= 0 &&
            fechaDoc.compareTo(mesFinStr) <= 0) {
          segundosAcumulados += (data["totalSegundos"] ?? 0) as int;
        }
      }
      horasTotales = segundosAcumulados / 3600.0;

      final snapshotClients = await FirebaseFirestore.instance
          .collection("Clients")
          .where("idInvitadoPor", isEqualTo: uidLimpia)
          .get();

      for (var doc in snapshotClients.docs) {
        final data = doc.data();
        dynamic fechaRaw = data["createdAt"] ?? data["fechaRegistro"];
        DateTime? fechaRegistro;

        if (fechaRaw is Timestamp) {
          fechaRegistro = fechaRaw.toDate();
        } else if (fechaRaw is String) {
          fechaRegistro = DateTime.tryParse(fechaRaw);
        }

        if (fechaRegistro != null) {
          if (fechaRegistro.year == anio && fechaRegistro.month == mes) {
            clientesReferidos++;
          }
        } else {
          clientesReferidos++;
        }
      }

      final snapshotDrivers = await FirebaseFirestore.instance
          .collection("Drivers")
          .where("idInvitadoPor", isEqualTo: uidLimpia)
          .get();

      for (var doc in snapshotDrivers.docs) {
        final data = doc.data();
        final estado = (data["Verificacion_Status"] ?? "").toString().toLowerCase();

        if (estado == "activado") {
          dynamic fechaRaw = data["10_Fecha_Registro_timestamp"] ?? data["createdAt"];
          DateTime? fechaRegistro;

          if (fechaRaw is Timestamp) {
            fechaRegistro = fechaRaw.toDate();
          } else if (fechaRaw is String) {
            fechaRegistro = DateTime.tryParse(fechaRaw);
          }

          if (fechaRegistro != null) {
            if (fechaRegistro.year == anio && fechaRegistro.month == mes) {
              conductoresReferidos++;
            }
          } else {
            conductoresReferidos++;
          }
        }
      }

    } catch (e) {
      print("❌ Error consultando métricas del driver $uidLimpia: $e");
    }

    final resultado = {
      "horas": horasTotales,
      "usuarios": clientesReferidos,
      "conductores": conductoresReferidos,
    };

    _cacheMetricas[keyCache] = resultado;

    return resultado;
  }

  // 🪟 MODAL DE DETALLE DEL ESCUADRÓN CON PROMEDIO
  void _mostrarDetalleEscuadron(int escuadronNum, List<Driver> miembros, double valorPorPunto, double bolsa20) {
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
                            "${promedio.toStringAsFixed(1)} Pts",
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
                  DataColumn(label: Text("Horas (40pts)", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Clientes (40pts)", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Conds (20pts)", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Total Pts", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Estado", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Pago Estimado", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: miembros.map((driver) {
                  return DataRow(
                    cells: [
                      DataCell(Text("${driver.the01Nombres} ${driver.the02Apellidos}",
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(driver.the03NumeroDocumento ?? "S/N")),

                      ...List.generate(6, (indexCell) {
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

                              double pago80 = califica ? (total * valorPorPunto) : 0.0;
                              bool esDelGanador = escuadronNum == 1;
                              double bono = (califica && esDelGanador) ? ((bolsa20 / 3) / miembros.length) : 0.0;

                              switch (indexCell) {
                                case 0:
                                  return Text("${horas.toStringAsFixed(1)} h (${ptsH.toStringAsFixed(1)})");
                                case 1:
                                  return Text("$usuarios (${ptsU.toStringAsFixed(1)})");
                                case 2:
                                  return Text("$conds (${ptsC.toStringAsFixed(1)})");
                                case 3:
                                  return Text(
                                    total.toStringAsFixed(1),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: califica ? Colors.green.shade800 : Colors.red),
                                  );
                                case 4:
                                  return Text(
                                    califica ? "✅ CALIFICA" : "❌ REPROBADO",
                                    style: TextStyle(
                                        color: califica ? Colors.green.shade800 : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  );
                                case 5:
                                  return Text(_copFormat.format(pago80 + bono),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent));
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
  }
}
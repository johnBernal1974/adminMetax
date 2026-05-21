import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/main_layout.dart';
import '../../src/color.dart';

import 'package:csv/csv.dart';

import 'dart:convert';

import 'dart:typed_data';

import 'package:universal_html/html.dart'
as html;

class HistorialBonosPage extends StatefulWidget {

  const HistorialBonosPage({super.key});

  @override
  State<HistorialBonosPage>
  createState() =>
      _HistorialBonosPageState();
}

class _HistorialBonosPageState
    extends State<HistorialBonosPage> {

  bool loading = true;

  List<QueryDocumentSnapshot>
  bonos = [];

  Map<String,
      List<QueryDocumentSnapshot>>
  bonosPorSemana = {};

  String semanaSeleccionada =
      'Todas';

  List<QueryDocumentSnapshot>
  bonosFiltrados = [];

  int totalBonos = 0;

  int totalPendientes = 0;

  int totalNequi = 0;

  int totalSaldoMetax = 0;

  final ScrollController
  _tableScrollController =
  ScrollController();


  @override
  void initState() {
    super.initState();
    cargarBonos();
  }

  Future<void> cargarBonos() async {

    try {

      setState(() {
        loading = true;
      });

      final snap =

      await FirebaseFirestore.instance

          .collection('TravelHistory')

          .where(
        'bono_promocional',
        isEqualTo: true,
      )

          .orderBy(
        'bonoPagadoAt',
        descending: true,
      )

          .get();

      bonos = snap.docs;

      totalBonos = 0;
      totalPendientes = 0;
      totalNequi = 0;
      totalSaldoMetax = 0;

      for (final doc in bonos) {

        final data =
        doc.data()
        as Map<String, dynamic>;

        final valor =

            (data['tarifaDescuento']
            as num?)

                ?.toInt()

                ?? 0;

        final pagado =
            data['bonoPagado']
                == true;

        final metodo =
            data['bonoMetodo']
                ?? '';

        totalBonos += valor;

        if (!pagado) {

          totalPendientes += valor;
        }

        if (metodo == 'NEQUI') {

          totalNequi += valor;
        }

        if (metodo == 'SALDO_METAX') {

          totalSaldoMetax += valor;
        }
      }

    } catch (e) {

      debugPrint(
        'ERROR HISTORIAL BONOS: $e',
      );
    }

    if (mounted) {
      agruparBonosPorSemana();
      filtrarBonos();

      setState(() {
        loading = false;
      });
    }
  }

  void agruparBonosPorSemana() {

    bonosPorSemana.clear();

    for (final doc in bonos) {

      final data =
      doc.data()
      as Map<String, dynamic>;

      final Timestamp? fecha =

          data['bonoPagadoAt']
              ?? data['finalViaje'];

      if (fecha == null) continue;

      final date =
      fecha.toDate();

      final semana =

      obtenerSemana(date);

      final inicioSemana =

      date.subtract(
        Duration(
          days: date.weekday - 1,
        ),
      );

      final finSemana =

      inicioSemana.add(
        const Duration(days: 6),
      );

      final key =

          'Semana $semana\n'
          '${DateFormat('dd MMM', 'es_CO').format(inicioSemana)} '
          'al '
          '${DateFormat('dd MMM yyyy', 'es_CO').format(finSemana)}';

      bonosPorSemana
          .putIfAbsent(
        key,
            () => [],
      )
          .add(doc);
    }
  }

  void filtrarBonos() {

    if (semanaSeleccionada ==
        'Todas') {

      bonosFiltrados = bonos;

      return;
    }

    bonosFiltrados =

        bonosPorSemana[
        semanaSeleccionada]

            ?? [];
  }

  int obtenerSemana(DateTime date) {

    final firstDay =
    DateTime(date.year, 1, 1);

    final diff =
    date.difference(firstDay);

    return
      ((diff.inDays +
          firstDay.weekday)
          / 7)
          .ceil();
  }

  Future<void> exportarCSV() async {

    try {

      List<List<dynamic>> rows = [];

      /// HEADERS
      rows.add([

        'Fecha pago',

        'Conductor',

        'Placa',

        'Valor bono',

        'Método',

        'Número viaje',
      ]);

      /// DATOS
      for (final doc in bonosFiltrados) {

        final data =
        doc.data()
        as Map<String, dynamic>;

        final fecha =

            data['bonoPagadoAt']
                ?? data['finalViaje'];

        final fechaFormat =

        fecha != null

            ? DateFormat(

          'dd/MM/yyyy hh:mm a',
          'es_CO',

        ).format(
          fecha.toDate(),
        )

            : '';

        rows.add([

          fechaFormat,

          data['driver_nombre']
              ?? '-',

          data['placa']
              ?? '-',

          data['tarifaDescuento']
              ?? 0,

          data['bonoMetodo']
              ?? '-',

          data['numeroViaje']
              ?? '-',
        ]);
      }

      rows.add([]);

      rows.add([
        'TOTAL BONOS',
        totalBonos,
      ]);

      rows.add([
        'TOTAL PENDIENTES',
        totalPendientes,
      ]);

      rows.add([
        'TOTAL NEQUI',
        totalNequi,
      ]);

      rows.add([
        'TOTAL SALDO METAX',
        totalSaldoMetax,
      ]);

      /// CONVERTIR A CSV
      String csvData =

      const ListToCsvConverter(
        fieldDelimiter: ';',
      )
          .convert(rows);

      final bytes =

      utf8.encode(
        '\uFEFF$csvData',
      );

      final blob = html.Blob([
        bytes
      ]);

      final url =
      html.Url.createObjectUrlFromBlob(
        blob,
      );

      final nombreArchivo =

      semanaSeleccionada == 'Todas'

          ? 'bonos_todas_las_semanas.csv'

          : '${semanaSeleccionada

          .replaceAll('\n', ' ')
          .replaceAll('/', '-')
          .replaceAll(':', '')}.csv';

      final anchor =
      html.AnchorElement(
        href: url,
      )

        ..setAttribute(

          "download",

          nombreArchivo,
        )

        ..click();

      html.Url.revokeObjectUrl(url);

      if (mounted) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              '✅ CSV descargado',
            ),
          ),
        );
      }

    } catch (e) {

      debugPrint(
        'ERROR EXPORT CSV: $e',
      );
    }
  }

  bool isDesktop(BuildContext context) {

    return MediaQuery.of(context)
        .size
        .width > 900;
  }

  String formatMoney(num value) {

    return NumberFormat(
      '#,###',
      'es_CO',
    ).format(value);
  }

  String formatFecha(
      Timestamp? timestamp,
      ) {

    if (timestamp == null) {
      return '';
    }

    return DateFormat(

      'dd/MM/yyyy hh:mm a',
      'es_CO',

    ).format(
      timestamp.toDate(),
    );
  }

  @override
  Widget build(BuildContext context) {

    return MainLayout(

      pageTitle:
      'Historial bonos',

      content: Align(

        alignment:
        Alignment.topCenter,

        child: SizedBox(

          width:

          isDesktop(context)

              ? MediaQuery.of(context)
              .size
              .width * 0.96

              : double.infinity,

          child: Padding(

            padding:
            const EdgeInsets.all(20),

            child:

            SingleChildScrollView(
              child: loading
              
                  ? const Center(
              
                child:
                CircularProgressIndicator(),
              )
              
                  : bonos.isEmpty
              
                  ? const Center(
              
                child: Text(
                  'No hay historial de bonos',
                ),
              )
              
                  : Column(
              
                crossAxisAlignment:
                CrossAxisAlignment.start,
              
                children: [
              
                  const Text(
              
                    'Historial general de bonos promocionales',
              
                    style: TextStyle(
              
                      fontSize: 20,
              
                      fontWeight:
                      FontWeight.w900,
                    ),
                  ),
              
                  const SizedBox(height: 20),
                  Align(

                    alignment:
                    Alignment.centerRight,

                    child: ElevatedButton.icon(

                      onPressed: exportarCSV,

                      style:
                      ElevatedButton.styleFrom(

                        backgroundColor:
                        primary,
                      ),

                      icon: const Icon(

                        Icons.download,

                        color: Colors.black,
                      ),

                      label: const Text(

                        'Descargar reporte',

                        style: TextStyle(

                          color: Colors.black,

                          fontWeight:
                          FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(

                    children: [

                      Container(

                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),

                        decoration: BoxDecoration(

                          color: Colors.white,

                          borderRadius:
                          BorderRadius.circular(12),

                          border: Border.all(
                            color: gris,
                          ),
                        ),

                        child: DropdownButtonHideUnderline(

                          child: DropdownButton<String>(

                            value:
                            semanaSeleccionada,

                            items: [

                              const DropdownMenuItem(

                                value: 'Todas',

                                child: Text(
                                  'Todas las semanas',
                                ),
                              ),

                              ...bonosPorSemana.keys
                                  .map((semana) {

                                return DropdownMenuItem(

                                  value: semana,

                                  child: Text(
                                    semana,
                                  ),
                                );
                              }),
                            ],

                            onChanged: (value) {

                              if (value == null) return;

                              setState(() {

                                semanaSeleccionada =
                                    value;

                                filtrarBonos();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
              
                  Wrap(
              
                    spacing: 14,
                    runSpacing: 14,
              
                    children: [
              
                      _cardResumen(
                        'Total bonos',
                        totalBonos,
                        Colors.black,
                      ),
              
                      _cardResumen(
                        'Pendientes',
                        totalPendientes,
                        Colors.orange,
                      ),
              
                      _cardResumen(
                        'Transferencias a Nequi',
                        totalNequi,
                        Colors.green,
                      ),
              
                      _cardResumen(
                        'Transladados al saldo ',
                        totalSaldoMetax,
                        primary,
                      ),
                    ],
                  ),
              
                  const SizedBox(height: 20),
              
                  isDesktop(context)
              
                      ? _buildDesktop()
              
                      : _buildMobile(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardResumen(

      String titulo,

      int valor,

      Color color,
      ) {

    return Container(

      width: 220,

      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(14),

        border: Border.all(
          color: gris,
        ),

        boxShadow: [

          BoxShadow(

            color:
            Colors.black.withOpacity(
              0.03,
            ),

            blurRadius: 6,
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(

            titulo,

            style: TextStyle(

              fontSize: 13,

              color: color,

              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Text(

            '\$ ${formatMoney(valor)}',

            style: const TextStyle(

              fontSize: 22,

              fontWeight:
              FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop() {

    return ListView(

      shrinkWrap: true,

      physics:
      const NeverScrollableScrollPhysics(),

      children:

      (semanaSeleccionada == 'Todas'

          ? bonosPorSemana.entries

          : bonosPorSemana.entries.where(

            (e) =>

        e.key ==
            semanaSeleccionada,
      ))

          .map((entry) {

        final semana =
            entry.key;

        final docs =
            entry.value;

        final fechas = docs.map((doc) {

          final data =
          doc.data()
          as Map<String, dynamic>;

          final Timestamp? fecha =

              data['bonoPagadoAt']
                  ?? data['finalViaje'];

          return fecha!.toDate();

        }).toList();

        fechas.sort();

        final inicioSemana =
            fechas.first;

        final finSemana =
            fechas.last;

        int totalSemana = 0;

        for (final doc in docs) {

          final data =
          doc.data()
          as Map<String, dynamic>;

          totalSemana +=

              (data['tarifaDescuento']
              as num?)

                  ?.toInt()

                  ?? 0;
        }

        return Container(

          margin:
          const EdgeInsets.only(
            bottom: 20,
          ),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius:
            BorderRadius.circular(18),

            border: Border.all(
              color: gris,
            ),
          ),

          child: ExpansionTile(

            tilePadding:
            const EdgeInsets.symmetric(

              horizontal: 20,
              vertical: 8,
            ),

            childrenPadding:
            const EdgeInsets.all(16),

            title: Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(

                      semana,

                      style: const TextStyle(

                        fontSize: 18,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(

                      '${DateFormat('dd MMM', 'es_CO').format(inicioSemana)} '
                          'al '
                          '${DateFormat('dd MMM yyyy', 'es_CO').format(finSemana)}',

                      style: TextStyle(

                        fontSize: 12,

                        color:
                        Colors.grey.shade700,

                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(

                  children: [

                    Text(

                      '${docs.length} bonos',

                      style: TextStyle(

                        color:
                        Colors.grey.shade700,

                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 20),

                    Text(

                      '\$ ${formatMoney(totalSemana)}',

                      style: const TextStyle(

                        color: primary,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            children: docs.map((doc) {

              final data =
              doc.data()
              as Map<String, dynamic>;

              final pagado =
                  data['bonoPagado']
                      == true;

              return Container(

                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),

                padding:
                const EdgeInsets.all(14),

                decoration: BoxDecoration(

                  color:
                  Colors.grey.shade50,

                  borderRadius:
                  BorderRadius.circular(14),
                ),

                child: Row(

                  children: [

                    Expanded(

                      flex: 2,

                      child: Text(

                        data['numeroViaje']
                            ?? '',

                        style: const TextStyle(

                          fontWeight:
                          FontWeight.w900,
                        ),
                      ),
                    ),

                    Expanded(

                      child: Text(

                        data['placa']
                            ?? '-',

                        style: const TextStyle(

                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),

                    Expanded(

                      flex: 2,

                      child: Text(

                        data['driver_nombre']
                            ?? '-',

                        style: const TextStyle(

                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),

                    Expanded(

                      child: Text(

                        formatFecha(

                          data['bonoPagadoAt']
                              ?? data['finalViaje'],
                        ),
                      ),
                    ),

                    Expanded(

                      child: Text(

                        '\$ ${formatMoney(data['tarifaDescuento'] ?? 0)}',

                        style: const TextStyle(

                          fontWeight:
                          FontWeight.w900,
                        ),
                      ),
                    ),

                    Expanded(

                      child: Text(

                        data['bonoMetodo']
                            ?? '-',
                      ),
                    ),

                    Expanded(

                      child: Container(

                        padding:
                        const EdgeInsets.symmetric(

                          horizontal: 10,
                          vertical: 5,
                        ),

                        decoration: BoxDecoration(

                          color:

                          pagado

                              ? Colors.green
                              .withOpacity(0.10)

                              : Colors.orange
                              .withOpacity(0.10),

                          borderRadius:
                          BorderRadius.circular(10),
                        ),

                        child: Text(

                          pagado
                              ? 'PAGADO'
                              : 'PENDIENTE',

                          textAlign:
                          TextAlign.center,

                          style: TextStyle(

                            color:

                            pagado
                                ? Colors.green
                                : Colors.orange,

                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

            }).toList(),
          ),
        );

      }).toList(),
    );
  }

  @override
  void dispose() {

    _tableScrollController.dispose();

    super.dispose();
  }

  Widget _buildMobile() {

    return ListView.builder(

      shrinkWrap: true,

      physics:
      const NeverScrollableScrollPhysics(),

      itemCount: bonos.length,

      itemBuilder: (_, index) {

        final data = bonos[index]
            .data()

        as Map<String, dynamic>;

        final pagado =
            data['bonoPagado']
                == true;

        return Container(

          margin:
          const EdgeInsets.only(
            bottom: 12,
          ),

          padding:
          const EdgeInsets.all(14),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius:
            BorderRadius.circular(14),

            border: Border.all(
              color: gris,
            ),
          ),

          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(

                data['numeroViaje']
                    ?? '',

                style: const TextStyle(

                  fontWeight:
                  FontWeight.w900,

                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),

              Text(

                data['driver_nombre']
                    ?? '-',

                style: TextStyle(

                  fontSize: 13,

                  fontWeight:
                  FontWeight.w700,

                  color:
                  Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),

              Text(

                'Placa: '
                    '${data['placa'] ?? '-'}',

                style: TextStyle(

                  fontSize: 12,

                  color:
                  Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 4),

              Text(

                'Método: '
                    '${data['bonoMetodo'] ?? '-'}',

                style: TextStyle(

                  fontSize: 12,

                  color:
                  Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 8),

              Text(

                '\$ ${formatMoney(data['tarifaDescuento'] ?? 0)}',

                style: const TextStyle(

                  fontWeight:
                  FontWeight.w900,

                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Row(

                children: [

                  Container(

                    padding:
                    const EdgeInsets.symmetric(

                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(

                      color:

                      pagado

                          ? Colors.green
                          .withOpacity(0.1)

                          : Colors.orange
                          .withOpacity(0.1),

                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    child: Text(

                      pagado
                          ? 'PAGADO'
                          : 'PENDIENTE',

                      style: TextStyle(

                        color:

                        pagado
                            ? Colors.green
                            : Colors.orange,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(

                    data['bonoMetodo']
                        ?? '-',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
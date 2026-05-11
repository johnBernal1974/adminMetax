import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/main_layout.dart';
import '../../src/color.dart';

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

  int totalBonos = 0;

  int totalPendientes = 0;

  int totalNequi = 0;

  int totalSaldoMetax = 0;

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
        'tarifaDescuento',
        isGreaterThan: 0,
      )

          .orderBy(
        'tarifaDescuento',
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

      setState(() {
        loading = false;
      });
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

              ? 1300
              : double.infinity,

          child: Padding(

            padding:
            const EdgeInsets.all(20),

            child:

            loading

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
                      'Nequi',
                      totalNequi,
                      Colors.green,
                    ),

                    _cardResumen(
                      'Saldo MetaX',
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

    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(14),

        border: Border.all(
          color: gris,
        ),
      ),

      child: SingleChildScrollView(

        scrollDirection:
        Axis.horizontal,

        child: DataTable(

          columns: const [

            DataColumn(
              label: Text('Fecha'),
            ),

            DataColumn(
              label: Text('Viaje'),
            ),

            DataColumn(
              label: Text('Valor'),
            ),

            DataColumn(
              label: Text('Estado'),
            ),

            DataColumn(
              label: Text('Método'),
            ),
            DataColumn(
              label: Text('TX'),
            ),

            DataColumn(
              label: Text('Observación'),
            ),
          ],

          rows: bonos.map((doc) {

            final data =

            doc.data()
            as Map<String, dynamic>;

            final pagado =
                data['bonoPagado']
                    == true;

            return DataRow(

              cells: [

                DataCell(

                  Text(

                    formatFecha(
                      data['bonoPagadoAt']
                          ?? data['createdAt'],
                    ),
                  ),
                ),

                DataCell(

                  Text(
                    data['numeroViaje']
                        ?? '',
                  ),
                ),

                DataCell(

                  Text(

                    '\$ ${formatMoney(data['tarifaDescuento'] ?? 0)}',
                  ),
                ),

                DataCell(

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
                ),

                DataCell(

                  Text(

                    data['bonoMetodo']
                        ?? '-',
                  ),
                ),
                DataCell(

                  Text(

                    data['bonoTransaccionId']
                        ?? '-',
                  ),
                ),

                DataCell(

                  SizedBox(

                    width: 240,

                    child: Text(

                      data['bonoObservacion']
                          ?? '-',

                      overflow:
                      TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
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
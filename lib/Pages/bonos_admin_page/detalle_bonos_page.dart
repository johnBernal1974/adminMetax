import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/main_layout.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DetalleBonosDriverPage extends StatefulWidget {
  const DetalleBonosDriverPage({super.key});

  @override
  State<DetalleBonosDriverPage> createState() =>
      _DetalleBonosDriverPageState();
}

class _DetalleBonosDriverPageState
    extends State<DetalleBonosDriverPage> {

  bool loading = true;

  List<QueryDocumentSnapshot<
      Map<String, dynamic>>> bonos = [];

  double totalBonos = 0;

  int cantidadBonos = 0;

  late Map<String, dynamic> driverData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    driverData =

    ModalRoute.of(context)!
        .settings
        .arguments

    as Map<String, dynamic>;

    cargarBonos();
  }

  Future<void> cargarBonos() async {

    setState(() {
      loading = true;
    });

    final snap =
    await FirebaseFirestore.instance

        .collection('TravelHistory')

        .where(
      'idDriver',
      isEqualTo:
      driverData['idDriver'],
    )

        .where(
      'tarifaDescuento',
      isGreaterThan: 0,
    )

        .where(
      'bonoPagado',
      isEqualTo: false,
    )

        .orderBy(
      'tarifaDescuento',
    )

        .orderBy(
      'finalViaje',
      descending: true,
    )

        .get();

    bonos = snap.docs;

    totalBonos = 0;
    cantidadBonos = bonos.length;

    for (final doc in bonos) {

      final data = doc.data();

      totalBonos +=

          (data['tarifaDescuento']
          as num?)

              ?.toDouble()

              ?? 0;
    }

    setState(() {
      loading = false;
    });
  }

  String formatMoney(num value) {

    return NumberFormat(
      '#,###',
      'es_CO',
    ).format(value);
  }

  String formatFecha(dynamic timestamp) {

    if (timestamp == null) {
      return '';
    }

    final date =
    (timestamp as Timestamp)
        .toDate();

    return DateFormat(
      'dd/MM/yyyy hh:mm a',
    ).format(date);
  }

  bool isDesktop(BuildContext context) {

    return MediaQuery.of(context)
        .size
        .width >= 900;
  }

  @override
  Widget build(BuildContext context) {

    return MainLayout(

      pageTitle:
      'Detalle bonos',

      content: Padding(

        padding:
        const EdgeInsets.all(20),

        child:

        loading

            ? const Center(
          child:
          CircularProgressIndicator(),
        )

            : Column(

          children: [


            /// 🔥 RESUMEN
            Container(

              width: double.infinity,

              padding:
              const EdgeInsets.all(18),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius:
                BorderRadius.circular(
                  18,
                ),

                border: Border.all(
                  color:
                  Colors.grey.shade300,
                ),

                boxShadow: [

                  BoxShadow(

                    color:
                    Colors.black
                        .withOpacity(
                      0.04,
                    ),

                    blurRadius: 8,

                    offset:
                    const Offset(
                      0,
                      3,
                    ),
                  ),
                ],
              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [

                  Row(

                    children: [

                      Container(

                        width: 48,

                        height: 48,

                        decoration:
                        BoxDecoration(

                          color:
                          Colors.orange
                              .withOpacity(
                            0.12,
                          ),

                          shape:
                          BoxShape.circle,
                        ),

                        child:
                        const Icon(

                          Icons
                              .card_giftcard,

                          color:
                          Colors.orange,

                          size: 24,
                        ),
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(

                        child: Column(

                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            Text(

                              (driverData['nombre'] ??
                                  driverData['nombres'] ??
                                  'Conductor')
                                  .toString(),

                              style:
                              const TextStyle(

                                fontSize:
                                18,

                                fontWeight:
                                FontWeight
                                    .w900,
                              ),
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            Text(

                              driverData['celular'],

                              style:
                              TextStyle(

                                fontSize:
                                12,

                                color:
                                Colors
                                    .grey
                                    .shade700,

                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                    children: [

                      Column(

                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          Text(

                            '$cantidadBonos '
                                '${cantidadBonos == 1 ? 'bono pendiente' : 'bonos pendientes'}',

                            style:
                            TextStyle(

                              fontSize:
                              12,

                              color:
                              Colors
                                  .grey
                                  .shade700,

                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          const Text(

                            'Total pendiente',

                            style:
                            TextStyle(

                              fontSize:
                              11,

                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ],
                      ),

                      Text(

                        '\$ ${formatMoney(totalBonos.toInt())}',

                        style:
                        const TextStyle(

                          fontSize:
                          28,

                          fontWeight:
                          FontWeight
                              .w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// 🔥 LISTA
            Expanded(

              child:

              bonos.isEmpty

                  ? const Center(

                child: Text(
                  'No hay bonos pendientes',
                ),
              )

                  : isDesktop(context)

                  ? _buildTable()

                  : _buildCards(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {

    return SingleChildScrollView(

      scrollDirection: Axis.horizontal,

      child: DataTable(

        columns: const [
          DataColumn(
            label: Text(
              'N° Viaje',
            ),
          ),

          DataColumn(
            label: Text(
              'Fecha',
            ),
          ),

          DataColumn(
            label: Text(
              'Tarifa',
            ),
          ),

          DataColumn(
            label: Text(
              'Cliente pagó',
            ),
          ),

          DataColumn(
            label: Text(
              'Bono MetaX',
            ),
          ),
        ],

        rows:

        bonos.map((doc) {

          final data = doc.data();

          final numeroViaje =
              data['numeroViaje']
                  ?? '';

          final tarifa =
              data['tarifa']
                  ?? 0;

          final bono =
              data['tarifaDescuento']
                  ?? 0;

          final clientePago =
              data['totalClientePaga']
                  ?? tarifa;

          final fecha =
          formatFecha(
            data['finalViaje'],
          );

          return DataRow(
            onSelectChanged: (_) {

              _mostrarDetalleBono(
                data,
                doc.id,
              );
            },

            cells: [
              DataCell(
                Text(numeroViaje),
              ),

              DataCell(
                Text(fecha),
              ),

              DataCell(
                Text(
                  '\$ ${formatMoney(tarifa)}',
                ),
              ),

              DataCell(
                Text(
                  '\$ ${formatMoney(clientePago)}',
                ),
              ),

              DataCell(

                Text(

                  '\$ ${formatMoney(bono)}',

                  style:
                  const TextStyle(

                    color:
                    Colors.orange,

                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ),
            ],
          );

        }).toList(),
      ),
    );
  }

  void _mostrarDetalleBono(

      Map<String, dynamic> data,

      String travelHistoryId,
      ) {

    final numeroViaje =
        data['numeroViaje']
            ?? '';

    final tarifa =
        data['tarifa']
            ?? 0;

    final bono =
        data['tarifaDescuento']
            ?? 0;

    final clientePago =
        data['totalClientePaga']
            ?? tarifa;

    final fecha =
    formatFecha(
      data['finalViaje'],
    );

    showDialog(

      context: context,

      builder: (_) {

        return AlertDialog(

          shape:
          RoundedRectangleBorder(

            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),

          title: const Text(

            'Detalle bono',

            style: TextStyle(
              fontWeight:
              FontWeight.w900,
            ),
          ),

          content: SizedBox(

            width: 420,

            child: Column(

              mainAxisSize:
              MainAxisSize.min,

              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                _rowDato(

                  'Conductor',

                  (driverData['nombre'] ??
                      driverData['nombres'] ??
                      'Sin nombre')
                      .toString(),
                ),

                _rowDato(
                  'N° Viaje',
                  numeroViaje,
                ),

                _rowDato(
                  'Fecha',
                  fecha,
                ),

                _rowDato(
                  'Tarifa',
                  '\$ ${formatMoney(tarifa)}',
                ),

                _rowDato(
                  'Cliente pagó',
                  '\$ ${formatMoney(clientePago)}',
                ),

                _rowDato(
                  'Bono MetaX',
                  '\$ ${formatMoney(bono)}',
                  color: Colors.orange,
                  bold: true,
                ),
              ],
            ),
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(
                  context,
                );
              },

              child: const Text(
                'Cerrar',
              ),
            ),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                onPressed: () async {

                  try {

                    final callable = FirebaseFunctions.instance
                        .httpsCallable(
                      'enviarPlantillaBonoPendiente',
                    );

                    final telefono =
                    driverData['celular']
                        .toString()
                        .trim();

                    final nombre =
                    (driverData['nombre'] ??
                        driverData['nombres'] ??
                        'Conductor')
                        .toString();

                    final ruta =
                        '${data['from']} → ${data['to']}';

                    final valorBono =

                        (data['tarifaDescuento']
                        as num?)

                            ?.toInt()

                            ?? 0;

                    await callable.call({

                      "telefono":
                      "57$telefono",

                      "nombre":
                      nombre,

                      "numeroViaje":
                      numeroViaje,

                      "ruta":
                      ruta,

                      "valorBono":
                      valorBono.toString(),
                    });

                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(

                        backgroundColor:
                        Colors.green,

                        content: Text(

                          'Plantilla enviada correctamente 🚕',

                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );

                  } catch (e) {

                    debugPrint(
                      'ERROR ENVIANDO PLANTILLA: $e',
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      SnackBar(

                        backgroundColor:
                        Colors.red,

                        content: Text(
                          'Error: $e',
                        ),
                      ),
                    );
                  }
                },

                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),

                label: const Text(

                  'Preguntar tipo de pago del bono',

                  style: TextStyle(

                    color: Colors.black,

                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                style: ElevatedButton.styleFrom(

                  backgroundColor:
                  const Color(0xFF25D366),

                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Row(

              children: [

                Expanded(

                  child: ElevatedButton.icon(

                    onPressed: () async {

                      Navigator.pop(context);

                      await marcarComoPagado(
                        data,
                      );
                    },

                    icon: const Icon(

                      Icons.payments,

                      color: Colors.black,
                    ),

                    label: const Text(

                      'Pagado',

                      style: TextStyle(

                        color:
                        Colors.black,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    style:
                    ElevatedButton.styleFrom(

                      backgroundColor:
                      Colors.green,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(

                  child: ElevatedButton.icon(

                    onPressed: () {

                      Navigator.pop(context);

                      pagarBonoIndividual(
                        data,
                        travelHistoryId,
                      );
                    },

                    icon: const Icon(

                      Icons.account_balance_wallet,

                      color: Colors.black,
                    ),

                    label: const Text(

                      'Saldo',

                      style: TextStyle(

                        color:
                        Colors.black,

                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    style:
                    ElevatedButton.styleFrom(

                      backgroundColor:
                      Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> pagarBonoIndividual(

      Map<String, dynamic> data,

      String travelHistoryId,
      ) async {

    try {

      final idDriver =
      data['idDriver'];

      final numeroViaje =
      data['numeroViaje'];

      final int valorBono =

          (data['tarifaDescuento']
          as num?)

              ?.toInt()

              ?? 0;

      final driverRef =

      FirebaseFirestore.instance

          .collection('Drivers')

          .doc(idDriver);

      final globalHistoryRef =

      FirebaseFirestore.instance

          .collection('TravelHistory')

          .doc(travelHistoryId);

      /// 🔥 HISTORY DEL DRIVER
      final driverHistoryRef =

      FirebaseFirestore.instance

          .collection('Drivers')

          .doc(idDriver)

          .collection('history')

          .doc(travelHistoryId);

      final recargaRef =

      FirebaseFirestore.instance

          .collection('recargas')

          .doc();

      await FirebaseFirestore.instance
          .runTransaction((tx) async {

        final historySnap =

        await tx.get(
          globalHistoryRef,
        );

        final historyData =

        historySnap.data()
        as Map<String, dynamic>;

        if (historyData[
        'bonoPagado'] == true) {

          throw Exception(

            'Este bono ya fue procesado',
          );
        }

        final driverSnap =
        await tx.get(driverRef);

        final driverData =

        driverSnap.data()

        as Map<String, dynamic>?;

        if (driverData == null) {

          throw Exception(
            'Conductor no encontrado',
          );
        }

        final saldoActual =

            (driverData[
            '32_Saldo_Recarga']
            as num?)

                ?.toInt()

                ?? 0;

        final nuevoSaldo =

        (saldoActual + valorBono)
            .toInt();

        /// 🔥 SUMAR SALDO
        tx.update(driverRef, {

          '32_Saldo_Recarga':
          nuevoSaldo,
        });

        /// 🔥 GLOBAL HISTORY
        tx.update(globalHistoryRef, {

          'bonoPagado': true,

          'bonoPagadoAt':
          FieldValue.serverTimestamp(),

          'bonoMetodo':
          'SALDO_METAX',

          'bonoPagadoPor':
          FirebaseAuth.instance.currentUser?.uid,

          'bonoTransaccionId':
          recargaRef.id,

          'bonoObservacion':

          'Transferido al saldo',
        });

        /// 🔥 DRIVER HISTORY
        tx.update(driverHistoryRef, {

          'bonoPagado': true,

          'bonoPagadoAt':
          FieldValue.serverTimestamp(),

          'bonoMetodo':
          'SALDO_METAX',

          'bonoPagadoPor':
          FirebaseAuth.instance.currentUser?.uid,

          'bonoTransaccionId':
          recargaRef.id,

          'bonoObservacion':

          'Transferido al saldo',
        });

        /// 🔥 RECARGA
        tx.set(recargaRef, {

          'amount':
          valorBono,

          'applied':
          true,

          'appliedAt':
          FieldValue.serverTimestamp(),

          'createdAt':
          FieldValue.serverTimestamp(),

          'updatedAt':
          FieldValue.serverTimestamp(),

          'driverExists':
          true,

          'paymentMethod':
          'BONO_METAX_ADMIN',

          'reference':

          'bono_admin_'
              '$numeroViaje',

          'saldo_anterior':
          saldoActual,

          'status':
          'APPROVED',

          'transactionId':
          recargaRef.id,

          'userId':
          idDriver,

          'numeroViaje':
          numeroViaje,

          'travelHistoryId':
          globalHistoryRef.id,

          'descripcion':

          'Transferido al saldo',
        });
      });

      await cargarBonos();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          backgroundColor:
          Colors.green,

          content: Text(

            'Saldo actualizado correctamente',

            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      );

    } catch (e) {

      debugPrint(
        'ERROR pagarBonoIndividual: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          backgroundColor:
          Colors.red,

          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }


  Future<void> marcarComoPagado(
      Map<String, dynamic> data,
      ) async {

    try {

      final numeroViaje =
      data['numeroViaje'];

      final operadorId =
          FirebaseAuth
              .instance
              .currentUser
              ?.uid;

      final transaccionId =

          'BONO-${DateTime.now().millisecondsSinceEpoch}';

      /// 🔥 QUERY
      final query =

      await FirebaseFirestore.instance

          .collection('TravelHistory')

          .where(
        'numeroViaje',
        isEqualTo:
        numeroViaje,
      )

          .get();

      final batch =
      FirebaseFirestore.instance
          .batch();

      for (final doc in query.docs) {

        /// 🔥 GLOBAL HISTORY
        batch.update(

          doc.reference,

          {

            'bonoPagado': true,

            'bonoMetodo':
            'NEQUI',

            'bonoPagadoAt':
            FieldValue.serverTimestamp(),

            'bonoPagadoPor':
            operadorId,

            'bonoTransaccionId':
            transaccionId,

            'bonoObservacion':

            'Pagado por Nequi',
          },
        );

        /// 🔥 DRIVER HISTORY
        /// 🔥 DRIVER HISTORY

        final idDriver =
        (data['idDriver'] ?? '')
            .toString();

        if (idDriver.isNotEmpty) {

          final driverHistoryRef =

          FirebaseFirestore.instance

              .collection('Drivers')

              .doc(idDriver)

              .collection('history')

              .doc(doc.id);

          batch.update(

            driverHistoryRef,

            {

              'bonoPagado': true,

              'bonoMetodo':
              'NEQUI',

              'bonoPagadoAt':
              FieldValue.serverTimestamp(),

              'bonoPagadoPor':
              operadorId,

              'bonoTransaccionId':
              transaccionId,

              'bonoObservacion':

              'Pagado por Nequi',
            },
          );
        }
      }

      await batch.commit();

      await cargarBonos();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(

            'Bono marcado '
                'como pagado 😮‍💨🔥',
          ),
        ),
      );

    } catch (e) {

      debugPrint(
        'ERROR marcarComoPagado: $e',
      );
    }
  }

  Widget _buildCards() {

    return ListView.builder(

      itemCount:
      bonos.length,

      itemBuilder:
          (context, index) {

        final data =
        bonos[index].data();

        final numeroViaje =
            data['numeroViaje']
                ?? '';

        final tarifa =
            data['tarifa']
                ?? 0;

        final bono =
            data['tarifaDescuento']
                ?? 0;

        final clientePago =
            data['totalClientePaga']
                ?? tarifa;

        final fecha =
        formatFecha(
          data['finalViaje'],
        );

        return Container(

          margin:
          const EdgeInsets.only(
            bottom: 12,
          ),

          decoration:
          BoxDecoration(

            color:
            Colors.white,

            borderRadius:
            BorderRadius.circular(
              16,
            ),

            border: Border.all(
              color: Colors
                  .grey.shade300,
            ),
          ),

          child: Padding(

            padding:
            const EdgeInsets.all(
              14,
            ),

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                Text(

                  numeroViaje,

                  style:
                  const TextStyle(

                    fontWeight:
                    FontWeight.w900,

                    fontSize: 14,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  fecha,
                ),

                const SizedBox(
                  height: 12,
                ),

                _rowDato(
                  'Tarifa',
                  '\$ ${formatMoney(tarifa)}',
                ),

                _rowDato(
                  'Cliente pagó',
                  '\$ ${formatMoney(clientePago)}',
                ),

                _rowDato(
                  'Bono MetaX',
                  '\$ ${formatMoney(bono)}',
                  color: Colors.orange,
                  bold: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rowDato(

      String label,
      String value, {

        Color? color,
        bool bold = false,
      }) {

    return Padding(

      padding:
      const EdgeInsets.only(
        bottom: 6,
      ),

      child: Row(

        mainAxisAlignment:
        MainAxisAlignment
            .spaceBetween,

        children: [

          Text(label),

          Text(

            value,

            style: TextStyle(

              color: color,

              fontWeight:

              bold
                  ? FontWeight.w900
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
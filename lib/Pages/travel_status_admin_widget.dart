import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:metax_administrador/src/color.dart';

class TravelStatusAdminWidget extends StatelessWidget {
  const TravelStatusAdminWidget({super.key});

  // Pon esto fuera del build o como una constante de clase
  static const  Map<String, String> traducciones = {
    'created': 'Solicitado',
    'accepted': 'Aceptado',
    'no_accepted': 'No aceptado',
    'driver_on_the_way': 'En camino',
    'driver_is_waiting': 'Conductor esperando',
    'started': 'Viaje iniciado',
    'finished': 'Finalizado',
    'cancelled': 'Cancelado',
    'no_driver_found': 'Sin conductor',
    'cancelByDriver': 'Conductor Canceló',
    'cancelByDriverAfterAccepted': 'Conductor Canceló',
    'cancelByClient': 'Cliente Canceló',
    'cancelByClientAfterAccepted': 'Cliente Canceló',
  };

  static const List<String> estados = [

    'created',

    'accepted',

    'no_accepted',

    'driver_on_the_way',

    'driver_is_waiting',

    'started',

    'finished',

    'cancelled',

    'no_driver_found',

    'cancelByDriver',

    'cancelByDriverAfterAccepted',

    'cancelByClient',

    'cancelByClientAfterAccepted',

  ];



  Color colorEstado(String status) {
    switch (status) {
      case 'created':
        return Colors.grey;

      case 'accepted':
        return Colors.blue;

      case 'no_accepted':
        return Colors.red;

      case 'driver_on_the_way':
        return Colors.orange;

      case 'driver_is_waiting':
        return Colors.deepOrange;

      case 'started':
        return Colors.green;

      case 'finished':
        return Colors.teal;

      case 'cancelled':
        return Colors.red;

      case 'no_driver_found':
        return Colors.black54;

      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('TravelInfo')
          .orderBy(
        'horaSolicitudViaje',
        descending: true,
      )
          .snapshots(),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;

        /// 🔥 SOLO ACTIVOS
        final viajes = docs.where((doc) {

          final data =
          doc.data() as Map<String, dynamic>;

          final status =
              data['status'] ?? '';

          return status != 'finished' &&
              status != 'cancelled';

        }).toList();

        print(
            "🚕 Viajes activos: ${viajes.length}"
        );

        if (viajes.isEmpty) {
          return const Center(
            child: Text(
              "No hay viajes activos",
            ),
          );
        }

        return ListView.builder(
          itemCount: viajes.length,

          itemBuilder: (context, index) {

            final doc = viajes[index];

            final data =
            doc.data() as Map<String, dynamic>;

            final numero =
                data['numeroViaje'] ?? '';

            final origen =
                data['from'] ?? '';

            final destino =
                data['to'] ?? '';

            final driver =
                data['idDriver'] ?? '';

            final cliente =
                data['id'] ?? '';

            String status =
                data['status'] ?? 'created';

            return StatefulBuilder(
              builder: (context, refresh) {

                return Container(
                  margin: const EdgeInsets.all(10),

                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(16),

                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      /// 🔥 NUMERO
                      Text(
                        numero,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(

                        formatearFechaHora(
                          data['horaSolicitudViaje'],
                        ),

                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "📍 Origen: $origen",
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "🏁 Destino: $destino",
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      FutureBuilder<DocumentSnapshot>(

                        future:

                        (data['id'] ?? '').toString().isEmpty

                            ? null

                            : (() {

                          print(
                              "👤 Leyendo cliente: ${data['id']}"
                          );

                          return FirebaseFirestore.instance
                              .collection('Clients')
                              .doc(data['id'])
                              .get();

                        })(),


                        builder: (context, snapshot) {

                          if (!snapshot.hasData ||
                              snapshot.data == null ||
                              !snapshot.data!.exists) {



                            return const Text(
                              "👤 Sin cliente",
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            );
                          }

                          final client =
                          snapshot.data!.data()
                          as Map<String, dynamic>?;

                          final nombre =
                              "${client?['01_Nombres'] ?? ''} "
                              "${client?['02_Apellidos'] ?? ''}";

                          return Text(
                            "👤 $nombre",
                            style: const TextStyle(
                              fontSize: 11,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 4),

                      FutureBuilder<DocumentSnapshot>(

                        future:

                        (data['idDriver'] ?? '').toString().isEmpty

                            ? null

                            : (() {

                          print(
                              "🚕 Leyendo conductor: ${data['idDriver']}"
                          );

                          return FirebaseFirestore.instance
                              .collection('Drivers')
                              .doc(data['idDriver'])
                              .get();

                        })(),


                        builder: (context, snapshot) {

                          if (!snapshot.hasData ||
                              snapshot.data == null ||
                              !snapshot.data!.exists) {

                            return const Text(
                              "🚕 Sin conductor",
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            );
                          }

                          final driver =
                          snapshot.data!.data()
                          as Map<String, dynamic>?;

                          final nombre =
                              "${driver?['01_Nombres'] ?? ''} "
                              "${driver?['02_Apellidos'] ?? ''}";

                          return Text(
                            "🚕 $nombre",
                            style: const TextStyle(
                              fontSize: 11,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      /// 🔥 STATUS
                      Row(
                        children: [

                          Expanded(
                            child:
                            DropdownButtonFormField<String>(
                              value: estados.contains(status) ? status : 'created',
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: colorEstado(status).withOpacity(0.08),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: estados.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    traducciones[e] ?? e, // 🔥 Aquí está el cambio: busca la traducción, si no existe muestra el original
                                    style: TextStyle(
                                      color: colorEstado(e),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                refresh(() {
                                  status = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.black, // 🔥 Esto pone tanto el icono como el texto de color negro
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('TravelInfo')
                                  .doc(doc.id)
                                  .update({
                                "status": status,
                              });

                              if(context.mounted){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Estado actualizado"),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text("Guardar"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  String formatearFechaHora(dynamic timestamp) {

    if (timestamp is! Timestamp) {
      return '';
    }

    final fecha = timestamp.toDate();

    return
      "${fecha.day}/${fecha.month}/${fecha.year} "
          "${fecha.hour.toString().padLeft(2, '0')}:"
          "${fecha.minute.toString().padLeft(2, '0')}";
  }
}
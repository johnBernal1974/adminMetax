import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Pages/travel_status_admin_widget.dart';
import '../Pages/widgets/side_bar_menu.dart';
import '../providers/operador_provider.dart';
import '../src/color.dart';

class MainLayout extends StatefulWidget {

  final Widget content;
  final String pageTitle;

  const MainLayout({
    Key? key,
    required this.content,
    required this.pageTitle,
  }) : super(key: key);

  @override
  State<MainLayout> createState() =>
      _MainLayoutState();
}

class _MainLayoutState
    extends State<MainLayout> {

  bool blink = false;

  Timer? _timer;

  @override
  void initState() {

    super.initState();

    _timer = Timer.periodic(
      const Duration(milliseconds: 700),
          (_) {

        if (!mounted) return;

        setState(() {
          blink = !blink;
        });
      },
    );
  }

  @override
  void dispose() {

    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final role =
    (context.read<OperadorProvider>()
        .rolActual ??
        '')
        .trim();

    final isMobile =
        MediaQuery.of(context).size.width < 1100;

    return Scaffold(

      backgroundColor: blancoCards,

      drawer:
      MediaQuery.of(context).size.width < 1100
          ? const SideBar()
          : null,

      appBar: AppBar(

        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),

        backgroundColor: primary,

        iconTheme:
        const IconThemeData(
          color: Colors.black,
        ),


          actions: [

      if (role == 'Master' ||
      role == 'operadorFull' ||
      role == 'contador') ...[

          /// 🔥 ALERTA VIAJES
          StreamBuilder<QuerySnapshot>(

            stream: FirebaseFirestore.instance
                .collection('TravelInfo')
                .snapshots(),

            builder: (context, snapshot) {

              int cantidadProblemas = 0;

              if (snapshot.hasData) {

                cantidadProblemas =
                    snapshot.data!.docs.where((doc) {

                      final data =
                      doc.data()
                      as Map<String, dynamic>;

                      return data['status']
                          == 'no_accepted';

                    }).length;
              }

              final hayProblemas =
                  cantidadProblemas > 0;

              return Padding(

                padding:
                const EdgeInsets.only(
                  right: 12,
                ),

                child: InkWell(

                  borderRadius:
                  BorderRadius.circular(30),

                  onTap: () {

                    showDialog(

                      context: context,

                      builder: (_) {

                        return Dialog(

                          insetPadding:
                          const EdgeInsets.all(20),

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                20),
                          ),

                          child: Container(

                            width: 900,
                            height: 700,

                            padding:
                            const EdgeInsets.all(
                                16),

                            child: Column(

                              children: [

                                Row(
                                  children: [

                                    const Expanded(
                                      child: Text(
                                        "Control manual de viajes",
                                        style:
                                        TextStyle(
                                          fontSize:
                                          18,
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      icon:
                                      const Icon(
                                        Icons.close,
                                      ),

                                      onPressed: () {
                                        Navigator.pop(
                                            context);
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                    height: 10),

                                const Expanded(
                                  child:
                                  TravelStatusAdminWidget(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },

                  child: AnimatedContainer(

                    duration:
                    const Duration(
                        milliseconds: 400),

                    padding:
                    EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 14,
                      vertical: isMobile ? 5 : 8,
                    ),

                    decoration: BoxDecoration(

                      color:

                      hayProblemas

                          ? (

                          blink

                              ? Colors.red
                              .shade700

                              : Colors.red
                              .shade300

                      )

                          : Colors.green
                          .shade700,

                      borderRadius:
                      BorderRadius.circular(
                          30),
                    ),

                    child: Row(

                      children: [

                        Icon(

                          hayProblemas

                              ? Icons
                              .warning_amber

                              : Icons
                              .check_circle,

                          color: Colors.white,
                          size: isMobile ? 14 : 18,
                        ),

                        if (hayProblemas)

                          Padding(

                            padding:
                            const EdgeInsets.only(
                              left: 6,
                            ),

                            child: Text(

                              cantidadProblemas
                                  .toString(),

                              style:
                              const TextStyle(
                                color:
                                Colors.white,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          /// 🔥 BONOS PENDIENTES
          StreamBuilder<QuerySnapshot>(

            stream: FirebaseFirestore.instance

                .collection('TravelHistory')

                .where(
              'tarifaDescuento',
              isGreaterThan: 0,
            )

                .where(
              'bonoPagado',
              isEqualTo: false,
            )

                .snapshots(),

            builder: (context, snapshot) {

              final cantidadBonos =

                  snapshot.data
                      ?.docs
                      .length

                      ?? 0;

              final hayBonos =
                  cantidadBonos > 0;

              return Padding(

                padding:
                EdgeInsets.only(
                  right: isMobile ? 4 : 12,
                ),

                child: InkWell(

                  borderRadius:
                  BorderRadius.circular(30),

                  onTap: () {

                    Navigator.pushNamed(
                      context,
                      'bonos_admin_page',
                    );
                  },

                  child: AnimatedContainer(

                    duration:
                    const Duration(
                      milliseconds: 400,
                    ),

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(

                      color:

                      hayBonos

                          ? (

                          blink

                              ? Colors.orange
                              .shade700

                              : Colors.orange
                              .shade400

                      )

                          : Colors.grey
                          .shade500,

                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),
                    ),

                    child: Row(

                      children: [

                        const Icon(

                          Icons
                              .card_giftcard,

                          color:
                          Colors.white,

                          size: 18,
                        ),

                        if (hayBonos)

                          Padding(

                            padding:
                            const EdgeInsets.only(
                              left: 6,
                            ),

                            child: Text(

                              cantidadBonos
                                  .toString(),

                              style:
                              const TextStyle(

                                color:
                                Colors.white,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          /// 🔥 ESTADO CONDUCTORES
          StreamBuilder<DocumentSnapshot>(

            stream: FirebaseFirestore.instance
                .collection('system_metrics')
                .doc('drivers_status')
                .snapshots(),

            builder: (context, snapshot) {

              int dormidos = 0;

              int sinLocation = 0;

              if (snapshot.hasData &&
                  snapshot.data!.exists) {

                final data =
                snapshot.data!.data()
                as Map<String, dynamic>;

                dormidos =
                    data['dormidos'] ?? 0;

                sinLocation =
                    data['sinLocation'] ?? 0;
              }

              final totalProblemas =
                  dormidos + sinLocation;

              final hayProblemas =
                  totalProblemas > 0;

              return Padding(

                padding:
                const EdgeInsets.only(
                  right: 12,
                ),

                child: InkWell(

                  borderRadius:
                  BorderRadius.circular(30),

                  onTap: () {

                    Navigator.pushNamed(
                      context,
                      'drivers_activity_admin_page',
                    );
                  },

                  child: AnimatedContainer(

                    duration:
                    const Duration(
                      milliseconds: 400,
                    ),

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(

                      color:

                      hayProblemas

                          ? (

                          blink

                              ? Colors.purple
                              .shade700

                              : Colors.purple
                              .shade400

                      )

                          : Colors.green
                          .shade700,

                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),
                    ),

                    child: Row(

                      children: [

                        const Icon(

                          Icons
                              .monitor_heart_outlined,

                          color:
                          Colors.white,

                          size: 18,
                        ),

                        if (hayProblemas)

                          Padding(

                            padding:
                            const EdgeInsets.only(
                              left: 6,
                            ),

                            child: Text(

                              totalProblemas
                                  .toString(),

                              style:
                              const TextStyle(

                                color:
                                Colors.white,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],

          /// 🔥 OPERADOR
          Consumer<OperadorProvider>(

            builder:
                (context, operadorProvider, _) {

              if (operadorProvider.isLoading) {

                return const Padding(

                  padding:
                  EdgeInsets.only(
                      right: 20),

                  child: Center(

                    child: SizedBox(
                      width: 15,
                      height: 15,

                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }

              final nombre =
                  operadorProvider
                      .nombreActual ??
                      '';

              final apellido =
                  operadorProvider
                      .apellidosActual ??
                      '';

              return Padding(

                padding:
                const EdgeInsets.only(
                    right: 20),

                child: Row(

                  children: [

                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ],

      ),

      body: Row(

        children: [

          if (MediaQuery.of(context)
              .size
              .width >
              1100)

            const SizedBox(
              width: 300,
              child: SideBar(),
            ),

          Expanded(
            child: widget.content,
          ),
        ],
      ),
    );
  }
}
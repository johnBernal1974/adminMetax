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

    return Scaffold(

      backgroundColor: blancoCards,

      drawer:
      MediaQuery.of(context).size.width < 800
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
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
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
                          size: 18,
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

                    const CircleAvatar(

                      radius: 14,

                      backgroundColor:
                      Colors.white,

                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(
                        width: 8),

                    Text(

                      "$nombre $apellido",

                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
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
              800)

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
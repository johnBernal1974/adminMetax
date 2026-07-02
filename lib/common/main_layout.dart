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

        /// =========================================================================
        /// 🔥 [ALERTA VIAJES OPTIMIZADA]
        /// Filtra en el servidor para traer solo los viajes que necesitan atención
        /// y usa un widget interno aislado para no recargar toda la web al parpadear.
        /// =========================================================================
        StreamBuilder<QuerySnapshot>(
          // ✅ OPTIMIZACIÓN 1: El servidor solo nos manda los viajes no aceptados en tiempo real
          stream: FirebaseFirestore.instance
              .collection('TravelInfo')
              .where('status', isEqualTo: 'no_accepted')
              .snapshots(),
          builder: (context, snapshot) {
            int cantidadProblemas = 0;

            if (snapshot.hasData) {
              // Ahora la cantidad es simplemente el conteo de los documentos que pasaron el filtro del servidor
              cantidadProblemas = snapshot.data!.docs.length;
            }

            final hayProblemas = cantidadProblemas > 0;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _BotonAlertaParpadeante(
                cantidad: cantidadProblemas,
                hayProblemas: hayProblemas,
                isMobile: isMobile,
                onTap: () {
                  // Mantenemos exactamente tu mismo showDialog original intacto
                  showDialog(
                    context: context,
                    builder: (_) {
                      return Dialog(
                        insetPadding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          width: 900,
                          height: 700,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      "Control manual de viajes",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Expanded(
                                child: TravelStatusAdminWidget(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
        /// =========================================================================

        /// =========================================================================
        /// 🔥 [BONOS PENDIENTES OPTIMIZADO]
        /// Limita la descarga de datos históricos y maneja su parpadeo de forma aislada
        /// =========================================================================
        StreamBuilder<QuerySnapshot>(
          // ✅ OPTIMIZACIÓN 1: El .limit(50) frena en seco descargas masivas si se acumula historial viejo
          stream: FirebaseFirestore.instance
              .collection('TravelHistory')
              .where('tarifaDescuento', isGreaterThan: 0)
              .where('bonoPagado', isEqualTo: false)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            final cantidadBonos = snapshot.data?.docs.length ?? 0;
            final hayBonos = cantidadBonos > 0;

            return Padding(
              padding: EdgeInsets.only(
                right: isMobile ? 4 : 12,
              ),
              child: _BotonBonosParpadeante(
                cantidad: cantidadBonos,
                hayBonos: hayBonos,
                onTap: () {
                  // Mantenemos tu navegación original intacta
                  Navigator.pushNamed(
                    context,
                    'bonos_admin_page',
                  );
                },
              ),
            );
          },
        ),
        /// =========================================================================

        /// =========================================================================
        /// 🔥 [ESTADO CONDUCTORES OPTIMIZADO]
        /// Mantiene su lectura eficiente de un solo documento y aísla su parpadeo
        /// =========================================================================
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('system_metrics')
              .doc('drivers_status')
              .snapshots(),
          builder: (context, snapshot) {
            int dormidos = 0;
            int sinLocation = 0;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              dormidos = data['dormidos'] ?? 0;
              sinLocation = data['sinLocation'] ?? 0;
            }

            final totalProblemas = dormidos + sinLocation;
            final hayProblemas = totalProblemas > 0;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _BotonConductoresParpadeante(
                cantidad: totalProblemas,
                hayProblemas: hayProblemas,
                onTap: () {
                  // Mantenemos tu navegación original intacta
                  Navigator.pushNamed(
                    context,
                    'drivers_activity_admin_page',
                  );
                },
              ),
            );
          },
        ),
        /// =========================================================================
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

/// =========================================================================
/// 📦 WIDGET AUXILIAR OPTIMIZADO: BOTÓN DE ALERTA PARPADEANTE AISLADO
/// Controla su propio timer interno para no forzar setStates en el MainLayout
/// =========================================================================
class _BotonAlertaParpadeante extends StatefulWidget {
  final int cantidad;
  final bool hayProblemas;
  final VoidCallback onTap;
  final bool isMobile;

  const _BotonAlertaParpadeante({
    Key? key,
    required this.cantidad,
    required this.hayProblemas,
    required this.onTap,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<_BotonAlertaParpadeante> createState() => _BotonAlertaParpadeanteState();
}

class _BotonAlertaParpadeanteState extends State<_BotonAlertaParpadeante> {
  bool _blink = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.hayProblemas) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(_BotonAlertaParpadeante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hayProblemas && _timer == null) {
      _startTimer();
    } else if (!widget.hayProblemas) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() {
        _blink = !_blink;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isMobile ? 8 : 14,
          vertical: widget.isMobile ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: widget.hayProblemas
              ? (_blink ? Colors.red.shade700 : Colors.red.shade300)
              : Colors.green.shade700,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              widget.hayProblemas ? Icons.warning_amber : Icons.check_circle,
              color: Colors.white,
              size: widget.isMobile ? 14 : 18,
            ),
            if (widget.hayProblemas)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  widget.cantidad.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// =========================================================================
/// 📦 WIDGET AUXILIAR OPTIMIZADO: BOTÓN DE CONDUCTORES PARPADEANTE AISLADO
/// Controla su propio timer interno para eliminar por completo el lag en la web
/// =========================================================================
class _BotonConductoresParpadeante extends StatefulWidget {
  final int cantidad;
  final bool hayProblemas;
  final VoidCallback onTap;

  const _BotonConductoresParpadeante({
    Key? key,
    required this.cantidad,
    required this.hayProblemas,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_BotonConductoresParpadeante> createState() => _BotonConductoresParpadeanteState();
}

class _BotonConductoresParpadeanteState extends State<_BotonConductoresParpadeante> {
  bool _blink = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.hayProblemas) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(_BotonConductoresParpadeante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hayProblemas && _timer == null) {
      _startTimer();
    } else if (!widget.hayProblemas) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() {
        _blink = !_blink;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: widget.hayProblemas
              ? (_blink ? Colors.purple.shade700 : Colors.purple.shade400)
              : Colors.green.shade700,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.monitor_heart_outlined,
              color: Colors.white,
              size: 18,
            ),
            if (widget.hayProblemas)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  widget.cantidad.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// =========================================================================
/// 📦 WIDGET AUXILIAR OPTIMIZADO: BOTÓN DE BONOS PARPADEANTE AISLADO
/// =========================================================================
class _BotonBonosParpadeante extends StatefulWidget {
  final int cantidad;
  final bool hayBonos;
  final VoidCallback onTap;

  const _BotonBonosParpadeante({
    Key? key,
    required this.cantidad,
    required this.hayBonos,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_BotonBonosParpadeante> createState() => _BotonBonosParpadeanteState();
}

class _BotonBonosParpadeanteState extends State<_BotonBonosParpadeante> {
  bool _blink = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.hayBonos) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(_BotonBonosParpadeante oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hayBonos && _timer == null) {
      _startTimer();
    } else if (!widget.hayBonos) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() {
        _blink = !_blink;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: widget.hayBonos
              ? (_blink ? Colors.orange.shade700 : Colors.orange.shade400)
              : Colors.grey.shade500,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 18,
            ),
            if (widget.hayBonos)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  widget.cantidad.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
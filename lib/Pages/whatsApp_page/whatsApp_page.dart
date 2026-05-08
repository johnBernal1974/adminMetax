
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/main_layout.dart';
import 'dart:html' as web_html;

import '../../models/conductor_model.dart';
import '../../models/usuario_model.dart';
import '../../widget/audio_player_widget.dart';
import '../../widget/video_player_widget.dart';
import '../ClientDetailPage/client_detail_page.dart';
import '../DriverDetailPage/driver_detail_page.dart';

class WhatsAppMetaXPage extends StatefulWidget {
  const WhatsAppMetaXPage({super.key});

  @override
  State<WhatsAppMetaXPage> createState() => _WhatsAppMetaXPageState();
}

class _WhatsAppMetaXPageState extends State<WhatsAppMetaXPage> {

  String? selectedNumero;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? usuarioInfo;
  bool loadingUsuario = false;

  final AudioPlayer _player = AudioPlayer();

  String? ultimoMensajeId;
  String? ultimoNumeroInicial;

  bool audioHabilitado = false;
  bool enviando = false;
  bool chatActivo = true;
  bool enviandoPlantilla = false;
  late final Stream<QuerySnapshot> conversacionesStream;

  final Map<String, Map<String, dynamic>?> cacheUsuarios = {};

  String textoBusqueda = '';

  List<Map<String, dynamic>> resultadosExternos = [];
  bool buscandoExternos = false;


  @override
  void initState() {
    super.initState();

    conversacionesStream = FirebaseFirestore.instance
        .collection('whatsapp_conversations_metax')
        .orderBy('lastMessageAt', descending: true)
        .snapshots();

    /// 🔥 AUTO-SELECCIONAR SOLO UNA VEZ
    FirebaseFirestore.instance
        .collection('whatsapp_conversations_metax')
        .orderBy('lastMessageAt', descending: true)
        .limit(1)
        .get()
        .then((snapshot) async {

      if (snapshot.docs.isNotEmpty) {

        final doc = snapshot.docs.first;
        final data = doc.data();

        final numero = data['conversationId'];

        // 🔥 1. TRAER USUARIO
        final dataUsuario = await obtenerUsuario(numero);

        // 🔥 2. EVALUAR VENTANA 24H
        evaluarVentana24h(data);

        if (mounted) {
          setState(() {
            selectedNumero = numero;
            usuarioInfo = dataUsuario;
            loadingUsuario = false;
          });
        }
      }
    });

    /// 🔊 sonido (lo dejas como ya lo tienes)
    FirebaseFirestore.instance
        .collection('whatsapp_messages_metax')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final id = doc.id;

      if (id != ultimoMensajeId) {
        ultimoMensajeId = id;

        final data = doc.data();

        if (!(data['from_me'] ?? false)) {
          reproducirSonido();
        }
      }
    });
  }

  Future<void> buscarUsuariosExternos(
      String texto,
      ) async {

    if (texto.trim().isEmpty) {

      if (!mounted) return;
      setState(() {
        resultadosExternos = [];
      });

      return;
    }

    if (!mounted) return;
    setState(() {
      buscandoExternos = true;
    });

    final resultados = <Map<String, dynamic>>[];

    try {

      /// 🔥 CLIENTES
      final clients = await FirebaseFirestore.instance
          .collection('Clients')
          .get();

      for (final doc in clients.docs) {

        final data = doc.data();

        final nombre =
        "${data['01_Nombres'] ?? ''} ${data['02_Apellidos'] ?? ''}"
            .toLowerCase();

        String celular =
        (data['07_Celular'] ?? '')
            .toString();

        /// 🔥 NORMALIZAR
        celular = celular
            .replaceAll(' ', '')
            .replaceAll('+', '');

        if (celular.startsWith('57')) {
          celular = celular.substring(2);
        }

        final coincide =
            nombre.contains(texto.toLowerCase()) ||

                celular.contains(
                  texto
                      .replaceAll(' ', '')
                      .replaceAll('+', ''),
                );

        if (coincide) {

          resultados.add({
            "id": doc.id,
            "tipo": "Cliente",
            "nombre":
            "${data['01_Nombres'] ?? ''} ${data['02_Apellidos'] ?? ''}",
            "numero": celular,
            "foto":
            data['29_Foto_perfil'] ??
                data['foto_perfil_url'],
          });
        }
      }

      /// 🔥 CONDUCTORES
      final drivers = await FirebaseFirestore.instance
          .collection('Drivers')
          .get();

      for (final doc in drivers.docs) {

        final data = doc.data();

        final nombre =
        "${data['01_Nombres'] ?? ''} ${data['02_Apellidos'] ?? ''}"
            .toLowerCase();

        String celular =
        (data['07_Celular'] ?? '')
            .toString();

        /// 🔥 NORMALIZAR
        celular = celular
            .replaceAll(' ', '')
            .replaceAll('+', '');

        if (celular.startsWith('57')) {
          celular = celular.substring(2);
        }

        final coincide =
            nombre.contains(texto.toLowerCase()) ||

                celular.contains(
                  texto
                      .replaceAll(' ', '')
                      .replaceAll('+', ''),
                );

        if (coincide) {

          resultados.add({
            "id": doc.id,
            "tipo": "Conductor",
            "nombre":
            "${data['01_Nombres'] ?? ''} ${data['02_Apellidos'] ?? ''}",
            "numero": celular,
            "foto":
            data['29_Foto_perfil'],
          });
        }
      }
      if (!mounted) return;

      setState(() {
        resultadosExternos = resultados;
        print("🔥 RESULTADOS EXTERNOS: ${resultados.length}");
      });

    } catch (e) {

      print("ERROR BUSQUEDA EXTERNA: $e");

    }

    setState(() {
      buscandoExternos = false;
    });
  }

  void evaluarVentana24h(Map<String, dynamic> conversacion) {

    final timestamp = conversacion['lastMessageAt'];

    if (timestamp == null || timestamp is! Timestamp) {
      chatActivo = false;
      return;
    }

    final ultimaFecha = timestamp.toDate();
    final ahora = DateTime.now();

    final diferencia = ahora.difference(ultimaFecha);

    print("⏱ Diferencia horas: ${diferencia.inHours}");

    if (!mounted) return;

    setState(() {
      chatActivo = diferencia.inHours < 24;
    });
  }

  Future<void> habilitarAudio() async {
    if (audioHabilitado) return;

    try {
      await _player.setAsset('audio/notificacion_whatsApp.mp3');
      await _player.setVolume(1.0);
      await _player.play();   // 🔥 esto “desbloquea” el audio
      await _player.stop();   // lo detienes inmediatamente

      audioHabilitado = true;

      print("🔊 Audio habilitado correctamente");
    } catch (e) {
      print("❌ Error habilitando audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return MainLayout(
      pageTitle: "WhatsApp MetaX",
      content: isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [

        /// LISTA
        Container(
          width: 350,
          color: Colors.grey.shade200,
          child: _buildListaConversaciones(),
        ),

        /// CHAT
        Expanded(
          child: Stack(
            children: [
              _buildChat(isMobile: false),
              if (selectedNumero == null)
                const Center(child: Text("Selecciona una conversación")),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListaConversaciones() {

    return Column(
      children: [

        /// 🔥 BUSCADOR
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.white,

          child: TextField(

            onChanged: (value) {

              setState(() {

                textoBusqueda =
                    value.toLowerCase().trim();

              });

              buscarUsuariosExternos(textoBusqueda);

            },

            decoration: InputDecoration(
              hintText: "Buscar conversación...",
              prefixIcon: const Icon(Icons.search),

              filled: true,
              fillColor: Colors.grey.shade100,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        /// 🔥 LISTA
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: conversacionesStream,

            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                  ),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting &&
                  !snapshot.hasData) {

                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs =
                  snapshot.data?.docs ?? [];

              final coincidencias = <QueryDocumentSnapshot>[];
              final restantes = <QueryDocumentSnapshot>[];

              for (final doc in docs) {

                final data =
                doc.data() as Map<String, dynamic>;

                final nombre =
                (data['nombre'] ?? '')
                    .toString()
                    .toLowerCase();

                final numero =
                (data['conversationId'] ?? '')
                    .toString()
                    .toLowerCase();

                final coincide =
                    textoBusqueda.isNotEmpty &&
                        (
                            nombre.contains(textoBusqueda) ||
                                numero.contains(textoBusqueda)
                        );

                if (coincide) {

                  coincidencias.add(doc);

                } else {

                  restantes.add(doc);

                }
              }

              /// 🔥 RESULTADOS ARRIBA
              final List<dynamic> conversacionesOrdenadas = [

                /// 🔥 CHATS ENCONTRADOS
                ...coincidencias,

                if (coincidencias.isNotEmpty)

                  <String, dynamic>{
                    "type": "divider_chats"
                  },

                /// 🔥 USUARIOS EXTERNOS
                if (resultadosExternos.isNotEmpty)

                  <String, dynamic>{
                    "type": "divider_externos"
                  },

                ...resultadosExternos,

                /// 🔥 RESTO DE CHATS
                ...restantes,

              ];

              if (conversacionesOrdenadas.isEmpty) {

                return const Center(
                  child: Text(
                    "No se encontraron resultados",
                  ),
                );

              }

              return ListView.builder(

                cacheExtent: 1200,

                itemCount: conversacionesOrdenadas.length,

                itemBuilder: (context, index) {

                  final item =
                  conversacionesOrdenadas[index];

                  /// 🔥 LINEA SEPARADORA
                  if (item is Map &&
                      item['type'] == 'divider_chats') {

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 14,
                      ),

                      child: Row(
                        children: [

                          Expanded(
                            child: Divider(
                              color: Colors.blue.withOpacity(0.4),
                              thickness: 1.2,
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),

                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: const Text(
                              "Resultado",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),

                          Expanded(
                            child: Divider(
                              color: Colors.blue.withOpacity(0.4),
                              thickness: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  /// 🔥 DIVIDER EXTERNOS
                  if (item is Map &&
                      item['type'] == 'divider_externos') {

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),

                      child: Row(
                        children: [

                          Expanded(
                            child: Divider(
                              color: Colors.green.withOpacity(0.4),
                              thickness: 1.2,
                            ),
                          ),

                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),

                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: const Text(
                              "Usuarios encontrados",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),

                          Expanded(
                            child: Divider(
                              color: Colors.green.withOpacity(0.4),
                              thickness: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  /// 🔥 RESULTADO EXTERNO
                  if (item is Map &&
                      item['type'] == null) {

                    return _buildResultadoExterno(
                      Map<String, dynamic>.from(item),
                    );

                  }

                  final doc =
                  item as QueryDocumentSnapshot;

                  return _buildItemConversacion(doc);;

                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultadoExterno(
      Map<String, dynamic> data,
      ) {

    final nombre = data['nombre'] ?? '';
    final numero = data['numero'] ?? '';
    final foto = data['foto'];
    final tipo = data['tipo'] ?? '';

    return Container(
      color: Colors.green.withOpacity(0.03),

      child: ListTile(

        leading: CircleAvatar(
          backgroundImage:
          (foto != null &&
              foto.toString().isNotEmpty)

              ? CachedNetworkImageProvider(
            foto.toString(),
          )

              : null,

          child: (foto == null ||
              foto.toString().isEmpty)

              ? const Icon(Icons.person)

              : null,
        ),

        title: Text(
          nombre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          "$tipo • ${formatearNumero(numero)}",
        ),

        trailing: const Icon(
          Icons.chat,
          color: Colors.green,
        ),

        onTap: () async {

          setState(() {

            selectedNumero = numero;

            textoBusqueda = '';

            /// 🔥 CARGAR INFO TEMPORAL
            usuarioInfo = {
              "tipo": tipo,
              "data": {
                "01_Nombres": nombre,
                "29_Foto_perfil": foto,
              }
            };

            /// 🔥 COMO NO HAY CHAT AUN
            chatActivo = false;

          });

        },
      ),
    );
  }

  Widget _buildMobileLayout() {

    /// 🔹 SI NO HAY CHAT → LISTA
    if (selectedNumero == null) {
      return _buildListaConversaciones();
    }

    /// 🔹 SI HAY CHAT → PANTALLA CHAT
    return Column(
      children: [
        Expanded(child: _buildChat(isMobile: true)),
      ],
    );
  }

  Widget _buildItemConversacion(QueryDocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    final numeroRaw = map['conversationId'] ?? '';
    final numero = formatearNumero(numeroRaw);
    final texto = map['lastMessage'] ?? 'Sin mensaje';

    final nombre = map['nombre'];
    final foto = map['foto'];
    final unreadRaw = map['unread'];

    final int unread =

    unreadRaw is bool

        ? (unreadRaw ? 1 : 0)

        : (unreadRaw as int? ?? 0);

    final isSelected = selectedNumero == numeroRaw;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFDCEEFF) : Colors.white, // 🔥 más visible
        border: Border(
          left: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 4, // 🔥 barra lateral tipo WhatsApp Web
          ),
        ),
      ),
      child: ListTile(
        onTap: () async {

          await habilitarAudio();

          if (selectedNumero != numeroRaw) {

            final conversacionData = doc.data() as Map<String, dynamic>;

            evaluarVentana24h(conversacionData);

            await FirebaseFirestore.instance
                .collection('whatsapp_conversations_metax')
                .doc(numeroRaw)
                .update({
              "unread": false,
            });

            final dataUsuario =
            await obtenerUsuario(numeroRaw);

            if (!mounted) return;

            setState(() {

              selectedNumero = numeroRaw;

              usuarioInfo = dataUsuario;

              loadingUsuario = false;

              /// 🔥 LIMPIAR BUSQUEDA
              textoBusqueda = '';

            });
          }
        },

        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: Container(
                width: 44,
                height: 44,
                color: Colors.grey.shade300,
                child: (foto != null && foto.toString().isNotEmpty)
                    ? CachedNetworkImage(
                  imageUrl: foto.toString(),
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => const Icon(
                    Icons.person,
                    color: Colors.black54,
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    color: Colors.black54,
                  ),
                )
                    : const Icon(
                  Icons.person,
                  color: Colors.black54,
                ),
              ),
            ),

            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: map['tipo'] == 'Conductor'
                      ? Colors.deepPurple
                      : map['tipo'] == 'Cliente'
                      ? Colors.blue
                      : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),

        title: Row(
          children: [
            Expanded(
              child: Text(
                (nombre != null && nombre.toString().isNotEmpty)
                    ? nombre
                    : numero,
                style: TextStyle(
                  fontWeight:

                  (isSelected || ((unread ?? 0) > 0))

                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            /// 🔴 BADGE (solo uno, limpio)
            if ((unread ?? 0) > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:Text(
                  "$unread",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            Text(
              formatearFechaLista(map['lastMessageAt']),
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.blueGrey : Colors.black,
              ),
            ),
          ],
        ),

        subtitle: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight:

            ((unread ?? 0) > 0)

                ? FontWeight.w600
                : FontWeight.normal,

            color:

            ((unread ?? 0) > 0)

                ? Colors.black
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> obtenerUsuario(String numero) async {

    /// 🔥 NORMALIZAR
    String numeroBusqueda =
    normalizarNumero(numero);
    if (numeroBusqueda.startsWith('57')) {
      numeroBusqueda = numeroBusqueda.substring(2);
    }

    /// 🔥 1. REVISAR CACHE
    if (cacheUsuarios.containsKey(numeroBusqueda)) {
      print("⚡ Usuario desde cache");
      return cacheUsuarios[numeroBusqueda];
    }

    try {

      print("🔍 Buscando usuario en Firestore: $numeroBusqueda");

      final driver = await FirebaseFirestore.instance
          .collection("Drivers")
          .where(
        "07_Celular",
        isEqualTo:
        numeroBusqueda.replaceFirst('57', ''),
      )
          .limit(1)
          .get();

      if (driver.docs.isNotEmpty) {
        final data = {
          "tipo": "Conductor",
          "data": {
            ...driver.docs.first.data(),
            "id": driver.docs.first.id,
          },
        };

        cacheUsuarios[numeroBusqueda] = data; // 🔥 GUARDAR CACHE
        return data;
      }

      final client = await FirebaseFirestore.instance
          .collection("Clients")
          .where("07_Celular", isEqualTo: numeroBusqueda)
          .limit(1)
          .get();

      if (client.docs.isNotEmpty) {
        final data = {
          "tipo": "Cliente",
          "data": {
            ...client.docs.first.data(),
            "id": client.docs.first.id,
          },
        };

        cacheUsuarios[numeroBusqueda] = data; // 🔥 GUARDAR CACHE
        return data;
      }

      cacheUsuarios[numeroBusqueda] = null;
      return null;

    } catch (e) {
      print("❌ Error buscando usuario: $e");
      return null;
    }
  }

  Future<void> reproducirSonido() async {
    try {
      print("🔊 Intentando reproducir sonido");

      await _player.setAsset('assets/audio/notificacion_whatsApp.mp3');
      await _player.play();

      print("✅ Sonido reproducido");

    } catch (e) {
      print("❌ Error sonido: $e");
    }
  }

  String formatearHoraAmPmDesdeTimestamp(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';

    final fecha = timestamp.toDate();

    int hour = fecha.hour;
    final minute = fecha.minute.toString().padLeft(2, '0');

    final isPM = hour >= 12;

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }

    final periodo = isPM ? 'PM' : 'AM';

    return "$hour:$minute $periodo";
  }

  String formatearFechaLista(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';

    final fecha = timestamp.toDate();
    final now = DateTime.now();

    final hoy = DateTime(now.year, now.month, now.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final fechaMsg = DateTime(fecha.year, fecha.month, fecha.day);

    /// 🔥 HOY → HORA AM/PM
    if (fechaMsg == hoy) {
      int hour = fecha.hour;
      final minute = fecha.minute.toString().padLeft(2, '0');

      final isPM = hour >= 12;

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour = hour - 12;
      }

      final periodo = isPM ? 'PM' : 'AM';

      return "$hour:$minute $periodo";
    }

    /// 🔥 AYER
    if (fechaMsg == ayer) {
      return "Ayer";
    }

    /// 🔥 ANTIGUO → FECHA
    return "${fecha.day}/${fecha.month}/${fecha.year}";
  }

  String formatearHora(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';

    final fecha = timestamp.toDate();
    final now = DateTime.now();

    final hoy = DateTime(now.year, now.month, now.day);
    final fechaMsg = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaMsg == hoy) {
      return "${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}";
    }

    return "${fecha.day}/${fecha.month}/${fecha.year}";
  }

  String formatearNumero(String numero) {
    if (numero.startsWith('57')) {
      numero = numero.substring(2);
    }

    if (numero.length == 10) {
      return "${numero.substring(0, 3)} ${numero.substring(3)}";
    }

    return numero;
  }


  /// 🔥 WIDGET DEL CHAT
  Widget _buildChat({required bool isMobile}) {

    if (selectedNumero == null) {
      return const Center(child: Text("Selecciona una conversación"));
    }


    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('whatsapp_conversations_metax')
          .doc(selectedNumero)
          .snapshots(),
      builder: (context, snapshot) {

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        final nombre =

            data?['nombre']

                ??

                usuarioInfo?['data']?['01_Nombres']

                ??

                formatearNumero(selectedNumero!);

        final foto =

            data?['foto']

                ??

                usuarioInfo?['data']?['29_Foto_perfil'];

        final tipo =

            data?['tipo']

                ??

                usuarioInfo?['tipo']

                ??

                "No registrado";

        final esConductor = tipo == "Conductor";

        return Column(
          children: [

            /// 🔥 HEADER DEL CHAT
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 16,
                vertical: isMobile ? 6 : 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          selectedNumero = null;
                        });
                      },
                    ),
                  const SizedBox(width: 4),

                  CircleAvatar(
                    radius: isMobile ? 18 : 40,
                    backgroundImage: (foto != null && foto.toString().isNotEmpty)
                        ? CachedNetworkImageProvider(foto.toString())
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: (foto == null || foto.toString().isEmpty)
                        ? Icon(
                      Icons.person,
                      size: isMobile ? 18 : 32,
                      color: Colors.black54,
                    )
                        : null,
                  ),

                  SizedBox(width: isMobile ? 6 : 12),

                  /// 🔥 INFO USUARIO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 12 : 15,
                          ),
                        ),

                        const SizedBox(height: 4),

                        /// 🔥 MINI CARD TIPO USUARIO
                        Container(
                          margin: EdgeInsets.only(top: isMobile ? 3 : 5),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 7 : 10,
                            vertical: isMobile ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: tipo == "Conductor"
                                ? Colors.deepPurple.withOpacity(0.08)
                                : tipo == "Cliente"
                                ? Colors.blue.withOpacity(0.08)
                                : Colors.red.withOpacity(0.08),

                            borderRadius: BorderRadius.circular(20),

                            border: Border.all(
                              color: tipo == "Conductor"
                                  ? Colors.deepPurple.withOpacity(0.25)
                                  : tipo == "Cliente"
                                  ? Colors.blue.withOpacity(0.25)
                                  : Colors.red.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            tipo,
                            style: TextStyle(
                              fontSize: isMobile ? 9 : 11,
                              fontWeight: FontWeight.w600,
                              color: tipo == "Conductor"
                                  ? Colors.deepPurple
                                  : tipo == "Cliente"
                                  ? Colors.blue
                                  : Colors.red,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (!isMobile)
                          Text(
                            formatearNumero(selectedNumero!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),

                  /// 🔥 BOTÓN TEMPLATE (24h)
                  if (!chatActivo)
                    isMobile
                        ? IconButton(
                      tooltip: "Enviar plantilla",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      onPressed: enviandoPlantilla ? null : iniciarConversacion,
                      icon: enviandoPlantilla
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(
                        Icons.campaign,
                        color: Colors.orange,
                        size: 20,
                      ),
                    )
                        : Row(
                      children: [
                        const Text(
                          "Fuera de 24h",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: "Enviar plantilla",
                          onPressed: enviandoPlantilla ? null : iniciarConversacion,
                          icon: enviandoPlantilla
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.campaign, color: Colors.orange),
                        ),
                      ],
                    ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// 🔥 ABRIR PERFIL
                      IconButton(
                        tooltip: "Abrir perfil",
                        icon: const Icon(Icons.open_in_new),

                        onPressed: () async {

                          if (selectedNumero == null) return;

                          final tipoUsuario =
                          usuarioInfo?['tipo'];

                          final userData =
                          usuarioInfo?['data'];

                          if (tipoUsuario == null ||
                              userData == null) {
                            return;
                          }

                          /// 🔥 CONDUCTOR
                          if (tipoUsuario == "Conductor") {

                            final driver =
                            Driver.fromJson({
                              ...userData,
                              "id": userData["id"] ?? "",
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DriverDetailPage(
                                      driver: driver,
                                    ),
                              ),
                            );
                          }

                          /// 🔥 CLIENTE
                          else if (tipoUsuario == "Cliente") {

                            final client =
                            Client.fromJson({
                              ...userData,
                              "id": userData["id"] ?? "",
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ClientDetailPage(
                                      client: client,
                                    ),
                              ),
                            );
                          }
                        },
                      ),

                      if (!isMobile)
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                    ],
                  )
                ],
              ),
            ),

            /// 🔥 MENSAJES
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('whatsapp_messages_metax')
                    .where('conversationId', isEqualTo: selectedNumero)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final mensajes = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['timestamp'] != null;
                  }).toList();

                  if (mensajes.isEmpty) {
                    return const Center(child: Text("No hay mensajes"));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) {

                      final map = mensajes[index].data() as Map<String, dynamic>;
                      final fromMe = map['from_me'] ?? false;

                      return buildMensaje(map, fromMe);
                    },
                  );
                },
              ),
            ),

            /// 🔥 INPUT (ESTILO ORIGINAL REDONDEADO)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [

                    /// 🔘 BOTÓN "+"
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.black54),
                      onPressed: () {},
                    ),

                    /// 🔘 INPUT REDONDO
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [

                            /// 😊 EMOJI
                            const Icon(Icons.emoji_emotions_outlined, color: Colors.black54),

                            const SizedBox(width: 8),

                            /// ✍️ TEXTFIELD
                            Expanded(
                              child: RawKeyboardListener(
                                focusNode: _keyboardFocusNode,
                                onKey: (event) {
                                  if (event is RawKeyUpEvent) {
                                    final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
                                    final isShiftPressed = event.isShiftPressed;

                                    if (isEnter && !isShiftPressed) {
                                      enviarMensaje();
                                    }
                                  }
                                },
                                child: TextField(
                                  controller: _messageController,
                                  enabled: chatActivo,
                                  focusNode: _textFieldFocusNode,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: chatActivo
                                        ? "Escribe un mensaje"
                                        : "Debes usar plantilla (fuera de 24h)",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),

                            /// 🎤 MICROFONO
                            const Icon(Icons.mic, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// 📤 BOTÓN ENVIAR
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: enviando ? Colors.grey : Colors.green,
                      ),
                      onPressed: enviando ? null : enviarMensaje,
                    ),
                  ],
                ),
              ),
            ),


            /// 🔥 BOTONES RÁPIDOS (LOS QUE TENÍAS)
            if (esConductor)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.grey.shade100,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [

                  /// 📘 TUTORIALES
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      enviarMensajePlantilla(value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "Conectarse y desconectarse",
                        child: Text("Conectarse y desconectarse"),
                      ),
                      const PopupMenuItem(
                        value: "Aceptar un servicio",
                        child: Text("Aceptar un servicio"),
                      ),
                      const PopupMenuItem(
                        value: "Como recargar",
                        child: Text("Cómo recargar"),
                      ),
                      const PopupMenuItem(
                        value: "Como inscribir un nuevo vehiculo",
                        child: Text("Inscribir vehículo"),
                      ),
                    ],
                    child: _botonRapido("Tutoriales", Icons.menu_book),
                  ),

                  /// 📲 APP CONDUCTORES
                  _botonRapido("App Conductores", Icons.directions_car, onTap: () {
                    enviarMensajeDirecto(
                        "Descarga la app de Meta X para conductores aquí:\n\nhttps://play.google.com/store/apps/details?id=com.apptaxxic.apptaxisc&hl=es_CO"
                    );
                  }),

                  /// 📲 APP CLIENTES
                  _botonRapido("App Clientes", Icons.person, onTap: () {
                    enviarMensajeDirecto(
                        "Descarga la app de Meta X para usuarios aquí:\n\nhttps://play.google.com/store/apps/details?id=com.app_taxis.apptaxis&hl=es_CO"
                    );
                  }),

                  /// 💬 MENSAJE MOTIVACIONAL
                  _botonRapido(
                    "Motivar conductor",
                    Icons.favorite,
                    onTap: () {

                      final nombreCompleto = usuarioInfo?['data']?['01_Nombres']
                          ?.toString()
                          .trim() ?? '';

                      final nombre = nombreCompleto.isNotEmpty
                          ? nombreCompleto.split(' ').first
                          : 'Compañero';

                      final mensaje =
                          "Hola $nombre, muy buenos días 👋\n\n"

                          "Queremos agradecerte sinceramente por el compromiso y el apoyo que le estás dando a Meta X.\n\n"

                          "La plataforma ya está en operación y en nuestra primera semana ya hemos superado los 50 servicios aceptados 🚕. Poco a poco cada vez más usuarios están conociendo la app y ya varios compañeros han comenzado a realizar viajes.\n\n"

                          "Actualmente seguimos realizando trabajo en campo, promociones y difusión para que el número de solicitudes aumente progresivamente y cada vez haya más movimiento para todos.\n\n"

                          "Sabemos que al inicio este proceso requiere paciencia, pero estamos trabajando constantemente para que Meta X siga creciendo y fortaleciéndose junto a ustedes.\n\n"

                          "De verdad, muchas gracias por creer en este proyecto y por seguir haciendo parte de esta comunidad.\n\n"

                          "Atentamente,\n"
                          "Mónica\n"
                          "Equipo Meta X";

                      enviarMensajeDirecto(mensaje);

                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _botonRapido(String texto, IconData icono, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Text(
              texto,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void enviarMensajeDirecto(String texto) {
    _messageController.text = texto;
    enviarMensaje();
  }

  Future<void> enviarImagen(String urlImagen) async {
    if (selectedNumero == null) return;

    await FirebaseFirestore.instance
        .collection('whatsapp_messages_metax')
        .add({
      "conversationId": selectedNumero,
      "imageUrl": urlImagen,
      "from_me": true,
      "timestamp": Timestamp.now(),
    });

    /// actualizar conversación
    await FirebaseFirestore.instance
        .collection('whatsapp_conversations_metax')
        .where('conversationId', isEqualTo: selectedNumero)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.first.reference.update({
          "lastMessage": "📷 Imagen",
          "lastMessageAt": Timestamp.now(),
        });
      }
    });
  }

  Future<void> enviarVideo(String urlVideo) async {
    if (selectedNumero == null) return;

    await FirebaseFirestore.instance
        .collection('whatsapp_messages_metax')
        .add({
      "conversationId": selectedNumero,
      "text": urlVideo,
      "from_me": true,
      "timestamp": Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection('whatsapp_conversations_metax')
        .where('conversationId', isEqualTo: selectedNumero)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.first.reference.update({
          "lastMessage": "🎥 Video",
          "lastMessageAt": Timestamp.now(),
        });
      }
    });
  }

  void enviarMensajePlantilla(String tipo) {
    String mensaje = "";

    switch (tipo) {

      case "Conectarse y desconectarse":
        mensaje =
        "🔌 *Cómo conectarte y desconectarte*\n\n"
            "Mira este tutorial:\n"
            "https://youtube.com/shorts/8kq5iWSqOZ0?feature=share";
        break;

      case "Aceptar un servicio":
        mensaje =
        "🚕 *Cómo aceptar un servicio*\n\n"
            "Sigue este paso a paso:\n"
            "https://youtu.be/KevVY_nEkD4";
        break;

      case "Como recargar":
        mensaje =
        "💳 *Cómo recargar saldo*\n\n"
            "Mira cómo hacerlo aquí:\n"
            "https://youtube.com/shorts/SEei5W92ez4?feature=share";
        break;

      case "Como inscribir un nuevo vehiculo":
        mensaje =
        "🚗 *Cómo inscribir un vehículo*\n\n"
            "Mira este tutorial:\n"
            "https://youtu.be/748akd2TYG8";
        break;
    }

    enviarMensajeDirecto(mensaje);
  }

  String formatearFecha(DateTime? fecha) {
    if (fecha == null) return '';

    final now = DateTime.now();

    final hoy = DateTime(now.year, now.month, now.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final fechaMsg = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaMsg == hoy) return "Hoy";
    if (fechaMsg == ayer) return "Ayer";

    return "${fecha.day}/${fecha.month}/${fecha.year}";
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _textFieldFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Widget buildMensaje(Map<String, dynamic> map, bool fromMe) {

    final texto =
        map['text'] ?? map['mensaje'] ?? map['body'] ?? '';

    final esTemplate = map['tipo'] == 'template';



    final esYoutube = texto.contains("youtube.com") || texto.contains("youtu.be");

    final timestamp = map['timestamp'];
    DateTime? fecha;

    if (timestamp is Timestamp) {
      fecha = timestamp.toDate();
    }

    final hora = fecha != null ? formatearHoraAmPm(fecha) : '';

    final imageUrl = map['imageUrl'];
    final audioUrl = map['audioUrl'];
    final videoUrl = map['videoUrl'];


    return Align(
      alignment:
      fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: fromMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 4),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                decoration: BoxDecoration(
                  color: fromMe
                      ? const Color(0xFFD9FDD3)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(fromMe ? 12 : 0),
                    bottomRight: Radius.circular(fromMe ? 0 : 12),
                  ),
                  boxShadow: [
                    if (!fromMe)
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (map['tipo'] == 'template')
                      const Text(
                        "Plantilla",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 200,
                        ),
                      ),
                    if (audioUrl != null)
                      AudioPlayerWidget(url: audioUrl),
                    if (videoUrl != null)
                      VideoPlayerWidget(url: videoUrl),
                    if (esYoutube)
                      Builder(
                        builder: (_) {
                          final videoId = extraerYoutubeId(texto);

                          if (videoId == null) return Text(texto);

                          final thumbnail =
                              "https://img.youtube.com/vi/$videoId/0.jpg";

                          final titulo = extraerTitulo(texto);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// 🎥 PREVIEW
                              GestureDetector(
                                onTap: () async {
                                  final urlString = extraerUrl(texto);
                                  if (urlString == null) return;

                                  final url = Uri.parse(urlString);
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        thumbnail,
                                        width: 220,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.play_circle_fill,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),

                              /// 🔥 TÍTULO DEL TUTORIAL
                              if (titulo.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    titulo,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    else if (texto.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          texto,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                  ],
                ),
              ),

              /// ⏰ HORA + CHECKS
              Positioned(
                bottom: 4,
                right: 32,
                child: Row(
                  children: [
                    Text(
                      hora,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),

                    /// ✔✔ CHECKS
                    if (fromMe)
                      Builder(
                        builder: (_) {
                          final status = map['status'] ?? 'sent';

                          if (status == 'sent') {
                            return const Icon(Icons.check, size: 14, color: Colors.grey);
                          } else if (status == 'delivered') {
                            return const Icon(Icons.done_all, size: 14, color: Colors.grey);
                          } else if (status == 'read') {
                            return const Icon(Icons.done_all, size: 14, color: Colors.blue);
                          }
                          return const SizedBox();
                        },
                      )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  String extraerTitulo(String texto) {
    final lineas = texto.split('\n');
    return lineas.isNotEmpty ? lineas.first : '';
  }

  String? extraerYoutubeId(String url) {
    try {
      if (url.contains("youtu.be")) {
        return url.split("/").last.split("?").first;
      } else if (url.contains("shorts")) {
        return url.split("shorts/").last.split("?").first;
      } else if (url.contains("youtube.com")) {
        final uri = Uri.parse(url);
        return uri.queryParameters['v'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String? extraerUrl(String texto) {
    final regex = RegExp(r'https?:\/\/[^\s]+');
    final match = regex.firstMatch(texto);
    return match?.group(0);
  }

  String formatearHoraAmPm(DateTime fecha) {
    int hour = fecha.hour;
    final minute = fecha.minute.toString().padLeft(2, '0');

    final isPM = hour >= 12;

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }

    final periodo = isPM ? 'PM' : 'AM';

    return "$hour:$minute $periodo";
  }

  Future<void> enviarMensaje() async {

    // 🔴 BLOQUEO SI NO HAY VENTANA
    if (!chatActivo) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes usar una plantilla. Han pasado más de 24h sin interacción."),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    if (enviando) return;

    final texto = _messageController.text.trim();

    if (texto.isEmpty || selectedNumero == null) return;

    enviando = true;

    _messageController.clear();

    try {

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      await functions
          .httpsCallable('enviarWhatsAppMetaX')
          .call({
        "telefono": selectedNumero,
        "mensaje": texto,
      });

    } catch (e) {
      print("ERROR AL ENVIAR: $e");
    }

    enviando = false;
  }

  Future<void> iniciarConversacion() async {
    if (enviandoPlantilla) return;
    enviandoPlantilla = true;

    if (selectedNumero == null) {
      enviandoPlantilla = false;
      return;
    }

    final telefono =
    normalizarNumero(selectedNumero!);

    try {
      /// 🔥 1. TRAER NOMBRE DESDE LA CONVERSACIÓN
      final conversacionDoc = await FirebaseFirestore.instance
          .collection('whatsapp_conversations_metax')
          .doc(telefono)
          .get();

      final dataConversacion = conversacionDoc.data();

      final nombreCompleto =
          dataConversacion?['nombre']?.toString().trim() ?? '';

      final nombre = nombreCompleto.isNotEmpty
          ? nombreCompleto.split(' ').first
          : "Usuario";

      final mensajeReal =
          "Hola $nombre, este mensaje corresponde a una gestión relacionada con tu cuenta en Meta X.\n\n"
          "¿Nos puedes atender un momento?\n\n"
          "Equipo de Meta X";

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('enviarInicioConversacion');

      /// 🔥 2. ENVÍA A WHATSAPP
      /// 🔥 2. ENVÍA A WHATSAPP
      final response = await callable.call({

        "telefono": telefono,

        "nombre": nombre,
      });

      final wamid =
      response.data['messages'][0]['id'];

      /// 🔥 3. GUARDA EN FIRESTORE
      await FirebaseFirestore.instance
          .collection('whatsapp_messages_metax')
          .add({

        "conversationId": telefono,

        "text": mensajeReal,

        "from_me": true,

        "timestamp": Timestamp.now(),

        "tipo": "template",

        "status": "sent",

        /// 🔥 NECESARIO PARA ✔✔ Y AZUL
        "wamid": wamid,
      });

      /// 🔥 4. ACTUALIZA LA CONVERSACIÓN
      await FirebaseFirestore.instance
          .collection('whatsapp_conversations_metax')
          .doc(telefono)
          .set({

        "conversationId": telefono,

        "nombre": nombreCompleto,

        "foto":

        usuarioInfo?['data']?['29_Foto_perfil']

            ??

            usuarioInfo?['data']?['foto_perfil_url']

            ??

            '',

        "tipo": usuarioInfo?['tipo'],

        "lastMessage": mensajeReal,

        "lastMessageAt": Timestamp.now(),

        "unread": 0,

      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Plantilla enviada a $nombre"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Error enviando plantilla: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error enviando plantilla"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      enviandoPlantilla = false;
    }
  }

  String normalizarNumero(String numero) {

    numero = numero
        .replaceAll(" ", "")
        .replaceAll("+", "");

    /// 🔥 SI NO TIENE 57 → AGREGARLO
    if (!numero.startsWith("57")) {
      numero = "57$numero";
    }

    return numero;
  }
}
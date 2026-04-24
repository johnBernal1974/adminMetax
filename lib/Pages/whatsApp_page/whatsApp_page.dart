import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/main_layout.dart';
import 'dart:html' as html;

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


  @override
  void initState() {
    super.initState();

    /// 🔥 AUTO-SELECCIONAR SOLO UNA VEZ
    FirebaseFirestore.instance
        .collection('whatsapp_conversations_metax')
        .orderBy('lastMessageAt', descending: true)
        .limit(1)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final first = snapshot.docs.first.data();
        final numero = first['conversationId'];

        if (mounted) {
          setState(() {
            selectedNumero = numero;
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
    return MainLayout(
      pageTitle: "WhatsApp MetaX",
      content: Row(
        children: [

          /// 🔹 LISTA DE CONVERSACIONES
          RepaintBoundary(
            child: Container(
              width: 350,
              color: Colors.grey.shade200,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('whatsapp_conversations_metax')
                    .orderBy('lastMessageAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
            
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
            
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

            
                  if (docs.isEmpty) {
                    return const Center(child: Text("No hay mensajes aún"));
                  }
            
                  return ListView.builder(
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
            
                      return KeyedSubtree(
                        key: ValueKey(doc.id), // 🔥 CLAVE
                        child: _buildItemConversacion(doc),
                      );
                    },
                  );
                },
              )
            ),
          ),

          /// 🔹 CHAT
          Expanded(
            child: Stack(
              children: [

                /// CHAT (SIEMPRE EXISTE)
                _buildChat(),

                /// OVERLAY CUANDO NO HAY SELECCIÓN
                if (selectedNumero == null)
                  const Center(
                    child: Text(
                      "Selecciona una conversación",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemConversacion(QueryDocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    final numeroRaw = map['conversationId'] ?? '';
    final numero = formatearNumero(numeroRaw);
    final texto = map['lastMessage'] ?? 'Sin mensaje';

    final nombre = map['nombre'];
    final foto = map['foto'];
    final unread = map['unread'] ?? false;

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

            final dataUsuario = await obtenerUsuario(numeroRaw);

            await FirebaseFirestore.instance
                .collection('whatsapp_conversations_metax')
                .doc(numeroRaw)
                .update({
              "unread": false,
            });

            setState(() {
              selectedNumero = numeroRaw;
              usuarioInfo = dataUsuario;
              loadingUsuario = false;
            });
          }
        },

        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

        leading: CircleAvatar(
          radius: 22,
          backgroundImage: (foto != null && foto.toString().isNotEmpty)
              ? NetworkImage(foto)
              : null,
          backgroundColor: Colors.grey.shade300,
          child: (foto == null || foto.toString().isEmpty)
              ? const Icon(Icons.person, color: Colors.black54)
              : null,
        ),

        title: Row(
          children: [
            Expanded(
              child: Text(
                (nombre != null && nombre.toString().isNotEmpty)
                    ? nombre
                    : numero,
                style: TextStyle(
                  fontWeight: (isSelected || unread)
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            /// 🔴 BADGE (solo uno, limpio)
            if (unread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "1",
                  style: TextStyle(
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
            fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
            color: unread ? Colors.black : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> obtenerUsuario(String numero) async {
    try {

      /// 🔥 NORMALIZAR NÚMERO (QUITAR 57)
      String numeroBusqueda = numero;

      if (numeroBusqueda.startsWith('57')) {
        numeroBusqueda = numeroBusqueda.substring(2);
      }

      print("Buscando usuario con número: $numeroBusqueda");

      final driver = await FirebaseFirestore.instance
          .collection("Drivers")
          .where("07_Celular", isEqualTo: numeroBusqueda)
          .limit(1)
          .get();

      if (driver.docs.isNotEmpty) {
        return {
          "tipo": "Conductor",
          "data": driver.docs.first.data(),
        };
      }

      final client = await FirebaseFirestore.instance
          .collection("Clients")
          .where("07_Celular", isEqualTo: numeroBusqueda)
          .limit(1)
          .get();

      if (client.docs.isNotEmpty) {
        return {
          "tipo": "Cliente",
          "data": client.docs.first.data(),
        };
      }

      return null;

    } catch (e) {
      print("Error buscando usuario: $e");
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
  Widget _buildChat() {

    final foto = usuarioInfo?['data'] != null
        ? (usuarioInfo!['tipo'] == 'Conductor'
        ? usuarioInfo!['data']['image']
        : usuarioInfo!['data']['foto_perfil_url'])
        : null;
    return Column(
      children: [
        /// HEADER DEL CHAT
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [

              CircleAvatar(
                radius: 40,
                backgroundImage: (foto != null && foto.toString().isNotEmpty)
                    ? NetworkImage(foto)
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: (foto == null || foto.toString().isEmpty)
                    ? const Icon(Icons.person, color: Colors.black54)
                    : null,
              ),

              const SizedBox(width: 12),

              /// 🧑 INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// 🔥 NOMBRE + APELLIDO O NUMERO
                    Builder(
                      builder: (_) {
                        String nombreMostrar = '';
                        String celularMostrar = selectedNumero != null
                            ? formatearNumero(selectedNumero!)
                            : '';

                        if (usuarioInfo != null) {
                          final data = usuarioInfo!['data'];

                          final nombre = data['01_Nombres'] ?? '';
                          final apellido = data['02_Apellidos'] ?? '';

                          nombreMostrar = "$nombre $apellido".trim();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// 👤 NOMBRE
                            Text(
                              nombreMostrar.isNotEmpty
                                  ? nombreMostrar
                                  : celularMostrar,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),

                            /// 🔥 TIPO USUARIO (PRO)
                            if (usuarioInfo != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: usuarioInfo!['tipo'] == 'Conductor'
                                      ? Colors.deepPurple.shade100
                                      : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  usuarioInfo!['tipo'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: usuarioInfo!['tipo'] == 'Conductor'
                                        ? Colors.deepPurple
                                        : Colors.blue,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "No registrado",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 2),


                            /// 📱 CELULAR / ESTADO
                            if (loadingUsuario)
                              const Text(
                                "Buscando...",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              )
                            else if (usuarioInfo != null)
                              Text(
                                celularMostrar,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              )
                            else
                              const Text(
                                "No está registrado en Meta X",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              /// 🔍 ACCIONES (opcional)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        ),

        /// MENSAJES
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('whatsapp_messages_metax')
                .where('conversationId', isEqualTo: selectedNumero)
                .orderBy('timestamp', descending: true)
                .snapshots(),

            builder: (context, snapshot) {

              /// 🔥 ERROR REAL
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              /// 🔥 LOADING REAL
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              final mensajes = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['timestamp'] != null;
              }).toList();


              if (mensajes.isEmpty) {
                return const Center(
                  child: Text("No hay mensajes"),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: mensajes.length,
                itemBuilder: (context, index) {

                  final data = mensajes[index];
                  final map = data.data() as Map<String, dynamic>;
                  final fromMe = map['from_me'] ?? false;

                  final timestamp = map['timestamp'];
                  DateTime? fecha;

                  if (timestamp is Timestamp) {
                    fecha = timestamp.toDate();
                  }

                  /// 🔥 MENSAJE ANTERIOR
                  DateTime? fechaAnterior;
                  if (index < mensajes.length - 1) {
                    final prev = mensajes[index + 1].data() as Map<String, dynamic>;
                    final prevTimestamp = prev['timestamp'];
                    if (prevTimestamp is Timestamp) {
                      fechaAnterior = prevTimestamp.toDate();
                    }
                  }

                  /// 🔥 ¿CAMBIÓ EL DÍA?
                  bool mostrarFecha = false;

                  if (fecha != null) {
                    if (fechaAnterior == null) {
                      mostrarFecha = true;
                    } else {
                      mostrarFecha =
                          fecha.day != fechaAnterior.day ||
                              fecha.month != fechaAnterior.month ||
                              fecha.year != fechaAnterior.year;
                    }
                  }

                  return Column(
                    children: [

                      /// 📅 SEPARADOR DE FECHA
                      if (mostrarFecha)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            formatearFecha(fecha),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),

                      /// 💬 MENSAJE
                      buildMensaje(map, fromMe),
                    ],
                  );
                },
              );
            },
          ),
        ),

        /// INPUT (solo UI por ahora)
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
                      color: Color(0xFFF0F2F5),
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
                              if (event is RawKeyDownEvent) {
                                final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
                                final isShiftPressed = event.isShiftPressed;

                                /// 🔥 ENTER → ENVÍA
                                if (isEnter && !isShiftPressed) {
                                  enviarMensaje();
                                }
                              }
                            },
                            child: TextField(
                              controller: _messageController,
                              focusNode: _textFieldFocusNode,

                              keyboardType: TextInputType.multiline,
                              maxLines: null,

                              decoration: const InputDecoration(
                                hintText: "Escribe un mensaje",
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
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: enviarMensaje,
                ),
              ],
            ),
          ),
        ),
        /// 🔥 BOTONES RÁPIDOS
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

              // _botonRapido("Enviar Imagen", Icons.image, onTap: () {
              //   enviarImagen("https://via.placeholder.com/300");
              // }),
              // _botonRapido("Enviar Video", Icons.video_collection, onTap: () {
              //   enviarVideo("https://youtu.be/dQw4w9WgXcQ");
              // }),
            ],
          ),
        ),
      ],
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

    final esYoutube = texto.contains("youtube.com") || texto.contains("youtu.be");

    final timestamp = map['timestamp'];
    DateTime? fecha;

    if (timestamp is Timestamp) {
      fecha = timestamp.toDate();
    }

    final hora = fecha != null ? formatearHoraAmPm(fecha) : '';

    final imageUrl = map['imageUrl'];
    final audioUrl = map['audioUrl'];


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
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 200,
                        ),
                      ),
                    if (audioUrl != null)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              // luego conectamos audio player
                            },
                          ),
                          const Text("Audio"),
                        ],
                      ),
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
    final texto = _messageController.text.trim();

    if (texto.isEmpty || selectedNumero == null) return;

    _messageController.clear();

    try {
      print("ENVIANDO A WHATSAPP:");
      print("telefono: $selectedNumero");
      print("mensaje: $texto");

      /// 🔥 1. ENVIAR A WHATSAPP PRIMERO
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      final response = await functions
          .httpsCallable('enviarWhatsAppMetaX')
          .call({
        "telefono": selectedNumero,
        "mensaje": texto,
      });

      print("RESPUESTA WHATSAPP: ${response.data}");

      /// 🔥 2. OBTENER WAMID
      final wamid = response.data['wamid'];

      print("WAMID: $wamid");

      /// 🔥 3. GUARDAR MENSAJE (AHORA SÍ)
      await FirebaseFirestore.instance
          .collection('whatsapp_messages_metax')
          .add({
        "conversationId": selectedNumero,
        "text": texto,
        "from_me": true,
        "timestamp": Timestamp.now(),
        "status": "sent",
        "wamid": wamid, // 🔥 AHORA SÍ EXISTE
      });

      /// 🔥 4. ACTUALIZAR CONVERSACIÓN
      final snapshot = await FirebaseFirestore.instance
          .collection('whatsapp_conversations_metax')
          .where('conversationId', isEqualTo: selectedNumero)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          "lastMessage": texto,
          "lastMessageAt": Timestamp.now(),
        });
      }

    } catch (e) {
      print("ERROR AL ENVIAR: $e");
    }
  }
}
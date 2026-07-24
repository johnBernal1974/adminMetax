import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metax_administrador/models/usuario_model.dart';
import '../../common/main_layout.dart';
import '../../models/operador_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';
import '../ClientDetailPage/client_detail_page.dart';
import 'package:intl/intl.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({Key? key}) : super(key: key);

  @override
  _UsuariosPageState createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  int totalClients = 0;
  Operador? operador;
  Client? client;
  final OperadorProvider _operadorProvider = OperadorProvider();
  final MyAuthProvider _authProvider = MyAuthProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientProvider>(context, listen: false).fetchClients();
    });
  }

  Color getStatusColor(Client client) {
    if (client.fotoPerfilEstado == 'rechazada' ||
        client.cedulaFrontalEstado == 'rechazada' ||
        client.cedulaReversoEstado == 'rechazada') {
      return Colors.orange;
    }

    if (client.fotoPerfilEstado == 'corregida' ||
        client.cedulaFrontalEstado == 'corregida' ||
        client.cedulaReversoEstado == 'corregida') {
      return Colors.purple;
    }

    if (client.status == 'procesando') {
      return Colors.blueAccent;
    }

    if (client.status == 'activacion_parcial') {
      return Colors.black87;
    }

    if (client.status == 'registrado') {
      return Colors.blueGrey;
    }

    if (client.status == 'activado') {
      return Colors.green;
    }

    if (client.status == 'bloqueado') {
      return Colors.red.shade900;
    }

    return Colors.grey;
  }

  bool tieneCorregida(Client client) {
    return client.fotoPerfilEstado == 'corregida' ||
        client.cedulaFrontalEstado == 'corregida' ||
        client.cedulaReversoEstado == 'corregida' ||
        client.nombreEstado == 'corregida';
  }

  bool tieneRechazada(Client client) {
    return client.fotoPerfilEstado == 'rechazada' ||
        client.cedulaFrontalEstado == 'rechazada' ||
        client.cedulaReversoEstado == 'rechazada';
  }

  List ordenarClientes(List lista) {
    lista.sort((a, b) {
      final fechaA = a.fechaRegistro;
      final fechaB = b.fechaRegistro;

      DateTime? dateA;
      DateTime? dateB;

      if (fechaA is Timestamp) dateA = fechaA.toDate();
      if (fechaB is Timestamp) dateB = fechaB.toDate();

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);
    final usuarios = clientProvider.clients;

    // 1. LÓGICA DE BÚSQUEDA (Nombre, Apellidos, Celular)
    final q = searchQuery.toLowerCase();
    List filteredClientes = usuarios.where((client) {
      if (searchQuery.isEmpty) return true;
      return client.nombres.toLowerCase().contains(q) ||
          client.apellidos.toLowerCase().contains(q) ||
          client.celular.toLowerCase().contains(q);
    }).toList();

    // 2. CATEGORÍAS (Pestañas)
    final registrados = ordenarClientes(filteredClientes.where((client) {
      final estado = (client.status ?? "").toLowerCase().trim();
      return estado == "registrado" && !tieneCorregida(client) && !tieneRechazada(client);
    }).toList());

    final corregidos = ordenarClientes(filteredClientes.where((client) {
      final estado = (client.status ?? "").toLowerCase().trim();
      if (estado == "bloqueado") return false;
      return tieneCorregida(client);
    }).toList());

    final rechazados = ordenarClientes(filteredClientes.where((client) {
      final estado = (client.status ?? "").toLowerCase().trim();
      if (estado == "bloqueado") return false;
      return tieneRechazada(client) && !tieneCorregida(client);
    }).toList());

    final procesando = ordenarClientes(filteredClientes.where((client) {
      final estado = (client.status ?? "").toLowerCase().trim();
      if (estado == "bloqueado") return false;
      if (tieneCorregida(client)) return false;
      return estado == "procesando" && !tieneRechazada(client);
    }).toList());

    final activacionParcial = ordenarClientes(filteredClientes.where((client) {
      final estado = (client.status ?? "").toLowerCase().trim();
      if (estado == "bloqueado") return false;
      if (tieneCorregida(client)) return false;
      return estado == "activacion_parcial" && !tieneRechazada(client);
    }).toList());

    final activadosGeneral = filteredClientes.where((client) {
      final estado = (client.status ?? "").toLowerCase().trim();
      return estado == "activado";
    }).toList();

    // 🔥 SUB-DIVISIÓN PARA CONTROL DE CÉDULA A PARTIR DEL TERCER SERVICIO (Viajes >= 2)
    // 🔥 ACTUALIZADO: A partir de 0 viajes (desde el inicio o primer servicio)
    final activadosConCedula = ordenarClientes(activadosGeneral.where((client) {
      final viajes = client.viajes ?? 0;
      final tieneCedulaSubida = (client.cedulaFrontalUrl ?? "").isNotEmpty &&
          (client.cedulaReversoUrl ?? "").isNotEmpty;
      return viajes >= 0 && tieneCedulaSubida;
    }).toList());

    final activadosSinCedula = ordenarClientes(activadosGeneral.where((client) {
      final viajes = client.viajes ?? 0;
      final tieneCedulaSubida = (client.cedulaFrontalUrl ?? "").isNotEmpty &&
          (client.cedulaReversoUrl ?? "").isNotEmpty;
      return viajes >= 0 && !tieneCedulaSubida;
    }).toList());

    final activados = ordenarClientes(activadosGeneral);

    final bloqueados = ordenarClientes(filteredClientes.where((client) {
      final estado = (client.status ?? "").toLowerCase().trim();
      return estado == "bloqueado";
    }).toList());

    totalClients = filteredClientes.length;

    return MainLayout(
      pageTitle: 'Clientes',
      content: DefaultTabController(
        length: 9,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),

            // Barra superior con Buscador y Refrescar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildSearchField(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 26),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      clientProvider.fetchClients();
                    },
                  ),
                ],
              ),
            ),

            // 🔥 PESTAÑAS DISTRIBUIDAS EN 2 LÍNEAS (WRAP) PARA QUE NINGUNA SE OCULTE EN PORTÁTILES
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.white,
              width: double.infinity,
              child: Builder(
                builder: (context) {
                  final TabController tabController = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: [
                          _buildCustomTabButton("🆕 Registrados", registrados.length, 0, tabController),
                          _buildCustomTabButton("🛠️ Corregidos", corregidos.length, 1, tabController),
                          _buildCustomTabButton("⏳ Procesando", procesando.length, 2, tabController),
                          _buildCustomTabButton("🟡 Activ. Parcial", activacionParcial.length, 3, tabController),
                          _buildCustomTabButton("🚫 Rechazados", rechazados.length, 4, tabController),
                          _buildCustomTabButton("🟢 Activos", activados.length, 5, tabController),
                          _buildCustomTabButton("⚠️ Sin Cédula", activadosSinCedula.length, 6, tabController),
                          _buildCustomTabButton("✅ Al Día", activadosConCedula.length, 7, tabController),
                          _buildCustomTabButton("🔴 Bloqueados", bloqueados.length, 8, tabController),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Contenido de las Pestañas
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                margin: const EdgeInsets.all(7),
                child: TabBarView(
                  children: [
                    _buildTabContent(registrados),
                    _buildTabContent(corregidos),
                    _buildTabContent(procesando),
                    _buildTabContent(activacionParcial),
                    _buildTabContent(rechazados),
                    _buildTabContent(activados),
                    _buildTabContent(activadosSinCedula),
                    _buildTabContent(activadosConCedula),
                    _buildTabContent(bloqueados),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabButton(String title, int count, int index, TabController controller) {
    final bool isSelected = controller.index == index;
    return InkWell(
      onTap: () {
        controller.animateTo(index);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          "$title ($count)",
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List listaClientes) {
    if (listaClientes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "No hay clientes disponibles en esta sección.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildClientTable(listaClientes, getStatusColor),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 350,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Buscar por nombre, apellidos o celular',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildClientTable(List filteredClientes, Color Function(Client) getStatusColor) {
    return DataTable(
      columnSpacing: 20.0,
      headingRowHeight: 56.0,
      dataRowHeight: 70.0,
      columns: const [
        DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Foto', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Apellidos', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Celular', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Viajes', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Fecha registro', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: filteredClientes.map((client) {
        return DataRow(
          onSelectChanged: (_) => _irADetalleCliente(client),
          cells: [
            DataCell(
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, color: getStatusColor(client)),
              ),
            ),
            DataCell(
              // 🔥 ENVOLVEMOS LA FOTO EN UN GESTUREDETECTOR PARA QUE SEA CLICKEABLE
              InkWell(
                onTap: () {
                  if (client.fotoPerfilUrl != null && client.fotoPerfilUrl.isNotEmpty) {
                    _mostrarFotoGrande(context, client.fotoPerfilUrl, "${client.nombres} ${client.apellidos}");
                  }
                },
                child: Tooltip(
                  message: "Haz clic para ver la foto en grande",
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      image: (client.fotoPerfilUrl != null && client.fotoPerfilUrl.isNotEmpty)
                          ? DecorationImage(
                        image: NetworkImage(client.fotoPerfilUrl),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: (client.fotoPerfilUrl == null || client.fotoPerfilUrl.isEmpty)
                        ? const Icon(Icons.person, size: 20, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(client.nombres.isNotEmpty ? client.nombres : "Nombre no disponible", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (tieneCorregida(client)) _buildMiniBadge("Corregido", Colors.purple),
                  if (!tieneCorregida(client) && tieneRechazada(client)) _buildMiniBadge("Rechazado", Colors.orange),
                ],
              ),
            ),
            DataCell(Text(client.apellidos.isNotEmpty ? client.apellidos : "Apellidos no disponibles", style: const TextStyle(color: Colors.black))),
            DataCell(Text(client.celular.isNotEmpty ? client.celular : "Celular no disponible")),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${client.viajes ?? 0}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
            DataCell(Text(_formatearFecha(client.fechaRegistro))),
            DataCell(
              IconButton(
                icon: const Icon(Icons.double_arrow_outlined, color: Colors.black),
                onPressed: () => _irADetalleCliente(client),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // 🔥 MÉTODO PARA ABRIR LA TARJETA FLOTANTE CON LA FOTO GRANDE
  void _mostrarFotoGrande(BuildContext context, String imageUrl, String nombreCliente) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera con Nombre y Botón de Cerrar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        nombreCliente,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                // Imagen ampliada con soporte de Zoom
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 350,
                      maxHeight: 400,
                    ),
                    child: InteractiveViewer(
                      panEnabled: true, // Permite mover la imagen si se hace zoom
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 150,
                            child: Center(child: Text("No se pudo cargar la imagen")),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "💡 Puedes hacer zoom con el mouse o la pantalla táctil",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniBadge(String texto, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _formatearFecha(dynamic fecha) {
    try {
      if (fecha == null) return "Sin fecha";
      if (fecha is Timestamp) {
        final date = fecha.toDate();
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
      if (fecha is String) {
        return fecha;
      }
      return "Formato inválido";
    } catch (e) {
      return "Error";
    }
  }

  void _irADetalleCliente(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailPage(client: client),
      ),
    );
  }
}
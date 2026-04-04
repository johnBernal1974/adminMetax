
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

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({Key? key}) : super(key: key);

  @override
  _UsuariosPageState createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String filterStatus = "";
  int totalClients = 0;
  Operador? operador;
  Client? client;
  OperadorProvider _operadorProvider = OperadorProvider();
  MyAuthProvider _authProvider = MyAuthProvider();

  @override
  Widget build(BuildContext context) {
    print('Nombre del operador recibido es/////////////////////**************************: ${operador?.the01Nombres}');
    final clientProvider = Provider.of<ClientProvider>(context);
    final usuarios = clientProvider.clients;
    final isMobileOrTablet = MediaQuery.of(context).size.width <= 800;

    Color getStatusColor(Client client) {

      // 🔴 prioridad máxima
      if (client.fotoPerfilEstado == 'rechazada' ||
          client.cedulaFrontalEstado == 'rechazada' ||
          client.cedulaReversoEstado == 'rechazada') {
        return Colors.red;
      }

      // 🟣 corregida
      if (client.fotoPerfilEstado == 'corregida' ||
          client.cedulaFrontalEstado == 'corregida' ||
          client.cedulaReversoEstado == 'corregida') {
        return Colors.purple;
      }

      // 🔵 en proceso
      if (client.status == 'procesando') {
        return Colors.blue;
      }

      // ⚪ registrado
      if (client.status == 'registrado') {
        return Colors.grey;
      }

      // 🟢 activado
      if (client.status == 'activado') {
        return Colors.green;
      }

      return Colors.grey;
    }

    List filteredClientes = usuarios.where((client) {
      bool matchesFilter = true;
      if (filterStatus.isNotEmpty) {
        switch (filterStatus) {
          case 'registrado':
            matchesFilter = client.status == 'registrado';
            break;
          case 'foto_tomada':
            matchesFilter = client.status == 'foto_tomada';
            break;
          case 'corregida':
            matchesFilter =
                client.fotoPerfilEstado == 'corregida' ||
                    client.cedulaFrontalEstado == 'corregida' ||
                    client.cedulaReversoEstado == 'corregida';
            break;

          case 'rechazada':
            matchesFilter =
                client.fotoPerfilEstado == 'rechazada' ||
                    client.cedulaFrontalEstado == 'rechazada' ||
                    client.cedulaReversoEstado == 'rechazada';
            break;

        }
      }
      return matchesFilter &&
          (client.nombres.toLowerCase().contains(searchQuery.toLowerCase()) ||
              client.apellidos.toLowerCase().contains(searchQuery.toLowerCase()) ||
              client.celular.toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();
    totalClients = filteredClientes.length;

    int countByStatus(String status) {
      return usuarios.where((client) {
        switch (status) {

          case 'registrado':
            return client.status == 'registrado';

          case 'procesando':
            return client.status == 'procesando';

          case 'activado':
            return client.status == 'activado';

          case 'bloqueado':
            return client.status == 'bloqueado';

          case 'rechazado_docs':
            return client.fotoPerfilEstado == 'rechazada' ||
                client.cedulaFrontalEstado == 'rechazada' ||
                client.cedulaReversoEstado == 'rechazada';

          case 'corregido_docs':
            return client.fotoPerfilEstado == 'corregida' ||
                client.cedulaFrontalEstado == 'corregida' ||
                client.cedulaReversoEstado == 'corregida';

          default:
            return false;
        }
      }).length;
    }

    return MainLayout(
      content: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top), // Espacio para la barra de estado en la parte superior
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                margin: const EdgeInsets.all(7),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth <= 600) {
                      return _buildMobileLayout(context, clientProvider, filteredClientes, countByStatus, getStatusColor);
                    } else {
                      return _buildDesktopLayout(context, clientProvider, filteredClientes, countByStatus, getStatusColor);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      pageTitle: 'Clientes',
    );
  }

  void getOperadorInfo() async {
    operador = await OperadorProvider().getById(_authProvider.getUser()!.uid);
    print('Datos del operador: $operador');
    // Asegúrate de llamar a setState si es necesario para actualizar la UI
  }

  Widget _buildMobileLayout(
      BuildContext context,
      ClientProvider clientProvider,
      List filteredClientes,
      int Function(String) countByStatus,
      Color Function(Client) getStatusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Total de Clientes:\n$totalClients', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.refresh),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                clientProvider.fetchClients();
              },
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 20, thickness: 2),
        _buildSearchField(),
        const SizedBox(height: 30),
        // _buildFilterButtons(true, countByStatus),
        const SizedBox(height: 10),
        _buildClientTable(filteredClientes, getStatusColor),
      ],
    );
  }



  Widget _buildDesktopLayout(
      BuildContext context,
      ClientProvider clienProvider,
      List filteredClientes,
      int Function(String) countByStatus,
      Color Function(Client) getStatusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Total de Clientes:\n$totalClients', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 100),
            ElevatedButton(
              onPressed: () {
                clienProvider.fetchClients();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Cargar Clientes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 20, thickness: 2),
        _buildSearchField(),
        const SizedBox(height: 30),
        _buildClientTable(filteredClientes, getStatusColor),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 350,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Buscar cliente',
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await _ejecutarBusqueda();
            },
          ),
        ),

        // 🔥 SOLO cuando presiona ENTER
        onSubmitted: (value) async {
          await _ejecutarBusqueda();
        },

        // ❌ IMPORTANTE: quitar lógica de búsqueda en tiempo real
        onChanged: (value) {
          // solo actualiza el texto, NO busca
          searchQuery = value.trim();
        },
      ),
    );
  }

  Future<void> _ejecutarBusqueda() async {
    final query = searchController.text.trim();

    final provider = Provider.of<ClientProvider>(context, listen: false);

    if (query.isEmpty) {
      await provider.fetchClients();
      return;
    }

    await provider.searchClients(query);

    // 🔥 validar si no encontró resultados
    if (provider.clients.isEmpty && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Sin resultados"),
          content: const Text("No se encontró ningún cliente con ese criterio."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            )
          ],
        ),
      );
    }
  }

  Widget _buildClientTable(List filteredClientes, Color Function(Client) getStatusColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 20.0,
          headingRowHeight: 56.0,
          dataRowHeight: 70.0,
          columns: const [
            DataColumn(
              label: Text(
                'Estado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            DataColumn(
              label: Text(
                'Nombre',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Apellidos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Celular',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Acción',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: filteredClientes.map((client) {
            return DataRow(
              onSelectChanged: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientDetailPage(client: client),
                  ),
                );
              },
              cells: [
                DataCell(
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: getStatusColor(client),
                    ),
                  ),
                ),
                DataCell(Text(client.nombres.isNotEmpty ? client.nombres : "Nombre no disponible")),
                DataCell(Text(client.apellidos.isNotEmpty ? client.apellidos : "Apellidos no disponibles")),
                DataCell(Text(client.celular.isNotEmpty ? client.celular : "Celular no disponible")),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.double_arrow_outlined, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClientDetailPage(client: client),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }


}

import 'package:cached_network_image/cached_network_image.dart';
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

    Color getStatusColor(client) {

      if (client.status == "registrado") {
        return Colors.grey; // ⚪ gris
      }

      if (client.status == "procesando") {
        return Colors.blue; // 🔵 proceso
      }

      if (client.status == "corregida") {
        return Colors.purple; // 🟣 corregida
      }

      if (client.status == "rechazada") {
        return Colors.amber; // 🟡 rechazada
      }

      if (client.status == "foto_tomada") {
        return Colors.blue; // 🔵 info cargada
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
            matchesFilter = client.status == 'corregida';
            break;
          case 'rechazada':
            matchesFilter = client.status == 'rechazada';
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

  Widget _buildMobileLayout(BuildContext context, ClientProvider clientProvider, List filteredClientes, int Function(String) countByStatus, Color Function(dynamic) getStatusColor) {
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
        _buildFilterButtons(true, countByStatus),
        const SizedBox(height: 10),
        _buildClientTable(filteredClientes, getStatusColor),
      ],
    );
  }



  Widget _buildDesktopLayout(BuildContext context, ClientProvider clienProvider, List filteredClientes, int Function(String) countByStatus, Color Function(dynamic) getStatusColor) {
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
        _buildFilterButtons(false, countByStatus),
        const SizedBox(height: 10),
        _buildClientTable(filteredClientes, getStatusColor),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 350,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Buscar cliente',
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                searchQuery = searchController.text.trim();
              });
            },
          ),
        ),
        onChanged: (value) async {
          final query = value.trim();

          setState(() {
            searchQuery = query;
          });

          final provider = Provider.of<ClientProvider>(context, listen: false);

          if (query.isEmpty) {
            await provider.fetchClients(); // vuelve a filtrado normal
          } else {
            await provider.searchClients(query); // busca en TODOS
          }
        },
      ),
    );
  }

  Widget _buildFilterButtons(bool isMobile, int Function(String) countByStatus) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        if (isMobile)
          ..._buildMobileFilterButtons(countByStatus)
        else
          ..._buildDesktopFilterButtons(countByStatus),
      ],
    );
  }
  List<Widget> _buildMobileFilterButtons(int Function(String) countByStatus) {
    return [
      IconButton(
        icon: Icon(Icons.account_circle, color: Colors.blueGrey),
        onPressed: () {
          setState(() {
            filterStatus = 'registrado';
          });
        },
        tooltip: 'Registrado (${countByStatus('registrado')})',
      ),
      IconButton(
        icon: Icon(Icons.photo_camera, color: Colors.amber),
        onPressed: () {
          setState(() {
            filterStatus = 'foto_tomada';
          });
        },
        tooltip: 'Doc. Faltantes (${countByStatus('foto_tomada')})',
      ),

      IconButton(
        icon: Icon(Icons.check_circle, color: Colors.purple),
        onPressed: () {
          setState(() {
            filterStatus = 'corregida';
          });
        },
        tooltip: 'Corregida (${countByStatus('corregida')})',
      ),
      IconButton(
        icon: Icon(Icons.watch_later, color: Colors.brown.shade900),
        onPressed: () {
          setState(() {
            filterStatus = 'rechazada';
          });
        },
        tooltip: 'En espera (${countByStatus('rechazada')})',
      ),

      IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () {
          setState(() {
            filterStatus = '';
            searchQuery = '';
          });
        },
        tooltip: 'Reset',
      ),
    ];
  }

  List<Widget> _buildDesktopFilterButtons(int Function(String) countByStatus) {
    return [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black, backgroundColor: Colors.blueGrey,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'registrado';
          });
        },
        child: Text('Registrado (${countByStatus('registrado')})', style: TextStyle(color: blanco)),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.amber,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'foto_tomada';
          });
        },
        child: Text('Doc. Faltantes (${countByStatus('foto_tomada')})', style: TextStyle(color: negro)),
      ),

      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.purple,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'corregida';
          });
        },
        child: Text('Corregida (${countByStatus('corregida')})'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.brown.shade900,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'rechazada';
          });
        },
        child: Text('En espera (${countByStatus('rechazada')})'),
      ),

      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          setState(() {
            filterStatus = '';
            searchQuery = '';
          });
        },
        tooltip: 'Reset',
      ),
    ];
  }

  Widget _buildClientTable(List filteredClientes, Color Function(dynamic) getStatusColor) {
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

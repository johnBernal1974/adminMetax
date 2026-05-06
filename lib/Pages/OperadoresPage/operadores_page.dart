import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/main_layout.dart';
import '../../models/operador_model.dart';
import '../../providers/operador_provider.dart';
import '../../src/color.dart';
import '../OperadorDetailPage/operador_detail_page.dart';

class OperadoresPage extends StatefulWidget {
  const OperadoresPage({Key? key}) : super(key: key);

  @override
  _OperadoresPageState createState() => _OperadoresPageState();
}

class _OperadoresPageState extends State<OperadoresPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String filterStatus = "";
  int totalOperadores = 0;
  Operador? operador;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperadorProvider>().fetchOperadores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final operadorProvider = Provider.of<OperadorProvider>(context);
    final operadores = operadorProvider.operadores;
    final isMobileOrTablet = MediaQuery.of(context).size.width <= 800;

    Color getStatusColor(operador) {
      if (operador.verificacionStatus == "registrado"
      ) {
        return Colors.blueGrey;
      }

      else if (operador.verificacionStatus == 'activado') {
        return Colors.green;
      }
      else if (operador.verificacionStatus == 'bloqueado') {
        return Colors.red.shade900;
      }


      else {
        return Colors.grey;
      }
    }

    List filteredOperadores = operadores.where((operador) {
      bool matchesFilter = true;
      if (filterStatus.isNotEmpty) {
        switch (filterStatus) {
          case 'registrado':
            matchesFilter = operador.verificacionStatus == 'registrado';
            break;
          case 'activado':
            matchesFilter = operador.verificacionStatus == 'activado';
            break;
          case 'bloqueado':
            matchesFilter = operador.verificacionStatus == "bloqueado";
            break;


        }
      }
      return matchesFilter &&
          (operador.the01Nombres.toLowerCase().contains(searchQuery.toLowerCase()) ||
              operador.the02Apellidos.toLowerCase().contains(searchQuery.toLowerCase()) ||
              operador.the04NumeroDocumento.toLowerCase().contains(searchQuery.toLowerCase()) ||
              operador.the06Email.toLowerCase().contains(searchQuery.toLowerCase()) ||
              operador.the07Celular.toLowerCase().contains(searchQuery.toLowerCase()));
    }).toList();
    totalOperadores = filteredOperadores.length;

    int countByStatus(String status) {
      return operadores.where((operador) {
        switch (status) {
          case 'registrado':
            return operador.verificacionStatus == 'registrado';

          case 'activado':
            return operador.verificacionStatus == 'activado';

          case 'bloqueado':
            return operador.verificacionStatus == 'bloqueado';

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
                      return _buildMobileLayout(context, operadorProvider, filteredOperadores, countByStatus, getStatusColor);
                    } else {
                      return _buildDesktopLayout(context, operadorProvider, filteredOperadores, countByStatus, getStatusColor);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      pageTitle: 'Operadores',
    );
  }

  Widget _buildMobileLayout(BuildContext context, OperadorProvider operadorProvider, List filteredOperadores, int Function(String) countByStatus, Color Function(dynamic) getStatusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Total operadores:\n$totalOperadores', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.refresh),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                operadorProvider.fetchOperadores();
              },
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 20, thickness: 2),
        _buildSearchField(),
        const SizedBox(height: 30),
        _buildFilterButtons(true, countByStatus),
        const SizedBox(height: 10),
        _buildOperadoresTable(filteredOperadores, getStatusColor),
      ],
    );
  }



  Widget _buildDesktopLayout(BuildContext context, OperadorProvider operadorProvider, List filteredOperadores, int Function(String) countByStatus, Color Function(dynamic) getStatusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Total operadores:\n$totalOperadores', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 100),
            ElevatedButton(
              onPressed: () {
                operadorProvider.fetchOperadores();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Cargar Operadores', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 20, thickness: 2),
        _buildSearchField(),
        const SizedBox(height: 30),
        _buildFilterButtons(false, countByStatus),
        const SizedBox(height: 10),
        _buildOperadoresTable(filteredOperadores, getStatusColor),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 350,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Buscar operador',
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                searchQuery = searchController.text.trim();
              });
            },
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
        icon: Icon(Icons.verified, color: Colors.green),
        onPressed: () {
          setState(() {
            filterStatus = 'activado';
          });
        },
        tooltip: 'Activado (${countByStatus('activado')})',
      ),
      IconButton(
        icon: Icon(Icons.block, color: Colors.red.shade900),
        onPressed: () {
          setState(() {
            filterStatus = 'bloqueado';
          });
        },
        tooltip: 'Bloqueado (${countByStatus('bloqueado')})',
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
          foregroundColor: Colors.white, backgroundColor: Colors.green,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'activado';
          });
        },
        child: Text('Activado (${countByStatus('activado')})'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.red.shade900,
        ),
        onPressed: () {
          setState(() {
            filterStatus = 'bloqueado';
          });
        },
        child: Text('Bloqueado (${countByStatus('bloqueado')})'),
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

  Widget _buildOperadoresTable(List filteredOperadores, Color Function(dynamic) getStatusColor) {
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
                'Imagen',
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
                'Identificación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Correo',
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
          rows: filteredOperadores.map((operador) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: getStatusColor(operador),
                    ),
                  ),
                ),
                DataCell(
                  ClipOval(
                    child: operador.image != null && operador.image.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: operador.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                        : Icon(Icons.person, size: 50), // Muestra un ícono si la URL está vacía
                  ),
                ),

                DataCell(Text(
                  operador.the01Nombres ?? "Nombre no disponible",
                  style: TextStyle(color: Colors.black),
                )),
                DataCell(Text(
                  operador.the02Apellidos ?? "Apellidos no disponibles",
                  style: TextStyle(color: Colors.black),
                )),
                DataCell(Text(operador.the04NumeroDocumento ?? "Documento no disponible")),
                DataCell(Text(operador.the06Email ?? "Email no disponible")),
                DataCell(Text(operador.the07Celular ?? "Celular no disponible")),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.double_arrow_outlined, color: negro),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OperadorDetailPage(operador: operador),
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

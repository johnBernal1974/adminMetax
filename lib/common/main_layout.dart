import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Pages/widgets/side_bar_menu.dart';
import '../providers/operador_provider.dart';
import '../src/color.dart';

class MainLayout extends StatelessWidget {
  final Widget content;
  final String pageTitle; // Nuevo atributo para el título dinámico

  const MainLayout({Key? key, required this.content, required this.pageTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: blancoCards,
      drawer: MediaQuery.of(context).size.width < 800 ? const SideBar() : null,
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.black),

        /// 🔥 AQUÍ AGREGAMOS EL NOMBRE DEL OPERADOR
        actions: [
          Consumer<OperadorProvider>(
            builder: (context, operadorProvider, _) {

              /// 🧠 mientras carga
              if (operadorProvider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final nombre = operadorProvider.nombreActual ?? '';
              final apellido = operadorProvider.apellidosActual ?? '';

              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 16, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$nombre $apellido",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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
          if (MediaQuery.of(context).size.width > 800)
            const SizedBox(
              width: 300,
              child: SideBar(),
            ),
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }
}

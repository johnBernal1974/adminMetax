import 'package:flutter/material.dart';
import '../Pages/widgets/side_bar_menu.dart';
import '../src/color.dart';

class MainLayout extends StatelessWidget {
  final Widget content;
  final String pageTitle; // Nuevo atributo para el título dinámico

  const MainLayout({Key? key, required this.content, required this.pageTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: grisMapa,
      drawer: MediaQuery.of(context).size.width < 800 ? const SideBar() : null,
      appBar: AppBar(
        title: Text(pageTitle, style: const TextStyle(color: Colors.black),),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.black),// Usar el atributo pageTitle para el título
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

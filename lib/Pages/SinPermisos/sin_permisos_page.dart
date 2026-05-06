import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SinPermisosPage extends StatelessWidget {
  const SinPermisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 60),
              SizedBox(height: 12),
              Text(
                'Acceso restringido',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Tu cuenta no tiene permisos para ingresar a ésta página.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
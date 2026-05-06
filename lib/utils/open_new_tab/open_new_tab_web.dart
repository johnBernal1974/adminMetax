import 'dart:html' as html;

/// Soporta apps con hash (#/ruta) y sin hash (/ruta).
void openNewTabRouteImpl(String routeName) {
  final base = Uri.base;

  // Asegura que empiece con /
  final path = routeName.startsWith('/') ? routeName : '/$routeName';

  // Si tu app usa HashUrlStrategy (lo típico), el route va en el fragment: #/ruta
  // Si usas PathUrlStrategy, va en el path normal: /ruta
  final usesHash = base.fragment.startsWith('/');

  final url = usesHash
      ? '${base.origin}${base.path}#$path'
      : '${base.origin}$path';

  // noopener/noreferrer por seguridad
  html.window.open(url, '_blank', 'noopener,noreferrer');
}

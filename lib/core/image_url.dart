/// Para fotos alojadas en Cloudinary, pide al CDN una versión ya recortada
/// y comprimida al tamaño en que se va a pintar, en vez de descargar el
/// original (una foto de móvil pesa 1–3 MB para un avatar de 56 px).
/// Cualquier otra URL (p. ej. fotos de Google, ya pequeñas) se devuelve
/// tal cual.
String thumbnailUrl(String url, {required double logicalSize}) {
  const marker = '/image/upload/';
  final index = url.indexOf(marker);
  if (!url.contains('res.cloudinary.com') || index == -1) return url;

  // x3 cubre pantallas de alta densidad; redondeado a múltiplos de 32 para
  // que tamaños parecidos compartan la misma versión en la caché del CDN.
  final px = ((logicalSize * 3) / 32).ceil() * 32;
  final insertAt = index + marker.length;
  return '${url.substring(0, insertAt)}'
      'c_fill,w_$px,h_$px,q_auto,f_auto/'
      '${url.substring(insertAt)}';
}

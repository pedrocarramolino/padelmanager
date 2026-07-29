import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logotipo oficial "G" de Google (multicolor), para el botón de
/// inicio de sesión. Los iconos de Material no incluyen el logo de
/// Google, así que se dibuja a partir del SVG oficial de la marca.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">
  <path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4814h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2581h2.9087c1.7018-1.5668 2.6836-3.8741 2.6836-6.615z"/>
  <path fill="#34A853" d="M9 18c2.43 0 4.4673-.8055 5.9564-2.1805l-2.9087-2.2581c-.8055.5395-1.8368.8618-3.0477.8618-2.3436 0-4.3277-1.5832-5.036-3.7104H.9573v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
  <path fill="#FBBC05" d="M3.964 10.7386c-.18-.5395-.2822-1.1114-.2822-1.7386s.1023-1.1991.2822-1.7386V4.9295H.9573C.3477 6.1732 0 7.5477 0 9s.3477 2.8268.9573 4.0705l3.0068-2.3319z"/>
  <path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5813-2.5814C13.4632.8918 11.4259 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9295L3.964 7.2614C4.6723 5.1341 6.6564 3.5795 9 3.5795z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

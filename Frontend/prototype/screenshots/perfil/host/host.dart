class PerfilHost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375,
          height: 855,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                left: 26,
                top: 125,
                child: Container(
                  width: 324,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 7,
                    children: [
                      Container(
                        width: 96,
                        height: 92,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFD9D9D9),
                          shape: OvalBorder(),
                        ),
                      ),
                      SizedBox(
                        width: 324,
                        height: 26,
                        child: Text(
                          'Acesse agora',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF182541) /* Dark-Blue */,
                            fontSize: 20,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w700,
                            height: 1.20,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 324,
                        height: 26,
                        child: Text(
                          'usuario@user.com',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0x3F182541),
                            fontSize: 13,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w500,
                            height: 1.85,
                          ),
                        ),
                      ),
                      Container(
                        width: 116,
                        height: 29,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 116,
                                height: 29,
                                decoration: ShapeDecoration(
                                  color: const Color(0x33EC6725),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFEC6725),
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 1,
                              child: SizedBox(
                                width: 116,
                                height: 26,
                                child: Text(
                                  'Editar perfil ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF182541),
                                    fontSize: 13,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w500,
                                    height: 1.85,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 27,
                top: 328,
                child: Container(
                  width: 321,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 15,
                    children: [
                      SizedBox(
                        width: 317,
                        height: 42.53,
                        child: Text(
                          'Atividade',
                          style: TextStyle(
                            color: const Color(0x7F182541),
                            fontSize: 13,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w500,
                            height: 1.85,
                          ),
                        ),
                      ),
                      Container(
                        width: 321,
                        height: 180,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0x3F182541),
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                      Container(
                        width: 307,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 9,
                          children: [
                            Container(
                              height: 25,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 10,
                                children: [
                                  SizedBox(
                                    width: 251,
                                    height: 26,
                                    child: Text(
                                      'notificações',
                                      style: TextStyle(
                                        color: const Color(0x7F182541),
                                        fontSize: 13,
                                        fontFamily: 'Stack Sans Headline',
                                        fontWeight: FontWeight.w500,
                                        height: 1.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    strokeAlign: BorderSide.strokeAlignCenter,
                                    color: const Color(0x3F182541),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 294,
                              height: 25,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 7,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(),
                                  ),
                                  SizedBox(
                                    width: 251,
                                    height: 24,
                                    child: Text(
                                      'Agendamentos',
                                      style: TextStyle(
                                        color: const Color(0x7F182541),
                                        fontSize: 13,
                                        fontFamily: 'Stack Sans Headline',
                                        fontWeight: FontWeight.w500,
                                        height: 1.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    strokeAlign: BorderSide.strokeAlignCenter,
                                    color: const Color(0x3F182541),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 25,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 10,
                                children: [
                                  SizedBox(
                                    width: 251,
                                    height: 26,
                                    child: Text(
                                      'Dashboard',
                                      style: TextStyle(
                                        color: const Color(0x7F182541),
                                        fontSize: 13,
                                        fontFamily: 'Stack Sans Headline',
                                        fontWeight: FontWeight.w500,
                                        height: 1.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    strokeAlign: BorderSide.strokeAlignCenter,
                                    color: const Color(0x3F182541),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 25,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 10,
                                children: [
                                  SizedBox(
                                    width: 251,
                                    height: 26,
                                    child: Text(
                                      'Meus quartos',
                                      style: TextStyle(
                                        color: const Color(0x7F182541),
                                        fontSize: 13,
                                        fontFamily: 'Stack Sans Headline',
                                        fontWeight: FontWeight.w500,
                                        height: 1.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 319,
                        height: 26,
                        child: Text(
                          'sistema',
                          style: TextStyle(
                            color: const Color(0x7F182541),
                            fontSize: 13,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w500,
                            height: 1.85,
                          ),
                        ),
                      ),
                      Container(
                        width: 321,
                        height: 98,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: const Color(0x3F182541),
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                      Container(
                        width: 307,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 9,
                          children: [
                            Container(
                              height: 25,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 10,
                                children: [
                                  SizedBox(
                                    width: 251,
                                    height: 26,
                                    child: Text(
                                      'configurações',
                                      style: TextStyle(
                                        color: const Color(0x7F182541),
                                        fontSize: 13,
                                        fontFamily: 'Stack Sans Headline',
                                        fontWeight: FontWeight.w500,
                                        height: 1.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    strokeAlign: BorderSide.strokeAlignCenter,
                                    color: const Color(0x3F182541),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 294,
                              height: 25,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 7,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(),
                                  ),
                                  SizedBox(
                                    width: 251,
                                    height: 24,
                                    child: Text(
                                      'suporte',
                                      style: TextStyle(
                                        color: const Color(0x7F182541),
                                        fontSize: 13,
                                        fontFamily: 'Stack Sans Headline',
                                        fontWeight: FontWeight.w500,
                                        height: 1.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 321,
                        height: 48,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 321,
                                height: 48,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFEC6725),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFEC6725),
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 13,
                              child: SizedBox(
                                width: 321,
                                height: 23,
                                child: Text(
                                  'sair',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF182541),
                                    fontSize: 13,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w500,
                                    height: 1.85,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 375,
                  height: 44,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 21,
                        top: 12,
                        child: Container(
                          width: 54,
                          height: 21,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Stack(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: -8,
                top: 756,
                child: Container(
                  width: 390,
                  height: 99.50,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 22.50,
                        child: Container(
                          width: 390,
                          height: 77,
                          decoration: BoxDecoration(
                            color: const Color(0xFF182541) /* Dark-Blue */,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 308,
                        top: 4.50,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFD9D9D9) /* Grey */,
                            shape: OvalBorder(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 183,
                        top: 37,
                        child: Container(
                          width: 24,
                          height: 24,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: Stack(),
                        ),
                      ),
                      Positioned(
                        left: 47,
                        top: 39,
                        child: Container(
                          width: 24,
                          height: 22.98,
                          child: Stack(),
                        ),
                      ),
                      Positioned(
                        left: 251,
                        top: 37,
                        child: Container(
                          width: 24,
                          height: 24,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(),
                                  child: Stack(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 115,
                        top: 38,
                        child: Container(
                          width: 24,
                          height: 24,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: Stack(),
                        ),
                      ),
                      Positioned(
                        left: 319,
                        top: 14,
                        child: Container(
                          width: 24,
                          height: 24,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: Stack(),
                        ),
                      ),
                      Positioned(
                        left: 36,
                        top: 109,
                        child: SizedBox(
                          width: 46,
                          height: 23,
                          child: Opacity(
                            opacity: 0,
                            child: Text(
                              'search',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFD9D9D9) /* Grey */,
                                fontSize: 14,
                                fontFamily: 'Stack Sans Headline',
                                fontWeight: FontWeight.w400,
                                height: 1.36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 104,
                        top: 109,
                        child: SizedBox(
                          width: 46,
                          height: 23,
                          child: Opacity(
                            opacity: 0,
                            child: Text(
                              'likes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFD9D9D9) /* Grey */,
                                fontSize: 14,
                                fontFamily: 'Stack Sans Headline',
                                fontWeight: FontWeight.w400,
                                height: 1.36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 172,
                        top: 109,
                        child: SizedBox(
                          width: 46,
                          height: 23,
                          child: Opacity(
                            opacity: 0,
                            child: Text(
                              'home',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFD9D9D9) /* Grey */,
                                fontSize: 14,
                                fontFamily: 'Stack Sans Headline',
                                fontWeight: FontWeight.w400,
                                height: 1.36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 226,
                        top: 109,
                        child: SizedBox(
                          width: 70,
                          height: 23,
                          child: Opacity(
                            opacity: 0,
                            child: Text(
                              'messages',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFD9D9D9) /* Grey */,
                                fontSize: 14,
                                fontFamily: 'Stack Sans Headline',
                                fontWeight: FontWeight.w400,
                                height: 1.36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 296,
                        top: 66,
                        child: SizedBox(
                          width: 70,
                          height: 23,
                          child: Text(
                            'perfil',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFD9D9D9) /* Grey */,
                              fontSize: 14,
                              fontFamily: 'Stack Sans Headline',
                              fontWeight: FontWeight.w400,
                              height: 1.36,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
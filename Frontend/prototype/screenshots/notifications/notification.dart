class Notification extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375,
          height: 812,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: -76,
                child: Container(
                  width: 375,
                  height: 225,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF182541) /* Dark-Blue */,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.50,
                        color: const Color(0xFFE6E6E6),
                      ),
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 26,
                top: 108,
                child: SizedBox(
                  width: 324,
                  height: 26,
                  child: Text(
                    'Notificações ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Stack Sans Headline',
                      fontWeight: FontWeight.w700,
                      height: 1.20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 28,
                top: 175,
                child: Container(
                  width: 322,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 60,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 322,
                                height: 60,
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
                            ),
                            Positioned(
                              left: 283,
                              top: 19,
                              child: Container(
                                width: 27,
                                height: 27,
                                decoration: ShapeDecoration(
                                  color: const Color(0x49EC6725),
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFEC6725),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 291,
                              top: 27,
                              child: Container(
                                width: 12,
                                height: 12,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 16,
                              child: SizedBox(
                                width: 184,
                                height: 15,
                                child: Text(
                                  'Reserva Aprovada',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 14,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.07,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 166,
                              top: 23,
                              child: SizedBox(
                                width: 86,
                                height: 15,
                                child: Text(
                                  'ver detalhes',
                                  style: TextStyle(
                                    color: const Color(0xFFEC6725) /* Orange */,
                                    fontSize: 14,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.07,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 31,
                              child: SizedBox(
                                width: 215,
                                child: Text(
                                  'Grand Hotel Budapest',
                                  style: TextStyle(
                                    color: const Color(0xFFA3A3A3) /* Darker-grey */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 60,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 322,
                                height: 60,
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
                            ),
                            Positioned(
                              left: 283,
                              top: 19,
                              child: Container(
                                width: 27,
                                height: 27,
                                decoration: ShapeDecoration(
                                  color: const Color(0x49EC6725),
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFEC6725),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 291,
                              top: 27,
                              child: Container(
                                width: 12,
                                height: 12,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 16,
                              child: SizedBox(
                                width: 184,
                                height: 15,
                                child: Text(
                                  'Nova Mensagem',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 14,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.07,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 166,
                              top: 23,
                              child: SizedBox(
                                width: 86,
                                height: 15,
                                child: Text(
                                  'ver detalhes',
                                  style: TextStyle(
                                    color: const Color(0xFFEC6725) /* Orange */,
                                    fontSize: 14,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.07,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 31,
                              child: SizedBox(
                                width: 215,
                                child: Text(
                                  'Bo turista',
                                  style: TextStyle(
                                    color: const Color(0xFFA3A3A3) /* Darker-grey */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 60,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 322,
                                height: 60,
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
                            ),
                            Positioned(
                              left: 283,
                              top: 19,
                              child: Container(
                                width: 27,
                                height: 27,
                                decoration: ShapeDecoration(
                                  color: const Color(0x49EC6725),
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFEC6725),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 291,
                              top: 27,
                              child: Container(
                                width: 12,
                                height: 12,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 16,
                              child: SizedBox(
                                width: 184,
                                height: 15,
                                child: Text(
                                  'Reserva cancelada',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 14,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.07,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 166,
                              top: 23,
                              child: SizedBox(
                                width: 86,
                                height: 15,
                                child: Text(
                                  'ver detalhes',
                                  style: TextStyle(
                                    color: const Color(0xFFEC6725) /* Orange */,
                                    fontSize: 14,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.07,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 31,
                              child: SizedBox(
                                width: 215,
                                child: Text(
                                  'Copacabana Palace',
                                  style: TextStyle(
                                    color: const Color(0xFFA3A3A3) /* Darker-grey */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
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
                left: 95,
                top: 743,
                child: Container(
                  width: 185,
                  height: 35,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 185,
                          height: 35,
                          decoration: ShapeDecoration(
                            color: const Color(0x33EC6725),
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
                        left: 50,
                        top: 10,
                        child: SizedBox(
                          width: 86,
                          height: 15,
                          child: Text(
                            'limpar ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF182541) /* Dark-Blue */,
                              fontSize: 14,
                              fontFamily: 'Stack Sans Headline',
                              fontWeight: FontWeight.w700,
                              height: 1.07,
                            ),
                          ),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFF182541) /* Dark-Blue */,
                  ),
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
                left: 313,
                top: 54,
                child: Container(
                  width: 45.79,
                  height: 45.79,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 45.79,
                          height: 45.79,
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.37),
                            shape: OvalBorder(
                              side: BorderSide(
                                width: 0.62,
                                color: Colors.white.withValues(alpha: 0.17),
                              ),
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
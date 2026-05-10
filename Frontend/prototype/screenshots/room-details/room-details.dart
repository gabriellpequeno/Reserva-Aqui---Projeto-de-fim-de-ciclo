class RoomDetais extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375,
          height: 914,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                left: -1,
                top: 801,
                child: Container(
                  width: 376,
                  height: 95,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 28,
                        top: 12,
                        child: Container(
                          width: 66.02,
                          height: 66.02,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 18,
                                top: 18,
                                child: Container(
                                  width: 32,
                                  height: 32,
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
                        left: 113,
                        top: 12,
                        child: Container(
                          width: 288,
                          height: 66,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  width: 288,
                                  height: 66,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFEC6725) /* Orange */,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 27,
                                top: 13,
                                child: Container(
                                  width: 184,
                                  height: 38,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(),
                                  child: Stack(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 1,
                child: Container(
                  width: 375,
                  height: 422,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: -6,
                        child: Container(
                          width: 376,
                          height: 374,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: NetworkImage("https://placehold.co/376x374"),
                              fit: BoxFit.fill,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(11),
                                bottomRight: Radius.circular(11),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: -1,
                        child: Container(
                          width: 375,
                          height: 89,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(0.45, -0.25),
                              end: Alignment(0.45, 0.81),
                              colors: [const Color(0xFF182541) /* Dark-Blue */, const Color(0x00182541)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 157,
                        top: 336,
                        child: Container(
                          width: 62,
                          height: 63,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: NetworkImage("https://placehold.co/62x63"),
                              fit: BoxFit.cover,
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0x00182541),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 230,
                        top: 336,
                        child: Container(
                          width: 62,
                          height: 63,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: NetworkImage("https://placehold.co/62x63"),
                              fit: BoxFit.cover,
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0x00182541),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 302,
                        top: 336,
                        child: Container(
                          width: 62,
                          height: 63,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: NetworkImage("https://placehold.co/62x63"),
                              fit: BoxFit.fill,
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0x00182541),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 375,
                        top: 336,
                        child: Container(
                          width: 62,
                          height: 63,
                          decoration: ShapeDecoration(
                            image: DecorationImage(
                              image: NetworkImage("https://placehold.co/62x63"),
                              fit: BoxFit.fill,
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0x00182541),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        top: 328,
                        child: Container(
                          width: 117,
                          height: 118,
                          child: Stack(
                            children: [
                              Positioned(
                                left: -76,
                                top: 0,
                                child: Container(
                                  width: 193,
                                  height: 81,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 11,
                                top: 17,
                                child: SizedBox(
                                  width: 93.16,
                                  height: 46.58,
                                  child: Text(
                                    '128',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: const Color(0xFFEC6725) /* Orange */,
                                      fontSize: 39,
                                      fontFamily: 'Stack Sans Headline',
                                      fontWeight: FontWeight.w700,
                                      height: 0.62,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 11,
                                top: 17,
                                child: SizedBox(
                                  width: 23.81,
                                  height: 46.58,
                                  child: Text(
                                    '\$',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: const Color(0xFFEC6725) /* Orange */,
                                      fontSize: 39,
                                      fontFamily: 'Stack Sans Headline',
                                      fontWeight: FontWeight.w700,
                                      height: 0.62,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 11,
                                top: 41,
                                child: SizedBox(
                                  width: 94,
                                  height: 23,
                                  child: Text(
                                    'por dia',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: const Color(0xFFEC6725) /* Orange */,
                                      fontSize: 14,
                                      fontFamily: 'Stack Sans Headline',
                                      fontWeight: FontWeight.w700,
                                      height: 1.71,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 17,
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
              ),
              Positioned(
                left: 0,
                top: 1,
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
                left: 13,
                top: 447,
                child: Container(width: 381, height: 53),
              ),
              Positioned(
                left: 13,
                top: 447,
                child: Container(
                  width: 577.03,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 13,
                    children: [
                      Container(
                        width: 162.34,
                        height: 44,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.14),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 92.55,
                        height: 13.66,
                        child: Text(
                          'café da manhã',
                          style: TextStyle(
                            color: const Color(0xFF182541),
                            fontSize: 12.14,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      ),
                      Container(
                        width: 34.90,
                        height: 33.38,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(),
                        child: Stack(),
                      ),
                      Container(
                        width: 162.34,
                        height: 44,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.14),
                          ),
                        ),
                      ),
                      Container(
                        width: 31.86,
                        height: 31.86,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(),
                        child: Stack(
                          children: [
                            Positioned(
                              left: -0.27,
                              top: -3.50,
                              child: Container(
                                width: 32.52,
                                height: 33.78,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 92.55,
                        height: 13.66,
                        child: Text(
                          'ar condicionado',
                          style: TextStyle(
                            color: const Color(0xFF182541),
                            fontSize: 12.14,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      ),
                      Container(
                        width: 101.66,
                        height: 44,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.14),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 21.24,
                        height: 13.66,
                        child: Text(
                          'wifi',
                          style: TextStyle(
                            color: const Color(0xFF182541),
                            fontSize: 12.14,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      ),
                      Container(
                        width: 31.86,
                        height: 30.34,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(),
                        child: Stack(),
                      ),
                      Container(
                        width: 125.93,
                        height: 44,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.14),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48.55,
                        height: 13.66,
                        child: Text(
                          '2 camas',
                          style: TextStyle(
                            color: const Color(0xFF182541),
                            fontSize: 12.14,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w400,
                            height: 1,
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 42.48,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(),
                      ),
                      Container(
                        width: 36.41,
                        height: 33.38,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(),
                        child: Stack(),
                      ),
                      Text(
                        'Comodidades',
                        style: TextStyle(
                          color: const Color(0xFF182541) /* Dark-Blue */,
                          fontSize: 13,
                          fontFamily: 'Stack Sans Headline',
                          fontWeight: FontWeight.w700,
                          height: 0.62,
                        ),
                      ),
                      Text(
                        'Detalhes',
                        style: TextStyle(
                          color: const Color(0xFF182541) /* Dark-Blue */,
                          fontSize: 13,
                          fontFamily: 'Stack Sans Headline',
                          fontWeight: FontWeight.w700,
                          height: 0.62,
                        ),
                      ),
                      SizedBox(
                        width: 318,
                        height: 75,
                        child: Text(
                          'Mussum Ipsum, cacilds vidis litro abertis. Todo mundo vê os porris que eu tomo, mas ninguém vê os tombis que eu levo! Per aumento de cachacis, eu reclamis.',
                          style: TextStyle(
                            color: const Color(0xFF182541) /* Dark-Blue */,
                            fontSize: 13,
                            fontFamily: 'Stack Sans Headline',
                            fontWeight: FontWeight.w400,
                            height: 1.15,
                          ),
                        ),
                      ),
                      Container(
                        width: 362,
                        height: 132,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 362,
                                height: 107,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: SizedBox(
                                        width: 138,
                                        height: 26,
                                        child: Text(
                                          'Grand Hotel Budapest',
                                          style: TextStyle(
                                            color: const Color(0xFF182541) /* Dark-Blue */,
                                            fontSize: 13,
                                            fontFamily: 'Stack Sans Headline',
                                            fontWeight: FontWeight.w700,
                                            height: 1.85,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 3,
                                      top: 34,
                                      child: Container(
                                        width: 99,
                                        height: 98,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFD9D9D9),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 122,
                                      top: 34,
                                      child: SizedBox(
                                        width: 222,
                                        height: 75,
                                        child: Text(
                                          'Mussum Ipsum, cacilds vidis litro abertis. Todo mundo vê os porris que eu tomo, mas ninguém vê os tombis que eu levo! Per aumento de cachacis, eu reclamis.',
                                          style: TextStyle(
                                            color: const Color(0xFF182541) /* Dark-Blue */,
                                            fontSize: 13,
                                            fontFamily: 'Stack Sans Headline',
                                            fontWeight: FontWeight.w400,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 185,
                                      top: 1,
                                      child: SizedBox(
                                        width: 24,
                                        height: 19.70,
                                        child: Text(
                                          '5.0',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: const Color(0x7F182541),
                                            fontSize: 8,
                                            fontFamily: 'Stack Sans Headline',
                                            fontWeight: FontWeight.w400,
                                            height: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 122,
                              top: 115,
                              child: SizedBox(
                                width: 78,
                                height: 17,
                                child: Text(
                                  'Saiba Mais',
                                  style: TextStyle(
                                    color: const Color(0xFFEC6725) /* Orange */,
                                    fontSize: 15,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1,
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
            ],
          ),
        ),
      ],
    );
  }
}
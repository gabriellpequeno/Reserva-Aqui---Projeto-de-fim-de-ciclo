class HotelDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375,
          height: 1721,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 417,
                child: Container(
                  width: 375,
                  height: 134,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 12,
                        top: 11,
                        child: SizedBox(
                          width: 350,
                          height: 30,
                          child: Text(
                            'Descrição',
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
                      ),
                      Positioned(
                        left: 24,
                        top: 41,
                        child: SizedBox(
                          width: 326,
                          height: 45,
                          child: Text(
                            'Mussum Ipsum, cacilds vidis litro abertis. Todo mundo vê os porris que eu tomo, mas ninguém vê os tombis que eu levo! Per aumento de cachacis, eu reclamis. ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF182541) /* Dark-Blue */,
                              fontSize: 12,
                              fontFamily: 'Stack Sans Headline',
                              fontWeight: FontWeight.w400,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 25,
                top: 417,
                child: Container(
                  width: 324,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 23,
                top: 369,
                child: SizedBox(
                  width: 329,
                  height: 26,
                  child: Text(
                    'grand Hotel budaPest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF182541) /* Dark-Blue */,
                      fontSize: 24,
                      fontFamily: 'Stack Sans Headline',
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 1,
                child: Container(
                  width: 375,
                  height: 299,
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
                        left: -231,
                        top: -6,
                        child: Container(
                          width: 678,
                          height: 381,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage("https://placehold.co/678x381"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 128,
                top: 233,
                child: Container(
                  width: 118,
                  height: 120,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: OvalBorder(),
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
                left: -2,
                top: 788,
                child: Container(
                  width: 375,
                  height: 374,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 25,
                        top: -414,
                        child: Container(
                          width: 324,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                strokeAlign: BorderSide.strokeAlignCenter,
                                color: Colors.black.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 23,
                        child: Container(
                          width: 439,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 13,
                            children: [
                              SizedBox(
                                width: 439,
                                height: 26,
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: ' quartos ',
                                        style: TextStyle(
                                          color: const Color(0xFF182541) /* Dark-Blue */,
                                          fontSize: 20,
                                          fontFamily: 'Stack Sans Headline',
                                          fontWeight: FontWeight.w700,
                                          height: 1.20,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' recomendados',
                                        style: TextStyle(
                                          color: const Color(0xFFEC6725) /* Orange */,
                                          fontSize: 20,
                                          fontFamily: 'Stack Sans Headline',
                                          fontWeight: FontWeight.w700,
                                          height: 1.20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 11,
                                children: [
                                  Container(
                                    width: 83,
                                    height: 29,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 83,
                                            height: 29,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 40,
                                          top: 10,
                                          child: SizedBox(
                                            width: 32,
                                            height: 9,
                                            child: Text(
                                              '1 Cama',
                                              style: TextStyle(
                                                color: const Color(0xFF878D9B),
                                                fontSize: 8,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w400,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 10,
                                          top: 3,
                                          child: Container(
                                            width: 24,
                                            height: 22,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Stack(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 83,
                                    height: 29,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 83,
                                            height: 29,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 40,
                                          top: 10,
                                          child: SizedBox(
                                            width: 32,
                                            height: 9,
                                            child: Text(
                                              '2 Cama',
                                              style: TextStyle(
                                                color: const Color(0xFF878D9B),
                                                fontSize: 8,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w400,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 10,
                                          top: 3,
                                          child: Container(
                                            width: 24,
                                            height: 22,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Stack(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 83,
                                    height: 29,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: Container(
                                            width: 83,
                                            height: 29,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 40,
                                          top: 10,
                                          child: SizedBox(
                                            width: 32,
                                            height: 9,
                                            child: Text(
                                              '3 Cama',
                                              style: TextStyle(
                                                color: const Color(0xFF878D9B),
                                                fontSize: 8,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w400,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 10,
                                          top: 3,
                                          child: Container(
                                            width: 24,
                                            height: 22,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Stack(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 248,
                                      height: 231,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            child: Container(
                                              width: 182.47,
                                              height: 231,
                                              decoration: ShapeDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment(0.24, 1.00),
                                                  end: Alignment(0.24, 0.55),
                                                  colors: [const Color(0xFF182541) /* Dark-Blue */, const Color(0x003D5FA7)],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(11),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 7.06,
                                            top: 175.52,
                                            child: Container(
                                              width: 168.36,
                                              height: 43.38,
                                              decoration: ShapeDecoration(
                                                color: Colors.white.withValues(alpha: 0.58),
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    width: 1,
                                                    color: Colors.white.withValues(alpha: 0),
                                                  ),
                                                  borderRadius: BorderRadius.circular(11),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 121.98,
                                            top: 162.41,
                                            child: Container(
                                              width: 39.32,
                                              height: 13.11,
                                              decoration: ShapeDecoration(
                                                color: Colors.white.withValues(alpha: 0.58),
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    width: 1,
                                                    color: Colors.white.withValues(alpha: 0),
                                                  ),
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(11),
                                                    topRight: Radius.circular(11),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 63.51,
                                            top: 183.47,
                                            child: SizedBox(
                                              width: 116.94,
                                              height: 36.31,
                                              child: Text(
                                                'copacabana\npalace',
                                                style: TextStyle(
                                                  color: const Color(0xFF182541) /* Dark-Blue */,
                                                  fontSize: 12,
                                                  fontFamily: 'Stack Sans Headline',
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.25,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 131,
                                            top: 164,
                                            child: SizedBox(
                                              width: 116.94,
                                              height: 11.10,
                                              child: Text(
                                                '5,0',
                                                style: TextStyle(
                                                  color: const Color(0x7F182541),
                                                  fontSize: 7,
                                                  fontFamily: 'Stack Sans Headline',
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.57,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 16.13,
                                            top: 184.60,
                                            child: Container(
                                              width: 15.12,
                                              height: 12.10,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Stack(),
                                            ),
                                          ),
                                          Positioned(
                                            left: 35.28,
                                            top: 184.60,
                                            child: Container(
                                              width: 12.10,
                                              height: 12.10,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Stack(),
                                            ),
                                          ),
                                          Positioned(
                                            left: 16.13,
                                            top: 196.70,
                                            child: Container(
                                              width: 15.12,
                                              height: 15.13,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Stack(),
                                            ),
                                          ),
                                          Positioned(
                                            left: 142.15,
                                            top: 162.41,
                                            child: Container(
                                              width: 13.11,
                                              height: 13.11,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Stack(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 248,
                                      height: 231,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            child: Container(
                                              width: 182.47,
                                              height: 231,
                                              decoration: ShapeDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment(0.24, 1.00),
                                                  end: Alignment(0.24, 0.55),
                                                  colors: [const Color(0xFF182541) /* Dark-Blue */, const Color(0x003D5FA7)],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(11),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 7.06,
                                            top: 175.52,
                                            child: Container(
                                              width: 168.36,
                                              height: 43.38,
                                              decoration: ShapeDecoration(
                                                color: Colors.white.withValues(alpha: 0.58),
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    width: 1,
                                                    color: Colors.white.withValues(alpha: 0),
                                                  ),
                                                  borderRadius: BorderRadius.circular(11),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 121.98,
                                            top: 162.41,
                                            child: Container(
                                              width: 39.32,
                                              height: 13.11,
                                              decoration: ShapeDecoration(
                                                color: Colors.white.withValues(alpha: 0.58),
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    width: 1,
                                                    color: Colors.white.withValues(alpha: 0),
                                                  ),
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(11),
                                                    topRight: Radius.circular(11),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 63.51,
                                            top: 183.47,
                                            child: SizedBox(
                                              width: 116.94,
                                              height: 36.31,
                                              child: Text(
                                                'copacabana\npalace',
                                                style: TextStyle(
                                                  color: const Color(0xFF182541) /* Dark-Blue */,
                                                  fontSize: 12,
                                                  fontFamily: 'Stack Sans Headline',
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.25,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 131,
                                            top: 164,
                                            child: SizedBox(
                                              width: 116.94,
                                              height: 11.10,
                                              child: Text(
                                                '5,0',
                                                style: TextStyle(
                                                  color: const Color(0x7F182541),
                                                  fontSize: 7,
                                                  fontFamily: 'Stack Sans Headline',
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.57,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 16.13,
                                            top: 184.60,
                                            child: Container(
                                              width: 15.12,
                                              height: 12.10,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Stack(),
                                            ),
                                          ),
                                          Positioned(
                                            left: 35.28,
                                            top: 184.60,
                                            child: Container(
                                              width: 12.10,
                                              height: 12.10,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Stack(),
                                            ),
                                          ),
                                          Positioned(
                                            left: 16.13,
                                            top: 196.70,
                                            child: Container(
                                              width: 15.12,
                                              height: 15.13,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Stack(),
                                            ),
                                          ),
                                          Positioned(
                                            left: 142.15,
                                            top: 162.41,
                                            child: Container(
                                              width: 13.11,
                                              height: 13.11,
                                              clipBehavior: Clip.antiAlias,
                                              decoration: BoxDecoration(),
                                              child: Stack(),
                                            ),
                                          ),
                                        ],
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
                        left: 25,
                        top: 0,
                        child: Container(
                          width: 324,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                strokeAlign: BorderSide.strokeAlignCenter,
                                color: Colors.black.withValues(alpha: 0.12),
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
                left: 0,
                top: 516,
                child: Container(
                  width: 375,
                  height: 272,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 13,
                        child: Container(
                          width: 375,
                          height: 268,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 25,
                                top: 1,
                                child: Container(
                                  width: 324,
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 1,
                                        strokeAlign: BorderSide.strokeAlignCenter,
                                        color: Colors.black.withValues(alpha: 0.12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 25,
                                top: 259,
                                child: Container(
                                  width: 324,
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 1,
                                        strokeAlign: BorderSide.strokeAlignCenter,
                                        color: Colors.black.withValues(alpha: 0.12),
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
                        left: 17,
                        top: 25,
                        child: Container(
                          width: 397,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 10,
                            children: [
                              SizedBox(
                                width: 397,
                                height: 26,
                                child: Text(
                                  'dependencias',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 20,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.20,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 13,
                                  children: [
                                    Container(
                                      width: 192,
                                      height: 185,
                                      decoration: ShapeDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage("https://placehold.co/192x185"),
                                          fit: BoxFit.cover,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 192,
                                      height: 185,
                                      decoration: ShapeDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage("https://placehold.co/192x185"),
                                          fit: BoxFit.cover,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(11),
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
              ),
              Positioned(
                left: 23,
                top: 1100,
                child: Container(
                  width: 324,
                  height: 474,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 75,
                        child: SizedBox(
                          width: 324,
                          height: 26,
                          child: Text(
                            'Avaliações',
                            style: TextStyle(
                              color: const Color(0xFF182541) /* Dark-Blue */,
                              fontSize: 20,
                              fontFamily: 'Stack Sans Headline',
                              fontWeight: FontWeight.w700,
                              height: 1.20,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 144,
                        top: 111,
                        child: SizedBox(
                          width: 36,
                          height: 21,
                          child: Text(
                            '4.0',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFEC6725) /* Orange */,
                              fontSize: 24,
                              fontFamily: 'Stack Sans Headline',
                              fontWeight: FontWeight.w200,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 136,
                        child: Container(
                          width: 324,
                          height: 464,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 15,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 4,
                                children: [
                                ,
                                ],
                              ),
                              SizedBox(
                                width: 264,
                                height: 67,
                                child: Text(
                                  'Mussum Ipsum, cacilds vidis litro abertis. Todo mundo vê os porris que eu tomo, mas ninguém vê os tombis que eu levo! Per aumento de cachacis, eu reclamis. ',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 73,
                                height: 12,
                                child: Text(
                                  '14 dias atrás',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: const Color(0xFFA3A3A3) /* Darker-grey */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 117,
                                height: 15,
                                child: Text(
                                  'Fulana da Silva',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              Container(
                                width: 46,
                                height: 45,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  shape: OvalBorder(),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 2,
                                children: [
                                ,
                                ],
                              ),
                              Container(
                                width: double.infinity,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      strokeAlign: BorderSide.strokeAlignCenter,
                                      color: Colors.black.withValues(alpha: 0.12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 264,
                                height: 67,
                                child: Text(
                                  'Mussum Ipsum, cacilds vidis litro abertis. Todo mundo vê os porris que eu tomo, mas ninguém vê os tombis que eu levo! Per aumento de cachacis, eu reclamis. ',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 85,
                                height: 12,
                                child: Text(
                                  ' 5 meses atrás',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: const Color(0xFFA3A3A3) /* Darker-grey */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 117,
                                height: 15,
                                child: Text(
                                  'Cicrano Gomes',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              Container(
                                width: 46,
                                height: 45,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  shape: OvalBorder(),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 2,
                                children: [
                                ,
                                ],
                              ),
                              Container(
                                width: double.infinity,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      strokeAlign: BorderSide.strokeAlignCenter,
                                      color: Colors.black.withValues(alpha: 0.12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 264,
                                height: 67,
                                child: Text(
                                  'Mussum Ipsum, cacilds vidis litro abertis. Todo mundo vê os porris que eu tomo, mas ninguém vê os tombis que eu levo! Per aumento de cachacis, eu reclamis. ',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 142,
                                height: 15,
                                child: Text(
                                  'Diogenes Lourisvaldo',
                                  style: TextStyle(
                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 85,
                                height: 12,
                                child: Text(
                                  ' 1 ano atrás',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: const Color(0xFFA3A3A3) /* Darker-grey */,
                                    fontSize: 12,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              Container(
                                width: 46,
                                height: 45,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  shape: OvalBorder(),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 2,
                                children: [
                                ,
                                ],
                              ),
                              SizedBox(
                                width: 324,
                                child: Text(
                                  'Ver Mais',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFEC6725) /* Orange */,
                                    fontSize: 15,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 2,
                        top: 60,
                        child: Container(
                          width: 324,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                strokeAlign: BorderSide.strokeAlignCenter,
                                color: Colors.black.withValues(alpha: 0.12),
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
      ],
    );
  }
}
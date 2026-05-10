class Search extends StatelessWidget {
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
                left: 13,
                top: 271,
                child: Container(
                  width: 349,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: Colors.white /* ✦-_bg-bg-default */,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 224,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 349,
                                height: 224,
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
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 161,
                                height: 224,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -84,
                              top: 0,
                              child: Container(
                                width: 332,
                                height: 224,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage("https://placehold.co/332x224"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 161,
                                height: 224,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -84,
                              top: 0,
                              child: Container(
                                width: 332,
                                height: 224,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage("https://placehold.co/332x224"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 174,
                              top: 17,
                              child: Container(
                                width: 160,
                                height: 189.02,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 8,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 132,
                                          height: 50,
                                          child: Text(
                                            'grand Hotel\nBudapest',
                                            style: TextStyle(
                                              color: const Color(0xFF182541) /* Dark-Blue */,
                                              fontSize: 20,
                                              fontFamily: 'Stack Sans Headline',
                                              fontWeight: FontWeight.w700,
                                              height: 1.20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 107,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 5,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            spacing: 4,
                                            children: [
                                              Container(
                                                width: 56.98,
                                                height: 25.02,
                                                decoration: ShapeDecoration(
                                                  color: const Color(0xFFF5F5F5),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 20,
                                                height: 8,
                                                child: Text(
                                                  'wifi',
                                                  style: TextStyle(
                                                    color: const Color(0x7F182541),
                                                    fontSize: 8,
                                                    fontFamily: 'Stack Sans Headline',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 17.86,
                                                height: 17.25,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 70.59,
                                                height: 25.02,
                                                decoration: ShapeDecoration(
                                                  color: const Color(0xFFF5F5F5),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 43,
                                                height: 7,
                                                child: Text(
                                                  '2 camas',
                                                  style: TextStyle(
                                                    color: const Color(0x7F182541),
                                                    fontSize: 8,
                                                    fontFamily: 'Stack Sans Headline',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 24.66,
                                                height: 24.15,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                              ),
                                              Container(
                                                width: 20.41,
                                                height: 18.98,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            width: 101,
                                            height: 25,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 67,
                                            height: 7,
                                            child: Text(
                                              'café da manhã',
                                              style: TextStyle(
                                                color: const Color(0x7F182541),
                                                fontSize: 8,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w700,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 19.56,
                                            height: 18.98,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Stack(),
                                          ),
                                          Container(
                                            width: 101,
                                            height: 25,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          Container(
                                            width: 17.86,
                                            height: 18.11,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  left: -0.15,
                                                  top: -1.99,
                                                  child: Container(
                                                    width: 18.23,
                                                    height: 19.20,
                                                    clipBehavior: Clip.antiAlias,
                                                    decoration: BoxDecoration(),
                                                    child: Stack(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 76,
                                            height: 7,
                                            child: Text(
                                              'ar condicionado',
                                              style: TextStyle(
                                                color: const Color(0x7F182541),
                                                fontSize: 8,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w700,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        spacing: 5,
                                        children: [
                                          Container(
                                            width: 160,
                                            height: 38,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFF182541),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(11),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 116,
                                            height: 24,
                                            child: Text(
                                              'ver mais',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: const Color(0xFFFFFAF8),
                                                fontSize: 14,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w700,
                                                height: 1.71,
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
                      Container(
                        width: double.infinity,
                        height: 224,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 349,
                                height: 224,
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
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 161,
                                height: 224,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -84,
                              top: 0,
                              child: Container(
                                width: 332,
                                height: 224,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage("https://placehold.co/332x224"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 161,
                                height: 224,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -84,
                              top: 0,
                              child: Container(
                                width: 332,
                                height: 224,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage("https://placehold.co/332x224"),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 174,
                              top: 17,
                              child: Container(
                                width: 160,
                                height: 189.02,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 8,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 132,
                                          height: 50,
                                          child: Text(
                                            'grand Hotel\nBudapest',
                                            style: TextStyle(
                                              color: const Color(0xFF182541) /* Dark-Blue */,
                                              fontSize: 20,
                                              fontFamily: 'Stack Sans Headline',
                                              fontWeight: FontWeight.w700,
                                              height: 1.20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 107,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 5,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            spacing: 4,
                                            children: [
                                              Container(
                                                width: 56.98,
                                                height: 25.02,
                                                decoration: ShapeDecoration(
                                                  color: const Color(0xFFF5F5F5),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 20,
                                                height: 8,
                                                child: Text(
                                                  'wifi',
                                                  style: TextStyle(
                                                    color: const Color(0x7F182541),
                                                    fontSize: 8,
                                                    fontFamily: 'Stack Sans Headline',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 17.86,
                                                height: 17.25,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                              Container(
                                                width: 70.59,
                                                height: 25.02,
                                                decoration: ShapeDecoration(
                                                  color: const Color(0xFFF5F5F5),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 43,
                                                height: 7,
                                                child: Text(
                                                  '2 camas',
                                                  style: TextStyle(
                                                    color: const Color(0x7F182541),
                                                    fontSize: 8,
                                                    fontFamily: 'Stack Sans Headline',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 24.66,
                                                height: 24.15,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                              ),
                                              Container(
                                                width: 20.41,
                                                height: 18.98,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            width: 101,
                                            height: 25,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 67,
                                            height: 7,
                                            child: Text(
                                              'café da manhã',
                                              style: TextStyle(
                                                color: const Color(0x7F182541),
                                                fontSize: 8,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w700,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 19.56,
                                            height: 18.98,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Stack(),
                                          ),
                                          Container(
                                            width: 101,
                                            height: 25,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          Container(
                                            width: 17.86,
                                            height: 18.11,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  left: -0.15,
                                                  top: -1.99,
                                                  child: Container(
                                                    width: 18.23,
                                                    height: 19.20,
                                                    clipBehavior: Clip.antiAlias,
                                                    decoration: BoxDecoration(),
                                                    child: Stack(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 76,
                                            height: 7,
                                            child: Text(
                                              'ar condicionado',
                                              style: TextStyle(
                                                color: const Color(0x7F182541),
                                                fontSize: 8,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w700,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        spacing: 5,
                                        children: [
                                          Container(
                                            width: 160,
                                            height: 38,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFF182541),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(11),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 116,
                                            height: 24,
                                            child: Text(
                                              'ver mais',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: const Color(0xFFFFFAF8),
                                                fontSize: 14,
                                                fontFamily: 'Stack Sans Headline',
                                                fontWeight: FontWeight.w700,
                                                height: 1.71,
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
                  ),
                ),
              ),
              Positioned(
                left: -8,
                top: 713,
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
                        left: 36,
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
                        left: 319,
                        top: 35.50,
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
                        top: 15,
                        child: Container(
                          width: 24,
                          height: 24,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
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
                        left: 36,
                        top: 67,
                        child: SizedBox(
                          width: 46,
                          height: 23,
                          child: Text(
                            'buscar',
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
                        left: 228,
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
                        top: 109,
                        child: SizedBox(
                          width: 70,
                          height: 23,
                          child: Opacity(
                            opacity: 0,
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
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: -1,
                top: 78,
                child: Container(
                  width: 375,
                  height: 195,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 155,
                        top: 84,
                        child: Container(
                          width: 206,
                          height: 40,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF5F5F5) /* ✦-_bg-bg-secondary */,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0x3F182541),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 41,
                                top: 0,
                                child: SizedBox(
                                  width: 324,
                                  height: 26,
                                  child: Text(
                                    'Data',
                                    style: TextStyle(
                                      color: const Color(0x7F182541),
                                      fontSize: 13,
                                      fontFamily: 'Stack Sans Headline',
                                      fontWeight: FontWeight.w700,
                                      height: 1.85,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 41,
                                top: 15,
                                child: SizedBox(
                                  width: 126,
                                  height: 26,
                                  child: Text(
                                    '14/04/26 - 15/04/26',
                                    style: TextStyle(
                                      color: const Color(0x3F182541),
                                      fontSize: 13,
                                      fontFamily: 'Stack Sans Headline',
                                      fontWeight: FontWeight.w400,
                                      height: 1.85,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 9,
                                top: 8,
                                child: Container(
                                  width: 23,
                                  height: 23,
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
                        left: 18,
                        top: 84,
                        child: Container(
                          width: 133,
                          height: 40,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF5F5F5) /* ✦-_bg-bg-secondary */,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: const Color(0x3F182541),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 35,
                                top: 8,
                                child: SizedBox(
                                  width: 324,
                                  height: 26,
                                  child: Text(
                                    'hospedes',
                                    style: TextStyle(
                                      color: const Color(0x7F182541),
                                      fontSize: 13,
                                      fontFamily: 'Stack Sans Headline',
                                      fontWeight: FontWeight.w700,
                                      height: 1.85,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 11,
                                top: 10,
                                child: Container(
                                  width: 16.95,
                                  height: 21.02,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage("https://placehold.co/17x21"),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 11,
                                top: -2.28,
                                child: Container(
                                  width: 16.95,
                                  height: 69.02,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEC6725) /* Orange */,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 134,
                        child: Container(
                          width: 343,
                          height: 35,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  width: 343,
                                  height: 35,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF172540),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 115,
                                top: 6,
                                child: SizedBox(
                                  width: 112,
                                  height: 24,
                                  child: Text(
                                    'Buscar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: 'Stack Sans Headline',
                                      fontWeight: FontWeight.w700,
                                      height: 1.60,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 34,
                        child: Container(
                          width: 343,
                          height: 40,
                          child: Stack(
                            children: [
                              Positioned(
                                left: -10,
                                top: -10,
                                child: Container(
                                  width: 363,
                                  height: 417,
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: 10,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 40,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFF5F5F5) /* ✦-_bg-bg-secondary */,
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(0x3F182541),
                                            ),
                                            borderRadius: BorderRadius.circular(11),
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 41,
                                              top: 9,
                                              child: SizedBox(
                                                width: 324,
                                                height: 26,
                                                child: Text(
                                                  'para onde você vai?',
                                                  style: TextStyle(
                                                    color: const Color(0x7F182541),
                                                    fontSize: 15,
                                                    fontFamily: 'Stack Sans Headline',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.60,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 8,
                                              top: 7,
                                              child: Container(
                                                width: 28,
                                                height: 28,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 25,
                        top: 195,
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
                left: 108,
                top: 61,
                child: Container(
                  width: 159,
                  height: 33,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 108,
                top: 61,
                child: Container(
                  width: 159,
                  height: 33,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 312,
                top: 53,
                child: Container(
                  width: 47.62,
                  height: 47.62,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 47.62,
                          height: 47.62,
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.37),
                            shape: OvalBorder(
                              side: BorderSide(
                                width: 0.64,
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
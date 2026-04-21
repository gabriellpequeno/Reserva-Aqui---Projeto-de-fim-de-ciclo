class Navbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 430,
          height: 802.50,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: const Color(0xFF8A38F5)),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 683,
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
              Positioned(
                left: 20,
                top: 520,
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
                        left: 238,
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
                        top: 39,
                        child: Container(
                          width: 24,
                          height: 22.98,
                          child: Stack(),
                        ),
                      ),
                      Positioned(
                        left: 251,
                        top: 16,
                        child: Container(width: 20, height: 20, child: Stack()),
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
                        left: 220,
                        top: 69,
                        child: SizedBox(
                          width: 82,
                          height: 23,
                          child: Text(
                            'mensagens',
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
                left: 20,
                top: 353,
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
                        left: 172,
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
                        left: 172,
                        top: 68,
                        child: SizedBox(
                          width: 46,
                          height: 23,
                          child: Text(
                            'início',
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
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 186,
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
                        left: 102,
                        top: 4,
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
                        left: 113,
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
                        left: 95,
                        top: 68,
                        child: SizedBox(
                          width: 60,
                          height: 23,
                          child: Text(
                            'curtidas',
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
                left: 20,
                top: 20,
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
            ],
          ),
        ),
      ],
    );
  }
}

class Login extends StatelessWidget {
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
                left: -3.50,
                top: 223,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 19,
                    children: [
                      SizedBox(
                        width: 324,
                        height: 26,
                        child: Text(
                          'Acesse agora',
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
                        width: 327,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 16,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    color: const Color(0xFFDFDFDF),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 16,
                                children: [
                                  SizedBox(
                                    width: 295,
                                    child: Text(
                                      'email@domain.com',
                                      style: TextStyle(
                                        color: const Color(0xFF828282),
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                        height: 1.40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    color: const Color(0xFFDFDFDF),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 16,
                                children: [
                                  SizedBox(
                                    width: 295,
                                    child: Text(
                                      'senha',
                                      style: TextStyle(
                                        color: const Color(0xFF828282),
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                        height: 1.40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFEC6725) /* Orange */,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      color: const Color(0xFF182541) /* Dark-Blue */,
                                      fontSize: 14,
                                      fontFamily: 'Stack Sans Text',
                                      fontWeight: FontWeight.w700,
                                      height: 1.40,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 327,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 8,
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(color: const Color(0xFFE6E6E6)),
                              ),
                            ),
                            Text(
                              'or',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF828282),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.40,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(color: const Color(0xFFE6E6E6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Container(
                            width: 164,
                            height: 52,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFEEEEEE),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 10.50,
                                  top: 12,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Stack(),
                                      ),
                                      SizedBox(
                                        width: 107,
                                        height: 16,
                                        child: Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            height: 1.10,
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
                            width: 162,
                            height: 52,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFEEEEEE),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 9.50,
                                  top: 8,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage("https://placehold.co/36x36"),
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 99,
                                        child: Text(
                                          'Continue with Apple',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            height: 1.10,
                                          ),
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
                      Container(
                        width: double.infinity,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF182541) /* Dark-Blue */,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              'cadastre-se agora',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Stack Sans Text',
                                fontWeight: FontWeight.w700,
                                height: 1.40,
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
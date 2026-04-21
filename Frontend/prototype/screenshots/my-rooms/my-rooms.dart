class MyRooms extends StatelessWidget {
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
                top: -46,
                child: Container(
                  width: 375,
                  height: 233,
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
                left: 33,
                top: 105,
                child: SizedBox(
                  width: 309,
                  height: 29.41,
                  child: Text(
                    'Meus Quartos',
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
                left: 13,
                top: 204,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 9,
                  children: [
                    Container(
                      width: 349,
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
                                      Container(
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
                                      Container(
                                        width: 12,
                                        height: 12,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Stack(),
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
                                          width: 160,
                                          height: 24,
                                          child: Text(
                                            'ver mais',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
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
              Positioned(
                left: 13,
                top: 444,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 9,
                  children: [
                    Container(
                      width: 349,
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
                                      Container(
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
                                      Container(
                                        width: 12,
                                        height: 12,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Stack(),
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
                                          width: 160,
                                          height: 24,
                                          child: Text(
                                            'ver mais',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
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
              Positioned(
                left: 13,
                top: 684,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 9,
                  children: [
                    Container(
                      width: 349,
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
                                      Container(
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
                                      Container(
                                        width: 12,
                                        height: 12,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Stack(),
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
                                          width: 160,
                                          height: 24,
                                          child: Text(
                                            'ver mais',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
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
              Positioned(
                left: 24,
                top: 139,
                child: Container(
                  width: 335,
                  height: 36,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 326,
                top: 145,
                child: Container(
                  width: 24,
                  height: 24,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 106,
                top: 749,
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
                            color: const Color(0x68EC6725),
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
                            'adicionar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF182541),
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
              Positioned(
                left: 21,
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
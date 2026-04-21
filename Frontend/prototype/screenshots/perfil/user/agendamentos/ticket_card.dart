class TicketCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 391,
          height: 961,
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
                top: 20,
                child: Container(
                  width: 335,
                  height: 168,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 335,
                          height: 168,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 236,
                                top: 1,
                                child: Container(
                                  width: 99,
                                  height: 159,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD9D9D9),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 159,
                                top: 1,
                                child: Container(
                                  width: 237.65,
                                  height: 160.60,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "https://placehold.co/238x161",
                                      ),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 26,
                                top: 12,
                                child: Container(
                                  width: 194.70,
                                  height: 137,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 4,
                                    children: [
                                      SizedBox(
                                        width: 132,
                                        height: 50,
                                        child: Text(
                                          'grand Hotel\nBudapest',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFF182541,
                                            ) /* Dark-Blue */,
                                            fontSize: 20,
                                            fontFamily: 'Stack Sans Headline',
                                            fontWeight: FontWeight.w700,
                                            height: 1.20,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 118,
                                        height: 25,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(
                                                0xFFEC6725,
                                              ) /* Orange */,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 96,
                                        child: Text(
                                          'em breve',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFFEC6725,
                                            ) /* Orange */,
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            height: 1.40,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 16,
                                        height: 16,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Stack(),
                                      ),
                                      Container(
                                        width: 120,
                                        height: 25,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(
                                                0xFFEC6725,
                                              ) /* Orange */,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 86,
                                        child: Text(
                                          '10/set - 15/set',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFFEC6725,
                                            ) /* Orange */,
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            height: 1.40,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 19,
                                        height: 19,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Stack(),
                                      ),
                                      Container(
                                        width: 165,
                                        height: 25.02,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(
                                                0xFFEC6725,
                                              ) /* Orange */,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 135,
                                        child: Text(
                                          'Rua dos Bobos, nº 0',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFFEC6725,
                                            ) /* Orange */,
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            height: 1.40,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 13,
                                        height: 15,
                                        child: Stack(),
                                      ),
                                    ],
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
                left: 20,
                top: 202,
                child: Container(
                  width: 335,
                  height: 168,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 236,
                        top: 1,
                        child: Container(
                          width: 99,
                          height: 159,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 159,
                        top: 1,
                        child: Container(
                          width: 237.65,
                          height: 160.60,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                "https://placehold.co/238x161",
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        top: 12,
                        child: Container(
                          width: 194.70,
                          height: 137,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              SizedBox(
                                width: 132,
                                height: 50,
                                child: Text(
                                  'grand Hotel\nBudapest',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF182541,
                                    ) /* Dark-Blue */,
                                    fontSize: 20,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.20,
                                  ),
                                ),
                              ),
                              Container(
                                width: 118,
                                height: 25,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(
                                        0xFF182541,
                                      ) /* Dark-Blue */,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 96,
                                child: Text(
                                  'em andamento',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF182541,
                                    ) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                              Container(
                                width: 120,
                                height: 25,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(
                                        0xFF182541,
                                      ) /* Dark-Blue */,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 86,
                                child: Text(
                                  '10/set - 15/set',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF182541,
                                    ) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(
                                width: 19,
                                height: 19,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                              Container(
                                width: 165,
                                height: 25.02,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(
                                        0xFF182541,
                                      ) /* Dark-Blue */,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 135,
                                child: Text(
                                  'Rua dos Bobos, nº 0',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF182541,
                                    ) /* Dark-Blue */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(width: 13, height: 15, child: Stack()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 396,
                child: Container(
                  width: 335,
                  height: 168,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 236,
                        top: 0,
                        child: Container(
                          width: 99,
                          height: 159,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 159,
                        top: 0,
                        child: Container(
                          width: 237.65,
                          height: 160.60,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                "https://placehold.co/238x161",
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        top: 11,
                        child: Container(
                          width: 194.70,
                          height: 137,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              SizedBox(
                                width: 132,
                                height: 50,
                                child: Text(
                                  'grand Hotel\nBudapest',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF182541,
                                    ) /* Dark-Blue */,
                                    fontSize: 20,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.20,
                                  ),
                                ),
                              ),
                              Container(
                                width: 100,
                                height: 25,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(
                                        0xFF16A026,
                                      ) /* check-creen */,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 96,
                                child: Text(
                                  'Hospedado',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF16A026,
                                    ) /* check-creen */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                              Container(
                                width: 120,
                                height: 25,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(
                                        0xFF16A026,
                                      ) /* check-creen */,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 86,
                                child: Text(
                                  '10/set - 15/set',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF16A026,
                                    ) /* check-creen */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(
                                width: 19,
                                height: 19,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                              Container(
                                width: 165,
                                height: 25.02,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(
                                        0xFF16A026,
                                      ) /* check-creen */,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 135,
                                child: Text(
                                  'Rua dos Bobos, nº 0',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF16A026,
                                    ) /* check-creen */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(width: 13, height: 15, child: Stack()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 584,
                child: Container(
                  width: 335,
                  height: 168,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 236,
                        top: 4,
                        child: Container(
                          width: 99,
                          height: 159,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 159,
                        top: 4,
                        child: Container(
                          width: 237.65,
                          height: 160.60,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                "https://placehold.co/238x161",
                              ),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        top: 15,
                        child: Container(
                          width: 194.70,
                          height: 137,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              SizedBox(
                                width: 132,
                                height: 50,
                                child: Text(
                                  'grand Hotel\nBudapest',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF182541,
                                    ) /* Dark-Blue */,
                                    fontSize: 20,
                                    fontFamily: 'Stack Sans Headline',
                                    fontWeight: FontWeight.w700,
                                    height: 1.20,
                                  ),
                                ),
                              ),
                              Container(
                                width: 93,
                                height: 25,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFEF2828),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 96,
                                child: Text(
                                  'Cancelado',
                                  style: TextStyle(
                                    color: const Color(0xFFEF2828),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                              Container(
                                width: 120,
                                height: 25,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFEF2828),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 86,
                                child: Text(
                                  '10/set - 15/set',
                                  style: TextStyle(
                                    color: const Color(0xFFEF2828),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(
                                width: 19,
                                height: 19,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                              Container(
                                width: 165,
                                height: 25.02,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: const Color(0xFFEF2828),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 135,
                                child: Text(
                                  'Rua dos Bobos, nº 0',
                                  style: TextStyle(
                                    color: const Color(0xFFEF2828),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                  ),
                                ),
                              ),
                              Container(width: 13, height: 15, child: Stack()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 773,
                child: Container(
                  width: 335,
                  height: 168,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 335,
                          height: 168,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 236,
                                top: 1,
                                child: Container(
                                  width: 99,
                                  height: 159,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD9D9D9),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 159,
                                top: 1,
                                child: Container(
                                  width: 237.65,
                                  height: 160.60,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "https://placehold.co/238x161",
                                      ),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 26,
                                top: 12,
                                child: Container(
                                  width: 194.70,
                                  height: 137,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 4,
                                    children: [
                                      SizedBox(
                                        width: 132,
                                        height: 50,
                                        child: Text(
                                          'grand Hotel\nBudapest',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFF182541,
                                            ) /* Dark-Blue */,
                                            fontSize: 20,
                                            fontFamily: 'Stack Sans Headline',
                                            fontWeight: FontWeight.w700,
                                            height: 1.20,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 118,
                                        height: 25,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(
                                                0xFF182541,
                                              ) /* Dark-Blue */,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 96,
                                        child: Text(
                                          'finalizado',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFF182541,
                                            ) /* Dark-Blue */,
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            height: 1.40,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 16,
                                        height: 16,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Stack(),
                                      ),
                                      Container(
                                        width: 120,
                                        height: 25,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(
                                                0xFF182541,
                                              ) /* Dark-Blue */,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 86,
                                        child: Text(
                                          '10/set - 15/set',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFF182541,
                                            ) /* Dark-Blue */,
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            height: 1.40,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 19,
                                        height: 19,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(),
                                        child: Stack(),
                                      ),
                                      Container(
                                        width: 165,
                                        height: 25.02,
                                        decoration: ShapeDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: const Color(
                                                0xFF182541,
                                              ) /* Dark-Blue */,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 135,
                                        child: Text(
                                          'Rua dos Bobos, nº 0',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFF182541,
                                            ) /* Dark-Blue */,
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            height: 1.40,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 13,
                                        height: 15,
                                        child: Stack(),
                                      ),
                                    ],
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
            ],
          ),
        ),
      ],
    );
  }
}

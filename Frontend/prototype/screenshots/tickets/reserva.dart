class TicketDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375,
          height: 812,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9) /* Grey */,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 18,
                top: 658,
                child: Container(
                  width: 340,
                  height: 192,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 17,
                top: 658,
                child: Container(
                  width: 343,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                        'R\$190.98',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: const Color(0xFF182541),
                          fontSize: 12,
                          fontFamily: 'Stack Sans Text',
                          fontWeight: FontWeight.w400,
                          height: 1.40,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Subtotal',
                          style: TextStyle(
                            color: const Color(0xFF182541),
                            fontSize: 12,
                            fontFamily: 'Stack Sans Text',
                            fontWeight: FontWeight.w700,
                            height: 1.40,
                          ),
                        ),
                      ),
                      Text(
                        '-R\$20.00',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: const Color(0xFF182541),
                          fontSize: 12,
                          fontFamily: 'Stack Sans Text',
                          fontWeight: FontWeight.w400,
                          height: 1.40,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Descontos',
                          style: TextStyle(
                            color: const Color(0xFF182541),
                            fontSize: 12,
                            fontFamily: 'Stack Sans Text',
                            fontWeight: FontWeight.w700,
                            height: 1.40,
                          ),
                        ),
                      ),
                      Text(
                        'R\$19.00',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: const Color(0xFF182541),
                          fontSize: 12,
                          fontFamily: 'Stack Sans Text',
                          fontWeight: FontWeight.w400,
                          height: 1.40,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Taxas',
                          style: TextStyle(
                            color: const Color(0xFF182541),
                            fontSize: 12,
                            fontFamily: 'Stack Sans Text',
                            fontWeight: FontWeight.w700,
                            height: 1.40,
                          ),
                        ),
                      ),
                      Text(
                        'R\$189.98',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: const Color(0xFFEC6725) /* Orange */,
                          fontSize: 12,
                          fontFamily: 'Stack Sans Text',
                          fontWeight: FontWeight.w700,
                          height: 1.40,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Total',
                          style: TextStyle(
                            color: const Color(0xFFEC6725) /* Orange */,
                            fontSize: 12,
                            fontFamily: 'Stack Sans Text',
                            fontWeight: FontWeight.w700,
                            height: 1.40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 160,
                child: Container(
                  height: 477,
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Container(
                        width: 340,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Expanded(
                              child: Container(
                                height: 82,
                                padding: const EdgeInsets.all(16),
                                clipBehavior: Clip.antiAlias,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 0.50,
                                      color: const Color(0xFFE6E6E6) /* ✦-_border-border-default */,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 12,
                                  children: [
                                    SizedBox(
                                      width: 308,
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Rua dos Bobos, nº 0\n',
                                              style: TextStyle(
                                                color: const Color(0xFF182541),
                                                fontSize: 12,
                                                fontFamily: 'Stack Sans Text',
                                                fontWeight: FontWeight.w700,
                                                height: 1.67,
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'Check-in: 10/11/2026, segunda-feira\nCheck-out: 11/11/2026, terça-feira',
                                              style: TextStyle(
                                                color: const Color(0xFF182541),
                                                fontSize: 12,
                                                fontFamily: 'Stack Sans Text',
                                                fontWeight: FontWeight.w300,
                                                height: 1.67,
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
                      Container(
                        width: 340,
                        height: 381,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 72,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 0.50,
                                    color: const Color(0xFFE6E6E6) /* ✦-_border-border-default */,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: 80,
                                    children: [
                                      SizedBox(
                                        width: 113,
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Chegada\n',
                                                style: TextStyle(
                                                  color: const Color(0xFF182541),
                                                  fontSize: 12,
                                                  fontFamily: 'Stack Sans Text',
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.67,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '13:00',
                                                style: TextStyle(
                                                  color: const Color(0xFF182541),
                                                  fontSize: 12,
                                                  fontFamily: 'Stack Sans Text',
                                                  fontWeight: FontWeight.w300,
                                                  height: 1.67,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 111,
                                        height: 44,
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          runAlignment: WrapAlignment.start,
                                          spacing: -1,
                                          runSpacing: 0,
                                          children: [
                                            SizedBox(
                                              width: 111,
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'S',
                                                      style: TextStyle(
                                                        color: const Color(0xFF182541),
                                                        fontSize: 12,
                                                        fontFamily: 'Stack Sans Text',
                                                        fontWeight: FontWeight.w700,
                                                        height: 1.40,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: 'aída\n',
                                                      style: TextStyle(
                                                        color: const Color(0xFF182541),
                                                        fontSize: 12,
                                                        fontFamily: 'Stack Sans Text',
                                                        fontWeight: FontWeight.w700,
                                                        height: 1.67,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '19:00',
                                                      style: TextStyle(
                                                        color: const Color(0xFF182541),
                                                        fontSize: 12,
                                                        fontFamily: 'Stack Sans Text',
                                                        fontWeight: FontWeight.w300,
                                                        height: 1.67,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              height: 72,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 0.50,
                                    color: const Color(0xFFE6E6E6) /* ✦-_border-border-default */,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 10,
                                children: [
                                  Container(
                                    width: 309,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      spacing: 80,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Ticket ID\n',
                                                  style: TextStyle(
                                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                                    fontSize: 12,
                                                    fontFamily: 'Stack Sans Text',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.67,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '000000000',
                                                  style: TextStyle(
                                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                                    fontSize: 12,
                                                    fontFamily: 'Stack Sans Text',
                                                    fontWeight: FontWeight.w300,
                                                    height: 1.67,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 129,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 129,
                                                child: Text(
                                                  'Status',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    color: const Color(0xFF182541) /* Dark-Blue */,
                                                    fontSize: 12,
                                                    fontFamily: 'Stack Sans Text',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.40,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 129,
                                                child: Text(
                                                  '  Em Breve',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    color: const Color(0xFFEC6725) /* Orange */,
                                                    fontSize: 12,
                                                    fontFamily: 'Stack Sans Text',
                                                    fontWeight: FontWeight.w300,
                                                    height: 1.67,
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
                            ),
                            Container(
                              width: double.infinity,
                              height: 72,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              clipBehavior: Clip.antiAlias,
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 0.50,
                                    color: const Color(0xFFD9D9D9) /* Grey */,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 80,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Hospedes\n',
                                            style: TextStyle(
                                              color: const Color(0xFF182541) /* Dark-Blue */,
                                              fontSize: 12,
                                              fontFamily: 'Stack Sans Text',
                                              fontWeight: FontWeight.w700,
                                              height: 1.67,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '3 adultos',
                                            style: TextStyle(
                                              color: const Color(0xFF182541) /* Dark-Blue */,
                                              fontSize: 12,
                                              fontFamily: 'Stack Sans Text',
                                              fontWeight: FontWeight.w400,
                                              height: 1.67,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 129,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 129,
                                          child: Text(
                                            'Quarto',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              color: const Color(0xFF182541),
                                              fontSize: 12,
                                              fontFamily: 'Stack Sans Text',
                                              fontWeight: FontWeight.w700,
                                              height: 1.40,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 129,
                                          child: Text(
                                            'Standard ',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              color: const Color(0xFF182541),
                                              fontSize: 12,
                                              fontFamily: 'Stack Sans Text',
                                              fontWeight: FontWeight.w300,
                                              height: 1.67,
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
                              width: double.infinity,
                              height: 159,
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 10,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Detalhes',
                                      style: TextStyle(
                                        color: const Color(0xFF182541),
                                        fontSize: 12,
                                        fontFamily: 'Stack Sans Text',
                                        fontWeight: FontWeight.w700,
                                        height: 1.67,
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
                ),
              ),
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
              Positioned(
                left: 0,
                top: -74,
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
                  child: Stack(
                    children: [
                      Positioned(
                        left: 25,
                        top: 184,
                        child: SizedBox(
                          width: 324,
                          height: 26,
                          child: Text(
                            'Reserva ',
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
                        top: 80,
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
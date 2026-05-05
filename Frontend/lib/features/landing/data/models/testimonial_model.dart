class TestimonialModel {
  final String id;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final double rating;
  final String? hotelName;

  const TestimonialModel({
    required this.id,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.rating,
    this.hotelName,
  });
}

const List<TestimonialModel> mockTestimonials = [
  TestimonialModel(
    id: '1',
    userName: 'Ana Souza',
    userPhotoUrl: null,
    text: 'Nunca imaginei que reservar uma hospedagem pudesse ser tão fácil. O quarto estava impecável, a vista era de tirar o fôlego e o atendimento nos recebeu como se fossemos família. Já estou planejando a próxima viagem pelo Reserva Aqui!',
    rating: 5.0,
    hotelName: 'Grand Palace Hotel',
  ),
  TestimonialModel(
    id: '2',
    userName: 'Carlos Mendes',
    userPhotoUrl: null,
    text: 'Fiz a reserva em menos de 2 minutos direto pelo app. O quarto superou todas as expectativas — cama king, vista para o mar e café da manhã incluso. O processo de check-in foi igualmente simples. Definitivamente minha plataforma favorita de hospedagem.',
    rating: 4.5,
    hotelName: 'Pousada Vista Mar',
  ),
  TestimonialModel(
    id: '3',
    userName: 'Juliana Ferreira',
    userPhotoUrl: null,
    text: 'O assistente Bene me ajudou a escolher o hotel ideal pelo WhatsApp em poucos minutos. Fiz perguntas, pedi sugestões e ele até me avisou sobre a promoção de última hora. Serviço completamente diferenciado — tecnologia que realmente facilita a vida!',
    rating: 5.0,
    hotelName: 'Hotel Montanha Azul',
  ),
  TestimonialModel(
    id: '4',
    userName: 'Roberto Lima',
    userPhotoUrl: null,
    text: 'Localização perfeita, wifi excelente e piscina incrível. Com certeza o melhor custo-benefício que já tive.',
    rating: 4.0,
    hotelName: 'Chalé dos Lagos',
  ),
  TestimonialModel(
    id: '5',
    userName: 'Mariana Costa',
    userPhotoUrl: null,
    text: 'Fiz a reserva via app e tudo correu perfeitamente. A criatividade na decoração do quarto é única!',
    rating: 5.0,
    hotelName: 'Boutique Inn Centro',
  ),
  TestimonialModel(
    id: '6',
    userName: 'Felipe Alves',
    userPhotoUrl: null,
    text: 'Processo simplificado de check-in, quarto espaçoso e equipe super atenciosa. Recomendo a todos!',
    rating: 4.5,
    hotelName: 'Grand Palace Hotel',
  ),
];

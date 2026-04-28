import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/home/presentation/widgets/room_card.dart';

// Mock Models
class MockHotelDependency {
  final String imageUrl;
  final String title;
  MockHotelDependency({required this.imageUrl, required this.title});
}

class MockRecommendedRoom {
  final String imageUrl;
  final String title;
  final double price;
  MockRecommendedRoom({required this.imageUrl, required this.title, required this.price});
}

class MockReview {
  final String author;
  final String timeAgo;
  final String content;
  final double rating;
  MockReview({required this.author, required this.timeAgo, required this.content, required this.rating});
}

class HotelDetailsPage extends ConsumerWidget {
  final String hotelId;

  const HotelDetailsPage({
    super.key,
    required this.hotelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mocks
    final dependencies = [
      MockHotelDependency(imageUrl: 'lib/assets/images/home_page.jpeg', title: 'Piscina'),
      MockHotelDependency(imageUrl: 'lib/assets/images/home_page.jpeg', title: 'Academia'),
      MockHotelDependency(imageUrl: 'lib/assets/images/home_page.jpeg', title: 'Restaurante'),
      MockHotelDependency(imageUrl: 'lib/assets/images/home_page.jpeg', title: 'Spa'),
    ];

    final recommendedRooms = [
      {'roomId': '1', 'title': 'Copacabana Palace', 'imageUrl': 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=2070', 'rating': '5.0', 'amenities': [Icons.wifi, Icons.ac_unit, Icons.pool]},
      {'roomId': '2', 'title': 'Fasano Rio', 'imageUrl': 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?q=80&w=2000', 'rating': '4.9', 'amenities': [Icons.wifi, Icons.restaurant, Icons.spa]},
      {'roomId': '3', 'title': 'Hotel Unique SP', 'imageUrl': 'https://images.unsplash.com/photo-1541971802814-ced3bbff94a5?q=80&w=2070', 'rating': '4.8', 'amenities': [Icons.wifi, Icons.pool, Icons.fitness_center]},
    ];

    final reviews = [
      MockReview(author: 'João Silva', timeAgo: '1 semana atrás', content: 'Lugar incrível, excelente atendimento e café da manhã maravilhoso.', rating: 5.0),
      MockReview(author: 'Maria Souza', timeAgo: '1 mês atrás', content: 'Muito bom, porém a internet nos quartos deixava um pouco a desejar.', rating: 4.0),
      MockReview(author: 'Carlos Eduardo', timeAgo: '1 ano atrás', content: 'A vista do quarto é espetacular. Voltarei com certeza!', rating: 5.0),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48), // Padding from avatar
                      _buildHeader(),
                      const Divider(height: 48, color: Color(0xFFE0E0E0)),
                      Center(child: _buildSectionTitle('Descrição')),
                      const SizedBox(height: 12),
                      const Text(
                        'Mussum Ipsum, cacilds vidis litro abertis. Todo mundo vê os porris que eu tomo, mas ninguém vê os tombis que eu levo! Per aumento de cachacis, eu reclamis. Suco de cevadiss, é um leite divinis, qui tem lupuliz, matis, aguis e fermentis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const Divider(height: 48, color: Color(0xFFE0E0E0)),
                      _buildSectionTitle('Dependências'),
                      const SizedBox(height: 16),
                      _buildDependencies(dependencies),
                      const Divider(height: 48, color: Color(0xFFE0E0E0)),
                      _buildRichSectionTitle('Quartos ', 'Recomendados'),
                      const SizedBox(height: 16),
                      _buildBedFilter(),
                      const SizedBox(height: 16),
                      _buildRecommendedRooms(recommendedRooms),
                      const Divider(height: 48, color: Color(0xFFE0E0E0)),
                      _buildSectionTitle('Avaliações'),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          '4.0',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < 4 ? Icons.star : Icons.star_border,
                              color: AppColors.secondary,
                              size: 20,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildReviews(reviews),
                      const SizedBox(height: 48), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -40,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      image: const DecorationImage(
                        image: AssetImage('lib/assets/images/home_page.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: false,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              'lib/assets/images/home_page.jpeg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, size: 20),
              onPressed: () => context.go('/notifications'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Grand Hotel Budapest',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: AppColors.greyText, size: 16),
            SizedBox(width: 4),
            Text(
              'Budapest, Hungary',
              style: TextStyle(
                color: AppColors.greyText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRichSectionTitle(String primary, String secondary) {
    return Text.rich(
      TextSpan(
        text: primary,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: secondary,
            style: const TextStyle(
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependencies(List<MockHotelDependency> dependencies) {
    return SizedBox(
      height: 400,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dependencies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final dep = dependencies[index];
          return Container(
            width: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: AssetImage(dep.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(16),
              child: Text(
                dep.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBedFilter() {
    final filters = ['1 cama', '2 camas', '3 camas'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: filters.map((filter) {
        return Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.king_bed_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                filter,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendedRooms(List<Map<String, dynamic>> rooms) {
    return SizedBox(
      height: 400,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        separatorBuilder: (context, index) => const SizedBox(width: 0), // RoomCard has margin
        itemBuilder: (context, index) {
          final room = rooms[index];
          return RoomCard(
            roomId: room['roomId'] as String,
            hotelId: room['hotelId'] as String? ?? '',
            title: room['title'] as String,
            imageUrl: room['imageUrl'] as String,
            rating: room['rating'] as String,
            amenities: room['amenities'] as List<IconData>,
          );
        },
      ),
    );
  }

  Widget _buildReviews(List<MockReview> reviews) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1, color: Color(0xFFE0E0E0)),
          ),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFD9D9D9),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.author,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < review.rating ? Icons.star : Icons.star_border,
                                color: AppColors.secondary,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      review.timeAgo,
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 60), // Align with text start
                  child: Text(
                    review.content,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
        Center(
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'Ver Mais',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

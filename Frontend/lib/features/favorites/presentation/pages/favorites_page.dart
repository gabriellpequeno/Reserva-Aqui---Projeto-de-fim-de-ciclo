import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/utils/breakpoints.dart';
import '../providers/favorites_provider.dart';
import '../widgets/favorite_card.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final filteredFavorites = ref.watch(filteredFavoritesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isLoggedIn =
        ref.watch(authProvider).asData?.value.isAuthenticated ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: Column(
            children: [
              _buildHeader(context, ref),

          if (!isLoggedIn) _buildLoginMessage(context),

          Expanded(
            child: !isLoggedIn
                ? const SizedBox.shrink()
                : favoritesAsync.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : favoritesAsync.hasError
                        ? Center(
                            child: Text(
                              'Erro ao carregar favoritos.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : filteredFavorites.isEmpty
                            ? _buildEmptyState(searchQuery.isNotEmpty)
                            : GridView.builder(
                                padding: const EdgeInsets.only(
                                    bottom: 100, top: 10),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isTablet(context) ? 2 : 1,
                                  childAspectRatio: 2.2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                                itemCount: filteredFavorites.length,
                                itemBuilder: (context, index) =>
                                    FavoriteCard(
                                        hotel: filteredFavorites[index]),
                              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 48), // Spacer to balance the bell icon
              Expanded(
                child: SvgPicture.asset(
                  'lib/assets/icons/logo/logoDark.svg',
                  height: 32,
                ),
              ),
              // Notification Bell Icon
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Favoritos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Integrated Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
              decoration: const InputDecoration(
                hintText: 'Busque por destino, hotel ou quarto...',
                hintStyle: TextStyle(color: AppColors.greyText, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.transparent), // Hidden prefix
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.search, color: AppColors.secondary, size: 28),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 48, color: AppColors.secondary),
          const SizedBox(height: 16),
          const Text(
            'Faça login para favoritar hotéis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Salve seus lugares favoritos para encontrá-los facilmente depois.',
            style: TextStyle(color: AppColors.greyText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/auth/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ENTRAR AGORA'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.favorite_border,
            size: 64,
            color: AppColors.greyText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Nenhum resultado encontrado' : 'Você ainda não tem favoritos',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore quartos e clique no coração para salvá-los aqui.',
            style: TextStyle(color: AppColors.greyText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

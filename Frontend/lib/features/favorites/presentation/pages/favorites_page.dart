import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_app_bar.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: isDesktop
          ? null
          : const CustomAppBar(
              title: 'Favoritos',
              showNotificationIcon: true,
              showBackButton: false,
            ),
      body: Column(
        children: [
          _buildSearchBar(context, ref),

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
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                          )
                        : filteredFavorites.isEmpty
                            ? _buildEmptyState(context, searchQuery.isNotEmpty)
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth > 800) {
                                    return GridView.builder(
                                      padding: const EdgeInsets.only(
                                          bottom: 100, top: 10),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 2.2,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                      ),
                                      itemCount: filteredFavorites.length,
                                      itemBuilder: (context, index) =>
                                          FavoriteCard(
                                              hotel:
                                                  filteredFavorites[index]),
                                    );
                                  }
                                  return ListView.builder(
                                    padding: const EdgeInsets.only(
                                        bottom: 100, top: 10),
                                    itemCount: filteredFavorites.length,
                                    itemBuilder: (context, index) =>
                                        FavoriteCard(
                                            hotel: filteredFavorites[index]),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).update(value),
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Busque por destino, hotel ou quarto...',
            hintStyle:
                TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.transparent),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.search, color: AppColors.secondary, size: 28),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
          Text(
            'Faça login para favoritar hotéis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Salve seus lugares favoritos para encontrá-los facilmente depois.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
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

  Widget _buildEmptyState(BuildContext context, bool isSearch) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.favorite_border,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Nenhum resultado encontrado' : 'Você ainda não tem favoritos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore quartos e clique no coração para salvá-los aqui.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

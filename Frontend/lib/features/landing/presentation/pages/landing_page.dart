import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../features/chat/presentation/pages/chat_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/landing_header.dart';
import '../widgets/hero_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/featured_rooms_section.dart';
import '../widgets/ai_assistant_section.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/landing_footer.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();
  final _heroKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _roomsKey = GlobalKey();
  final _beneKey = GlobalKey();
  final _testimonialsKey = GlobalKey();

  final _howItWorksRevealed = ValueNotifier<bool>(false);

  bool _chatOpen = false;

  // pill height (52) + top padding (14) + bottom buffer (14)
  static const _headerHeight = 80.0;
  static const _fabBottom = 24.0;
  static const _fabRight = 24.0;
  static const _fabSize = 56.0;
  static const _chatWidth = 380.0;
  static const _chatHeight = 540.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _revealIfVisible(_howItWorksKey, _howItWorksRevealed);
  }

  void _revealIfVisible(GlobalKey key, ValueNotifier<bool> notifier) {
    if (notifier.value) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    if (pos.dy < screenH * 0.88) notifier.value = true;
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _howItWorksRevealed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Page content ────────────────────────────────────────
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: _headerHeight + 20),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(key: _heroKey, child: const HeroSection()),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _howItWorksKey,
                  child: HowItWorksSection(revealed: _howItWorksRevealed),
                ),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(
                    key: _roomsKey, child: const FeaturedRoomsSection()),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(
                    key: _beneKey, child: const AiAssistantSection()),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(
                    key: _testimonialsKey, child: const TestimonialsSection()),
              ),
              SliverToBoxAdapter(
                child: LandingFooter(
                  onHeroTap: () => _scrollTo(_heroKey),
                  onHowItWorksTap: () => _scrollTo(_howItWorksKey),
                  onRoomsTap: () => _scrollTo(_roomsKey),
                  onBeneTap: () => _scrollTo(_beneKey),
                  onTestimonialsTap: () => _scrollTo(_testimonialsKey),
                ),
              ),
            ],
          ),

          // ── Floating pill header ─────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LandingHeader(onHomeTap: _scrollToTop),
          ),

          // ── Mini chat panel ──────────────────────────────────────
          Positioned(
            bottom: _fabBottom + _fabSize + 12,
            right: _fabRight,
            child: AnimatedScale(
              scale: _chatOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.bottomRight,
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _chatOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: SizedBox(
                  width: _chatWidth,
                  height: _chatHeight,
                  child: Material(
                    elevation: 16,
                    shadowColor: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ChatPage(
                        hotelId: null,
                        onClose: () => setState(() => _chatOpen = false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── FAB Bene ─────────────────────────────────────────────
          Positioned(
            bottom: _fabBottom,
            right: _fabRight,
            child: _BeneFab(
              isOpen: _chatOpen,
              onTap: () => setState(() => _chatOpen = !_chatOpen),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAB widget ─────────────────────────────────────────────────

class _BeneFab extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const _BeneFab({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isOpen ? AppColors.primary : AppColors.secondary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isOpen
              ? const Icon(Icons.close, color: Colors.white, size: 24)
              : SvgPicture.asset(
                  'lib/assets/icons/logoFav.svg',
                  width: 32,
                  height: 32,
                ),
        ),
      ),
    );
  }
}

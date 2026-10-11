import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/reward_item.dart';
import '../../providers/language_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../theme/app_colors.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<RewardsProvider>(context, listen: false).loadRewards();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final rewardsProvider = Provider.of<RewardsProvider>(context);
    final isGujarati = languageProvider.isGujarati;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _buildAppBar(context, isGujarati),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => rewardsProvider.refreshRewards(),
          color: AppColors.saffronPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Title & Subtitle Banner
                _buildHeroBanner(isGujarati),
                const SizedBox(height: 16),

                // 2. Summary KPI Cards
                _buildSummaryCards(rewardsProvider, isGujarati),
                const SizedBox(height: 20),

                // 3. Tab Navigation (Store, History, My Claims)
                _buildTabs(isGujarati),
                const SizedBox(height: 16),

                // 4. Tab Content
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    switch (_tabController.index) {
                      case 0:
                        return _buildStoreSection(rewardsProvider, isGujarati);
                      case 1:
                        return _buildHistorySection(rewardsProvider, isGujarati);
                      case 2:
                        return _buildClaimedRewardsSection(rewardsProvider, isGujarati);
                      default:
                        return _buildStoreSection(rewardsProvider, isGujarati);
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// App Bar with Back to Home button
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isGujarati) {
    return AppBar(
      backgroundColor: const Color(0xFF0B3D2E),
      elevation: 3,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        tooltip: 'Back to Home',
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.saffronPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.saffronLight, width: 1.2),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: AppColors.saffronLight, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGujarati ? 'લોક સમાધાન પુરસ્કારો' : 'Lok Samadhan Rewards',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Grievance Coin (GC) Redressal System',
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Quick "Back to Home" Text Button
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white30),
              ),
            ),
            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 16),
            label: Text(
              isGujarati ? 'હોમ પર જાઓ' : 'Home',
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: Divider(height: 2, thickness: 2, color: AppColors.saffronPrimary),
      ),
    );
  }

  /// Hero Banner
  Widget _buildHeroBanner(bool isGujarati) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.saffronPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Grievance Coin (GC)',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981), width: 1),
                ),
                child: Text(
                  '1 GC per Complaint',
                  style: GoogleFonts.notoSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF34D399),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isGujarati ? 'લોક સમાધાન પુરસ્કારો' : 'Lok Samadhan Rewards',
            style: GoogleFonts.notoSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isGujarati
                ? 'અવાજ ઉઠાવો. નાગરિક સમસ્યાઓનું નિરાકરણ લાવો. ફરિયાદ સિક્કા (GC) મેળવો.'
                : 'Raise your voice. Solve civic problems. Earn Grievance Coins.',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFCBD5E1),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 4 Summary KPI Cards
  Widget _buildSummaryCards(RewardsProvider provider, bool isGujarati) {
    final balance = provider.balance;
    final eligible = provider.eligibleComplaintsCount;
    final redeemed = provider.rewardsRedeemedCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final cardWidth = isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Card 1: My Grievance Coins
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: isGujarati ? 'મારા ફરિયાદ સિક્કા' : 'My Grievance Coins',
                value: '$balance GC',
                subtitle: 'Available Balance',
                icon: Icons.toll_rounded,
                accentColor: const Color(0xFFD97706), // Amber
                bgGradient: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                borderColor: const Color(0xFFFDE68A),
              ),
            ),

            // Card 2: Eligible Complaints
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: isGujarati ? 'પાત્ર ફરિયાદો' : 'Eligible Complaints',
                value: '$eligible',
                subtitle: 'Earned 1 GC Each',
                icon: Icons.verified_rounded,
                accentColor: const Color(0xFF059669), // Emerald
                bgGradient: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                borderColor: const Color(0xFFA7F3D0),
              ),
            ),

            // Card 3: Rewards Redeemed
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: isGujarati ? 'રીડીમ કરેલા પુરસ્કાર' : 'Rewards Redeemed',
                value: '$redeemed',
                subtitle: 'Demo Claims',
                icon: Icons.card_giftcard_rounded,
                accentColor: const Color(0xFF2563EB), // Blue
                bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                borderColor: const Color(0xFFBFDBFE),
              ),
            ),

            // Card 4: How to Earn
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: isGujarati ? 'કેવી રીતે કમાવું?' : 'How to Earn',
                value: '1 GC / issue',
                subtitle: 'Submit Verified Complaint',
                icon: Icons.lightbulb_rounded,
                accentColor: const Color(0xFF7C3AED), // Purple
                bgGradient: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                borderColor: const Color(0xFFE9D5FF),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Color> bgGradient,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.notoSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Segmented Tab Switcher
  Widget _buildTabs(bool isGujarati) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.saffronPrimary,
        indicatorWeight: 3,
        labelColor: AppColors.saffronPrimary,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.notoSans(fontSize: 12.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w600),
        onTap: (index) => setState(() {}),
        tabs: [
          Tab(
            icon: const Icon(Icons.storefront_rounded, size: 18),
            text: isGujarati ? 'પુરસ્કાર સ્ટોર' : 'Rewards Store',
          ),
          Tab(
            icon: const Icon(Icons.history_rounded, size: 18),
            text: isGujarati ? 'GC ઇતિહાસ' : 'My GC History',
          ),
          Tab(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            text: isGujarati ? 'દાવા કરેલા' : 'My Claims',
          ),
        ],
      ),
    );
  }

  /// 4. Section: Redeem Your Grievance Coins (Store)
  Widget _buildStoreSection(RewardsProvider provider, bool isGujarati) {
    final catalogue = provider.catalogue;
    final currentBalance = provider.balance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store Section Header
        Row(
          children: [
            const Icon(Icons.redeem_rounded, color: AppColors.saffronPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              isGujarati ? 'તમારા ફરિયાદ સિક્કા રિડીમ કરો' : 'Redeem Your Grievance Coins',
              style: GoogleFonts.notoSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Prominent Demo Disclaimer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo Rewards Only — No real vouchers, redeem codes, or monetary value are provided.',
                  style: GoogleFonts.notoSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Vertical List of Reward Rows (One reward per row)
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 620;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: catalogue.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = catalogue[index];
                return _buildRewardListItem(
                  item: item,
                  currentBalance: currentBalance,
                  provider: provider,
                  isGujarati: isGujarati,
                  isMobile: isMobile,
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Compact Horizontal Reward List Item Row (One reward per row)
  Widget _buildRewardListItem({
    required RewardItem item,
    required int currentBalance,
    required RewardsProvider provider,
    required bool isGujarati,
    required bool isMobile,
  }) {
    final hasEnoughCoins = currentBalance >= item.cost;
    final coinsNeeded = item.cost - currentBalance;

    Color brandColor = const Color(0xFF2563EB);
    IconData brandIcon = Icons.card_giftcard_rounded;
    String brandEmoji = '🎁';

    final lowerName = item.name.toLowerCase();
    if (lowerName.contains('flipkart')) {
      brandColor = const Color(0xFF2874F0);
      brandIcon = Icons.card_giftcard_rounded;
      brandEmoji = '🎁';
    } else if (lowerName.contains('amazon')) {
      brandColor = const Color(0xFFFF9900);
      brandIcon = Icons.shopping_cart_rounded;
      brandEmoji = '🛒';
    } else if (lowerName.contains('google play')) {
      brandColor = const Color(0xFF00875A);
      brandIcon = Icons.play_arrow_rounded;
      brandEmoji = '▶';
    } else if (lowerName.contains('lenskart')) {
      brandColor = const Color(0xFF000042);
      brandIcon = Icons.visibility_rounded;
      brandEmoji = '👓';
    }

    final displayName = item.name.contains(brandEmoji)
        ? item.name
        : '$brandEmoji  ${item.name}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Small Icon on Left + Reward Name in Middle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBrandIcon(brandIcon, brandColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.notoSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 2. Middle: Short Description
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              item.description,
              style: GoogleFonts.notoSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ),

          // 3. Compact Insufficient Coins Warning (if needed)
          if (!hasEnoughCoins) ...[
            const SizedBox(height: 10),
            _buildInsufficientCoinsWarning(coinsNeeded, currentBalance, item.cost, isGujarati),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // 4. Bottom Line: GC Cost on Left, Redeem Button Aligned to Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildGcPriceBadge(item.cost),
              _buildRedeemButton(
                context: context,
                item: item,
                hasEnoughCoins: hasEnoughCoins,
                currentBalance: currentBalance,
                coinsNeeded: coinsNeeded,
                provider: provider,
                isGujarati: isGujarati,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Brand Icon
  Widget _buildBrandIcon(IconData brandIcon, Color brandColor) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brandColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Center(
        child: Icon(brandIcon, color: brandColor, size: 20),
      ),
    );
  }

  /// GC Cost Badge with Orange Accent
  Widget _buildGcPriceBadge(int cost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: AppColors.saffronPrimary, size: 15),
          const SizedBox(width: 4),
          Text(
            '$cost GC',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFC2410C),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Insufficient Coins Warning
  Widget _buildInsufficientCoinsWarning(
    int coinsNeeded,
    int currentBalance,
    int totalCost,
    bool isGujarati,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFECACA), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  isGujarati ? 'પૂરતા ફરિયાદ સિક્કા નથી!' : 'Not enough Grievance Coins!',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
                Text(
                  isGujarati
                      ? 'તમારે હજુ $coinsNeeded વધુ GC ની જરૂર છે.'
                      : 'You need $coinsNeeded more GC.',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Redeem Button
  Widget _buildRedeemButton({
    required BuildContext context,
    required RewardItem item,
    required bool hasEnoughCoins,
    required int currentBalance,
    required int coinsNeeded,
    required RewardsProvider provider,
    required bool isGujarati,
    bool isMobile = false,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: hasEnoughCoins ? AppColors.saffronPrimary : const Color(0xFFE2E8F0),
        foregroundColor: hasEnoughCoins ? Colors.white : const Color(0xFF94A3B8),
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        disabledForegroundColor: const Color(0xFF94A3B8),
        elevation: hasEnoughCoins ? 1.5 : 0,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 9,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(
        hasEnoughCoins ? Icons.shopping_cart_checkout_rounded : Icons.lock_outline_rounded,
        size: 15,
      ),
      label: Text(
        hasEnoughCoins
            ? (isGujarati ? 'રિડીમ કરો' : 'Redeem Reward')
            : (isGujarati ? 'અનુપલબ્ધ' : 'Unavailable'),
        style: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: hasEnoughCoins
          ? () => _showRedemptionConfirmDialog(context, item, provider, isGujarati)
          : () {
              _showInsufficientCoinsDialog(context, item, currentBalance, coinsNeeded, isGujarati);
            },
    );
  }

  /// Dialog when user clicks an unavailable reward
  void _showInsufficientCoinsDialog(
    BuildContext context,
    RewardItem item,
    int currentBalance,
    int coinsNeeded,
    bool isGujarati,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Not enough Grievance Coins!',
              style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need ${item.cost} GC to redeem ${item.name}, but you currently have $currentBalance GC.',
              style: GoogleFonts.notoSans(fontSize: 13, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coins Needed Formula:',
                    style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.cost} GC (Cost) - $currentBalance GC (Current) = $coinsNeeded GC Needed',
                    style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                  ),
                  const Divider(height: 12, thickness: 1, color: Color(0xFFFDE68A)),
                  Text(
                    'Earn $coinsNeeded more GC by submitting eligible complaints (equivalent to $coinsNeeded additional eligible complaints).',
                    style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Understood', style: GoogleFonts.notoSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Confirmation Dialog before executing redemption
  void _showRedemptionConfirmDialog(
    BuildContext context,
    RewardItem item,
    RewardsProvider provider,
    bool isGujarati,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, color: AppColors.saffronPrimary, size: 24),
            const SizedBox(width: 10),
            Text(
              'Confirm Demo Claim',
              style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to claim this reward?',
              style: GoogleFonts.notoSans(fontSize: 13, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cost:', style: GoogleFonts.notoSans(fontSize: 12, color: const Color(0xFF64748B))),
                      Text('${item.cost} Grievance Coins', style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFB45309))),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Balance after claim:', style: GoogleFonts.notoSans(fontSize: 12, color: const Color(0xFF64748B))),
                      Text('${provider.balance - item.cost} GC', style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Note: This is a demo simulation. No actual commercial voucher code will be issued.',
              style: GoogleFonts.notoSans(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.notoSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffronPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await provider.redeemReward(item);
              if (context.mounted) {
                if (result.success) {
                  _showSuccessRedemptionDialog(context, result);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message ?? 'Redemption failed'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              }
            },
            child: Text('Confirm Claim', style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  /// Success Celebration Dialog after successful claim
  void _showSuccessRedemptionDialog(BuildContext context, RedemptionResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration_rounded, color: Color(0xFF059669), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              '🎉 Reward Claimed Successfully!',
              style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF065F46)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You claimed: ${result.rewardName}',
              style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coins Deducted:', style: GoogleFonts.notoSans(fontSize: 12, color: const Color(0xFF64748B))),
                      Text('-${result.cost} GC', style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remaining Balance:', style: GoogleFonts.notoSans(fontSize: 12, color: const Color(0xFF64748B))),
                      Text('${result.remainingBalance} GC', style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF059669))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: Demo Claimed (Reference Saved)',
              style: GoogleFonts.notoSans(fontSize: 11, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Done', style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  /// 5. Section: My GC History
  Widget _buildHistorySection(RewardsProvider provider, bool isGujarati) {
    final transactions = provider.transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.saffronPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              isGujarati ? 'મારા જીસી વ્યવહારનો ઇતિહાસ' : 'My GC History',
              style: GoogleFonts.notoSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Color(0xFF94A3B8), size: 40),
                const SizedBox(height: 10),
                Text(
                  'No transactions yet. Submit an eligible complaint to earn your first GC!',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isEarned = tx.isEarned;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEarned ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEarned ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isEarned ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Description & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description,
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${tx.createdAt.day.toString().padLeft(2, '0')}/${tx.createdAt.month.toString().padLeft(2, '0')}/${tx.createdAt.year} ${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.notoSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              if (tx.referenceId != null) ...[
                                const Text(' • ', style: TextStyle(color: Color(0xFFCBD5E1))),
                                Text(
                                  tx.referenceId!,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Coins amount & Balance After
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isEarned ? '+${tx.amount} GC' : '${tx.amount} GC',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isEarned ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                        Text(
                          'Bal: ${tx.balanceAfter} GC',
                          style: GoogleFonts.notoSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  /// 6. Section: My Claimed Rewards
  Widget _buildClaimedRewardsSection(RewardsProvider provider, bool isGujarati) {
    final claims = provider.claimedRewards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.saffronPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              isGujarati ? 'મારા દાવો કરેલા પુરસ્કારો' : 'My Claimed Rewards',
              style: GoogleFonts.notoSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (claims.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: Color(0xFF94A3B8), size: 40),
                const SizedBox(height: 10),
                Text(
                  'No rewards claimed yet. Earn Grievance Coins by lodging civic complaints to redeem vouchers!',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: claims.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final claim = claims[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            claim.rewardName,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Ref: ${claim.id} • ${claim.createdAt.day}/${claim.createdAt.month}/${claim.createdAt.year}',
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            claim.status,
                            style: GoogleFonts.notoSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${claim.coinsDeducted} GC',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

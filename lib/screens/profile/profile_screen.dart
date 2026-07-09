import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/metro_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/data/metro_data.dart';
import '../auth/login_screen.dart';
import '../main_nav/main_navigation.dart';
import 'edit_profile_screen.dart';
import '../../core/services/notification_service.dart';
import 'transit_alarm_screen.dart';
import 'user_announcements_screen.dart';
import '../tickets/detailed_dummy_payment_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final tickets = context.watch<TicketProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final metro = context.watch<MetroProvider>();
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Profile header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (auth.userName.isEmpty
                                  ? 'T'
                                  : auth.userName[0])
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      auth.userName.isEmpty ? 'Traveller' : auth.userName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      auth.userEmail.isEmpty
                          ? 'user@example.com'
                          : auth.userEmail,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        _profileStat('Total Trips', '${tickets.totalTrips}'),
                        _divider(),
                        _profileStat('Total Spent', '₹${tickets.totalSpent}'),
                        _divider(),
                        _profileStat(
                            'Favorites', '${favorites.favorites.length}'),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

              // Wallet Section
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${wallet.balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _openAddMoney(context, wallet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              _menuItem(
                context,
                icon: Icons.star_rounded,
                iconColor: AppColors.yellowLine,
                title: 'Saved Routes',
                subtitle: '${favorites.favorites.length} routes saved',
                onTap: () => _showSavedRoutes(context, favorites, metro),
              ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05, end: 0),

              _menuItem(
                context,
                icon: Icons.history_rounded,
                iconColor: AppColors.aquaLine,
                title: 'Recent Searches',
                subtitle: '${favorites.recentSearches.length} searches',
                onTap: () => _showRecentSearches(context, favorites, metro),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05, end: 0),

              _menuItem(
                context,
                icon: Icons.confirmation_num_rounded,
                iconColor: AppColors.primary,
                title: 'Ticket History',
                subtitle: '${tickets.totalTrips} tickets',
                onTap: () => _showTicketHistory(context, tickets),
              ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05, end: 0),

              _menuItem(
                context,
                icon: Icons.campaign_rounded,
                iconColor: AppColors.error,
                title: 'Announcements & Alerts',
                subtitle: 'Live updates from admin',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserAnnouncementsScreen()),
                  );
                },
              ).animate().fadeIn(delay: 375.ms).slideX(begin: 0.05, end: 0),

              const SizedBox(height: 24),

              // App Info
              Text(
                'profile.settings'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 12),

              _menuItem(
                context,
                icon: Icons.language_rounded,
                iconColor: AppColors.primary,
                title: 'profile.language'.tr(),
                subtitle: _getLanguageName(context),
                onTap: () => _showLanguageSelector(context),
              ).animate().fadeIn(delay: 420.ms).slideX(begin: 0.05, end: 0),

              _menuItem(
                context,
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textMuted,
                title: 'About',
                subtitle: 'Mumbai Metro Smart Companion v1.0.0',
                onTap: () => _showAboutDialog(context),
              ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.05, end: 0),

              _menuItem(
                context,
                icon: Icons.train_rounded,
                iconColor: AppColors.textMuted,
                title: 'Metro Lines',
                subtitle: '4 lines, ${MetroData().allStations.length} stations',
                onTap: () => _showMetroLines(context),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05, end: 0),

              _menuItem(
                context,
                icon: Icons.alarm_rounded,
                iconColor: AppColors.aquaLine,
                title: 'Smart Transit Alarm',
                subtitle: 'Get notified before your stop',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransitAlarmScreen()),
                  );
                },
              ).animate().fadeIn(delay: 550.ms).slideX(begin: 0.05, end: 0),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text('profile.logout'.tr(),
                      style:
                          const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),

              // Footer
              Text(
                'Made with ❤️ for Mumbai commuters',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddMoney(BuildContext context, WalletProvider wallet) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Add Money to Wallet', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter amount (e.g. 500)',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(amountController.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                
                // Open DetailedDummyPaymentScreen
                final success = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailedDummyPaymentScreen(amount: val, isAddingMoney: true),
                  ),
                );

                if (success == true) {
                   final addSuccess = await wallet.addMoney(val);
                   if (addSuccess && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('₹$val added to wallet successfully'), backgroundColor: AppColors.success),
                      );
                   }
                }
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppColors.error),
                  );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Proceed to Pay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _profileStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.textMuted.withValues(alpha: 0.2),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppAuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('profile.logout'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(BuildContext context) {
    if (context.locale.languageCode == 'hi') return 'settings.hindi'.tr();
    if (context.locale.languageCode == 'mr') return 'settings.marathi'.tr();
    return 'settings.english'.tr();
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('profile.language'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _languageOption(ctx, 'English', const Locale('en')),
              _languageOption(ctx, 'हिन्दी (Hindi)', const Locale('hi')),
              _languageOption(ctx, 'मराठी (Marathi)', const Locale('mr')),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(BuildContext context, String title, Locale locale) {
    final isSelected = context.locale == locale;
    return ListTile(
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context);
      },
      title: Text(title,
          style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
    );
  }

  // ==================== SAVED ROUTES ====================
  void _showSavedRoutes(
      BuildContext context, FavoritesProvider fav, MetroProvider metro) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('⭐ Saved Routes',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Expanded(
                    child: fav.favorites.isEmpty
                        ? const Center(
                            child: Text('No saved routes yet',
                                style: TextStyle(color: AppColors.textMuted)),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: fav.favorites.length,
                            itemBuilder: (_, index) {
                              final route = fav.favorites[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: AppColors.yellowLine, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          // Set source/dest and navigate to routes
                                          final sources = metro.metroData
                                              .findStationsByName(route.source);
                                          final dests = metro.metroData
                                              .findStationsByName(route.destination);
                                          if (sources.isNotEmpty && dests.isNotEmpty) {
                                            metro.setSource(sources.first);
                                            metro.setDestination(dests.first);
                                            metro.findRoutes();
                                            Navigator.pop(ctx);
                                            MainNavigation.navKey.currentState
                                                ?.switchToTab(1);
                                          }
                                        },
                                        child: Text(
                                          '${route.source} → ${route.destination}',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => fav.toggleFavorite(
                                          route.source, route.destination),
                                      child: const Icon(Icons.delete_outline,
                                          color: AppColors.error, size: 18),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================== RECENT SEARCHES ====================
  void _showRecentSearches(
      BuildContext context, FavoritesProvider fav, MetroProvider metro) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final searches = fav.recentSearches.take(5).toList();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('🕐 Recent Searches',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  if (searches.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        fav.clearRecentSearches();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (searches.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No recent searches',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ...searches.map((search) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history,
                              color: AppColors.textMuted, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              search,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Parse "Source → Destination" and search
                              final parts = search.split(' → ');
                              if (parts.length == 2) {
                                final sources = metro.metroData
                                    .findStationsByName(parts[0].trim());
                                final dests = metro.metroData
                                    .findStationsByName(parts[1].trim());
                                if (sources.isNotEmpty && dests.isNotEmpty) {
                                  metro.setSource(sources.first);
                                  metro.setDestination(dests.first);
                                  metro.findRoutes();
                                  Navigator.pop(ctx);
                                  MainNavigation.navKey.currentState
                                      ?.switchToTab(1);
                                }
                              }
                            },
                            child: const Icon(Icons.chevron_right,
                                color: AppColors.textMuted, size: 20),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ==================== TICKET HISTORY ====================
  void _showTicketHistory(BuildContext context, TicketProvider tickets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('🎫 Ticket History',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Expanded(
                    child: tickets.usedTickets.isEmpty
                        ? const Center(
                            child: Text('No past tickets yet',
                                style: TextStyle(color: AppColors.textMuted)),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: tickets.usedTickets.length,
                            itemBuilder: (_, index) {
                              final ticket = tickets.usedTickets[index];
                              final isActive = ticket.status == 'active';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.success.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${ticket.source} → ${ticket.destination}',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? AppColors.success
                                                    .withValues(alpha: 0.15)
                                                : AppColors.textMuted
                                                    .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isActive ? 'ACTIVE' : 'USED',
                                            style: TextStyle(
                                              color: isActive
                                                  ? AppColors.success
                                                  : AppColors.textMuted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${ticket.fare.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          '${ticket.stops} stops • ${ticket.estimatedMinutes} min',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateFormat('dd MMM, hh:mm a')
                                              .format(ticket.createdAt),
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (ticket.linesTaken.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        ticket.linesTaken,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================== METRO LINES ====================
  void _showMetroLines(BuildContext context) {
    final metroData = MetroData();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('🚇 Metro Lines',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: metroData.lines.length,
                      itemBuilder: (_, lineIndex) {
                        final line = metroData.lines[lineIndex];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: line.color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: lineIndex == 0,
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: line.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              title: Text(
                                '${line.name} (${line.shortName})',
                                style: TextStyle(
                                  color: line.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${line.stations.length} stations • ${line.firstTrain} - ${line.lastTrain}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  child: Column(
                                    children: line.stations.map((station) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: line.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                station.name,
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            if (station.isInterchange)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.warning
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '🔄 ${station.connectedLineIds.join(", ")}',
                                                  style: const TextStyle(
                                                    color: AppColors.warning,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.train_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Mumbai Metro Smart Companion',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text('Version 1.0.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              const Text(
                'Your complete metro travel companion for Mumbai. Plan routes, book tickets, track crowd levels, and get smart travel insights.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '\nCovers Line 1 (Blue), Line 2A (Yellow),\nLine 7 (Red), Line 3 (Aqua)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Notification settings now handled by TransitAlarmScreen
}

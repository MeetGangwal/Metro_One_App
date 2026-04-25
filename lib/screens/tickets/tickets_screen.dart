import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ticket_provider.dart';
import '../../core/models/models.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Tickets',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 4),
                  Text(
                    '${ticketProvider.activeTickets.length} active • ${ticketProvider.usedTickets.length} used',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'History'),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTicketList(ticketProvider.activeTickets, true),
                  _buildTicketList(ticketProvider.usedTickets, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<MetroTicket> tickets, bool isActive) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive
                  ? Icons.confirmation_num_outlined
                  : Icons.history_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active tickets' : 'No ticket history',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Book a ticket from the Routes tab'
                  : 'Your used tickets will appear here',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticket: ticket),
              ),
            );
          },
          child: _buildTicketCard(ticket, isActive)
              .animate()
              .fadeIn(delay: (index * 100).ms)
              .slideY(begin: 0.05, end: 0),
        );
      },
    );
  }

  Widget _buildTicketCard(MetroTicket ticket, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.ticketGradient : null,
        color: isActive ? null : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Notch decorations
          Positioned(
            left: -8,
            top: 60,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -8,
            top: 60,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Route info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.source,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'FROM',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white70
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: isActive ? Colors.white70 : AppColors.textMuted,
                      size: 20,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ticket.destination,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.end,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TO',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white70
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: List.generate(
                      30,
                      (i) => Expanded(
                        child: Container(
                          height: 1,
                          color: i.isEven
                              ? (isActive
                                  ? Colors.white24
                                  : AppColors.textMuted.withValues(alpha: 0.2))
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),

                // Ticket details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ticketInfo(
                      'Fare',
                      '₹${ticket.fare.toStringAsFixed(0)}',
                      isActive,
                    ),
                    _ticketInfo(
                      'Stops',
                      '${ticket.stops}',
                      isActive,
                    ),
                    _ticketInfo(
                      'Time',
                      '${ticket.estimatedMinutes} min',
                      isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _detailedTimeInfo(
                      'Booking Time',
                      DateFormat('dd MMM yyyy, hh:mm a').format(ticket.createdAt),
                      isActive,
                    ),
                    _detailedTimeInfo(
                      'Valid Until',
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        ticket.ticketType == 'monthly_pass' 
                          ? ticket.createdAt.add(const Duration(days: 30)) 
                          : ticket.createdAt.add(const Duration(hours: 24))
                      ),
                      isActive,
                      alignment: CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketInfo(String label, String value, bool isActive) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white60 : AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _detailedTimeInfo(String label, String value, bool isActive, {CrossAxisAlignment alignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white60 : AppColors.textMuted,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
           value,
           style: TextStyle(
             color: isActive ? Colors.white : AppColors.textPrimary,
             fontSize: 12,
             fontWeight: FontWeight.w600,
           ),
        ),
      ],
    );
  }
}


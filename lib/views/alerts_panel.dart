import 'package:appmaniazar/constants/app_colors.dart';
import 'package:appmaniazar/models/weather_alert.dart';
import 'package:appmaniazar/models/weather.dart';
import 'package:appmaniazar/providers/current_weather_provider.dart';
import 'package:appmaniazar/services/alert_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertsPanel extends ConsumerStatefulWidget {
  const AlertsPanel({super.key});

  @override
  ConsumerState<AlertsPanel> createState() => _AlertsPanelState();
}

class _AlertsPanelState extends ConsumerState<AlertsPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

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
    final alertsAsync = ref.watch(userAlertsProvider);
    final unreadCount = ref.watch(unreadAlertsCountProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.95),
            AppColors.primaryBlue.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Real-time Updates & Alerts',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Expanded content
          if (_isExpanded) ...[
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 2,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Active Alerts'),
                  Tab(text: 'Today'),
                ],
              ),
            ),
            
            // Tab content
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAlertsTab(alertsAsync),
                  _buildTodayTab(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertsTab(AsyncValue<List<WeatherAlert>> alertsAsync) {
    return alertsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading alerts',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active alerts',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Weather conditions are normal',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertCard(alert);
          },
        );
      },
    );
  }

  Widget _buildAlertCard(WeatherAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert.type.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.type.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            alert.type.icon,
            color: alert.type.color,
            size: 20,
          ),
        ),
        title: Text(
          alert.title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              alert.timeAgo,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            if (!alert.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'New',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Colors.white70,
            size: 20,
          ),
          color: AppColors.primaryBlue,
          onSelected: (value) {
            if (value == 'mark_read') {
              ref.read(alertServiceProvider).markAlertAsRead(alert.id);
            } else if (value == 'delete') {
              ref.read(alertServiceProvider).deleteAlert(alert.id);
            }
          },
          itemBuilder: (context) => [
            if (!alert.isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Mark as read', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.description,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (alert.expiresAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    alert.expiresAtText,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (alert.actionUrl != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle action URL
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alert.type.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Take Action',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final weatherAsync = ref.watch(currentWeatherProvider);
    return weatherAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (_, __) => Center(
        child: Text(
          'Unable to load today updates',
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
      data: (weather) {
        final updates = _buildTodayUpdates(weather);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: updates.length,
          itemBuilder: (context, index) => _buildTodayUpdateCard(updates[index]),
        );
      },
    );
  }

  List<_TodayUpdate> _buildTodayUpdates(Weather weather) {
    final updates = <_TodayUpdate>[];
    final condition = weather.weather.isNotEmpty ? weather.weather.first.main.toLowerCase() : '';
    final description = weather.weather.isNotEmpty ? weather.weather.first.description : 'current conditions';

    updates.add(
      _TodayUpdate(
        title: 'Today Summary',
        subtitle:
            '${weather.temperature.toStringAsFixed(0)}°C now, feels like ${weather.main.feelsLike.toStringAsFixed(0)}°C, $description.',
        icon: Icons.today,
        color: Colors.lightBlueAccent,
      ),
    );

    if (condition.contains('rain') || condition.contains('thunderstorm')) {
      updates.add(
        const _TodayUpdate(
          title: 'Outdoor Plan',
          subtitle: 'Rain risk is elevated. Plan outdoor tasks earlier and keep rain gear ready.',
          icon: Icons.umbrella,
          color: Colors.cyanAccent,
        ),
      );
    } else {
      updates.add(
        const _TodayUpdate(
          title: 'Outdoor Plan',
          subtitle: 'Conditions are fairly stable for outdoor activity right now.',
          icon: Icons.directions_walk,
          color: Colors.greenAccent,
        ),
      );
    }

    if (weather.windSpeed >= 35) {
      updates.add(
        _TodayUpdate(
          title: 'Travel Note',
          subtitle:
              'Strong winds (${weather.windSpeed.toStringAsFixed(0)} km/h). Drive carefully and secure loose items.',
          icon: Icons.air,
          color: Colors.orangeAccent,
        ),
      );
    } else if (weather.visibilityInKm > 0 && weather.visibilityInKm <= 3) {
      updates.add(
        _TodayUpdate(
          title: 'Travel Note',
          subtitle:
              'Reduced visibility (${weather.visibilityInKm.toStringAsFixed(1)} km). Use headlights and leave extra space.',
          icon: Icons.visibility_off,
          color: Colors.amberAccent,
        ),
      );
    } else {
      updates.add(
        const _TodayUpdate(
          title: 'Travel Note',
          subtitle: 'No major travel disruptions indicated at the moment.',
          icon: Icons.directions_car,
          color: Colors.white70,
        ),
      );
    }

    return updates;
  }

  Widget _buildTodayUpdateCard(_TodayUpdate update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: update.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: update.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(update.icon, color: update.color, size: 20),
        ),
        title: Text(
          update.title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            update.subtitle,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayUpdate {
  const _TodayUpdate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

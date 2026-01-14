import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../data/repositories/history_repository.dart';
import '../widgets/ticket_list_item.dart';
import 'ticket_print_preview_page.dart';

/// History page
/// Displays list of issued tickets
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tickets = await historyRepository.getTickets();

      if (!mounted) return;

      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load tickets : $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openInMaps(Ticket ticket) async {
    final lat = ticket.position.latitude;
    final lng = ticket.position.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openPrintPreview(Ticket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketPrintPreviewPage(ticketId: ticket.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState(l10n)
          : _tickets.isEmpty
          ? _buildEmptyState(l10n)
          : _buildTicketList(l10n),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(l10n.error, style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? l10n.somethingWentWrong,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadTickets,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(l10n.noTicketsYet, style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              l10n.ticketsWillAppearHere,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l10n.ticketCount(_tickets.length),
                style: AppTextStyles.bodySmall,
              ),
            );
          }

          final ticket = _tickets[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TicketListItem(
              ticket: ticket,
              onTap: () => _openPrintPreview(ticket),
              onGoToLocation: () => _openInMaps(ticket),
              onPrint: () => _openPrintPreview(ticket),
            ),
          );
        },
      ),
    );
  }
}

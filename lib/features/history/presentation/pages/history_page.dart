import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../data/repositories/history_repository.dart';
import '../widgets/ticket_list_item.dart';
import 'ticket_print_preview_page.dart';

enum _DateFilter { today, yesterday, thisWeek, thisMonth, all }

/// History page
/// Displays list of issued tickets
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Ticket> _allTickets = [];
  List<Ticket> _filteredTickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  _DateFilter _dateFilter = _DateFilter.today;
  LicensePlate _searchPlate = const LicensePlate.empty();
  bool _showSearch = false;

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
        _allTickets = tickets;
        _applyFilter();
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
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.failedToLoadTicketsWithError(e.toString());
        _isLoading = false;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _applyFilter() {
    final now = DateTime.now();
    List<Ticket> result;

    switch (_dateFilter) {
      case _DateFilter.today:
        result = _allTickets.where((t) => _isSameDay(t.issuedAt, now)).toList();
        break;
      case _DateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        result =
            _allTickets
                .where((t) => _isSameDay(t.issuedAt, yesterday))
                .toList();
        break;
      case _DateFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate =
            DateTime(weekStart.year, weekStart.month, weekStart.day);
        result =
            _allTickets
                .where((t) => !t.issuedAt.isBefore(weekStartDate))
                .toList();
        break;
      case _DateFilter.thisMonth:
        result =
            _allTickets
                .where(
                  (t) =>
                      t.issuedAt.year == now.year &&
                      t.issuedAt.month == now.month,
                )
                .toList();
        break;
      case _DateFilter.all:
        result = _allTickets;
        break;
    }

    // Apply plate search filter
    if (_searchPlate.isNotEmpty) {
      final searchLeft = _searchPlate.left?.toLowerCase() ?? '';
      final searchRight = _searchPlate.right?.toLowerCase() ?? '';

      result = result.where((ticket) {
        final ticketLeft = ticket.plate.left?.toLowerCase() ?? '';
        final ticketRight = ticket.plate.right?.toLowerCase() ?? '';

        final leftMatch =
            searchLeft.isEmpty || ticketLeft.contains(searchLeft);
        final rightMatch =
            searchRight.isEmpty || ticketRight.contains(searchRight);

        return leftMatch && rightMatch;
      }).toList();
    }

    _filteredTickets = result;
  }

  String _filterLabel(AppLocalizations l10n, _DateFilter filter) {
    switch (filter) {
      case _DateFilter.today:
        return l10n.today;
      case _DateFilter.yesterday:
        return l10n.yesterday;
      case _DateFilter.thisWeek:
        return l10n.thisWeek;
      case _DateFilter.thisMonth:
        return l10n.thisMonth;
      case _DateFilter.all:
        return l10n.allTickets;
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
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchPlate = const LicensePlate.empty();
                  _applyFilter();
                }
              });
            },
          ),
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
              : _buildContent(l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Column(
      children: [
        // Date filter dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_DateFilter>(
                      value: _dateFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: _DateFilter.values.map((filter) {
                        return DropdownMenuItem(
                          value: filter,
                          child: Text(
                            _filterLabel(l10n, filter),
                            style: AppTextStyles.body,
                          ),
                        );
                      }).toList(),
                      onChanged: (filter) {
                        if (filter != null) {
                          setState(() {
                            _dateFilter = filter;
                            _applyFilter();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Plate search
        if (_showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: LicensePlateInput(
              onChanged: (plate) {
                setState(() {
                  _searchPlate = plate;
                  _applyFilter();
                });
              },
            ),
          ),
        // Ticket list or empty state
        Expanded(
          child: _filteredTickets.isEmpty
              ? _buildEmptyState(l10n)
              : _buildTicketList(l10n),
        ),
      ],
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
        itemCount: _filteredTickets.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l10n.ticketCount(_filteredTickets.length),
                style: AppTextStyles.bodySmall,
              ),
            );
          }

          final ticket = _filteredTickets[index - 1];
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

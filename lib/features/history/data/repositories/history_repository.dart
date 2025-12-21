import '../../../../shared/models/models.dart';
import '../../../create_ticket/data/repositories/ticket_repository.dart';

/// History repository
/// Provides access to ticket history from the API
class HistoryRepository {
  /// Get all tickets for the current agent
  Future<List<Ticket>> getTickets() async {
    return ticketRepository.getAgentTickets();
  }

  /// Get today's tickets
  Future<List<Ticket>> getTodayTickets() async {
    return ticketRepository.getTodayTickets();
  }
}

/// Singleton instance
final historyRepository = HistoryRepository();

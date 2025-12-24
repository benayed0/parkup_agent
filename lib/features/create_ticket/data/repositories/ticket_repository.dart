import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// Ticket repository
/// Handles ticket operations with the API
class TicketRepository {
  final Dio _dio = ApiClient.instance.dio;

  /// Create a new ticket
  Future<Ticket> createTicket({
    required String licensePlate,
    required Position position,
    required TicketReason reason,
    required double fineAmount,
    required String parkingZoneId,
    String? notes,
  }) async {
    try {
      // Get current agent ID
      final agent = authRepository.currentAgent;
      if (agent == null) {
        throw const ApiException(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }

      final now = DateTime.now();
      // Due date is 30 days from now by default
      final dueDate = now.add(const Duration(days: 30));

      final response = await _dio.post(
        ApiConfig.tickets,
        data: {
          'position': position.toJson(),
          'licensePlate': licensePlate.toUpperCase().replaceAll(' ', ''),
          'reason': reason.value,
          'fineAmount': fineAmount,
          'issuedAt': now.toIso8601String(),
          'dueDate': dueDate.toIso8601String(),
          'agentId': agent.id,
          'parkingZoneId': parkingZoneId,
          'notes': notes,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        return Ticket.fromJson(data['data'] as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Failed to create ticket',
        statusCode: 500,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get tickets issued by the current agent
  Future<List<Ticket>> getAgentTickets({int? limit}) async {
    try {
      final agent = authRepository.currentAgent;
      if (agent == null) {
        throw const ApiException(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }

      String url = ApiConfig.ticketsByAgent(agent.id);
      if (limit != null) {
        url += '?limit=$limit';
      }

      final response = await _dio.get(url);

      final data = response.data as Map<String, dynamic>;
      final tickets = (data['data'] as List?)
              ?.map((t) => Ticket.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [];

      return tickets;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get tickets for today
  Future<List<Ticket>> getTodayTickets() async {
    final allTickets = await getAgentTickets();
    final today = DateTime.now();

    return allTickets.where((ticket) {
      return ticket.issuedAt.year == today.year &&
          ticket.issuedAt.month == today.month &&
          ticket.issuedAt.day == today.day;
    }).toList();
  }

  /// Extract error message from Dio exception
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Failed to process ticket';
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your network.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please check your network.';
      default:
        return 'Failed to process ticket. Please try again.';
    }
  }
}

/// Singleton instance for shared access
final ticketRepository = TicketRepository();

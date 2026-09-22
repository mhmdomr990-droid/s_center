import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

class WalletProvider {
  final ApiClient _api;

  WalletProvider(this._api);

  Future<Response> getWallet() {
    return _api.get('/wallet/');
  }

  Future<Response> getTransactions({int limit = 20, int offset = 0}) {
    return _api.get('/wallet/transactions', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> createTopupRequest({
    required String amount,
    required String method,
    required String referenceNumber,
    required String senderName,
    String? note,
  }) {
    return _api.post(
      '/wallet/topup-requests',
      data: {
        'amount': amount,
        'method': method,
        'reference_number': referenceNumber,
        'sender_name': senderName,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      headers: {'Idempotency-Key': const Uuid().v4()},
    );
  }

  Future<Response> getTopupRequests({int limit = 20, int offset = 0}) {
    return _api.get('/wallet/topup-requests', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
  }
}

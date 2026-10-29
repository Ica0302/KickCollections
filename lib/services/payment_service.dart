import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/shoe.dart';

class PaymentException implements Exception {
  const PaymentException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.total,
    this.invoiceUrl,
  });

  final String orderId;
  final int total;

  final String? invoiceUrl;

  bool get requiresOnlinePayment => invoiceUrl != null;
}

class PaymentService {
  PaymentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> _ensureSignedIn() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }

  Future<CheckoutResult> createCheckout({
    required Map<Shoe, int> cart,
    required String paymentMethod,
    required Map<String, String> customer,
  }) async {
    try {
      await _ensureSignedIn();
      final response = await _client.functions.invoke(
        'create-payment',
        body: {
          'items': [
            for (final entry in cart.entries)
              {'productId': entry.key.id, 'quantity': entry.value},
          ],
          'paymentMethod': paymentMethod,
          'customer': customer,
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      return CheckoutResult(
        orderId: data['orderId'] as String,
        total: data['total'] as int,
        invoiceUrl: data['invoiceUrl'] as String?,
      );
    } on FunctionException catch (e) {
      final details = e.details;
      throw PaymentException(
        details is Map && details['error'] is String
            ? details['error'] as String
            : 'Payment service error (${e.status}).',
      );
    } on AuthException catch (e) {
      throw PaymentException(e.message);
    } catch (_) {
      throw const PaymentException(
        'Could not reach the payment service. Check your connection.',
      );
    }
  }

  Future<bool> openInvoice(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Stream<String> watchOrderStatus(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) =>
            rows.isEmpty ? 'pending' : rows.first['status'] as String);
  }

  Future<String> fetchOrderStatus(String orderId) async {
    final row = await _client
        .from('orders')
        .select('status')
        .eq('id', orderId)
        .single();
    return row['status'] as String;
  }
}

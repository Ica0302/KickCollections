import 'package:flutter/material.dart';

IconData paymentIcon(String method) {
  switch (method) {
    case 'Cash on Delivery':
      return Icons.payments_outlined;
    case 'GCash':
      return Icons.account_balance_wallet_outlined;
    case 'Maya':
      return Icons.wallet_outlined;
    default:
      return Icons.credit_card_outlined;
  }
}

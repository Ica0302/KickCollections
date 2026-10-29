import 'dart:async';

import 'package:flutter/material.dart';

class PaymentWaitDialog extends StatefulWidget {
  const PaymentWaitDialog({
    super.key,
    required this.statusStream,
  });

  final Stream<String> statusStream;

  @override
  State<PaymentWaitDialog> createState() => _PaymentWaitDialogState();
}

class _PaymentWaitDialogState extends State<PaymentWaitDialog> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.statusStream.listen((status) {
      if (status != 'pending' && mounted) {
        Navigator.pop(context, status);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Waiting for payment'),
      content: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Finish paying in the Xendit page, then come back here.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';

import '../../domain/entities/checkout.dart';
import '../../domain/repositories/payments_repository.dart';

/// Cashfree's hosted checkout (UPI, cards, netbanking) opened in-app.
///
/// The SDK reports through global callbacks, so only one checkout can run at
/// a time; this class turns them into a future.
class CashfreePaymentGateway implements PaymentGateway {
  CashfreePaymentGateway({required bool production})
    : _environment = production
          ? CFEnvironment.PRODUCTION
          : CFEnvironment.SANDBOX;

  final CFEnvironment _environment;
  Completer<GatewayOutcome>? _pending;

  @override
  Future<GatewayOutcome> pay(CheckoutSession session) {
    final previous = _pending;
    if (previous != null && !previous.isCompleted) return previous.future;

    final completer = _pending = Completer<GatewayOutcome>();
    final service = CFPaymentGatewayService()
      ..setCallback(
        (_) => _finish(completer, GatewayOutcome.completed),
        (error, _) => _finish(completer, _outcomeOf(error)),
      );
    try {
      final cfSession = CFSessionBuilder()
          .setEnvironment(_environment)
          .setOrderId(session.orderId)
          .setPaymentSessionId(session.sessionId)
          .build();
      service.doPayment(
        CFWebCheckoutPaymentBuilder().setSession(cfSession).build(),
      );
    } on Object {
      _finish(completer, GatewayOutcome.failed);
    }
    return completer.future;
  }

  static GatewayOutcome _outcomeOf(CFErrorResponse error) {
    final code = '${error.getCode()} ${error.getStatus()}'.toLowerCase();
    return code.contains('cancel') || code.contains('dropped')
        ? GatewayOutcome.cancelled
        : GatewayOutcome.failed;
  }

  static void _finish(
    Completer<GatewayOutcome> completer,
    GatewayOutcome outcome,
  ) {
    if (!completer.isCompleted) completer.complete(outcome);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart';
import '../core/api_client.dart';

class PurchaseService extends ChangeNotifier {
  PurchaseService({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;
  final InAppPurchase _store = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? product;
  bool loading = false;
  bool purchasing = false;
  String? message;

  Future<void> initialize() async {
    _subscription = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) {
        message = error.toString();
        notifyListeners();
      },
    );
    await loadProduct();
  }

  Future<void> loadProduct() async {
    loading = true;
    notifyListeners();
    try {
      final response = await _store.queryProductDetails({AppConfig.appleProductID});
      product = response.productDetails.isEmpty ? null : response.productDetails.first;
      if (product == null) {
        message = '暂时无法加载 Apple 会员商品。';
      }
    } catch (error) {
      message = error.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> purchase() async {
    final current = product;
    if (current == null) {
      message = '会员商品尚未加载完成。';
      notifyListeners();
      return;
    }

    purchasing = true;
    message = null;
    notifyListeners();

    try {
      await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: current),
      );
    } catch (error) {
      message = error.toString();
      purchasing = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    purchasing = true;
    message = null;
    notifyListeners();
    try {
      await _store.restorePurchases();
    } catch (error) {
      message = error.toString();
    }
    purchasing = false;
    notifyListeners();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await api.post(
            '/api/billing/apple/verify',
            body: {
              'transaction_jws':
                  purchase.verificationData.serverVerificationData,
              'environment': purchase.verificationData.source,
            },
          );
          message = '会员开通成功。';
        } catch (error) {
          message = error.toString();
        }
      } else if (purchase.status == PurchaseStatus.error) {
        message = purchase.error?.message ?? '购买失败，请稍后重试。';
      }

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
    purchasing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}




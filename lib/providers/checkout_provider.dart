import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checkout_provider.g.dart';

enum CheckoutStatus {
  initial,
  processing,
  completed,
  failed,
}

class CheckoutState {
  final CheckoutStatus status;
  final String? errorMessage;
  final bool isProcessing;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.errorMessage,
    this.isProcessing = false,
  });

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? errorMessage,
    bool? isProcessing,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

@riverpod
class CheckoutNotifier extends _$CheckoutNotifier {
  @override
  CheckoutState build() {
    return const CheckoutState();
  }

  void startProcessing() {
    state = state.copyWith(
      status: CheckoutStatus.processing,
      isProcessing: true,
      errorMessage: null,
    );
  }

  void completeCheckout() {
    state = state.copyWith(
      status: CheckoutStatus.completed,
      isProcessing: false,
      errorMessage: null,
    );
  }

  void failCheckout(String errorMessage) {
    state = state.copyWith(
      status: CheckoutStatus.failed,
      isProcessing: false,
      errorMessage: errorMessage,
    );
  }

  void reset() {
    state = const CheckoutState();
  }

  bool get isCompleted => state.status == CheckoutStatus.completed;
  bool get isProcessing => state.isProcessing;
  bool get hasError => state.status == CheckoutStatus.failed;
  String? get errorMessage => state.errorMessage;
}

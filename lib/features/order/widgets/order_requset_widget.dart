import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/address/controllers/address_controller.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/date_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class OrderRequestWidget extends StatefulWidget {
  final OrderModel orderModel;
  final int index;
  final Function onAccept;
  final Function onIgnore;

  const OrderRequestWidget({
    super.key,
    required this.orderModel,
    required this.index,
    required this.onAccept,
    required this.onIgnore,
  });

  @override
  State<OrderRequestWidget> createState() => _OrderRequestWidgetState();
}

class _OrderRequestWidgetState extends State<OrderRequestWidget>
    with TickerProviderStateMixin {
  static const Duration _responseDuration = Duration(seconds: 30);
  static const Duration _enterDuration = Duration(milliseconds: 300);

  late final AnimationController _enterController;
  late final AnimationController _countdownController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _expireTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: _enterDuration,
    );
    _countdownController = AnimationController(
      vsync: this,
      duration: _responseDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    );

    _enterController.forward();
    _countdownController.forward();
    _expireTimer = Timer(_responseDuration, _handleExpire);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _expireTimer?.cancel();
    _enterController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _handleExpire() {
    if (_isDisposed) return;
    Get.find<OrderController>().ignoreOrder(widget.index);
    widget.onIgnore();
  }

  void _handleIgnore() {
    _expireTimer?.cancel();
    Get.find<OrderController>().ignoreOrder(widget.index);
    widget.onIgnore();
  }

  void _handleAccept() {
    _expireTimer?.cancel();
    Get.find<OrderController>()
        .acceptOrder(widget.orderModel.id, widget.index, widget.orderModel)
        .then((success) {
      if (success) {
        widget.onAccept();
      }
    });
  }

  String _formatRemaining(Duration remaining) {
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final distance = Get.find<AddressController>().getRestaurantDistance(
      LatLng(
        double.parse(widget.orderModel.storeLat ?? '0'),
        double.parse(widget.orderModel.storeLng ?? '0'),
      ),
      customerLatLng: LatLng(
        double.parse(widget.orderModel.deliveryAddress?.latitude ?? '0'),
        double.parse(widget.orderModel.deliveryAddress?.longitude ?? '0'),
      ),
    );

    final double promoValue = widget.orderModel.dmTips ?? 0;
    final bool hasPromo = promoValue > 0;
    final bool isCashOnDelivery =
        widget.orderModel.paymentMethod == 'cash_on_delivery';

    final String scheduleAt = widget.orderModel.scheduleAt ?? '';
    final String deadline = scheduleAt.isNotEmpty
        ? DateConverterHelper.formatUtcTime(scheduleAt)
        : '';

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _countdownController,
          builder: (context, child) {
            final double progress = 1 - _countdownController.value;
            final Duration remaining = Duration(
              seconds:
                  (_responseDuration.inSeconds * progress).clamp(0, 30).round(),
            );
            final Color backgroundColor = Color.lerp(
                  const Color(0xFF2D2F3A),
                  const Color(0xFF1C1E26),
                  _countdownController.value,
                ) ??
                const Color(0xFF2D2F3A);

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Delivery',
                          style: robotoMedium.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _handleIgnore,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        PriceConverterHelper.convertPrice(
                          widget.orderModel.originalDeliveryCharge ?? 0,
                        ),
                        style: robotoBold.copyWith(
                          fontSize: 28,
                          color: Colors.white,
                        ),
                      ),
                      if (hasPromo) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${PriceConverterHelper.convertPrice(promoValue)}',
                            style: robotoBold.copyWith(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (deadline.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Entregar até $deadline',
                            style: robotoRegular.copyWith(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.route,
                    text:
                        'Distância total ${distance.toStringAsFixed(1)} km',
                  ),
                  if (isCashOnDelivery) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.attach_money,
                      text:
                          'Coletar ${PriceConverterHelper.convertPrice(widget.orderModel.orderAmount ?? 0)} em dinheiro',
                    ),
                  ],
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.store_mall_directory_outlined,
                    text: widget.orderModel.storeName ?? '',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: widget.orderModel.storeAddress ?? '',
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 6,
                            width: constraints.maxWidth * progress,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatRemaining(remaining),
                      style: robotoBold.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD200),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Aceitar pedido',
                        style: robotoBold.copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: robotoRegular.copyWith(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

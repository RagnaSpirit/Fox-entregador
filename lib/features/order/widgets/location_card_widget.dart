import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/address/controllers/address_controller.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';

import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';

import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

class LocationCardWidget extends StatefulWidget {
  final OrderModel orderModel;
  final OrderController orderController;
  final int index;
  final Function onTap;

  const LocationCardWidget({
    super.key,
    required this.orderModel,
    required this.orderController,
    required this.index,
    required this.onTap,
  });

  @override
  State<LocationCardWidget> createState() => _LocationCardWidgetState();
}

class _LocationCardWidgetState extends State<LocationCardWidget> {
  bool _arrivedAtStore = false;

  bool _canShowCustomerInfo() {
    final status = widget.orderModel.orderStatus ?? '';
    return _arrivedAtStore ||
        status == AppConstants.pickedUp ||
        status == AppConstants.delivered;
  }

  Future<void> _openExternalRoute() async {
    final String destinationLat = widget.orderModel.storeLat ??
        widget.orderModel.deliveryAddress?.latitude ??
        '0';
    final String destinationLng = widget.orderModel.storeLng ??
        widget.orderModel.deliveryAddress?.longitude ??
        '0';
    final String url =
        'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&mode=d';
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final double storeDistance = Get.find<AddressController>()
        .getRestaurantDistance(
      LatLng(
        double.parse(widget.orderModel.storeLat ?? '0'),
        double.parse(widget.orderModel.storeLng ?? '0'),
      ),
    );
    final bool isNearStore = storeDistance <= 0.1;
    final bool isCashOnDelivery =
        widget.orderModel.paymentMethod == 'cash_on_delivery';

    final String? customerName = _canShowCustomerInfo()
        ? widget.orderModel.deliveryAddress?.contactPersonName ??
            widget.orderModel.customer?.fName
        : null;
    final String? customerFullName = _canShowCustomerInfo()
        ? [
            widget.orderModel.customer?.fName,
            widget.orderModel.customer?.lName
          ]
            .where((value) => value != null && value!.isNotEmpty)
            .map((value) => value!)
            .join(' ')
        : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2F3A),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 28,
                      width: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD200),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.store_mall_directory_outlined,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.orderModel.storeName ?? '',
                        style: robotoBold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.orderModel.storeAddress ?? '',
                  style: robotoRegular.copyWith(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isCashOnDelivery)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Color(0xFFFFD200)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coletar ${PriceConverterHelper.convertPrice(widget.orderModel.orderAmount ?? 0)} em dinheiro do cliente',
                      style: robotoRegular.copyWith(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  height: 10,
                  width: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD200),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Inicie a rota manualmente até a loja',
                    style: robotoRegular.copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7A00),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Você só poderá confirmar "Cheguei na loja" se estiver a no máximo 100 metros do local.',
                    style: robotoRegular.copyWith(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_canShowCustomerInfo() &&
              (customerName != null || customerFullName != null))
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFFFFD200)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerFullName?.isNotEmpty == true
                          ? customerFullName!
                          : customerName ?? '',
                      style: robotoMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _openExternalRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD200),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Iniciar rota',
                      style: robotoBold.copyWith(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isNearStore
                        ? () {
                            setState(() {
                              _arrivedAtStore = true;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isNearStore
                          ? const Color(0xFF7A7F8C)
                          : Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Cheguei na loja',
                      style: robotoBold.copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }
}

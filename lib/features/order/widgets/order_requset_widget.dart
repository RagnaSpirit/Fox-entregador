import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/address/controllers/address_controller.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class OrderRequestWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final distance = Get.find<AddressController>().getRestaurantDistance(
      LatLng(
        double.parse(orderModel.storeLat ?? '0'),
        double.parse(orderModel.storeLng ?? '0'),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// VALOR + DISTÂNCIA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PriceConverterHelper.convertPrice(
                  orderModel.originalDeliveryCharge ?? 0,
                ),
                style: robotoBold.copyWith(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: robotoMedium.copyWith(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// LOJA
          Text(
            orderModel.storeName ?? '',
            style: robotoMedium.copyWith(fontSize: 16),
          ),

          const SizedBox(height: 4),

          /// CLIENTE
          Text(
            orderModel.deliveryAddress?.address ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 16),

          /// AÇÕES
          Row(
            children: [

              /// RECUSAR
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.find<OrderController>().ignoreOrder(index);
                    onIgnore();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Recusar',
                    style: robotoMedium.copyWith(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// ACEITAR
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.find<OrderController>()
                        .acceptOrder(orderModel.id, index, orderModel)
                        .then((success) {
                      if (success) {
                        onAccept();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Aceitar',
                    style: robotoBold.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

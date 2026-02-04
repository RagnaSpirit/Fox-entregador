import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/address/controllers/address_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';

import 'package:sixam_mart_delivery/helper/date_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';

import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

import 'package:sixam_mart_delivery/common/widgets/confirmation_dialog_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/features/order/screens/order_details_screen.dart';

class LocationCardWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool parcel = orderModel.orderType == 'parcel';

    final double restaurantDistance = Get.find<AddressController>()
        .getRestaurantDistance(
      LatLng(
        double.parse(parcel
            ? orderModel.deliveryAddress?.latitude ?? '0'
            : orderModel.storeLat ?? '0'),
        double.parse(parcel
            ? orderModel.deliveryAddress?.longitude ?? '0'
            : orderModel.storeLng ?? '0'),
      ),
    );

    final double restaurantToCustomerDistance =
    Get.find<AddressController>().getRestaurantDistance(
      LatLng(
        double.parse(parcel
            ? orderModel.deliveryAddress?.latitude ?? '0'
            : orderModel.storeLat ?? '0'),
        double.parse(parcel
            ? orderModel.deliveryAddress?.longitude ?? '0'
            : orderModel.storeLng ?? '0'),
      ),
      customerLatLng: LatLng(
        double.parse(parcel
            ? orderModel.receiverDetails?.latitude ?? '0'
            : orderModel.deliveryAddress?.latitude ?? '0'),
        double.parse(parcel
            ? orderModel.receiverDetails?.longitude ?? '0'
            : orderModel.deliveryAddress?.longitude ?? '0'),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// HEADER
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DistanceBlock(
                  value: restaurantDistance,
                  label: parcel
                      ? 'your_distance_from_sender'.tr
                      : 'your_distance_from_restaurant'.tr,
                ),
                Text(
                  '${DateConverterHelper.timeDistanceInMin(orderModel.createdAt!)} ${'mins_ago'.tr}',
                  style: robotoBold.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          /// SECOND DISTANCE
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: _DistanceBlock(
              value: restaurantToCustomerDistance,
              label: parcel
                  ? 'from_sender_to_receiver_distance'.tr
                  : 'from_customer_to_restaurant_distance'.tr,
            ),
          ),

          /// ACTION BAR (FIXED LOOK)
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .disabledColor
                  .withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(Dimensions.radiusDefault),
              ),
            ),
            child: Row(
              children: [

                /// EARNING
                Expanded(
                  child: (Get.find<SplashController>()
                      .configModel!
                      .showDmEarning! &&
                      Get.find<ProfileController>()
                          .profileModel!
                          .earnings ==
                          1)
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PriceConverterHelper.convertPrice(
                          orderModel.originalDeliveryCharge! +
                              orderModel.dmTips!,
                        ),
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                      Text(
                        orderModel.paymentMethod ==
                            'cash_on_delivery'
                            ? 'cod'.tr
                            : 'digitally_paid'.tr,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color:
                          Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  )
                      : const SizedBox(),
                ),

                /// BUTTONS
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.dialog(
                            ConfirmationDialogWidget(
                              icon: Images.warning,
                              title: 'are_you_sure_to_ignore'.tr,
                              description: parcel
                                  ? 'you_want_to_ignore_this_delivery'.tr
                                  : 'you_want_to_ignore_this_order'.tr,
                              onYesPressed: () {
                                if (Get.isSnackbarOpen) {
                                  Get.back();
                                }
                                orderController.ignoreOrder(index);
                                Get.back();
                                Get.back();
                                showCustomSnackBar(
                                  'order_ignored'.tr,
                                  isError: false,
                                );
                              },
                            ),
                            barrierDismissible: false,
                          ),
                          child: Text('ignore'.tr),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButtonWidget(
                          height: 40,
                          radius: Dimensions.radiusDefault,
                          buttonText: 'accept'.tr,
                          onPressed: () => Get.dialog(
                            ConfirmationDialogWidget(
                              icon: Images.warning,
                              title: 'are_you_sure_to_accept'.tr,
                              description: parcel
                                  ? 'you_want_to_accept_this_delivery'.tr
                                  : 'you_want_to_accept_this_order'.tr,
                              onYesPressed: () {
                                orderController
                                    .acceptOrder(
                                  orderModel.id,
                                  index,
                                  orderModel,
                                )
                                    .then((isSuccess) {
                                  if (isSuccess) {
                                    onTap();
                                    orderModel.orderStatus =
                                    (orderModel.orderStatus ==
                                        'pending' ||
                                        orderModel.orderStatus ==
                                            'confirmed')
                                        ? 'accepted'
                                        : orderModel.orderStatus;
                                    Get.toNamed(
                                      RouteHelper
                                          .getOrderDetailsRoute(
                                          orderModel.id),
                                      arguments: OrderDetailsScreen(
                                        orderId: orderModel.id,
                                        isRunningOrder: true,
                                        orderIndex: orderController
                                            .currentOrderList!
                                            .length -
                                            1,
                                        fromLocationScreen: true,
                                      ),
                                    );
                                  } else {
                                    orderController.getLatestOrders();
                                  }
                                });
                              },
                            ),
                            barrierDismissible: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceBlock extends StatelessWidget {
  final double value;
  final String label;

  const _DistanceBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeExtraSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .primaryColor
                .withOpacity(0.15),
            borderRadius:
            BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Text(
            '${value > 1000 ? '1000+' : value.toStringAsFixed(2)} ${'km_aprox'.tr}',
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).disabledColor,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/order/screens/order_location_screen.dart';
import 'package:sixam_mart_delivery/features/order/widgets/order_requset_widget.dart';

class OrderRequestScreen extends StatelessWidget {
  final VoidCallback onTap;

  const OrderRequestScreen({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(
      builder: (orderController) {
        if (orderController.latestOrderList != null &&
            orderController.latestOrderList!.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderController.latestOrderList!.length,
            itemBuilder: (context, index) {
              final orderModel = orderController.latestOrderList![index];
              return OrderRequestWidget(
                orderModel: orderModel,
                index: index,
                onAccept: () {
                  onTap();
                  Get.to(
                    () => OrderLocationScreen(
                      orderModel: orderModel,
                      orderController: orderController,
                      index: index,
                      onTap: () {},
                    ),
                  );
                },
                onIgnore: () {},
              );
            },
          );
        }

        return const Center(
          child: Text(
            'Sem pedidos',
            style: TextStyle(fontSize: 16),
          ),
        );
      },
    );
  }
}

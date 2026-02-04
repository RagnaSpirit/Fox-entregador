import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:sixam_mart_delivery/common/widgets/custom_alert_dialog_widget.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/dashboard/widgets/new_request_dialog_widget.dart';
import 'package:sixam_mart_delivery/features/disbursement/helper/disbursement_helper.dart';
import 'package:sixam_mart_delivery/features/home/screens/home_screen.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/order/screens/order_request_screen.dart';
import 'package:sixam_mart_delivery/features/order/screens/order_screen.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/profile/screens/profile_screen.dart';
import 'package:sixam_mart_delivery/helper/notification_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/main.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  final bool fromOrderDetails;

  const DashboardScreen({
    super.key,
    required this.pageIndex,
    this.fromOrderDetails = false,
  });

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  PageController? _pageController;
  int _pageIndex = 0;
  late List<Widget> _screens;

  final _channel = const MethodChannel('com.sixamtech/app_retain');
  late StreamSubscription _stream;

  final DisbursementHelper disbursementHelper = DisbursementHelper();
  bool _canExit = false;

  @override
  void initState() {
    super.initState();

    _pageIndex = widget.pageIndex;
    _pageController = PageController(initialPage: widget.pageIndex);

    _screens = [
      const HomeScreen(),

      /// TELA DE SOLICITAÇÕES (SEM PARÂMETRO INVENTADO)
      OrderRequestScreen(
        onTap: () => _setPage(0),
      ),

      const OrderScreen(),
      const ProfileScreen(),
    ];

    showDisbursementWarningMessage();
    Get.find<OrderController>().getLatestOrders();

    _stream = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String? type = message.data['body_loc_key'] ?? message.data['type'];
      String? orderID = message.data['title_loc_key'] ?? message.data['order_id'];
      bool isParcel = message.data['order_type'] == 'parcel_order';

      if (type != 'assign' &&
          type != 'new_order' &&
          type != 'message' &&
          type != 'order_request' &&
          type != 'order_status') {
        NotificationHelper.showNotification(
          message,
          flutterLocalNotificationsPlugin,
        );
      }

      if (type == 'new_order' || type == 'order_request') {
        Get.find<OrderController>().getCurrentOrders();
        Get.find<OrderController>().getLatestOrders();
        Get.dialog(
          NewRequestDialogWidget(
            isRequest: true,
            orderId: int.parse(message.data['order_id'].toString()),
            isParcel: isParcel,
            onTap: _navigateRequestPage,
          ),
        );
      } else if (type == 'assign' && orderID != null && orderID.isNotEmpty) {
        Get.dialog(
          NewRequestDialogWidget(
            isRequest: false,
            orderId: int.parse(orderID),
            isParcel: isParcel,
            onTap: () {
              Get.offAllNamed(
                RouteHelper.getOrderDetailsRoute(
                  int.parse(orderID),
                  fromNotification: true,
                ),
              );
            },
          ),
        );
      } else if (type == 'block') {
        Get.find<AuthController>().clearSharedData();
        Get.find<ProfileController>().stopLocationRecord();
        Get.offAllNamed(RouteHelper.getSignInRoute());
      }
    });
  }

  Future<void> showDisbursementWarningMessage() async {
    if (!widget.fromOrderDetails) {
      disbursementHelper.enableDisbursementWarningMessage(true);
    }
  }

  void _navigateRequestPage() {
    if (Get.find<ProfileController>().profileModel != null &&
        Get.find<ProfileController>().profileModel!.active == 1) {
      _setPage(1);
    } else {
      Get.dialog(
        CustomAlertDialogWidget(
          description: 'you_are_offline_now'.tr,
          onOkPressed: () => Get.back(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (_pageIndex != 0) {
          _setPage(0);
        } else {
          if (_canExit) {
            if (GetPlatform.isAndroid) {
              if (Get.find<ProfileController>().profileModel?.active == 1) {
                _channel.invokeMethod('sendToBackground');
              }
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'back_press_again_to_exit'.tr,
                style: const TextStyle(color: Colors.white),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF00C853),
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            ),
          );

          _canExit = true;
          Timer(const Duration(seconds: 2), () => _canExit = false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        bottomNavigationBar: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            children: [
              _BottomNavIcon(
                icon: Icons.home_outlined,
                isSelected: _pageIndex == 0,
                onTap: () => _setPage(0),
              ),
              _BottomNavIcon(
                icon: Icons.list_alt_outlined,
                isSelected: _pageIndex == 2,
                onTap: () => _setPage(2),
              ),
            ],
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
      ),
    );
  }

  void _setPage(int pageIndex) {
    setState(() {
      _pageController!.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });
  }
}

class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Icon(
            icon,
            size: 26,
            color: isSelected ? const Color(0xFF1F2A37) : Colors.black54,
          ),
        ),
      ),
    );
  }
}

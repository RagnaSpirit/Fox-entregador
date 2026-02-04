import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sixam_mart_delivery/common/widgets/confirmation_dialog_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:sixam_mart_delivery/features/address/controllers/address_controller.dart';
import 'package:sixam_mart_delivery/features/order/screens/order_request_screen.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/common/controllers/theme_controller.dart';
import 'package:sixam_mart_delivery/helper/map_style_helper.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_confirmation_bottom_sheet.dart';
import 'package:sixam_mart_delivery/features/refer_and_earn/screens/refer_and_earn_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  String? _darkMapStyle;
  String? _lightMapStyle;
  late final ThemeController _themeController;

  bool mapVisible = true;
  bool _alertPlayed = false;

  Timer? _searchingTimer;
  String searchingText = 'Buscando entregas';

  late AnimationController _cardAnimController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  late AnimationController _requestTimerController;
  Timer? _requestCountdownTimer;
  int _remainingSeconds = _requestTimeoutSeconds;
  int? _activeOrderId;

  static const int _requestTimeoutSeconds = 30;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-23.550520, -46.633308),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    Get.find<ProfileController>().getProfile();

    _themeController = Get.find<ThemeController>();
    _themeController.addListener(_handleThemeChange);
    _loadMapStyles();

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimController,
        curve: Curves.easeOut,
      ),
    );

    _requestTimerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _requestTimeoutSeconds),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _expireActiveOrder();
        }
      });
  }

  @override
  void dispose() {
    _searchingTimer?.cancel();
    _requestCountdownTimer?.cancel();
    _cardAnimController.dispose();
    _requestTimerController.dispose();
    super.dispose();
  }

  void _syncSearchingStatus(bool isOnline) {
    if (isOnline && _searchingTimer == null) {
      _startSearchingAnimation();
    } else if (!isOnline && _searchingTimer != null) {
      _stopSearching();
    }
  }

  void _startSearchingAnimation() {
    _searchingTimer?.cancel();
    searchingText = 'Buscando entregas';
    _searchingTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) {
        setState(() {
          if (searchingText.endsWith('...')) {
            searchingText = 'Buscando entregas';
          } else {
            searchingText += '.';
          }
        });
      },
    );
  }

  void _stopSearching() {
    _searchingTimer?.cancel();
    _searchingTimer = null;
    searchingText = 'Buscando entregas';
  }

  void _playAlertOnce() {
    if (_alertPlayed) return;
    _alertPlayed = true;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  void _applyMapStyle(bool isDarkMode) {
    _mapController?.setMapStyle(MapStyleHelper.styleFor(isDarkMode));
  }

  void _startRequestTimer(OrderModel order) {
    _requestCountdownTimer?.cancel();
    _requestTimerController.reset();

    _activeOrderId = order.id;
    _remainingSeconds = _requestTimeoutSeconds;
    _requestTimerController.forward();
    _requestCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;
        setState(() {
          _remainingSeconds = max(0, _remainingSeconds - 1);
        });
      },
    );
  }

  void _resetRequestTimer() {
    _requestCountdownTimer?.cancel();
    _requestCountdownTimer = null;
    _requestTimerController.reset();
    _remainingSeconds = _requestTimeoutSeconds;
    _activeOrderId = null;
  }

  void _expireActiveOrder() {
    final controller = Get.find<OrderController>();
    if (controller.latestOrderList != null && controller.latestOrderList!.isNotEmpty) {
      final index = controller.latestOrderList!
          .indexWhere((order) => order.id == _activeOrderId);
      if (index != -1) {
        controller.ignoreOrder(index);
      }
    }
    _resetRequestTimer();
  }

  Future<void> _acceptOrder(OrderModel order) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    final controller = Get.find<OrderController>();
    final index = controller.latestOrderList?.indexWhere((item) => item.id == order.id) ?? -1;
    if (index == -1) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      return;
    }

    final success = await controller.acceptOrder(order.id, index, order);
    _resetRequestTimer();
    if (success) {
      Get.toNamed(RouteHelper.getRunningOrderRoute());
    }
  }

  void _declineOrder() {
    final controller = Get.find<OrderController>();
    if (controller.latestOrderList != null && controller.latestOrderList!.isNotEmpty) {
      controller.ignoreOrder(0);
    }
    _resetRequestTimer();
  }

  void _toggleOnline(ProfileController profileController, OrderController orderController) {
    final bool isOnline = profileController.profileModel?.active == 1;

    if (isOnline && (orderController.currentOrderList?.isNotEmpty ?? false)) {
      showCustomBottomSheet(
        child: CustomConfirmationBottomSheet(
          title: 'you_cant_go_offline'.tr,
          description: 'you_can_not_go_offline_now'.tr,
          buttonWidget: Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('okay'.tr),
            ),
          ),
        ),
      );
      return;
    }

    Get.dialog(
      ConfirmationDialogWidget(
        icon: Images.warning,
        title: isOnline ? 'Desconectar' : 'Conectar',
        description: isOnline
            ? 'Deseja ficar offline agora?'
            : 'Deseja começar a receber entregas?',
        onYesPressed: () => profileController.updateActiveStatus(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _DriverDrawer(),
      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          final bool isOnline = profileController.profileModel?.active == 1;
          _syncSearchingStatus(isOnline);
          return Stack(
            children: [
              if (mapVisible)
                GetBuilder<ThemeController>(
                  builder: (themeController) {
                    _applyMapStyle(themeController.darkTheme);
                    return GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _applyMapStyle(themeController.darkTheme);
                      },
                    );
                  },
                ),

              /// TOPO
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) {
                          return GestureDetector(
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu, color: Colors.white),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _toggleOnline(
                          profileController,
                          Get.find<OrderController>(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD400),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            isOnline ? 'Desconectar' : 'Conectar',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// SALDO
              Positioned(
                top: 90,
                left: 16,
                right: 16,
                child: GetBuilder<ProfileController>(
                  builder: (controller) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 20,
                            color: Color(0x22000000),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Seu saldo disponível',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  PriceConverterHelper.convertPrice(
                                    controller.profileModel?.balance ?? 0,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ganhe mais ao entregar rápido e bem!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    );
                  },
                ),
              ),

              /// STATUS
              Positioned(
                left: 16,
                right: 16,
                bottom: 92,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isOnline ? 1 : 0,
                  child: Row(
                    children: [
                      Text(
                        searchingText,
                        style: const TextStyle(
                          color: Color(0xFFFFD400),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// BOTÃO +
              Positioned(
                right: 18,
                bottom: 120,
                child: GetBuilder<OrderController>(
                  builder: (orderController) {
                    final int available = orderController.latestOrderList?.length ?? 0;
                    return GestureDetector(
                      onTap: () {
                        Get.to(() => OrderRequestScreen(onTap: () => Get.back()));
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD400),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, size: 30),
                          ),
                          if (available > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  available.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              /// 📦 CARD ENTREGA
              GetBuilder<OrderController>(
                builder: (controller) {
                  if (controller.latestOrderList == null ||
                      controller.latestOrderList!.isEmpty) {
                    _alertPlayed = false;
                    _resetRequestTimer();
                    return const SizedBox();
                  }

                  final order = controller.latestOrderList!.first;

                  if (_activeOrderId != order.id) {
                    _startRequestTimer(order);
                  }

                  _playAlertOnce();
                  _cardAnimController.forward();

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _requestTimerController,
                          builder: (context, child) {
                            final opacity = 0.2 + 0.4 * _requestTimerController.value;
                            return Container(
                              color: Colors.black.withValues(alpha: opacity),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 90,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: _DeliveryRequestCard(
                              order: order,
                              remainingSeconds: _remainingSeconds,
                              progress: 1 - _requestTimerController.value,
                              onAccept: () => _acceptOrder(order),
                              onDecline: _declineOrder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DriverDrawer extends StatelessWidget {
  const _DriverDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: GetBuilder<ProfileController>(
          builder: (profileController) {
            final profile = profileController.profileModel;
            final config = Get.find<SplashController>().configModel;
            final bool showReferAndEarn = profile != null && profile.earnings == 1
                && (config?.dmReferralData?.dmReferalStatus == true || (profile.referalEarning ?? 0) > 0);
            final bool showPromotions = config?.dmLoyalityPointData?.dmLoyalityPointStatus == true;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: profile?.imageFullUrl?.isNotEmpty == true
                          ? NetworkImage(profile!.imageFullUrl!)
                          : null,
                      child: profile?.imageFullUrl?.isNotEmpty == true
                          ? null
                          : const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile?.fName ?? ''} ${profile?.lName ?? ''}'.trim(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFFD400), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${profile?.avgRating?.toStringAsFixed(1) ?? '0.0'}/5.0',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ganhos',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        PriceConverterHelper.convertPrice(profile?.balance ?? 0),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DrawerItem(
                  icon: Icons.attach_money,
                  label: 'Ganhos',
                  onTap: () => Get.toNamed(RouteHelper.getMyEarningRoute()),
                ),
                _DrawerItem(
                  icon: Icons.card_giftcard,
                  label: 'Recompensas',
                  onTap: () => Get.toNamed(RouteHelper.getMyAccountRoute()),
                ),
                if (showPromotions)
                  _DrawerItem(
                    icon: Icons.local_offer,
                    label: 'Promoções',
                    onTap: () => Get.toNamed(RouteHelper.getMyAccountRoute()),
                  ),
                if (showReferAndEarn)
                  _DrawerItem(
                    icon: Icons.person_add_alt_1,
                    label: 'Indique um amigo',
                    onTap: () => Get.to(() => const ReferAndEarnScreen()),
                  ),
                _DrawerItem(
                  icon: Icons.directions_bike,
                  label: 'Corridas',
                  onTap: () => Get.toNamed(RouteHelper.getRunningOrderRoute()),
                ),
                _DrawerItem(
                  icon: Icons.notifications_none,
                  label: 'Notificações',
                  onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                ),
                _DrawerItem(
                  icon: Icons.headset_mic_outlined,
                  label: 'Central de Ajuda',
                  onTap: () => Get.toNamed(RouteHelper.getConversationListRoute()),
                ),
                _DrawerItem(
                  icon: Icons.school_outlined,
                  label: 'Central de Educação',
                  onTap: () => showCustomSnackBar('Em breve', isError: false),
                ),
                _DrawerItem(
                  icon: Icons.emoji_events_outlined,
                  label: 'Score & Desempenho',
                  onTap: () => Get.toNamed(RouteHelper.getScorePerformanceRoute()),
                ),
                const SizedBox(height: 20),
                Text(
                  'v1.0',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF9A7B00)),
      title: Text(label),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }
}

/// 🔥 CARD FINAL
class _DeliveryRequestCard extends StatelessWidget {
  final OrderModel order;
  final int remainingSeconds;
  final double progress;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _DeliveryRequestCard({
    required this.order,
    required this.remainingSeconds,
    required this.progress,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final earnings =
        (order.originalDeliveryCharge ?? 0) + (order.dmTips ?? 0);
    final distance = Get.find<AddressController>().getRestaurantDistance(
      LatLng(
        double.tryParse(order.storeLat ?? '') ?? 0,
        double.tryParse(order.storeLng ?? '') ?? 0,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            color: Color(0x44000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.delivery_dining, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Delivery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDecline,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            PriceConverterHelper.convertPrice(earnings),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Valor base',
            value: PriceConverterHelper.convertPrice(order.originalDeliveryCharge ?? 0),
          ),
          if ((order.dmTips ?? 0) > 0)
            _InfoRow(
              label: 'Valor promocional',
              value: '+${PriceConverterHelper.convertPrice(order.dmTips ?? 0)}',
              highlight: true,
            ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Tipo', value: order.moduleType ?? 'Food'),
          _InfoRow(
            label: 'Distância',
            value: '${distance.toStringAsFixed(1)} km',
          ),
          _InfoRow(label: 'Prazo', value: order.scheduleAt ?? 'Agora'),
          _InfoRow(label: 'Loja', value: order.storeName ?? '-'),
          _InfoRow(
            label: 'Bairro',
            value: order.deliveryAddress?.address ?? '-',
          ),
          if (order.paymentMethod == 'cash_on_delivery')
            _InfoRow(
              label: 'Dinheiro',
              value: PriceConverterHelper.convertPrice(order.orderAmount ?? 0),
              highlight: true,
            ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0, 1),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD400),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Aceitar pedido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatSeconds(remainingSeconds),
                style: const TextStyle(
                  color: Color(0xFFFFD400),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatSeconds(int seconds) {
    final int clamped = seconds.clamp(0, _HomeScreenState._requestTimeoutSeconds);
    return '00:${clamped.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlight ? const Color(0xFFFFD400) : Colors.white,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

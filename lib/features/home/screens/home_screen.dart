import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sixam_mart_delivery/common/controllers/theme_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/profile/screens/profile_screen.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/order/screens/order_screen.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';

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

  bool isOnline = false;
  bool mapVisible = true;
  bool _alertPlayed = false;

  Timer? _searchingTimer;
  String searchingText = 'Buscando';

  late AnimationController _cardAnimController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-23.550520, -46.633308),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _searchingTimer?.cancel();
    _themeController.removeListener(_handleThemeChange);
    _cardAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyles() async {
    _lightMapStyle = await rootBundle.loadString('assets/map_light.json');
    _darkMapStyle = await rootBundle.loadString('assets/map_dark.json');
    _applyMapStyle();
  }

  void _handleThemeChange() {
    _applyMapStyle();
  }

  void _applyMapStyle() {
    final controller = _mapController;
    if (controller == null) return;
    final style = Get.isDarkMode ? _darkMapStyle : _lightMapStyle;
    if (style == null) return;
    controller.setMapStyle(style);
  }

  void toggleOnline() {
    if (isOnline) {
      _stopSearching();
    } else {
      isOnline = true;
      _startSearchingAnimation();
    }
    setState(() {});
  }

  void _startSearchingAnimation() {
    _searchingTimer?.cancel();
    searchingText = 'Buscando';
    _searchingTimer = Timer.periodic(
      const Duration(milliseconds: 700),
          (_) {
        setState(() {
          if (searchingText.endsWith('...')) {
            searchingText = 'Buscando';
          } else {
            searchingText += '.';
          }
        });
      },
    );
  }

  void _stopSearching() {
    _searchingTimer?.cancel();
    searchingText = 'Buscando';
    isOnline = false;
  }

  void _playAlertOnce() {
    if (_alertPlayed) return;
    _alertPlayed = true;
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (mapVisible)
            GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _applyMapStyle();
              },
            ),

          /// TOPO
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.to(() => const ProfileScreen()),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: GetBuilder<ProfileController>(
                        builder: (controller) {
                          return Text(
                            PriceConverterHelper.convertPrice(
                              controller.profileModel?.balance ?? 0,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// RODAPÉ
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FooterButton(
                      icon: mapVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      onTap: () =>
                          setState(() => mapVisible = !mapVisible),
                    ),
                    GestureDetector(
                      onTap: toggleOnline,
                      child: Container(
                        height: 55,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.orange : Colors.green,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Center(
                          child: Text(
                            isOnline ? searchingText : 'Conectar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _FooterButton(
                      icon: Icons.list_alt,
                      onTap: () => Get.to(() => const OrderScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// 📦 CARD ENTREGA
          GetBuilder<OrderController>(
            builder: (controller) {
              if (controller.currentOrderList == null ||
                  controller.currentOrderList!.isEmpty) {
                _alertPlayed = false;
                return const SizedBox();
              }

              final order = controller.currentOrderList!.first;

              if (isOnline) _stopSearching();

              _playAlertOnce();
              _cardAnimController.forward();

              return Positioned(
                left: 16,
                right: 16,
                bottom: 90,
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _DeliveryRequestCard(order: order),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 🔥 CARD FINAL
class _DeliveryRequestCard extends StatelessWidget {
  final OrderModel order;
  const _DeliveryRequestCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final earnings =
        (order.originalDeliveryCharge ?? 0) + (order.dmTips ?? 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            color: Color(0x22000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// TOPO
          Row(
            children: const [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF2F80ED),
                child: Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Nova entrega',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// VALOR
          Text(
            PriceConverterHelper.convertPrice(earnings),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// ORIGEM
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.circle,
                size: 10,
                color: Color(0xFFFFC107),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.storeName ?? 'Origem',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// DESTINO
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.circle,
                size: 10,
                color: Color(0xFF2F80ED),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.deliveryAddress?.address ?? 'Destino',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// BOTÃO
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Get.find<OrderController>()
                    .acceptOrder(order.id, 0, order);

                Get.to(() => const OrderScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FooterButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        width: 45,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}

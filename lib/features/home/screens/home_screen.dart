import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/profile/screens/profile_screen.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/order/screens/order_screen.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  LatLng? _currentLatLng;
  double _currentHeading = 0;
  BitmapDescriptor? _deliveryMarker;
  final Set<Marker> _mapMarkers = {};

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

    _loadMarker();
    _startLocationStream();

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
    _positionStream?.cancel();
    _cardAnimController.dispose();
    super.dispose();
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

  void _playAlertFeedback() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  Future<void> _loadMarker() async {
    _deliveryMarker = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      Images.deliveryManMarker,
    );
    _updateMarker();
  }

  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      if (!mounted) return;
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _currentHeading = position.heading;
        _updateMarker();
      });
    });
  }

  void _updateMarker() {
    if (_currentLatLng == null) return;
    _mapMarkers
      ..clear()
      ..add(
        Marker(
          markerId: const MarkerId('delivery_boy'),
          position: _currentLatLng!,
          rotation: _currentHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: _deliveryMarker ?? BitmapDescriptor.defaultMarker,
        ),
      );
  }

  void _animateToCurrentLocation() {
    if (_currentLatLng == null || _mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(_currentLatLng!),
    );
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
              onMapCreated: (controller) => _mapController = controller,
              markers: _mapMarkers,
            ),

          /// TOPO
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
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
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 16,
                            color: Color(0x1A000000),
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: GetBuilder<ProfileController>(
                        builder: (controller) {
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Saldo do dia',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      controller.showBalance
                                          ? PriceConverterHelper.convertPrice(
                                        controller.profileModel?.balance ?? 0,
                                      )
                                          : 'XXXXXX',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: controller.toggleBalanceVisibility,
                                child: Icon(
                                  controller.showBalance
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// BOTÕES DIREITA
          Positioned(
            top: 150,
            right: 16,
            child: Column(
              children: [
                _MapActionButton(
                  icon: Icons.my_location,
                  onTap: _animateToCurrentLocation,
                ),
                const SizedBox(height: 12),
                _MapActionButton(
                  icon: Icons.warning_amber_rounded,
                  onTap: _playAlertFeedback,
                ),
                const SizedBox(height: 12),
                _MapActionButton(
                  icon: mapVisible
                      ? Icons.layers_outlined
                      : Icons.layers_clear,
                  onTap: () => setState(() => mapVisible = !mapVisible),
                ),
              ],
            ),
          ),

          /// RODAPÉ
          Positioned(
            left: 16,
            bottom: 24,
            child: SafeArea(
              child: _MapActionButton(
                icon: Icons.list_alt,
                onTap: () => Get.to(() => const OrderScreen()),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: toggleOnline,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFFFFA726) : const Color(0xFF2BB673),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 20,
                          color: Color(0x33000000),
                          offset: Offset(0, 10),
                        ),
                      ],
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

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              color: Colors.black.withOpacity(0.12),
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }
}

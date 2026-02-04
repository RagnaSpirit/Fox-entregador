import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/common/controllers/theme_controller.dart';
import 'package:sixam_mart_delivery/helper/map_style_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/features/order/widgets/location_card_widget.dart';

class OrderLocationScreen extends StatefulWidget {
  final OrderModel orderModel;
  final OrderController orderController;
  final int index;
  final Function onTap;

  const OrderLocationScreen({
    super.key,
    required this.orderModel,
    required this.orderController,
    required this.index,
    required this.onTap,
  });

  @override
  State<OrderLocationScreen> createState() => _OrderLocationScreenState();
}

class _OrderLocationScreenState extends State<OrderLocationScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = HashSet<Marker>();

  /// 🔵 BUSCANDO... UI
  Timer? _searchTimer;
  String _searchText = 'Buscando';

  @override
  void initState() {
    super.initState();
    _startSearchingAnimation();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _startSearchingAnimation() {
    _searchTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      setState(() {
        if (_searchText.endsWith('...')) {
          _searchText = 'Buscando';
        } else {
          _searchText += '.';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool parcel = widget.orderModel.orderType == 'parcel';

    /// 🔴 REGRA VISUAL
    final bool isSearching = widget.orderModel.id == null;

    return Scaffold(
      appBar: CustomAppBarWidget(title: 'order_location'.tr),
      body: SafeArea(
        child: Stack(
          children: [
            GetBuilder<ThemeController>(
              builder: (themeController) {
                _controller?.setMapStyle(MapStyleHelper.styleFor(themeController.darkTheme));
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      double.parse(widget.orderModel.deliveryAddress?.latitude ?? '0'),
                      double.parse(widget.orderModel.deliveryAddress?.longitude ?? '0'),
                    ),
                    zoom: 16,
                  ),
                  minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                  zoomControlsEnabled: false,
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                    _controller?.setMapStyle(MapStyleHelper.styleFor(themeController.darkTheme));
                    setMarker(widget.orderModel, parcel);
                  },
                );
              },
            ),

            /// 🟢 OVERLAY BUSCANDO...
            if (isSearching)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _searchText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

            /// 📦 CARD DA ENTREGA
            if (!isSearching)
              Positioned(
                bottom: Dimensions.paddingSizeSmall,
                left: Dimensions.paddingSizeSmall,
                right: Dimensions.paddingSizeSmall,
                child: LocationCardWidget(
                  orderModel: widget.orderModel,
                  orderController: widget.orderController,
                  onTap: widget.onTap,
                  index: widget.index,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void setMarker(OrderModel orderModel, bool parcel) async {
    try {
      final Uint8List destinationImageData =
      await convertAssetToUnit8List(Images.customerMarker, width: 100);
      final Uint8List restaurantImageData =
      await convertAssetToUnit8List(
        parcel ? Images.userMarker : Images.restaurantMarker,
        width: parcel ? 70 : 100,
      );
      final Uint8List deliveryBoyImageData =
      await convertAssetToUnit8List(Images.yourMarker, width: 100);

      if (_controller == null) return;

      final double deliveryLat = double.parse(orderModel.deliveryAddress?.latitude ?? '0');
      final double deliveryLng = double.parse(orderModel.deliveryAddress?.longitude ?? '0');
      final double storeLat = double.parse(orderModel.storeLat ?? '0');
      final double storeLng = double.parse(orderModel.storeLng ?? '0');
      final double receiverLat = double.parse(orderModel.receiverDetails?.latitude ?? '0');
      final double receiverLng = double.parse(orderModel.receiverDetails?.longitude ?? '0');
      final double deliveryManLat =
          Get.find<ProfileController>().recordLocationBody?.latitude ?? 0;
      final double deliveryManLng =
          Get.find<ProfileController>().recordLocationBody?.longitude ?? 0;

      LatLngBounds bounds;

      if (parcel) {
        bounds = LatLngBounds(
          southwest: LatLng(
            min(deliveryLat, min(receiverLat, deliveryManLat)),
            min(deliveryLng, min(receiverLng, deliveryManLng)),
          ),
          northeast: LatLng(
            max(deliveryLat, max(receiverLat, deliveryManLat)),
            max(deliveryLng, max(receiverLng, deliveryManLng)),
          ),
        );
      } else {
        bounds = LatLngBounds(
          southwest: LatLng(
            min(deliveryLat, min(storeLat, deliveryManLat)),
            min(deliveryLng, min(storeLng, deliveryManLng)),
          ),
          northeast: LatLng(
            max(deliveryLat, max(storeLat, deliveryManLat)),
            max(deliveryLng, max(storeLng, deliveryManLng)),
          ),
        );
      }

      _controller!.moveCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      _markers.clear();

      if (orderModel.deliveryAddress != null) {
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(deliveryLat, deliveryLng),
          icon: BitmapDescriptor.bytes(destinationImageData),
        ));
      }

      if (parcel && orderModel.receiverDetails != null) {
        _markers.add(Marker(
          markerId: const MarkerId('receiver'),
          position: LatLng(receiverLat, receiverLng),
          icon: BitmapDescriptor.bytes(restaurantImageData),
        ));
      }

      if (!parcel && orderModel.storeLat != null && orderModel.storeLng != null) {
        _markers.add(Marker(
          markerId: const MarkerId('store'),
          position: LatLng(storeLat, storeLng),
          icon: BitmapDescriptor.bytes(restaurantImageData),
        ));
      }

      _markers.add(Marker(
        markerId: const MarkerId('delivery_boy'),
        position: LatLng(deliveryManLat, deliveryManLng),
        icon: BitmapDescriptor.bytes(deliveryBoyImageData),
      ));

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting markers: $e');
      }
    }
  }

  Future<Uint8List> convertAssetToUnit8List(String imagePath, {int width = 50}) async {
    ByteData data = await rootBundle.load(imagePath);
    Codec codec = await instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    FrameInfo fi = await codec.getNextFrame();
    ByteData? byteData = await fi.image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

import 'package:sixam_mart_delivery/features/profile/domain/models/profile_model.dart';

class ScoreHelper {
  static double calculateScore(ProfileModel? profile) {
    final double rating = (profile?.avgRating ?? 0).clamp(0, 5);
    final int orders = profile?.orderCount ?? 0;
    final int weekOrders = profile?.thisWeekOrderCount ?? 0;

    final double ratingPart = (rating / 5) * 0.6;
    final double volumePart = (orders / 200).clamp(0, 1) * 0.25;
    final double recentPart = (weekOrders / 50).clamp(0, 1) * 0.15;

    return ((ratingPart + volumePart + recentPart) * 5).clamp(0, 5);
  }
}

import 'package:wa3_core/wa3_core.dart';

import '../../common/domain/live.dart';

class RiderProfile {
  const RiderProfile({required this.name, required this.phone, required this.lang});
  final String name;
  final String phone;
  final String lang;

  factory RiderProfile.fromJson(Map<String, dynamic> m) =>
      RiderProfile(name: (m['name'] ?? '').toString(), phone: (m['phone'] ?? '').toString(), lang: (m['lang'] ?? 'ar').toString());
}

abstract class ProfileRepository {
  /// The signed-in rider's profile (riders/{uid}); null when not registered.
  Stream<Live<RiderProfile?>> watch();

  /// `registerRider` command.
  Future<void> register({required String name, required String lang, required IntentKey key});
}

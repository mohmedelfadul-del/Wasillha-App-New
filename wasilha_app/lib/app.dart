import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'theme/tokens.dart';

// Onboarding & auth
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/onboarding/otp_screen.dart';
import 'screens/onboarding/role_screen.dart';
// Rider
import 'screens/rider/home_screen.dart';
import 'screens/rider/search_screen.dart';
import 'screens/rider/booking_screen.dart';
import 'screens/rider/offer_screen.dart';
import 'screens/rider/tracking_screen.dart';
import 'screens/rider/complete_screen.dart';
import 'screens/rider/food_screen.dart';
import 'screens/rider/parcel_screen.dart';
// Account
import 'screens/account/wallet_screen.dart';
import 'screens/account/topup_screen.dart';
import 'screens/account/history_screen.dart';
import 'screens/account/notifications_screen.dart';
import 'screens/account/saved_screen.dart';
import 'screens/account/settings_screen.dart';
import 'screens/account/sos_screen.dart';
// Driver & store
import 'screens/driver/driver_home_screen.dart';
import 'screens/driver/driver_requests_screen.dart';
import 'screens/driver/driver_earnings_screen.dart';
import 'screens/driver/driver_delivery_screen.dart';
import 'screens/store/store_screen.dart';

/// Route table — names match the prototype's screen ids.
final Map<String, WidgetBuilder> routes = {
  'splash': (_) => const SplashScreen(),
  'onboarding': (_) => const OnboardingScreen(),
  'login': (_) => const LoginScreen(),
  'otp': (_) => const OTPScreen(),
  'role': (_) => const RoleScreen(),
  'home': (_) => const HomeScreen(),
  'search': (_) => const SearchScreen(),
  'booking': (_) => const BookingScreen(),
  'offer': (_) => const OfferScreen(),
  'food': (_) => const FoodScreen(),
  'parcel': (_) => const ParcelScreen(),
  'tracking': (_) => const TrackingScreen(),
  'complete': (_) => const CompleteScreen(),
  'wallet': (_) => const WalletScreen(),
  'topup': (_) => const TopupScreen(),
  'history': (_) => const HistoryScreen(),
  'notifications': (_) => const NotificationsScreen(),
  'saved': (_) => const SavedScreen(),
  'settings': (_) => const SettingsScreen(),
  'sos': (_) => const SOSScreen(),
  'driverHome': (_) => const DriverHomeScreen(),
  'driverRequests': (_) => const DriverRequestsScreen(),
  'driverEarnings': (_) => const DriverEarningsScreen(),
  'driverDelivery': (_) => const DriverDeliveryScreen(),
  'store': (_) => const StoreScreen(),
};

/// Screens that cross-fade instead of sliding (tab roots / full-bleed).
const _fadeRoutes = {'splash', 'home', 'wallet', 'history', 'settings', 'driverHome', 'store', 'sos'};

class WasilhaApp extends StatelessWidget {
  const WasilhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      title: 'Wasilha',
      debugShowCheckedModeBanner: false,
      theme: W.theme(s.accent, arabic: s.ar),
      locale: Locale(s.lang),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: 'splash',
      onGenerateRoute: (settings) {
        final b = routes[settings.name] ?? routes['home']!;
        if (_fadeRoutes.contains(settings.name)) {
          return PageRouteBuilder(
            settings: settings,
            transitionDuration: const Duration(milliseconds: 260),
            pageBuilder: (c, _, _) => b(c),
            transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
          );
        }
        return MaterialPageRoute(settings: settings, builder: b);
      },
    );
  }
}

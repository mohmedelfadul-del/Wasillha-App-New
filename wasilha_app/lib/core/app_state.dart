import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backend.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../theme/tokens.dart';

/// App-wide UI settings (the old "Tweaks" panel) plus the in-progress
/// booking draft. Persisted settings: language, accent, glass, card
/// layout, map style.
class AppState extends ChangeNotifier {
  AppState(this.backend, this._prefs) {
    lang = _prefs.getString('lang') ?? 'en';
    accent = Color(_prefs.getInt('accent') ?? W.defaultAccent.toARGB32());
    glass = _prefs.getDouble('glass') ?? 15;
    cardLayout = _prefs.getString('cardLayout') ?? 'pairs';
    mapStyle = _prefs.getString('mapStyle') ?? 'illustrated';
    onboarded = _prefs.getBool('onboarded') ?? false;
  }

  final WasilhaBackend backend;
  final SharedPreferences _prefs;

  late String lang;
  late Color accent;
  late double glass;

  /// pairs | grid | row
  late String cardLayout;

  /// white | dark | illustrated
  late String mapStyle;
  late bool onboarded;

  bool get ar => lang == 'ar';
  TextDirection get dir => ar ? TextDirection.rtl : TextDirection.ltr;

  /// Pick the English or Arabic string.
  String t(String en, String arText) => ar ? arText : en;

  void setLang(String v) {
    lang = v;
    _prefs.setString('lang', v);
    notifyListeners();
  }

  void setAccent(Color c) {
    accent = c;
    _prefs.setInt('accent', c.toARGB32());
    notifyListeners();
  }

  void setGlass(double v) {
    glass = v;
    _prefs.setDouble('glass', v);
    notifyListeners();
  }

  void setCardLayout(String v) {
    cardLayout = v;
    _prefs.setString('cardLayout', v);
    notifyListeners();
  }

  void setMapStyle(String v) {
    mapStyle = v;
    _prefs.setString('mapStyle', v);
    notifyListeners();
  }

  void setOnboarded() {
    onboarded = true;
    _prefs.setBool('onboarded', true);
  }

  // ── Booking draft ─────────────────────────────────────────
  ServiceType service = ServiceType.car;
  Place pickup = Catalog.defaultPickup;
  Place? dropoff;
  String payment = 'wallet';

  /// Trip currently being bid on / tracked by the rider.
  String? activeTripId;

  /// Order placed from the food flow.
  String? activeOrderId;

  void chooseService(ServiceType s) {
    service = s;
    notifyListeners();
  }

  void setPickup(Place p) {
    pickup = p;
    notifyListeners();
  }

  void setDropoff(Place p) {
    dropoff = p;
    notifyListeners();
  }

  void setPayment(String p) {
    payment = p;
    notifyListeners();
  }

  void setActiveTrip(String? id) {
    activeTripId = id;
    notifyListeners();
  }

  int suggestedFare([ServiceType? s]) {
    final d = dropoff;
    final svc = s ?? service;
    if (d == null) return svc.base;
    return svc.fareFor(pickup.kmTo(d));
  }
}

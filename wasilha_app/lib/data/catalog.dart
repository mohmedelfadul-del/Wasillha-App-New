import 'models.dart';

/// Static reference data: well-known places in greater Khartoum used by
/// search, and the restaurants shown in the food flow. A production build
/// would swap the place list for a geocoding / Places API.
class Catalog {
  Catalog._();

  static const defaultPickup = Place(
    id: 'riyadh',
    name: 'Riyadh District',
    nameAr: 'حي الرياض',
    area: 'Khartoum',
    lat: 15.5776,
    lng: 32.5634,
  );

  static const places = <Place>[
    defaultPickup,
    Place(id: 'afra', name: 'Afra Mall', nameAr: 'عفراء مول', area: 'Arkaweet', lat: 15.5512, lng: 32.5640),
    Place(id: 'airport', name: 'Khartoum International Airport', nameAr: 'مطار الخرطوم الدولي', area: 'Khartoum', lat: 15.5895, lng: 32.5532),
    Place(id: 'uofk', name: 'University of Khartoum', nameAr: 'جامعة الخرطوم', area: 'Khartoum Center', lat: 15.6031, lng: 32.5339),
    Place(id: 'corinthia', name: 'Corinthia Hotel', nameAr: 'فندق كورنثيا', area: 'Al Mogran', lat: 15.6100, lng: 32.5170),
    Place(id: 'mogran', name: 'Al Mogran — Nile confluence', nameAr: 'المقرن', area: 'Khartoum', lat: 15.6178, lng: 32.5087),
    Place(id: 'souq-omdurman', name: 'Omdurman Souq', nameAr: 'سوق أم درمان', area: 'Omdurman', lat: 15.6417, lng: 32.4807),
    Place(id: 'bahri', name: 'Bahri Market', nameAr: 'سوق بحري', area: 'Khartoum North', lat: 15.6406, lng: 32.5371),
    Place(id: 'africa-rd', name: 'Africa Road, Tower B', nameAr: 'شارع أفريقيا، برج ب', area: 'Amarat', lat: 15.5727, lng: 32.5517, kind: 'work'),
    Place(id: 'amarat15', name: 'Amarat, Street 15', nameAr: 'العمارات شارع ١٥', area: 'Amarat', lat: 15.5832, lng: 32.5468),
    Place(id: 'manshiya', name: 'Manshiya Bridge', nameAr: 'كبري المنشية', area: 'Manshiya', lat: 15.5948, lng: 32.5807),
    Place(id: 'tuti', name: 'Tuti Island', nameAr: 'جزيرة توتي', area: 'Tuti', lat: 15.6256, lng: 32.5167),
    Place(id: 'soba', name: 'Soba University Hospital', nameAr: 'مستشفى سوبا الجامعي', area: 'Soba', lat: 15.5210, lng: 32.6126),
    Place(id: 'kalakla', name: 'Kalakla', nameAr: 'الكلاكلة', area: 'South Khartoum', lat: 15.4720, lng: 32.5170),
    Place(id: 'burri', name: 'Burri', nameAr: 'بري', area: 'East Khartoum', lat: 15.6040, lng: 32.5650),
  ];

  static List<Place> search(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return places;
    return places
        .where((p) =>
            p.name.toLowerCase().contains(s) ||
            p.nameAr.contains(q.trim()) ||
            p.area.toLowerCase().contains(s))
        .toList();
  }

  static const restaurants = <Restaurant>[
    Restaurant(
      id: 'solitaire',
      name: 'Solitaire Café',
      nameAr: 'سوليتير كافيه',
      cuisine: 'Café · Bakery',
      rating: 4.8,
      etaMin: 25,
      deliveryFee: 600,
      place: Place(id: 'solitaire', name: 'Solitaire Café', area: 'Amarat', lat: 15.5801, lng: 32.5490),
      menu: [
        MenuItem(id: 'cap', name: 'Cappuccino', nameAr: 'كابتشينو', price: 900, category: 'Coffee', desc: 'Double shot, steamed milk'),
        MenuItem(id: 'latte', name: 'Iced latte', nameAr: 'لاتيه بارد', price: 1100, category: 'Coffee', desc: 'Cold milk, espresso, ice'),
        MenuItem(id: 'esp', name: 'Espresso', nameAr: 'إسبريسو', price: 600, category: 'Coffee'),
        MenuItem(id: 'crois', name: 'Butter croissant', nameAr: 'كرواسون', price: 850, category: 'Bakery'),
        MenuItem(id: 'cake', name: 'Cake slice', nameAr: 'قطعة كيك', price: 1200, category: 'Bakery'),
        MenuItem(id: 'sand', name: 'Halloumi sandwich', nameAr: 'ساندويتش حلوم', price: 1640, category: 'Kitchen'),
      ],
    ),
    Restaurant(
      id: 'papa-fool',
      name: 'Papa Fool',
      nameAr: 'بابا فول',
      cuisine: 'Sudanese · Breakfast',
      rating: 4.7,
      etaMin: 20,
      deliveryFee: 400,
      place: Place(id: 'papa-fool', name: 'Papa Fool', area: 'Riyadh', lat: 15.5760, lng: 32.5700),
      menu: [
        MenuItem(id: 'fool', name: 'Ful medames', nameAr: 'فول', price: 700, category: 'Mains', desc: 'Fava beans, sesame oil, cumin, feta'),
        MenuItem(id: 'tamiya', name: 'Tamiya (6)', nameAr: 'طعمية', price: 500, category: 'Mains'),
        MenuItem(id: 'kisra', name: 'Kisra with mullah', nameAr: 'كسرة بالملاح', price: 1300, category: 'Mains'),
        MenuItem(id: 'aseeda', name: 'Aseeda', nameAr: 'عصيدة', price: 1100, category: 'Mains'),
        MenuItem(id: 'karkade', name: 'Karkade (cold)', nameAr: 'كركدي', price: 350, category: 'Drinks'),
        MenuItem(id: 'tabaldi', name: 'Tabaldi juice', nameAr: 'عصير تبلدي', price: 450, category: 'Drinks'),
      ],
    ),
    Restaurant(
      id: 'nile-grill',
      name: 'Nile Grill House',
      nameAr: 'مشويات النيل',
      cuisine: 'Grill · Shawarma',
      rating: 4.6,
      etaMin: 35,
      deliveryFee: 700,
      place: Place(id: 'nile-grill', name: 'Nile Grill House', area: 'Al Mogran', lat: 15.6120, lng: 32.5200),
      menu: [
        MenuItem(id: 'shaw', name: 'Chicken shawarma', nameAr: 'شاورما فراخ', price: 1500, category: 'Grill'),
        MenuItem(id: 'agashe', name: 'Agashe skewers', nameAr: 'أقاشي', price: 2200, category: 'Grill'),
        MenuItem(id: 'mixed', name: 'Mixed grill platter', nameAr: 'مشويات مشكلة', price: 4800, category: 'Grill'),
        MenuItem(id: 'salata', name: 'Salata aswad', nameAr: 'سلطة أسود', price: 600, category: 'Sides'),
        MenuItem(id: 'lemon', name: 'Lemon mint', nameAr: 'ليمون نعناع', price: 500, category: 'Drinks'),
      ],
    ),
  ];
}

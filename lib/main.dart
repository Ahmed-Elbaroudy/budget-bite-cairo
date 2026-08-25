import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ElAkeelApp());
}

// ==========================================
// 1. DATA MODELS & UTILS
// ==========================================
class MenuItem {
  final String id;
  final String nameEn;
  final String nameAr;
  final double priceEgp;

  MenuItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.priceEgp,
  });

  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;
}

class LocationMetadata {
  final String key;
  final String nameEn;
  final String nameAr;
  final String parentRegionKey;
  final List<String> aliases;

  LocationMetadata({
    required this.key,
    required this.nameEn,
    required this.nameAr,
    required this.parentRegionKey,
    required this.aliases,
  });
}

class Restaurant {
  final String id;
  final String nameEn;
  final String nameAr;
  final String locationKey;
  final String addressEn;
  final String addressAr;
  final double rating;
  final List<MenuItem> menu;

  Restaurant({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.locationKey,
    required this.addressEn,
    required this.addressAr,
    required this.rating,
    required this.menu,
  });

  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;
  String getAddress(String lang) => lang == 'ar' ? addressAr : addressEn;
}

class SearchDiagnostics {
  final Map<String, dynamic> rawInput;
  final Map<String, dynamic> normalizedParams;
  final int totalDatabaseRecords;
  final int matchedLocationCount;
  final int matchedBudgetCount;
  final int finalResultCount;
  final bool fallbackTriggered;
  final String? fallbackReasonAr;
  final String? fallbackReasonEn;

  SearchDiagnostics({
    required this.rawInput,
    required this.normalizedParams,
    required this.totalDatabaseRecords,
    required this.matchedLocationCount,
    required this.matchedBudgetCount,
    required this.finalResultCount,
    required this.fallbackTriggered,
    this.fallbackReasonAr,
    this.fallbackReasonEn,
  });
}

// ==========================================
// 2. EXPANDED CAIRO LOCATION DATABASE
// ==========================================
class CairoLocationRegistry {
  static final List<LocationMetadata> locations = [
    LocationMetadata(
      key: 'zamalek',
      nameEn: 'Zamalek',
      nameAr: 'الزمالك',
      parentRegionKey: 'cairo_central',
      aliases: ['zamalek', 'az zamalek', 'زمالك', 'الزمالك'],
    ),
    LocationMetadata(
      key: 'downtown',
      nameEn: 'Downtown / Garden City',
      nameAr: 'وسط البلد / جاردن سيتي',
      parentRegionKey: 'cairo_central',
      aliases: ['downtown', 'wust el balad', 'garden city', 'kasr el nil', 'وسط البلد', 'جاردن سيتي', 'قصر النيل'],
    ),
    LocationMetadata(
      key: 'nasr_city',
      nameEn: 'Nasr City',
      nameAr: 'مدينة نصر',
      parentRegionKey: 'cairo_east',
      aliases: ['nasr city', 'madinet nasr', 'مدينة نصر', 'م نصر'],
    ),
    LocationMetadata(
      key: 'heliopolis',
      nameEn: 'Heliopolis / Korba',
      nameAr: 'مصر الجديدة / الكوربة',
      parentRegionKey: 'cairo_east',
      aliases: ['heliopolis', 'masr el gedida', 'korba', 'مصر الجديدة', 'الكوربة'],
    ),
    LocationMetadata(
      key: 'fifth_settlement',
      nameEn: 'Fifth Settlement / New Cairo',
      nameAr: 'التجمع الخامس / القاهرة الجديدة',
      parentRegionKey: 'new_cairo',
      aliases: ['fifth settlement', 'tagamoa', '5th settlement', 'tagamo3', 'new cairo', 'التجمع', 'التجمع الخامس', 'القاهرة الجديدة'],
    ),
    LocationMetadata(
      key: 'rehab_madinaty',
      nameEn: 'El Rehab / Madinaty',
      nameAr: 'الرحاب / مدينتي',
      parentRegionKey: 'new_cairo',
      aliases: ['rehab', 'el rehab', 'madinaty', 'الرحاب', 'مدينتي'],
    ),
    LocationMetadata(
      key: 'maadi',
      nameEn: 'Maadi',
      nameAr: 'المعادي',
      parentRegionKey: 'cairo_south',
      aliases: ['maadi', 'el maadi', 'degla', 'المعادي', 'دجلة'],
    ),
    LocationMetadata(
      key: 'dokki_mohandessin',
      nameEn: 'Dokki / Mohandessin',
      nameAr: 'الدقي / المهندسين',
      parentRegionKey: 'giza_core',
      aliases: ['dokki', 'mohandessin', 'agouza', 'الدقي', 'المهندسين', 'العجوزة'],
    ),
    LocationMetadata(
      key: 'october_zayed',
      nameEn: '6th of October / Sheikh Zayed',
      nameAr: '٦ أكتوبر / الشيخ زايد',
      parentRegionKey: 'giza_west',
      aliases: ['6th of october', 'october', 'sheikh zayed', 'zayed', '6 october', 'أكتوبر', '٦ أكتوبر', 'الشيخ زايد', 'زايد'],
    ),
  ];

  static String normalize(String text) {
    String result = text.toLowerCase().trim();
    result = result.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    result = result.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    result = result.replaceAll('ى', 'ي');
    result = result.replaceAll('ة', 'ه');
    result = result.replaceAll('3', 'a');
    result = result.replaceAll('7', 'h');
    result = result.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }

  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  static LocationMetadata? findBestLocationMatch(String query) {
    final cleanQuery = normalize(query);
    if (cleanQuery.isEmpty || cleanQuery == 'all' || cleanQuery == 'كل القاهرة الكبرى') {
      return null;
    }

    for (var loc in locations) {
      for (var alias in loc.aliases) {
        final cleanAlias = normalize(alias);
        if (cleanQuery == cleanAlias || cleanQuery.contains(cleanAlias) || cleanAlias.contains(cleanQuery)) {
          return loc;
        }
      }
    }

    LocationMetadata? bestFuzzyMatch;
    int lowestDistance = 99;
    for (var loc in locations) {
      for (var alias in loc.aliases) {
        final cleanAlias = normalize(alias);
        int dist = _levenshteinDistance(cleanQuery, cleanAlias);
        if (dist <= 2 && dist < lowestDistance) {
          lowestDistance = dist;
          bestFuzzyMatch = loc;
        }
      }
    }
    return bestFuzzyMatch;
  }
}

// ==========================================
// 3. REPOSITORY & SEARCH PIPELINE
// ==========================================
class RestaurantRepository {
  static const double minimumAllowedBalance = 50.0;

  static final List<Restaurant> _database = [
    Restaurant(
      id: 'r1',
      nameEn: 'Koshary El Tahrir',
      nameAr: 'كشري التحرير',
      locationKey: 'downtown',
      addressEn: 'Downtown, Cairo',
      addressAr: 'وسط البلد، القاهرة',
      rating: 4.7,
      menu: [
        MenuItem(id: 'm1', nameEn: 'Standard Box', nameAr: 'علبة كشري', priceEgp: 50.0),
        MenuItem(id: 'm2', nameEn: 'King Size Box', nameAr: 'علبة فويل ملكي', priceEgp: 75.0),
      ],
    ),
    Restaurant(
      id: 'r2',
      nameEn: 'Zooba',
      nameAr: 'زوبة',
      locationKey: 'zamalek',
      addressEn: '26th of July St, Zamalek',
      addressAr: 'شارع ٢٦ يوليو، الزمالك',
      rating: 4.5,
      menu: [
        MenuItem(id: 'm4', nameEn: 'Hawawshi', nameAr: 'حواوشي', priceEgp: 110.0),
        MenuItem(id: 'm5', nameEn: 'Stuffed Taameya Combo', nameAr: 'وجبة طعمية محشية', priceEgp: 65.0),
      ],
    ),
    Restaurant(
      id: 'r3',
      nameEn: 'Abou El Sid',
      nameAr: 'أبو السيد',
      locationKey: 'fifth_settlement',
      addressEn: 'Downtown Mall, 5th Settlement',
      addressAr: 'داون تاون مول، التجمع الخامس',
      rating: 4.6,
      menu: [
        MenuItem(id: 'm6', nameEn: 'Molokhia with Chicken', nameAr: 'ملوخية بالدجاج', priceEgp: 230.0),
      ],
    ),
  ];

  static Map<String, dynamic> searchRestaurants({
    required String locationInput,
    required double minBudget,
    required double maxBudget,
  }) {
    final double enforcedMin = math.max(minimumAllowedBalance, math.min(minBudget, maxBudget));
    final double enforcedMax = math.max(enforcedMin, maxBudget);
    final LocationMetadata? matchedLoc = CairoLocationRegistry.findBestLocationMatch(locationInput);

    List<Restaurant> locMatched = _database.where((r) {
      if (matchedLoc == null) return true;
      return r.locationKey == matchedLoc.key;
    }).toList();

    List<Restaurant> budgetMatched = locMatched.where((r) {
      return r.menu.any((item) => item.priceEgp >= enforcedMin && item.priceEgp <= enforcedMax);
    }).toList();

    bool fallbackTriggered = false;
    String? fallbackAr;
    String? fallbackEn;
    List<Restaurant> finalResults = List.from(budgetMatched);

    if (finalResults.isEmpty) {
      fallbackTriggered = true;
      if (locMatched.isEmpty && matchedLoc != null) {
        fallbackAr = "لم نجد مطاعم في ${matchedLoc.nameAr}. تم توسيع البحث للمناطق المجاورة.";
        fallbackEn = "No matches in ${matchedLoc.nameEn}. Search expanded to nearby districts.";

        finalResults = _database.where((r) {
          final rLoc = CairoLocationRegistry.locations.firstWhere((l) => l.key == r.locationKey);
          return rLoc.parentRegionKey == matchedLoc.parentRegionKey &&
                 r.menu.any((i) => i.priceEgp >= enforcedMin && i.priceEgp <= enforcedMax);
        }).toList();
      } else if (budgetMatched.isEmpty) {
        fallbackAr = "لا تتوفر خيارات تحت ${enforcedMax.toStringAsFixed(0)} ج.م في ${matchedLoc?.nameAr ?? 'القاهرة'}. عرض أقرب الخيارات.";
        fallbackEn = "No options under ${enforcedMax.toStringAsFixed(0)} EGP in ${matchedLoc?.nameEn ?? 'Cairo'}. Showing options.";
        finalResults = List.from(locMatched);
      }
    }

    final diagnostics = SearchDiagnostics(
      rawInput: {'location': locationInput, 'minBudget': minBudget, 'maxBudget': maxBudget},
      normalizedParams: {'matchedLocationKey': matchedLoc?.key ?? 'ALL_CAIRO', 'enforcedMin': enforcedMin, 'enforcedMax': enforcedMax},
      totalDatabaseRecords: _database.length,
      matchedLocationCount: locMatched.length,
      matchedBudgetCount: budgetMatched.length,
      finalResultCount: finalResults.length,
      fallbackTriggered: fallbackTriggered,
      fallbackReasonAr: fallbackAr,
      fallbackReasonEn: fallbackEn,
    );

    return {
      'results': finalResults,
      'diagnostics': diagnostics,
      'matchedLocation': matchedLoc,
    };
  }
}

// ==========================================
// 4. MAIN APP ENTRY POINT
// ==========================================
class ElAkeelApp extends StatefulWidget {
  const ElAkeelApp({super.key});

  @override
  State<ElAkeelApp> createState() => _ElAkeelAppState();
}

class _ElAkeelAppState extends State<ElAkeelApp> {
  String _currentLang = 'ar';
  bool _isDarkMode = false;

  void _changeLanguage(String lang) => setState(() => _currentLang = lang);
  void _toggleTheme(bool isDark) => setState(() => _isDarkMode = isDark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أكيل القاهرة الكبرى | El-Akeel Cairo',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFD35400),
        scaffoldBackgroundColor: const Color(0xFFF9F6F0),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(primary: Color(0xFFD35400), secondary: Color(0xFF27AE60)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE57E22),
        scaffoldBackgroundColor: const Color(0xFF12181B),
        cardColor: const Color(0xFF1E262B),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE57E22), secondary: Color(0xFF27AE60)),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: _currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: BudgetInputScreen(
        currentLang: _currentLang,
        onLanguageChange: _changeLanguage,
        onThemeToggle: _toggleTheme,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

// ==========================================
// 5. SCREEN 1: SEARCH & BUDGET INPUT
// ==========================================
class BudgetInputScreen extends StatefulWidget {
  final String currentLang;
  final Function(String) onLanguageChange;
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const BudgetInputScreen({
    super.key,
    required this.currentLang,
    required this.onLanguageChange,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<BudgetInputScreen> createState() => _BudgetInputScreenState();
}

class _BudgetInputScreenState extends State<BudgetInputScreen> {
  final TextEditingController _minBudgetController = TextEditingController(text: '50');
  final TextEditingController _maxBudgetController = TextEditingController(text: '200');
  final TextEditingController _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedDistrictKey = 'all';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final queryLocation = _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : _selectedDistrictKey;

      double minB = double.tryParse(_minBudgetController.text) ?? 50.0;
      double maxB = double.tryParse(_maxBudgetController.text) ?? 200.0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantResultsScreen(
            locationInput: queryLocation,
            minBudget: minB,
            maxBudget: maxB,
            currentLang: widget.currentLang,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.currentLang == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'عجيل القاهرة الكبرى' : 'El-Akeel Greater Cairo'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeToggle(!widget.isDarkMode),
          ),
          TextButton(
            child: Text(
              isAr ? 'English' : 'عربي',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            onPressed: () => widget.onLanguageChange(isAr ? 'en' : 'ar'),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 10),
                Text(
                  isAr ? 'ابحث عن المطاعم حسب المنطقة والميزانية' : 'Find Restaurants by Area & Budget',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: isAr ? 'أدخل اسم المنطقة (مثال: التجمع، Zamalek، زايد)' : 'Enter District (e.g., Tagamoa, Zayed)',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  value: _selectedDistrictKey,
                  decoration: InputDecoration(
                    labelText: isAr ? 'أو اختر المنطقة من القائمة' : 'Or Select Cairo District',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(isAr ? 'كافة مناطق القاهرة الكبرى' : 'All Greater Cairo')),
                    ...CairoLocationRegistry.locations.map((loc) => DropdownMenuItem(
                          value: loc.key,
                          child: Text(isAr ? loc.nameAr : loc.nameEn),
                        ))
                  ],
                  onChanged: (val) => setState(() => _selectedDistrictKey = val!),
                ),
                const SizedBox(height: 24),

                Text(
                  isAr ? 'حدد نطاق رصيدك (الحد الأدنى ٥٠ ج.م)' : 'Set Budget Range (Min 50 EGP)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minBudgetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          final val = double.tryParse(value ?? '');
                          if (val == null || val < 50) {
                            return isAr ? 'الحد الأدنى ٥٠ ج.م' : 'Minimum is 50 EGP';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: isAr ? 'الحد الأدنى' : 'Min (EGP)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxBudgetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          final val = double.tryParse(value ?? '');
                          if (val == null || val < 50) {
                            return isAr ? 'الحد الأدنى ٥٠ ج.م' : 'Minimum is 50 EGP';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: isAr ? 'الحد الأقصى' : 'Max (EGP)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isAr ? 'بحث عن المطاعم' : 'Search Restaurants',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. SCREEN 2: RESULTS SCREEN
// ==========================================
class RestaurantResultsScreen extends StatelessWidget {
  final String locationInput;
  final double minBudget;
  final double maxBudget;
  final String currentLang;

  const RestaurantResultsScreen({
    super.key,
    required this.locationInput,
    required this.minBudget,
    required this.maxBudget,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = currentLang == 'ar';

    final searchData = RestaurantRepository.searchRestaurants(
      locationInput: locationInput,
      minBudget: minBudget,
      maxBudget: maxBudget,
    );

    final List<Restaurant> results = searchData['results'];
    final SearchDiagnostics diagnostics = searchData['diagnostics'];
    final LocationMetadata? matchedLoc = searchData['matchedLocation'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          matchedLoc != null
              ? (isAr ? matchedLoc.nameAr : matchedLoc.nameEn)
              : (isAr ? 'نتائج القاهرة الكبرى' : 'Greater Cairo Results'),
        ),
      ),
      body: Column(
        children: [
          if (diagnostics.fallbackTriggered)
            Container(
              color: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAr ? diagnostics.fallbackReasonAr! : diagnostics.fallbackReasonEn!,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        isAr ? 'لم نتمكن من العثور على نتائج.' : 'No matching restaurants found.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final restaurant = results[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(restaurant.getName(currentLang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(restaurant.getAddress(currentLang)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text('${restaurant.rating}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

# ADR-0006: Maps - MapLibre + OpenFreeMap (مجاني 100%)

## الحالة (Status)
**مقبول** - 2026-06-03

## السياق (Context)
نحتاج خدمة خرائط لـ:
- عرض الخطوط (start + end markers)
- رسم المسار بين نقطتين (Polyline)
- تتبع موقع السائق بشكل حي
- Marker نابض للسائق (beacon animation)
- 3 أنماط: streets, dark, satellite

الخيارات:
1. **Google Maps** - ممتاز لكن **مدفوع** ($0-200/شهر)
2. **Mapbox** - جيد لكن له Free tier محدود (50K loads)
3. **MapLibre + OpenFreeMap** - **مجاني 100%** بدون API key

## القرار (Decision)
نستخدم **`maplibre_native`** (Flutter package رسمي) + **OpenFreeMap tiles**.

## المبررات
1. **مجاني 100%**: لا API key، لا حدود، لا billing
2. **نفس اختيار v1**: التطبيق القديم كان يستخدم MapLibre (الاستمرارية)
3. **Native Renderer**: أداء أفضل لتتبع 50+ نقطة/دقيقة
4. **Vector Tiles**: رسم أنعم مع Pan/Zoom
5. **نفس OSRM** للـ routing (مجاني)

## Tile Sources (مُقارَنة)

| Service | Free Tier | API Key | ملاحظات |
|---------|-----------|---------|--------|
| **OpenFreeMap** | ∞ | ❌ لا | ⭐ مُوصى |
| **MapLibre Demo** | ∞ | ❌ لا | للاختبار فقط |
| **OSM Raster** | ∞ | ❌ لا | أثقل |
| MapTiler | 100K/شهر | ✅ نعم | بهوية بصرية |
| Google Maps | $200 رصيد | ✅ نعم | مدفوع |

## التطبيق (Implementation)

### 1. Dependency
```yaml
dependencies:
  maplibre_native: ^0.2.0
```

### 2. Tile URL (production)
```dart
const String kOpenFreeMapStyleUrl = 'https://tiles.openfreemap.org/styles/positron';
const String kOpenFreeMapDarkStyleUrl = 'https://tiles.openfreemap.org/styles/bright';
const String kOpenFreeMapLibertyStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
```

### 3. Map Style Enum
```dart
enum MapStyle {
  streets(kOpenFreeMapStyleUrl, 'Streets'),
  dark(kOpenFreeMapDarkStyleUrl, 'Dark'),
  liberty(kOpenFreeMapLibertyStyleUrl, 'Liberty');

  final String url;
  final String displayName;
  const MapStyle(this.url, this.displayName);
}
```

### 4. Attribution (إلزامي)
```dart
// في زاوية الخريطة
const String kAttribution = '© OpenStreetMap contributors © OpenFreeMap';
```

## Routing: OSRM (مجاني)
```dart
class OsrmService {
  static const String baseUrl = 'https://router.project-osrm.org/route/v1/driving';
  
  Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    final url = '$baseUrl/${start.lng},${start.lat};${end.lng},${end.lat}'
                '?overview=full&geometries=geojson';
    // ... fetch with 5s timeout + fallback to straight line
  }
}
```

## خطة بديلة (Fallback)
- إذا MapLibre فشل → نُظهر widget نصي مع الإحداثيات
- (نفس ErrorBoundary pattern من v1)

## التكلفة النهائية
| الخدمة | التكلفة |
|------|--------|
| MapLibre + OpenFreeMap | $0 |
| OSRM | $0 |
| **الإجمالي** | **$0/شهر** |

## المراجع
- [MapLibre Native Flutter](https://pub.dev/packages/maplibre_native)
- [OpenFreeMap](https://openfreemap.org/)
- [OSRM](http://project-osrm.org/)
- [OpenStreetMap Attribution](https://www.openstreetmap.org/copyright)

import React, { useEffect, useRef, useState } from 'react';
import { supabase } from '../utils/supabaseClient';
import { useToast } from '../components/Toast';
import { EmptyState } from '../components/EmptyState';
import { getDistance } from 'geolib';
import { 
  Bus, 
  Phone, 
  Clock, 
  AlertTriangle,
  X,
  Search,
  Radio,
  User,
  Compass,
  Activity
} from 'lucide-react';

interface DriverProfile {
  full_name: string;
  phone: string;
}

interface Driver {
  id: string;
  vehicle_model: string;
  vehicle_plate: string;
  profiles: DriverProfile | null;
}

interface Route {
  title: string;
  start_lat: number | null;
  start_lng: number | null;
}

interface Trip {
  id: string;
  status: 'scheduled' | 'driver_waiting' | 'in_transit' | 'completed' | 'cancelled' | 'absent';
  last_lat: number | null;
  last_lng: number | null;
  last_location_update: string | null;
  drivers: Driver | null;
  routes: Route | null;
}

export const ActiveTripsTracker: React.FC = () => {
  const { showToast } = useToast();
  const [trips, setTrips] = useState<Trip[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTripId, setSelectedTripId] = useState<string | null>(null);
  
  // Dynamic Leaflet Load state
  const [leafletLoaded, setLeafletLoaded] = useState(false);
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<any>(null);
  const markersRef = useRef<{ [key: string]: { driverMarker?: any; startMarker?: any; routeLine?: any } }>({});

  // Cancellation Modal state
  const [cancelOpen, setCancelOpen] = useState(false);
  const [cancelingTripId, setCancelingTripId] = useState<string | null>(null);
  const [cancelReason, setCancelReason] = useState('');
  const [cancelLoading, setCancelLoading] = useState(false);

  // 1. Fetch active trips
  const fetchActiveTrips = async () => {
    try {
      const { data, error } = await supabase
        .from('trips')
        .select(`
          id,
          status,
          last_lat,
          last_lng,
          last_location_update,
          drivers!inner (
            id,
            vehicle_model,
            vehicle_plate,
            profiles:user_id (
              full_name,
              phone
            )
          ),
          routes!inner (
            title,
            start_lat,
            start_lng
          )
        `)
        .in('status', ['driver_waiting', 'in_transit']);

      if (error) throw error;

      // Map profiles and routes properly if returned as array
      const formatted = (data as any[] || []).map(t => {
        const d = t.drivers;
        const driverProfile = d ? (Array.isArray(d.profiles) ? d.profiles[0] : d.profiles) : null;
        const r = t.routes;
        const routeData = r ? (Array.isArray(r) ? r[0] : r) : null;

        return {
          id: t.id,
          status: t.status,
          last_lat: t.last_lat ? Number(t.last_lat) : null,
          last_lng: t.last_lng ? Number(t.last_lng) : null,
          last_location_update: t.last_location_update,
          drivers: d ? {
            id: d.id,
            vehicle_model: d.vehicle_model,
            vehicle_plate: d.vehicle_plate,
            profiles: driverProfile
          } : null,
          routes: routeData
        };
      });

      setTrips(formatted);
    } catch {
      showToast('فشل في جلب الرحلات النشطة', 'error');
    } finally {
      setLoading(false);
    }
  };

  // 2. Load Leaflet script/css once
  useEffect(() => {
    if ((window as any).L) {
      setLeafletLoaded(true);
      return;
    }

    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    link.integrity = 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=';
    link.crossOrigin = '';
    document.head.appendChild(link);

    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.integrity = 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=';
    script.crossOrigin = '';
    script.onload = () => {
      setLeafletLoaded(true);
    };
    document.body.appendChild(script);
  }, []);

  // 3. Initial fetch & Real-time subscription setup
  useEffect(() => {
    fetchActiveTrips();

    const channel = supabase
      .channel('realtime_active_trips')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'trips' },
        () => {
          fetchActiveTrips();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  // 4. Initialize Map
  useEffect(() => {
    if (!leafletLoaded || !mapContainerRef.current || mapRef.current) return;

    const L = (window as any).L;
    
    // Choose tile template based on active theme
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const tileUrl = isDark 
      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' 
      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

    const map = L.map(mapContainerRef.current, {
      center: [33.3152, 44.3661], // Baghdad default center
      zoom: 12,
      zoomControl: false
    });

    L.control.zoom({ position: 'topleft' }).addTo(map);

    L.tileLayer(tileUrl, {
      attribution: '&copy; OpenStreetMap contributors &copy; CartoDB'
    }).addTo(map);

    mapRef.current = map;

    // Listen to theme modifications to adapt map background
    const themeObserver = new MutationObserver(() => {
      const dark = document.documentElement.getAttribute('data-theme') === 'dark';
      const nextUrl = dark 
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' 
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
      
      map.eachLayer((layer: any) => {
        if (layer instanceof L.TileLayer) {
          map.removeLayer(layer);
        }
      });
      
      L.tileLayer(nextUrl, {
        attribution: '&copy; OpenStreetMap contributors &copy; CartoDB'
      }).addTo(map);
    });

    themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });

    return () => {
      themeObserver.disconnect();
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, [leafletLoaded]);

  // 5. Update Map Markers when trips load or update
  useEffect(() => {
    if (!mapRef.current || !leafletLoaded) return;

    const L = (window as any).L;
    const map = mapRef.current;

    // Clear old markers
    Object.values(markersRef.current).forEach((markerObj: any) => {
      if (markerObj.driverMarker) map.removeLayer(markerObj.driverMarker);
      if (markerObj.startMarker) map.removeLayer(markerObj.startMarker);
      if (markerObj.routeLine) map.removeLayer(markerObj.routeLine);
    });
    markersRef.current = {};

    trips.forEach((trip) => {
      const driverLat = trip.last_lat;
      const driverLng = trip.last_lng;
      const startLat = trip.routes?.start_lat;
      const startLng = trip.routes?.start_lng;

      const markerObj: any = {};

      // Draw Route Starting Point Stop Marker
      if (startLat && startLng) {
        const startIcon = L.divIcon({
          className: 'custom-start-marker',
          html: `<div style="background-color: #8b5cf6; border: 2.5px solid white; border-radius: 50%; width: 16px; height: 16px; box-shadow: 0 2px 5px rgba(0,0,0,0.3);"></div>`,
          iconSize: [16, 16],
          iconAnchor: [8, 8]
        });

        const startMarker = L.marker([startLat, startLng], { icon: startIcon })
          .addTo(map)
          .bindPopup(`<strong>نقطة الانطلاق: ${trip.routes?.title}</strong>`);
        markerObj.startMarker = startMarker;
      }

      // Draw Driver Bus Marker
      if (driverLat && driverLng) {
        const driverIcon = L.divIcon({
          className: 'custom-driver-marker',
          html: `
            <div style="
              background-color: var(--bg-secondary);
              border: 2.5px solid var(--primary);
              border-radius: 50%;
              width: 38px;
              height: 38px;
              display: flex;
              align-items: center;
              justify-content: center;
              box-shadow: var(--shadow-lg);
            ">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M8 6v6"/><path d="M15 6v6"/><path d="M2 12h20"/><path d="M22 7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h18a2 2 0 0 0 2-2V7Z"/><circle cx="6.5" cy="15.5" r="1.5"/><circle cx="17.5" cy="15.5" r="1.5"/></svg>
            </div>
          `,
          iconSize: [38, 38],
          iconAnchor: [19, 19]
        });

        const driverMarker = L.marker([driverLat, driverLng], { icon: driverIcon })
          .addTo(map)
          .bindPopup(`
            <div style="direction: rtl; text-align: right; font-family: var(--font-family); min-width: 180px; padding: 4px 0;">
              <strong style="font-size: 0.95rem; color: var(--text-primary); display: block; margin-bottom: 6px;">${trip.drivers?.profiles?.full_name || 'سائق حافلة'}</strong>
              <div style="font-size: 0.8rem; color: var(--text-secondary); line-height: 1.5;">
                <div><strong>الخط:</strong> ${trip.routes?.title || '—'}</div>
                <div><strong>الحافلة:</strong> ${trip.drivers?.vehicle_model || '—'}</div>
                <div><strong>اللوحة:</strong> ${trip.drivers?.vehicle_plate || '—'}</div>
                <div style="margin-top: 8px;">
                  <span class="badge ${trip.status === 'in_transit' ? 'badge-success' : 'badge-warning'}">
                    ${trip.status === 'in_transit' ? 'في الطريق' : 'السائق ينتظر'}
                  </span>
                </div>
              </div>
            </div>
          `);
        markerObj.driverMarker = driverMarker;
      }

      // Draw dotted connection path
      if (driverLat && driverLng && startLat && startLng) {
        const routeLine = L.polyline([[driverLat, driverLng], [startLat, startLng]], {
          color: 'var(--primary)',
          weight: 3,
          dashArray: '5, 8',
          opacity: 0.5
        }).addTo(map);
        markerObj.routeLine = routeLine;
      }

      markersRef.current[trip.id] = markerObj;
    });

  }, [trips, leafletLoaded]);

  // Center map on specific driver's location
  const handleSelectTrip = (trip: Trip) => {
    setSelectedTripId(trip.id);
    if (!mapRef.current || !trip.last_lat || !trip.last_lng) return;
    
    mapRef.current.setView([trip.last_lat, trip.last_lng], 15);
    
    const markers = markersRef.current[trip.id];
    if (markers?.driverMarker) {
      markers.driverMarker.openPopup();
    }
  };

  // Compute live distance using geolib & simulated ETA
  const getDistanceAndEta = (trip: Trip) => {
    const driverLat = trip.last_lat;
    const driverLng = trip.last_lng;
    const startLat = trip.routes?.start_lat;
    const startLng = trip.routes?.start_lng;

    if (!driverLat || !driverLng || !startLat || !startLng) return null;

    const distance = getDistance(
      { latitude: driverLat, longitude: driverLng },
      { latitude: startLat, longitude: startLng }
    ); // distance in meters

    const distanceKm = (distance / 1000).toFixed(1);
    const etaMins = Math.max(1, Math.round(distance / 500)); // 30 km/h is ~500m per min

    return { distanceKm, etaMins };
  };

  // Format last location timestamp helper
  const formatLastSeen = (timestampStr: string | null) => {
    if (!timestampStr) return 'غير متوفر';
    const now = new Date();
    const updateTime = new Date(timestampStr);
    const diffSeconds = Math.max(0, Math.floor((now.getTime() - updateTime.getTime()) / 1000));

    if (diffSeconds < 60) return 'الآن';
    const diffMinutes = Math.floor(diffSeconds / 60);
    if (diffMinutes < 60) return `منذ ${diffMinutes} دقيقة`;
    
    return updateTime.toLocaleTimeString('ar-IQ', { hour: '2-digit', minute: '2-digit' });
  };

  // Trip cancellation trigger
  const openCancelDialog = (tripId: string) => {
    setCancelingTripId(tripId);
    setCancelReason('');
    setCancelOpen(true);
  };

  const handleCancelTrip = async () => {
    if (!cancelingTripId) return;
    try {
      setCancelLoading(true);
      const { error } = await supabase.rpc('admin_cancel_trip', {
        p_trip_id: cancelingTripId,
        p_reason: cancelReason.trim() || 'إلغاء إداري بواسطة لوحة التحكم'
      });

      if (error) throw error;

      showToast('تم إلغاء الرحلة بنجاح', 'success');
      // Remove trip locally
      setTrips(prev => prev.filter(t => t.id !== cancelingTripId));
      setCancelOpen(false);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'فشل غير معروف';
      showToast('فشل في إلغاء الرحلة: ' + message, 'error');
    } finally {
      setCancelLoading(false);
    }
  };

  // Search filter
  const filteredTrips = trips.filter(t => 
    (t.routes?.title || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
    (t.drivers?.profiles?.full_name || '').toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="animate-fade-in" style={{ direction: 'rtl', height: 'calc(100vh - var(--topbar-height) - 40px)', display: 'flex', gap: '20px' }}>
      
      {/* Sidebar List (Right side in RTL) */}
      <div style={{ width: '360px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
        
        {/* Search bar card */}
        <div className="card" style={{ padding: '16px' }}>
          <div style={{ position: 'relative' }}>
            <Search size={18} style={{ position: 'absolute', top: '50%', right: '12px', transform: 'translateY(-50%)', color: 'var(--text-tertiary)' }} />
            <input 
              type="text" 
              className="form-input" 
              placeholder="البحث بالخط أو السائق..." 
              style={{ paddingRight: '40px' }}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>

        {/* Trips List scroll container */}
        <div className="card" style={{ flex: 1, padding: '16px', display: 'flex', flexDirection: 'column', gap: '12px', overflowY: 'auto' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
            <h2 style={{ fontSize: '0.95rem', fontWeight: 700 }}>الرحلات الجارية حالياً ({filteredTrips.length})</h2>
            <span style={{ fontSize: '0.75rem', color: 'var(--primary)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Radio size={12} className="animate-pulse" style={{ color: 'var(--primary)' }} />
              تحديث مباشر
            </span>
          </div>

          {loading ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="shimmer-bg" style={{ height: '100px', borderRadius: 'var(--radius-sm)' }}></div>
              ))}
            </div>
          ) : filteredTrips.length === 0 ? (
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <EmptyState 
                icon={Activity} 
                title="لا توجد رحلات نشطة" 
                description="لا توجد أي حافلات تتحرك أو تنتظر ركاباً في الوقت الحالي." 
              />
            </div>
          ) : (
            filteredTrips.map((trip) => {
              const metrics = getDistanceAndEta(trip);
              const isSelected = selectedTripId === trip.id;
              return (
                <div 
                  key={trip.id}
                  className="card"
                  style={{
                    padding: '14px',
                    borderRadius: 'var(--radius-sm)',
                    border: isSelected ? '2px solid var(--primary)' : '1px solid var(--border-color)',
                    cursor: 'pointer',
                    backgroundColor: isSelected ? 'var(--primary-glow)' : 'var(--bg-secondary)',
                    transition: 'all var(--transition-fast)'
                  }}
                  onClick={() => handleSelectTrip(trip)}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                    <h3 style={{ fontSize: '0.9rem', fontWeight: 700, color: 'var(--text-primary)' }}>{trip.routes?.title || 'خط غير محدد'}</h3>
                    <span className={`badge ${trip.status === 'in_transit' ? 'badge-success' : 'badge-warning'}`} style={{ fontSize: '0.7rem' }}>
                      {trip.status === 'in_transit' ? 'في الطريق' : 'انتظار ركاب'}
                    </span>
                  </div>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '0.8rem', color: 'var(--text-secondary)', marginBottom: '8px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <User size={12} />
                      <span>{trip.drivers?.profiles?.full_name || 'سائق غير معروف'}</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Bus size={12} />
                      <span>{trip.drivers?.vehicle_model || '—'} ({trip.drivers?.vehicle_plate || '—'})</span>
                    </div>
                    
                    {metrics ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--primary)', fontWeight: 600 }}>
                        <Compass size={12} />
                        <span>على بعد {metrics.distanceKm} كم (ETA: {metrics.etaMins} دقيقة)</span>
                      </div>
                    ) : (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--text-tertiary)' }}>
                        <Compass size={12} />
                        <span>إحداثيات السائق غير متوفرة</span>
                      </div>
                    )}

                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.75rem', color: 'var(--text-tertiary)', marginTop: '4px' }}>
                      <Clock size={11} />
                      <span>آخر إشارة: {formatLastSeen(trip.last_location_update)}</span>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '8px', borderTop: '1px solid var(--border-color)', paddingTop: '8px', marginTop: '4px' }}>
                    {trip.drivers?.profiles?.phone && (
                      <a 
                        href={`tel:${trip.drivers.profiles.phone}`}
                        className="btn btn-secondary"
                        style={{ flex: 1, height: '30px', fontSize: '0.75rem', padding: 0 }}
                        onClick={(e) => e.stopPropagation()}
                      >
                        <Phone size={12} /> الاتصال
                      </a>
                    )}
                    <button
                      type="button"
                      className="btn btn-secondary"
                      style={{ flex: 1, height: '30px', fontSize: '0.75rem', padding: 0, color: 'var(--danger)', borderColor: 'var(--danger)' }}
                      onClick={(e) => { e.stopPropagation(); openCancelDialog(trip.id); }}
                    >
                      <X size={12} /> إلغاء الرحلة
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Map Container */}
      <div className="card" style={{ flex: 1, padding: 0, position: 'relative', overflow: 'hidden' }}>
        {!leafletLoaded && (
          <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyItems: 'center', backgroundColor: 'var(--bg-primary)', zIndex: 10 }}>
            <div style={{ margin: 'auto', textAlign: 'center', color: 'var(--text-secondary)' }}>جاري تحميل خريطة سير التفاعلية...</div>
          </div>
        )}
        <div ref={mapContainerRef} style={{ width: '100%', height: '100%', zIndex: 1 }} />
      </div>

      {/* Cancellation dialog with reason input */}
      {cancelOpen && (
        <div className="modal-overlay" onClick={() => setCancelOpen(false)}>
          <div className="modal-content" style={{ maxWidth: '440px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>إلغاء رحلة جارية</h2>
              <button className="close-btn" onClick={() => setCancelOpen(false)}><X size={18} /></button>
            </div>
            <div className="modal-body">
              <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start', color: 'var(--danger)', backgroundColor: 'var(--danger-glow)', padding: '12px', borderRadius: 'var(--radius-sm)', marginBottom: '16px' }}>
                <AlertTriangle size={24} style={{ flexShrink: 0 }} />
                <p style={{ fontSize: '0.85rem', lineHeight: '1.4' }}>
                  تحذير: سيؤدي إلغاء الرحلة إلى إشعار الطلاب وإنهائها في النظام فوراً. الرجاء إدخال سبب مقنع للإلغاء ليتم إرساله في الإشعار للركاب.
                </p>
              </div>

              <div className="form-group">
                <label className="form-label">سبب الإلغاء (اختياري)</label>
                <input 
                  type="text" 
                  className="form-input" 
                  placeholder="مثال: عطل فني في الحافلة، ظروف طارئة..." 
                  value={cancelReason}
                  onChange={(e) => setCancelReason(e.target.value)}
                />
              </div>
            </div>
            <div className="modal-footer">
              <button type="button" className="btn btn-secondary" onClick={() => setCancelOpen(false)}>تراجع</button>
              <button 
                type="button" 
                className="btn btn-danger" 
                onClick={handleCancelTrip}
                disabled={cancelLoading}
              >
                {cancelLoading ? 'جاري الإلغاء...' : 'تأكيد إلغاء الرحلة'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// Wasilha — Role select + Driver flow + Store dashboard
// 17 Role · 18 Driver Home · 19 Earnings · 20 Active Delivery · 21 Store

// ─────────────────────────────────────────────────────────────
// 17 — ROLE SELECTION
// ─────────────────────────────────────────────────────────────
function RoleScreen({ nav, accent, lang }) {
  const [role, setRole] = React.useState('passenger');
  const t = lang === 'ar' ? {
    kicker: 'الخطوة ٠٣ / الدور',
    headline: 'كيف ستستخدم وصلها؟',
    sub: 'يمكنك التبديل بين الأدوار في أي وقت من إعدادات الحساب.',
    cont: 'متابعة',
    pass: { name: 'راكب', sub: 'احجز الراكشة والسيارة والدراجة والتوصيل', tag: 'الأكثر شيوعًا' },
    driver: { name: 'سائق', sub: 'اقبل طلبات الرحلات وتتبع أرباحك اليومية', tag: '+ ١٢٠ ألف ج.س / أسبوع' },
    store: { name: 'متجر', sub: 'أدر طلباتك واطلب توصيل من فروعك', tag: 'شركاء ٤٢٠+' },
  } : {
    kicker: 'STEP 03 / ROLE',
    headline: 'How will you use Wasilha?',
    sub: 'You can switch between roles anytime from account settings.',
    cont: 'Continue',
    pass: { name: 'Passenger', sub: 'Book Raksha, car, motorcycle & courier', tag: 'MOST COMMON' },
    driver: { name: 'Driver', sub: 'Accept ride requests, track daily earnings', tag: '120K SDG / WEEK AVG' },
    store: { name: 'Store', sub: 'Manage orders, dispatch couriers from branches', tag: '420+ PARTNERS' },
  };
  const roles = [
    { id: 'passenger', icon: 'user',   ...t.pass,   next: 'home' },
    { id: 'driver',    icon: 'car',    ...t.driver, next: 'driverHome' },
    { id: 'store',     icon: 'bag',    ...t.store,  next: 'store' },
  ];

  return (
    <div data-screen-label="17 Role" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 60, padding: '60px 24px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('otp')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          {t.kicker}
        </span>
        <div style={{ width: 40 }} />
      </div>

      <div style={{ padding: '32px 24px 0' }}>
        <div className="serif" style={{ fontSize: 40, lineHeight: 1, letterSpacing: '-0.025em', color: '#0A0908' }}>
          {lang === 'ar'
            ? <>كيف ستستخدم <span style={{ color: accent }}>وصلها؟</span></>
            : <>How will you use <span style={{ color: accent }}>Wasilha?</span></>}
        </div>
        <div style={{ fontSize: 13.5, color: 'var(--text-2)', marginTop: 12, lineHeight: 1.55, maxWidth: 320 }}>
          {t.sub}
        </div>
      </div>

      <div style={{ padding: '28px 24px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {roles.map(r => {
          const on = role === r.id;
          return (
            <button key={r.id} onClick={() => setRole(r.id)} style={{
              appearance: 'none', cursor: 'pointer', textAlign: 'left',
              border: on ? `1.5px solid ${accent}` : '0.5px solid var(--border)',
              background: on ? '#fff' : 'rgba(255,255,255,0.6)',
              borderRadius: 22, padding: '18px 18px',
              display: 'flex', alignItems: 'center', gap: 14,
              boxShadow: on ? `0 14px 32px ${accent}1A` : '0 1px 0 rgba(255,255,255,0.6) inset, 0 2px 8px rgba(20,15,30,0.04)',
              transition: 'all 0.2s',
              position: 'relative', overflow: 'hidden',
            }}>
              {on && (
                <div style={{
                  position: 'absolute', top: -40, right: -40, width: 140, height: 140, borderRadius: '50%',
                  background: `radial-gradient(circle, ${accent}30, transparent 70%)`,
                  pointerEvents: 'none',
                }} />
              )}
              <div style={{
                width: 56, height: 56, borderRadius: 16,
                background: on ? accent : 'var(--surface-2)',
                color: on ? '#fff' : '#0A0908',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: on ? `0 8px 18px ${accent}40` : 'none',
                position: 'relative', zIndex: 1,
              }}>
                <Icon name={r.icon} size={26} strokeWidth={1.5} />
              </div>
              <div style={{ flex: 1, position: 'relative', zIndex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span className="serif" style={{ fontSize: 24, letterSpacing: '-0.01em', lineHeight: 1 }}>{r.name}</span>
                </div>
                <div style={{ fontSize: 12, color: 'var(--text-2)', marginTop: 4, lineHeight: 1.45 }}>{r.sub}</div>
                <div className="mono" style={{ fontSize: 9.5, color: on ? accent : 'var(--text-3)', letterSpacing: '0.22em', marginTop: 7 }}>
                  ● {r.tag}
                </div>
              </div>
              <div style={{
                width: 22, height: 22, borderRadius: '50%',
                border: `1.5px solid ${on ? accent : 'var(--border-2)'}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                position: 'relative', zIndex: 1,
              }}>
                {on && <div style={{ width: 11, height: 11, borderRadius: '50%', background: accent }} />}
              </div>
            </button>
          );
        })}
      </div>

      <div style={{ marginTop: 'auto', padding: '20px 24px 36px' }}>
        <Btn full accent={accent} onClick={() => nav(roles.find(r => r.id === role).next)} icon="arrow">
          {t.cont}
        </Btn>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 18 — DRIVER HOME (online toggle + requests feed)
// ─────────────────────────────────────────────────────────────
function DriverHomeScreen({ nav, accent, lang, glass, mapStyle }) {
  const [online, setOnline] = React.useState(true);
  const [request, setRequest] = React.useState({
    open: true,
    name: 'Sara A.',
    rating: 4.9,
    from: 'Riyadh District',
    to: 'Khartoum Airport (KRT)',
    dist: '18 km',
    eta: '24 min',
    fare: 4200,
    pickupEta: '3 min',
    timer: 18,
  });

  React.useEffect(() => {
    if (!request.open || request.timer <= 0) return;
    const t = setTimeout(() => setRequest(r => ({ ...r, timer: r.timer - 1 })), 1000);
    return () => clearTimeout(t);
  }, [request.timer, request.open]);

  return (
    <div data-screen-label="18 Driver Home" style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        <MapView style={mapStyle} accent={accent} drivers={online ? 0 : 4} />
      </div>

      {/* Top status bar */}
      <div style={{ position: 'absolute', top: 60, left: 16, right: 16, zIndex: 10, display: 'flex', gap: 10 }}>
        <button onClick={() => nav('role')} style={{
          width: 44, height: 44, borderRadius: 14, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.1)',
        }}>
          <Avatar size={28} label="OM" tone="warm" />
        </button>
        <Glass intensity={glass} style={{
          flex: 1, borderRadius: 14, padding: '8px 8px 8px 16px',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{
            width: 8, height: 8, borderRadius: '50%',
            background: online ? '#1F8A5B' : '#A6A29A',
            boxShadow: online ? '0 0 0 4px rgba(31,138,91,0.18)' : 'none',
            animation: online ? 'pulse-soft 1.8s ease-in-out infinite' : 'none',
          }} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="mono" style={{ fontSize: 8.5, color: 'var(--text-3)', letterSpacing: '0.22em' }}>STATUS · DRIVER</div>
            <div style={{ fontSize: 13, fontWeight: 600, marginTop: 1, color: online ? '#1F8A5B' : '#0A0908' }}>
              {online ? (lang === 'ar' ? 'متصل · جاهز لطلبات' : 'Online · accepting trips') : (lang === 'ar' ? 'غير متصل' : 'Offline')}
            </div>
          </div>
          <button onClick={() => setOnline(!online)} style={{
            width: 50, height: 28, borderRadius: 999, border: 0, cursor: 'pointer',
            background: online ? '#1F8A5B' : '#D6D2C9',
            position: 'relative', transition: 'background 0.2s',
          }}>
            <div style={{
              width: 22, height: 22, borderRadius: '50%', background: '#fff',
              position: 'absolute', top: 3, left: online ? 25 : 3,
              transition: 'left 0.2s',
              boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
            }} />
          </button>
        </Glass>
      </div>

      {/* Recenter */}
      <button style={{
        position: 'absolute', right: 16, bottom: online && request.open ? 470 : 270, zIndex: 8,
        width: 44, height: 44, borderRadius: 14, border: 0, cursor: 'pointer',
        background: '#fff', color: '#0A0908',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 8px 22px rgba(20,15,30,0.12)',
        transition: 'bottom 0.3s',
      }}>
        <Icon name="target" size={18} strokeWidth={1.7} />
      </button>

      {/* Incoming request — full bleed sheet */}
      {online && request.open ? (
        <div style={{
          position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 25,
          background: '#0A0908', color: '#fff',
          borderTopLeftRadius: 28, borderTopRightRadius: 28,
          padding: '14px 18px 28px',
          boxShadow: '0 -16px 40px rgba(10,9,8,0.3)',
          animation: 'sheet-in 0.5s cubic-bezier(0.2,0.8,0.2,1)',
          overflow: 'hidden', position: 'absolute',
        }}>
          {/* radial glow */}
          <div style={{
            position: 'absolute', top: -60, right: -40, width: 240, height: 240, borderRadius: '50%',
            background: `radial-gradient(circle, ${accent}60, transparent 65%)`,
          }} />
          <div style={{ width: 38, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.18)', margin: '0 auto 12px', position: 'relative' }} />

          <div style={{ position: 'relative' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div className="mono" style={{ fontSize: 10, color: accent, letterSpacing: '0.32em' }}>
                ● {lang === 'ar' ? 'طلب جديد' : 'NEW REQUEST'}
              </div>
              <div style={{
                display: 'flex', alignItems: 'center', gap: 6,
                background: 'rgba(255,255,255,0.08)', padding: '4px 10px', borderRadius: 999,
              }}>
                <Icon name="clock" size={12} strokeWidth={2} style={{ color: accent }} />
                <span className="mono" style={{ fontSize: 11, fontWeight: 600 }}>0:{String(request.timer).padStart(2, '0')}</span>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginTop: 10 }}>
              <div>
                <div className="serif" style={{ fontSize: 56, lineHeight: 0.92, letterSpacing: '-0.035em' }}>
                  {request.fare.toLocaleString()}
                </div>
                <div className="mono" style={{ fontSize: 10, opacity: 0.55, letterSpacing: '0.22em', marginTop: 4 }}>
                  SDG · {request.dist.toUpperCase()} · {request.eta.toUpperCase()}
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <Avatar size={44} label="SA" tone="purple" />
                <div style={{ fontSize: 12, marginTop: 6 }}>{request.name}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 3, justifyContent: 'flex-end', fontSize: 11, opacity: 0.65, marginTop: 1 }}>
                  <Icon name="star" size={10} style={{ color: '#E4B73B' }} /> {request.rating}
                </div>
              </div>
            </div>

            {/* Route */}
            <div style={{ display: 'flex', gap: 12, marginTop: 16 }}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, paddingTop: 6 }}>
                <div style={{ width: 9, height: 9, borderRadius: '50%', background: '#1F8A5B' }} />
                <div style={{ width: 1.5, height: 22, background: 'rgba(255,255,255,0.18)' }} />
                <div style={{ width: 9, height: 9, borderRadius: 2, background: accent }} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ paddingBottom: 8, borderBottom: '0.5px solid rgba(255,255,255,0.08)' }}>
                  <div className="mono" style={{ fontSize: 8.5, opacity: 0.5, letterSpacing: '0.22em' }}>PICKUP · {request.pickupEta.toUpperCase()}</div>
                  <div style={{ fontSize: 13.5, fontWeight: 500, marginTop: 2 }}>{request.from}</div>
                </div>
                <div style={{ paddingTop: 8 }}>
                  <div className="mono" style={{ fontSize: 8.5, opacity: 0.5, letterSpacing: '0.22em' }}>DROP-OFF</div>
                  <div style={{ fontSize: 13.5, fontWeight: 500, marginTop: 2 }}>{request.to}</div>
                </div>
              </div>
            </div>

            {/* Accept / Decline */}
            <div style={{ display: 'flex', gap: 8, marginTop: 18 }}>
              <button onClick={() => setRequest(r => ({ ...r, open: false, timer: 18 }))} style={{
                width: 56, height: 56, borderRadius: 16, border: '0.5px solid rgba(255,255,255,0.14)',
                background: 'rgba(255,255,255,0.06)', color: '#fff', cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="close" size={20} strokeWidth={2} />
              </button>
              <button onClick={() => nav('driverDelivery')} style={{
                flex: 1, height: 56, borderRadius: 16, border: 0, cursor: 'pointer',
                background: accent, color: '#fff',
                fontFamily: 'inherit', fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                boxShadow: `0 10px 24px ${accent}50`,
              }}>
                {lang === 'ar' ? 'قبول الرحلة' : 'Accept trip'}
                <Icon name="arrow" size={18} strokeWidth={1.8} />
              </button>
            </div>
          </div>
        </div>
      ) : (
        /* Stats sheet when no active request */
        <div style={{
          position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 20,
          background: '#FBFAF6',
          borderTopLeftRadius: 28, borderTopRightRadius: 28,
          padding: '12px 18px 100px',
          boxShadow: '0 -10px 32px rgba(20,15,30,0.1)',
          maxHeight: '52%', overflowY: 'auto',
        }} className="no-scroll">
          <div style={{ width: 38, height: 4, borderRadius: 2, background: 'var(--border-2)', margin: '0 auto 14px' }} />

          {!online && (
            <div style={{
              padding: '14px 16px', borderRadius: 16, background: '#fff', border: '0.5px solid var(--border)',
              display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12,
            }}>
              <div style={{ width: 36, height: 36, borderRadius: 11, background: 'var(--surface-2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="moon" size={16} strokeWidth={1.7} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{lang === 'ar' ? 'أنت غير متصل' : "You're offline"}</div>
                <div style={{ fontSize: 11.5, color: 'var(--text-2)' }}>{lang === 'ar' ? 'فعّل الاتصال لبدء استلام الطلبات' : 'Toggle online to receive requests'}</div>
              </div>
            </div>
          )}

          {/* Today header */}
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
            <div>
              <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em' }}>TODAY · {new Date().toLocaleDateString('en', { weekday: 'short', day: 'numeric', month: 'short' }).toUpperCase()}</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 6 }}>
                <span className="serif" style={{ fontSize: 44, lineHeight: 1, letterSpacing: '-0.025em' }}>18,420</span>
                <span className="mono" style={{ fontSize: 11, color: 'var(--text-2)' }}>SDG</span>
              </div>
            </div>
            <button onClick={() => nav('driverEarnings')} style={{
              all: 'unset', cursor: 'pointer',
              fontSize: 12, color: accent, padding: '8px 14px',
              borderRadius: 999, background: accent + '12', fontWeight: 500,
            }}>{lang === 'ar' ? 'الأرباح' : 'Earnings'}</button>
          </div>

          {/* Mini stats */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginTop: 16 }}>
            {[
              { label: lang === 'ar' ? 'رحلات' : 'TRIPS', value: '7' },
              { label: lang === 'ar' ? 'ساعات' : 'HOURS', value: '4.2' },
              { label: lang === 'ar' ? 'تقييم' : 'RATING', value: '4.96', icon: 'star' },
            ].map((s, i) => (
              <div key={i} style={{
                padding: '12px 14px', borderRadius: 14, background: '#fff', border: '0.5px solid var(--border)',
              }}>
                <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em' }}>{s.label}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 4 }}>
                  <span className="serif" style={{ fontSize: 24, letterSpacing: '-0.02em', lineHeight: 1 }}>{s.value}</span>
                  {s.icon && <Icon name={s.icon} size={12} style={{ color: '#E4B73B' }} />}
                </div>
              </div>
            ))}
          </div>

          {/* Goal */}
          <div style={{ marginTop: 14, padding: 14, borderRadius: 16, background: '#0A0908', color: '#fff', position: 'relative', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', top: -40, right: -30, width: 160, height: 160, borderRadius: '50%', background: `radial-gradient(circle, ${accent}55, transparent 60%)` }} />
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', position: 'relative' }}>
              <div className="mono" style={{ fontSize: 9.5, opacity: 0.55, letterSpacing: '0.28em' }}>{lang === 'ar' ? 'هدف اليوم' : 'DAILY GOAL'}</div>
              <span className="mono" style={{ fontSize: 11, fontWeight: 600 }}>61%</span>
            </div>
            <div style={{ fontSize: 13, marginTop: 6, position: 'relative' }}>
              <span style={{ fontWeight: 600 }}>18,420</span>
              <span style={{ opacity: 0.55 }}> / 30,000 SDG</span>
            </div>
            <div style={{ height: 6, borderRadius: 3, background: 'rgba(255,255,255,0.1)', marginTop: 12, overflow: 'hidden', position: 'relative' }}>
              <div style={{ width: '61%', height: '100%', background: accent, borderRadius: 3, boxShadow: `0 0 14px ${accent}` }} />
            </div>
          </div>

          {/* Heatmap hint */}
          <button style={{
            marginTop: 12, width: '100%', appearance: 'none', cursor: 'pointer', border: 0,
            background: '#fff', borderRadius: 16, padding: 14, textAlign: 'left',
            border: '0.5px solid var(--border)',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 40, height: 40, borderRadius: 12, background: accent + '14', color: accent, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="flame" size={18} strokeWidth={1.7} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13.5, fontWeight: 500 }}>{lang === 'ar' ? 'منطقة طلبات نشطة' : 'High demand · Khartoum 2'}</div>
              <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2 }}>{lang === 'ar' ? 'متوسط +٤٠٪ هذا الوقت' : '+40% surge for this hour'}</div>
            </div>
            <Icon name="chevron" size={14} style={{ color: 'var(--text-3)' }} />
          </button>
        </div>
      )}

      <DriverNav active="home" onNav={nav} accent={accent} glass={glass} />
    </div>
  );
}

// Driver bottom nav (separate from passenger one)
function DriverNav({ active, onNav, accent, glass }) {
  const items = [
    { id: 'driverHome',     label: 'Drive',    icon: 'car' },
    { id: 'driverEarnings', label: 'Earnings', icon: 'wallet' },
    { id: 'history',        label: 'History',  icon: 'history' },
    { id: 'settings',       label: 'Account',  icon: 'user' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 12, right: 12, bottom: 22,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 30, pointerEvents: 'none',
    }}>
      <Glass intensity={glass} style={{
        borderRadius: 999, padding: '8px', display: 'flex', gap: 4,
        pointerEvents: 'auto',
      }}>
        {items.map(it => {
          const isActive = active === it.id;
          return (
            <button key={it.id} onClick={() => onNav(it.id)} style={{
              appearance: 'none', border: 0, cursor: 'pointer',
              padding: '0 14px', height: 44, minWidth: 44,
              borderRadius: 999,
              background: isActive ? '#0A0908' : 'transparent',
              color: isActive ? '#fff' : '#0A0908',
              display: 'flex', alignItems: 'center', gap: 8,
              fontFamily: 'inherit', fontSize: 13, fontWeight: 500,
              letterSpacing: '-0.01em',
              transition: 'background 0.2s, color 0.2s',
            }}>
              <Icon name={it.icon} size={18} strokeWidth={1.7} />
              {isActive && <span>{it.label}</span>}
            </button>
          );
        })}
      </Glass>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 19 — DRIVER EARNINGS
// ─────────────────────────────────────────────────────────────
function DriverEarningsScreen({ nav, accent, lang, glass }) {
  const [period, setPeriod] = React.useState('week');
  const days = [
    { d: 'M', v: 0.42 }, { d: 'T', v: 0.68 }, { d: 'W', v: 0.55 },
    { d: 'T', v: 0.81 }, { d: 'F', v: 0.95 }, { d: 'S', v: 0.72 }, { d: 'S', v: 0.34, today: true },
  ];
  const max = Math.max(...days.map(d => d.v));
  const trips = [
    { time: '21:14', from: 'Riyadh', to: 'Khartoum 2', fare: 4200, surge: true },
    { time: '19:48', from: 'Bahri',  to: 'Souq Arabi',  fare: 2800 },
    { time: '17:22', from: 'Amarat', to: 'University',  fare: 1850 },
    { time: '15:04', from: 'Africa Rd', to: 'Riverside', fare: 3120 },
    { time: '12:31', from: 'Mall',   to: 'Block 32',    fare: 1640 },
    { time: '10:18', from: 'KRT Airport', to: 'Amarat',  fare: 4810 },
  ];

  return (
    <div data-screen-label="19 Driver Earnings" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('driverHome')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          EARNINGS · الأرباح
        </span>
        <button style={{ width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer', background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="receipt" size={16} strokeWidth={1.7} />
        </button>
      </div>

      {/* Hero — week total */}
      <div style={{ padding: '24px 18px 0' }}>
        <div className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          {period === 'week' ? (lang === 'ar' ? 'هذا الأسبوع' : 'THIS WEEK') : (lang === 'ar' ? 'هذا اليوم' : 'TODAY')}
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 10 }}>
          <span className="serif" style={{ fontSize: 76, lineHeight: 0.95, letterSpacing: '-0.035em', color: '#0A0908' }}>
            {period === 'week' ? '128,420' : '18,420'}
          </span>
          <span className="mono" style={{ fontSize: 13, color: 'var(--text-2)', letterSpacing: '0.16em' }}>SDG</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
          <span style={{ fontSize: 12, color: '#1F8A5B', padding: '2px 8px', borderRadius: 999, background: '#1F8A5B14' }}>
            ↑ {period === 'week' ? '12.4%' : '4.2%'} {lang === 'ar' ? 'مقارنة' : 'vs prev'}
          </span>
          <span style={{ fontSize: 11, color: 'var(--text-3)' }}>· {period === 'week' ? '34 trips · 28h online' : '7 trips · 4.2h online'}</span>
        </div>
      </div>

      {/* Period toggle */}
      <div style={{ padding: '20px 18px 0', display: 'flex', gap: 6 }}>
        {['today', 'week', 'month'].map(p => (
          <button key={p} onClick={() => setPeriod(p)} style={{
            flex: 1, appearance: 'none', cursor: 'pointer',
            border: 0, background: period === p ? '#0A0908' : '#fff',
            color: period === p ? '#fff' : '#0A0908',
            borderRadius: 12, padding: '10px 0', fontSize: 12.5, fontWeight: 500,
            border: period === p ? 0 : '0.5px solid var(--border)',
          }}>{({today: lang === 'ar' ? 'اليوم' : 'Today', week: lang === 'ar' ? 'الأسبوع' : 'Week', month: lang === 'ar' ? 'الشهر' : 'Month'})[p]}</button>
        ))}
      </div>

      {/* Chart */}
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          background: '#fff', borderRadius: 18, padding: '18px 14px 12px',
          border: '0.5px solid var(--border)',
        }}>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 140 }}>
            {days.map((d, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, height: '100%' }}>
                <div style={{ flex: 1, width: '100%', display: 'flex', alignItems: 'flex-end' }}>
                  <div style={{
                    width: '100%', height: `${(d.v / max) * 100}%`, minHeight: 4,
                    borderRadius: 6,
                    background: d.today ? accent : '#0A0908',
                    boxShadow: d.today ? `0 6px 16px ${accent}40` : 'none',
                    position: 'relative',
                  }}>
                    {d.v / max > 0.85 && (
                      <div className="mono" style={{
                        position: 'absolute', top: -18, left: '50%', transform: 'translateX(-50%)',
                        fontSize: 8.5, color: '#0A0908', letterSpacing: '0.1em', whiteSpace: 'nowrap',
                      }}>{Math.round(d.v * 32)}K</div>
                    )}
                  </div>
                </div>
                <div className="mono" style={{ fontSize: 9, color: d.today ? accent : 'var(--text-3)', letterSpacing: '0.1em', fontWeight: d.today ? 600 : 400 }}>{d.d}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Breakdown */}
      <div style={{ padding: '20px 18px 0' }}>
        <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginBottom: 10 }}>
          {lang === 'ar' ? 'تفاصيل' : 'BREAKDOWN'}
        </div>
        <div style={{ background: '#fff', borderRadius: 18, padding: '0 16px', border: '0.5px solid var(--border)' }}>
          {[
            { label: lang === 'ar' ? 'أجور الرحلات' : 'Trip fares',     val: '112,400', detail: '34 trips' },
            { label: lang === 'ar' ? 'بقشيش' : 'Tips',                 val: '+ 8,200', detail: '21 riders' },
            { label: lang === 'ar' ? 'حوافز' : 'Bonuses & surge',      val: '+ 12,820', detail: '4 events', highlight: true },
            { label: lang === 'ar' ? 'عمولة وصلها' : 'Wasilha service fee', val: '− 5,000', detail: '15%', dim: true },
          ].map((row, i, arr) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', padding: '14px 0',
              borderBottom: i < arr.length - 1 ? '0.5px solid var(--border)' : 0,
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13.5, fontWeight: 500 }}>{row.label}</div>
                <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.18em', marginTop: 2 }}>{row.detail.toUpperCase()}</div>
              </div>
              <div className="mono" style={{
                fontSize: 14, fontWeight: 600,
                color: row.highlight ? accent : row.dim ? 'var(--text-2)' : '#0A0908',
              }}>{row.val}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Cash out */}
      <div style={{ padding: '16px 18px 0' }}>
        <button style={{
          width: '100%', appearance: 'none', border: 0, cursor: 'pointer',
          background: '#0A0908', color: '#fff', height: 56, borderRadius: 16,
          fontFamily: 'inherit', fontSize: 14.5, fontWeight: 500,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 18px', position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', top: -30, right: -20, width: 130, height: 130, borderRadius: '50%', background: `radial-gradient(circle, ${accent}50, transparent 65%)` }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, position: 'relative' }}>
            <Icon name="wallet" size={18} strokeWidth={1.7} />
            <span>{lang === 'ar' ? 'سحب إلى البنك' : 'Cash out to bank'}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, position: 'relative' }}>
            <span className="mono" style={{ fontSize: 11, opacity: 0.6 }}>BOK · 4471</span>
            <Icon name="arrow" size={16} strokeWidth={1.7} />
          </div>
        </button>
      </div>

      {/* Today trips list */}
      <div style={{ padding: '24px 18px 100px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
          <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
            {lang === 'ar' ? 'رحلات اليوم' : "TODAY'S TRIPS"}
          </div>
          <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>6 / 7</span>
        </div>
        <div style={{ background: '#fff', borderRadius: 18, padding: '0 16px', border: '0.5px solid var(--border)' }}>
          {trips.map((t, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '14px 0',
              borderBottom: i < trips.length - 1 ? '0.5px solid var(--border)' : 0,
            }}>
              <div className="mono" style={{ fontSize: 10.5, color: 'var(--text-3)', width: 36, letterSpacing: '0.08em' }}>{t.time}</div>
              <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 6, fontSize: 12.5, fontWeight: 500 }}>
                <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1 }}>{t.from}</span>
                <Icon name="arrow" size={11} style={{ color: 'var(--text-3)', flexShrink: 0 }} />
                <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1 }}>{t.to}</span>
              </div>
              {t.surge && (
                <span className="mono" style={{ fontSize: 8.5, padding: '2px 6px', borderRadius: 999, background: accent + '14', color: accent, letterSpacing: '0.18em' }}>SURGE</span>
              )}
              <div className="mono" style={{ fontSize: 12.5, fontWeight: 600, color: '#0A0908' }}>{t.fare.toLocaleString()}</div>
            </div>
          ))}
        </div>
      </div>

      <DriverNav active="driverEarnings" onNav={nav} accent={accent} glass={glass} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 20 — ACTIVE DELIVERY (driver workflow)
// ─────────────────────────────────────────────────────────────
function DriverDeliveryScreen({ nav, accent, lang, glass, mapStyle }) {
  const [phase, setPhase] = React.useState(0); // 0 to pickup, 1 arrived, 2 trip, 3 complete
  const phases = lang === 'ar' ? [
    { title: 'متجه للاستلام', sub: 'سارة · ٣ دقائق · حي الرياض', cta: 'وصلت', next: 'إلى الراكب' },
    { title: 'في الموقع', sub: 'انتظار سارة · ٠:٤٢', cta: 'بدء الرحلة', next: 'بدأت الرحلة' },
    { title: 'في الرحلة', sub: 'إلى مطار الخرطوم · ٢٢ دقيقة', cta: 'إنهاء الرحلة', next: 'انتهت' },
    { title: 'اكتملت', sub: 'تم استلام ٤,٢٠٠ ج.س', cta: 'العودة للوحة', next: '' },
  ] : [
    { title: 'Heading to pickup', sub: 'Sara · 3 min · Riyadh District', cta: "I've arrived", next: 'Arrived at pickup' },
    { title: 'At pickup', sub: 'Waiting for Sara · 0:42', cta: 'Start trip', next: 'Trip started' },
    { title: 'On trip', sub: 'To KRT Airport · 22 min',  cta: 'Complete trip', next: 'Trip complete' },
    { title: 'Complete', sub: '4,200 SDG paid to wallet', cta: 'Back to drive', next: '' },
  ];
  const p = phases[phase];

  return (
    <div data-screen-label="20 Driver Trip" style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        <MapView style={mapStyle} accent={accent} showRoute pulse drivers={1} />
      </div>

      {/* Top bar */}
      <div style={{ position: 'absolute', top: 60, left: 16, right: 16, zIndex: 10, display: 'flex', gap: 10 }}>
        <button onClick={() => nav('driverHome')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.1)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <Glass intensity={glass} style={{
          flex: 1, borderRadius: 12, padding: '8px 14px',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{ width: 8, height: 8, borderRadius: '50%', background: accent, boxShadow: `0 0 0 4px ${accent}30`, animation: 'pulse-soft 1.6s ease-in-out infinite' }} />
          <div style={{ flex: 1 }}>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em' }}>{lang === 'ar' ? 'رحلة نشطة' : 'ACTIVE TRIP'}</div>
            <div style={{ fontSize: 13, fontWeight: 500 }}>{p.title}</div>
          </div>
          <span className="mono" style={{ fontSize: 11, color: '#0A0908', fontWeight: 600 }}>
            {phase === 0 ? '0:03:14' : phase === 1 ? '0:00:42' : phase === 2 ? '0:22:08' : '−'}
          </span>
        </Glass>
      </div>

      {/* Phase strip */}
      <div style={{ position: 'absolute', top: 116, left: 16, right: 16, zIndex: 9, display: 'flex', gap: 6 }}>
        {phases.slice(0, 4).map((_, i) => (
          <div key={i} style={{
            flex: 1, height: 3, borderRadius: 2,
            background: i <= phase ? accent : 'rgba(0,0,0,0.12)',
            transition: 'background 0.3s',
          }} />
        ))}
      </div>

      {/* Trip sheet */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 20,
        background: '#FBFAF6',
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '12px 18px 28px',
        boxShadow: '0 -10px 32px rgba(20,15,30,0.1)',
      }}>
        <div style={{ width: 38, height: 4, borderRadius: 2, background: 'var(--border-2)', margin: '0 auto 14px' }} />

        {/* Rider card */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <Avatar size={52} label="SA" tone="purple" />
          <div style={{ flex: 1 }}>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em' }}>{lang === 'ar' ? 'الراكب' : 'YOUR RIDER'}</div>
            <div className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em', marginTop: 2, lineHeight: 1 }}>Sara A.</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4, fontSize: 11.5, color: 'var(--text-2)' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                <Icon name="star" size={12} style={{ color: '#E4B73B' }} /> 4.9
              </span>
              <span>·</span>
              <span>{lang === 'ar' ? 'دفع: محفظة' : 'Wallet · 4,200 SDG'}</span>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button style={{
              width: 44, height: 44, borderRadius: 12, border: 0, cursor: 'pointer',
              background: '#0A0908', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="phone" size={16} strokeWidth={1.7} />
            </button>
            <button style={{
              width: 44, height: 44, borderRadius: 12, border: '0.5px solid var(--border)', cursor: 'pointer',
              background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="chat" size={16} strokeWidth={1.7} />
            </button>
          </div>
        </div>

        {/* Phase status block */}
        <div style={{
          marginTop: 16, padding: 16, borderRadius: 18,
          background: phase === 3 ? accent + '10' : '#fff',
          border: phase === 3 ? `1px solid ${accent}40` : '0.5px solid var(--border)',
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 13,
            background: phase === 3 ? accent : phase >= 2 ? '#1F8A5B' : 'var(--surface-2)',
            color: phase >= 2 ? '#fff' : '#0A0908',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name={phase === 3 ? 'check' : phase === 2 ? 'nav' : phase === 1 ? 'pin' : 'car'} size={20} strokeWidth={1.7} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 500 }}>{p.title}</div>
            <div style={{ fontSize: 12, color: 'var(--text-2)', marginTop: 2 }}>{p.sub}</div>
          </div>
          {phase === 3 && (
            <div className="serif" style={{ fontSize: 22, color: accent, letterSpacing: '-0.02em' }}>+4,200</div>
          )}
        </div>

        {/* Navigation hint */}
        {phase < 3 && (
          <button style={{
            marginTop: 10, width: '100%', appearance: 'none', cursor: 'pointer', border: 0,
            background: 'transparent', padding: '10px 14px', borderRadius: 12, textAlign: 'left',
            display: 'flex', alignItems: 'center', gap: 10, color: 'var(--text-2)',
          }}>
            <Icon name="nav" size={14} strokeWidth={1.8} style={{ color: accent }} />
            <span style={{ fontSize: 12, flex: 1 }}>{lang === 'ar' ? 'فتح الخرائط' : 'Open in Google Maps'}</span>
            <Icon name="chevron" size={12} />
          </button>
        )}

        {/* CTA */}
        <button onClick={() => {
          if (phase < 3) setPhase(phase + 1);
          else nav('driverHome');
        }} style={{
          marginTop: 14, width: '100%', appearance: 'none', cursor: 'pointer', border: 0,
          background: phase === 3 ? '#0A0908' : accent, color: '#fff',
          height: 56, borderRadius: 16,
          fontFamily: 'inherit', fontSize: 15, fontWeight: 600, letterSpacing: '-0.01em',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          boxShadow: phase === 3 ? '0 10px 24px rgba(10,9,8,0.25)' : `0 10px 24px ${accent}45`,
        }}>
          {p.cta}
          <Icon name={phase === 3 ? 'home' : 'arrow'} size={18} strokeWidth={1.8} />
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 21 — STORE DASHBOARD
// ─────────────────────────────────────────────────────────────
function StoreScreen({ nav, accent, lang, glass }) {
  const [tab, setTab] = React.useState('orders');
  const t = lang === 'ar' ? {
    kicker: 'لوحة المتجر',
    headline: 'سوليتير كافيه',
    sub: 'فرعان · ٤ كباتن · مفتوح حتى ٢٣:٠٠',
    orders: 'الطلبات', menu: 'القائمة', branches: 'الفروع',
    today: 'اليوم', revenue: 'الإيرادات', orderCount: 'الطلبات', avgT: 'متوسط', rating: 'تقييم',
    newOrder: 'طلب جديد',
  } : {
    kicker: 'STORE DASHBOARD · المتجر',
    headline: 'Solitaire Café',
    sub: '2 branches · 4 couriers · open till 23:00',
    orders: 'Orders', menu: 'Menu', branches: 'Branches',
    today: 'TODAY', revenue: 'REVENUE', orderCount: 'ORDERS', avgT: 'AVG TIME', rating: 'RATING',
    newOrder: 'New order',
  };

  const orders = [
    { id: '#5712', state: 'preparing', name: 'Ahmed H.', items: '2× cappuccino · 1× croissant', total: 3650, time: '4 min ago', courier: 'Mostafa I.' },
    { id: '#5711', state: 'courier',   name: 'Layla M.', items: '1× iced latte · 1× cake slice', total: 2400, time: '8 min ago', courier: 'Babiker H.' },
    { id: '#5710', state: 'new',       name: 'Omar M.',  items: '3× espresso · 2× sandwiches',  total: 4180, time: '1 min ago', courier: null },
    { id: '#5709', state: 'delivered', name: 'Sara A.',  items: '1× hot chocolate · 1× cake',   total: 1900, time: '22 min ago', courier: 'Yousef A.' },
    { id: '#5708', state: 'delivered', name: 'Khalid R.',items: '4× drinks · 2× pastries',      total: 5240, time: '35 min ago', courier: 'Yousef A.' },
  ];
  const stateMeta = {
    new:       { label: lang === 'ar' ? 'جديد' : 'NEW',         bg: accent,        fg: '#fff' },
    preparing: { label: lang === 'ar' ? 'تحضير' : 'PREPARING',   bg: '#0A0908',     fg: '#fff' },
    courier:   { label: lang === 'ar' ? 'مع الكابتن' : 'COURIER',bg: '#E4B73B',     fg: '#0A0908' },
    delivered: { label: lang === 'ar' ? 'اكتمل' : 'DELIVERED',   bg: 'var(--surface-2)', fg: 'var(--text-2)' },
  };

  return (
    <div data-screen-label="21 Store" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('role')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          {t.kicker}
        </span>
        <button style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 6px 16px ${accent}40`,
        }}>
          <Icon name="plus" size={18} strokeWidth={1.8} />
        </button>
      </div>

      {/* Brand strip */}
      <div style={{ padding: '24px 18px 0' }}>
        <div className="serif" style={{ fontSize: 36, lineHeight: 1, letterSpacing: '-0.025em' }}>
          {t.headline.split(' ').slice(0, -1).join(' ')} <span style={{ color: accent }}>{t.headline.split(' ').slice(-1)}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
          <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#1F8A5B', boxShadow: '0 0 0 3px rgba(31,138,91,0.18)' }} />
          <span style={{ fontSize: 12.5, color: 'var(--text-2)' }}>{t.sub}</span>
        </div>
      </div>

      {/* KPI grid */}
      <div style={{ padding: '20px 18px 0', display: 'grid', gridTemplateColumns: '2fr 1fr 1fr', gap: 8 }}>
        <div style={{ background: '#0A0908', color: '#fff', borderRadius: 18, padding: 14, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -30, right: -20, width: 140, height: 140, borderRadius: '50%', background: `radial-gradient(circle, ${accent}55, transparent 65%)` }} />
          <div className="mono" style={{ fontSize: 9, opacity: 0.55, letterSpacing: '0.28em', position: 'relative' }}>{t.today} · {t.revenue}</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 5, marginTop: 8, position: 'relative' }}>
            <span className="serif" style={{ fontSize: 32, letterSpacing: '-0.025em', lineHeight: 1 }}>84,200</span>
            <span className="mono" style={{ fontSize: 10, opacity: 0.55 }}>SDG</span>
          </div>
          <div style={{ fontSize: 10.5, opacity: 0.7, marginTop: 6, position: 'relative' }}>↑ 18% vs yesterday</div>
        </div>
        <div style={{ background: '#fff', borderRadius: 18, padding: 14, border: '0.5px solid var(--border)' }}>
          <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em' }}>{t.orderCount}</div>
          <div className="serif" style={{ fontSize: 30, letterSpacing: '-0.02em', lineHeight: 1, marginTop: 6 }}>42</div>
          <div style={{ fontSize: 10, color: 'var(--text-3)', marginTop: 4 }}>+ 6 active</div>
        </div>
        <div style={{ background: '#fff', borderRadius: 18, padding: 14, border: '0.5px solid var(--border)' }}>
          <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em' }}>{t.rating}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 6 }}>
            <span className="serif" style={{ fontSize: 30, letterSpacing: '-0.02em', lineHeight: 1 }}>4.8</span>
            <Icon name="star" size={12} style={{ color: '#E4B73B' }} />
          </div>
          <div style={{ fontSize: 10, color: 'var(--text-3)', marginTop: 4 }}>128 reviews</div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ padding: '24px 18px 0', display: 'flex', gap: 6 }}>
        {[
          { id: 'orders', label: t.orders },
          { id: 'menu', label: t.menu },
          { id: 'branches', label: t.branches },
        ].map(x => (
          <button key={x.id} onClick={() => setTab(x.id)} style={{
            appearance: 'none', cursor: 'pointer', border: 0,
            background: tab === x.id ? '#0A0908' : '#fff',
            color: tab === x.id ? '#fff' : '#0A0908',
            borderRadius: 999, padding: '8px 14px', fontSize: 12.5, fontWeight: 500,
            border: tab === x.id ? 0 : '0.5px solid var(--border)',
          }}>{x.label}</button>
        ))}
        <div style={{ flex: 1 }} />
        <button style={{
          appearance: 'none', cursor: 'pointer', border: 0, background: 'transparent',
          padding: '8px 10px', borderRadius: 999, fontSize: 12, color: 'var(--text-2)',
          display: 'flex', alignItems: 'center', gap: 4,
        }}>
          <Icon name="search" size={13} strokeWidth={1.7} /> Search
        </button>
      </div>

      {/* Content */}
      {tab === 'orders' && (
        <div style={{ padding: '14px 18px 100px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {orders.map(o => {
              const m = stateMeta[o.state];
              return (
                <div key={o.id} style={{
                  background: '#fff', borderRadius: 16, padding: 14,
                  border: '0.5px solid var(--border)',
                  display: 'flex', flexDirection: 'column', gap: 10,
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span className="mono" style={{ fontSize: 11, color: 'var(--text-3)', letterSpacing: '0.14em', fontWeight: 600 }}>{o.id}</span>
                    <span className="mono" style={{
                      fontSize: 9, padding: '3px 8px', borderRadius: 999,
                      background: m.bg, color: m.fg, letterSpacing: '0.2em', fontWeight: 600,
                    }}>{m.label}</span>
                    <div style={{ flex: 1 }} />
                    <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>{o.time.toUpperCase()}</span>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13.5, fontWeight: 500 }}>{o.name}</div>
                      <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2, lineHeight: 1.45 }}>{o.items}</div>
                      {o.courier && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 6 }}>
                          <Icon name="bike" size={11} style={{ color: 'var(--text-3)' }} />
                          <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.12em' }}>
                            {lang === 'ar' ? 'الكابتن' : 'COURIER'} · {o.courier.toUpperCase()}
                          </span>
                        </div>
                      )}
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em', lineHeight: 1 }}>{o.total.toLocaleString()}</div>
                      <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.2em', marginTop: 2 }}>SDG</div>
                    </div>
                  </div>

                  {o.state === 'new' && (
                    <div style={{ display: 'flex', gap: 6, paddingTop: 4 }}>
                      <button style={{
                        flex: 1, appearance: 'none', border: '0.5px solid var(--border)', cursor: 'pointer',
                        background: '#fff', height: 40, borderRadius: 12,
                        fontFamily: 'inherit', fontSize: 12.5, color: '#0A0908',
                      }}>{lang === 'ar' ? 'رفض' : 'Decline'}</button>
                      <button style={{
                        flex: 2, appearance: 'none', border: 0, cursor: 'pointer',
                        background: accent, color: '#fff', height: 40, borderRadius: 12,
                        fontFamily: 'inherit', fontSize: 12.5, fontWeight: 500,
                        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                      }}>
                        {lang === 'ar' ? 'قبول · استدعاء كابتن' : 'Accept & dispatch'} <Icon name="arrow" size={14} strokeWidth={1.8} />
                      </button>
                    </div>
                  )}
                  {o.state === 'preparing' && (
                    <button style={{
                      width: '100%', appearance: 'none', border: 0, cursor: 'pointer',
                      background: '#0A0908', color: '#fff', height: 40, borderRadius: 12,
                      fontFamily: 'inherit', fontSize: 12.5, fontWeight: 500,
                    }}>{lang === 'ar' ? 'جاهز · طلب كابتن' : 'Ready · request courier'}</button>
                  )}
                  {o.state === 'courier' && (
                    <div style={{
                      padding: '8px 12px', borderRadius: 12, background: '#FFF5DC',
                      display: 'flex', alignItems: 'center', gap: 8,
                    }}>
                      <Icon name="nav" size={13} style={{ color: '#9A7A0E' }} strokeWidth={1.8} />
                      <span style={{ fontSize: 11.5, color: '#7E6212', flex: 1 }}>
                        {lang === 'ar' ? 'الكابتن في الطريق · ٤ دقائق' : 'Courier en route · 4 min to drop-off'}
                      </span>
                      <span className="mono" style={{ fontSize: 10, color: '#7E6212', letterSpacing: '0.12em' }}>TRACK</span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}
      {tab === 'menu' && (
        <div style={{ padding: '14px 18px 100px' }}>
          {[
            { cat: lang === 'ar' ? 'مشروبات ساخنة' : 'HOT DRINKS', items: [
              { n: 'Cappuccino',  p: 1200, on: true },
              { n: 'Espresso',    p: 800,  on: true },
              { n: 'Macchiato',   p: 1400, on: true },
            ]},
            { cat: lang === 'ar' ? 'مشروبات باردة' : 'COLD DRINKS', items: [
              { n: 'Iced Latte',  p: 1400, on: true },
              { n: 'Cold Brew',   p: 1600, on: false },
            ]},
            { cat: lang === 'ar' ? 'مخبوزات' : 'BAKERY', items: [
              { n: 'Croissant',   p: 1100, on: true },
              { n: 'Cake slice',  p: 1500, on: true },
            ]},
          ].map((sec, i) => (
            <div key={i} style={{ marginBottom: 18 }}>
              <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginBottom: 8 }}>{sec.cat}</div>
              <div style={{ background: '#fff', borderRadius: 16, padding: '0 14px', border: '0.5px solid var(--border)' }}>
                {sec.items.map((it, j, arr) => (
                  <div key={j} style={{
                    display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0',
                    borderBottom: j < arr.length - 1 ? '0.5px solid var(--border)' : 0, opacity: it.on ? 1 : 0.5,
                  }}>
                    <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--surface-2)' }} />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 13.5, fontWeight: 500 }}>{it.n}</div>
                      <div className="mono" style={{ fontSize: 11, color: 'var(--text-3)', marginTop: 2 }}>{it.p.toLocaleString()} SDG</div>
                    </div>
                    <button style={{
                      width: 40, height: 24, borderRadius: 999, border: 0, cursor: 'pointer',
                      background: it.on ? '#1F8A5B' : '#D6D2C9',
                      position: 'relative',
                    }}>
                      <div style={{
                        width: 18, height: 18, borderRadius: '50%', background: '#fff',
                        position: 'absolute', top: 3, left: it.on ? 19 : 3,
                      }} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
      {tab === 'branches' && (
        <div style={{ padding: '14px 18px 100px' }}>
          {[
            { n: 'Riyadh District', addr: 'Block 32 · open till 23:00', staff: 6, orders: 28, primary: true },
            { n: 'Africa Road',      addr: 'Tower B · open till 22:00', staff: 4, orders: 14 },
          ].map((b, i) => (
            <div key={i} style={{
              background: b.primary ? '#0A0908' : '#fff', color: b.primary ? '#fff' : '#0A0908',
              borderRadius: 18, padding: 16, marginBottom: 10,
              border: b.primary ? 0 : '0.5px solid var(--border)',
              position: 'relative', overflow: 'hidden',
            }}>
              {b.primary && (
                <div style={{ position: 'absolute', top: -30, right: -20, width: 150, height: 150, borderRadius: '50%', background: `radial-gradient(circle, ${accent}50, transparent 65%)` }} />
              )}
              <div style={{ position: 'relative' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em' }}>{b.n}</div>
                  {b.primary && <span className="mono" style={{ fontSize: 9, padding: '3px 7px', borderRadius: 999, background: accent, color: '#fff', letterSpacing: '0.2em' }}>MAIN</span>}
                </div>
                <div style={{ fontSize: 12, opacity: 0.65, marginTop: 4 }}>{b.addr}</div>
                <div style={{ display: 'flex', gap: 22, marginTop: 14 }}>
                  <div>
                    <div className="mono" style={{ fontSize: 9, opacity: 0.55, letterSpacing: '0.22em' }}>STAFF</div>
                    <div className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em', marginTop: 2 }}>{b.staff}</div>
                  </div>
                  <div>
                    <div className="mono" style={{ fontSize: 9, opacity: 0.55, letterSpacing: '0.22em' }}>{lang === 'ar' ? 'طلبات اليوم' : 'ORDERS · TODAY'}</div>
                    <div className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em', marginTop: 2 }}>{b.orders}</div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

Object.assign(window, { RoleScreen, DriverHomeScreen, DriverEarningsScreen, DriverDeliveryScreen, StoreScreen });

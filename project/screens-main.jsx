// Wasilha — main app screens (Home, Booking, Tracking)

function HomeScreen({ nav, accent, lang, glass, cardLayout, mapStyle }) {
  const [openSheet, setOpenSheet] = React.useState(false);
  const routeFor = (id) => {
    if (id === 'food') return 'food';
    if (id === 'delivery') return 'parcel';
    return 'booking';
  };
  const services = [
  { id: 'raksha', icon: 'raksha', name: 'Raksha', ar: 'راكشة', sub: '2 min away', primary: true },
  { id: 'car', icon: 'car', name: 'Car', ar: 'سيارة', sub: '3 min away' },
  { id: 'bike', icon: 'bike', name: 'Motorcycle', ar: 'دراجة', sub: '1 min away' },
  { id: 'delivery', icon: 'bag', name: 'Delivery', ar: 'توصيل', sub: 'Send a parcel' },
  { id: 'food', icon: 'bowl', name: 'Food', ar: 'طعام', sub: '25–40 min' },
  { id: 'sched', icon: 'clock', name: 'Schedule', ar: 'مجدول', sub: 'Book later' }];

  const places = [
  { icon: 'home', name: 'Home', detail: 'Riyadh District' },
  { icon: 'work', name: 'Work', detail: 'Africa Road, Tower B' },
  { icon: 'plane', name: 'Khartoum Airport', detail: 'KRT · Terminal 1' }];


  return (
    <div data-screen-label="05 Home" style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        <MapView style={mapStyle} accent={accent} drivers={6} />
      </div>

      {/* Top bar */}
      <div style={{ position: 'absolute', top: 60, left: 16, right: 16, zIndex: 10, display: 'flex', gap: 10 }}>
        <Glass intensity={glass} style={{
          flex: 1, borderRadius: 999, padding: '10px 14px 10px 16px',
          display: 'flex', alignItems: 'center', gap: 10
        }}>
          <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#1F8A5B', boxShadow: '0 0 0 4px rgba(31,138,91,0.18)' }} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="mono" style={{ fontSize: 8.5, color: 'var(--text-3)', letterSpacing: '0.22em' }}>CURRENT LOCATION</div>
            <div style={{ fontSize: 13.5, fontWeight: 500, marginTop: 1, color: '#0A0908', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {lang === 'ar' ? 'الرياض، الخرطوم' : 'Riyadh District, Khartoum'}
            </div>
          </div>
          <Icon name="chevDown" size={14} style={{ color: 'var(--text-2)' }} />
        </Glass>
        <Glass intensity={glass} style={{
          borderRadius: 999, width: 44, height: 44,
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', position: 'relative'
        }}>
          <button onClick={() => nav('notifications')} style={{ all: 'unset', cursor: 'pointer', display: 'flex' }}>
            <Icon name="bell" size={18} strokeWidth={1.7} />
          </button>
          <div style={{ position: 'absolute', top: 10, right: 10, width: 7, height: 7, borderRadius: '50%', background: accent, border: '1.5px solid #fff' }} />
        </Glass>
      </div>

      {/* Origin pin on map */}
      <div style={{
        position: 'absolute', top: '38%', left: '46%', zIndex: 6,
        width: 16, height: 16, borderRadius: '50%',
        background: accent, border: '3px solid #fff',
        boxShadow: `0 0 0 4px ${accent}30, 0 6px 14px ${accent}50`
      }}>
        <div style={{
          position: 'absolute', inset: -8, borderRadius: '50%',
          background: accent, opacity: 0.2,
          animation: 'pulse-ring 2.4s ease-out infinite'
        }} />
      </div>

      {/* Recenter */}
      <button style={{
        position: 'absolute', right: 16, bottom: 412, zIndex: 8,
        width: 44, height: 44, borderRadius: 14, border: 0, cursor: 'pointer',
        background: '#fff', color: '#0A0908',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 1px 0 rgba(255,255,255,0.7) inset, 0 8px 22px rgba(20,15,30,0.12)'
      }}>
        <Icon name="target" size={18} strokeWidth={1.7} />
      </button>

      {/* Quick promo strip */}
      <div style={{
        position: 'absolute', left: 16, bottom: 412, zIndex: 8,
        display: 'flex', alignItems: 'center', gap: 10,
        background: '#0A0908', color: '#fff',
        padding: '8px 12px 8px 8px', borderRadius: 999,
        boxShadow: '0 10px 24px rgba(10,9,8,0.2)'
      }}>
        <div style={{
          width: 28, height: 28, borderRadius: '50%',
          background: accent, display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}>
          <Icon name="gift" size={14} strokeWidth={1.8} />
        </div>
        <span style={{ fontSize: 12, letterSpacing: '-0.005em' }}>20% off your next 3 rides</span>
      </div>

      {/* Bottom sheet */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 20,
        background: '#FBFAF6',
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '12px 18px 100px',
        boxShadow: '0 -8px 30px rgba(20,15,30,0.08)',
        maxHeight: '64%', overflowY: 'auto'
      }} className="no-scroll">
        <div style={{ width: 38, height: 4, borderRadius: 2, background: 'var(--border-2)', margin: '0 auto 14px' }} />

        {/* Where to */}
        <button onClick={() => nav('search')} style={{
          width: '100%', appearance: 'none', cursor: 'pointer',
          background: '#0A0908', color: '#fff',
          borderRadius: 18, padding: '14px 16px', border: 0,
          display: 'flex', alignItems: 'center', gap: 12,
          boxShadow: '0 10px 28px rgba(10,9,8,0.16)',
          textAlign: 'left', fontFamily: 'inherit',
        }}>
          <Icon name="search" size={18} strokeWidth={1.7} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 500 }}>{lang === 'ar' ? 'إلى أين؟' : 'Where to?'}</div>
            <div className="mono" style={{ fontSize: 10, color: 'rgba(255,255,255,0.55)', letterSpacing: '0.18em', marginTop: 2 }}>{lang === 'ar' ? 'ابحث عن وجهتك' : 'SEARCH ANY DESTINATION'}</div>
          </div>
          <div style={{
            padding: '6px 10px', borderRadius: 999,
            background: 'rgba(255,255,255,0.12)', fontSize: 11,
            display: 'flex', alignItems: 'center', gap: 4
          }}>
            <Icon name="clock" size={12} strokeWidth={1.8} /> {lang === 'ar' ? 'الآن' : 'Now'}
          </div>
        </button>

        {/* Saved chips */}
        <div style={{ display: 'flex', gap: 8, marginTop: 12, overflowX: 'auto' }} className="no-scroll">
          {places.map((p) =>
          <button key={p.name} style={{
            flexShrink: 0, appearance: 'none', border: 0, cursor: 'pointer',
            background: '#fff', borderRadius: 999, padding: '8px 14px 8px 10px',
            display: 'flex', alignItems: 'center', gap: 8,
            border: '0.5px solid var(--border)'
          }}>
              <Icon name={p.icon} size={14} strokeWidth={1.7} />
              <span style={{ fontSize: 12.5, fontWeight: 500 }}>{p.name}</span>
              <span style={{ fontSize: 11, color: 'var(--text-3)' }}>· {p.detail}</span>
            </button>
          )}
        </div>

        {/* Services header */}
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginTop: 22, marginBottom: 12 }}>
          <div>
            <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em' }}>SERVICES</div>
            <div className="serif" style={{ fontSize: 24, lineHeight: 1.1, letterSpacing: '-0.02em', marginTop: 2 }}>
              How would you like to <span style={{ color: accent }}>move?</span>
            </div>
          </div>
        </div>

        {cardLayout === 'pairs' ?
        <ConnectedPairsPuzzle lang={lang} offset={14} onTap={(serviceId) => nav(routeFor(serviceId))} /> :
        cardLayout === 'grid' ?
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
            {services.map((s) =>
          <ServiceCard key={s.id} {...s} accent={accent} lang={lang} layout="grid" onTap={() => nav(routeFor(s.id))} />
          )}
          </div> :

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {services.map((s) =>
          <ServiceCard key={s.id} {...s} accent={accent} lang={lang} layout="row" onTap={() => nav(routeFor(s.id))} />
          )}
          </div>
        }

        {/* Promotions carousel */}
        <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginTop: 22, marginBottom: 12 }}>
          PROMOTIONS
        </div>
        <div style={{ display: 'flex', gap: 10, overflowX: 'auto' }} className="no-scroll">
          {[
          { title: 'Ramadan rides', sub: '500 SDG off after sunset', tag: 'LIMITED', tone: 'dark' },
          { title: 'Refer a friend', sub: 'Both get 1,000 SDG credit', tag: 'EVERGREEN', tone: 'paper' },
          { title: 'Airport flat fare', sub: 'KRT terminals · 3,800 SDG', tag: 'NEW', tone: 'accent' }].
          map((p, i) =>
          <div key={i} style={{
            flexShrink: 0, width: 240, padding: '16px 16px 14px',
            borderRadius: 18, position: 'relative', overflow: 'hidden',
            background: p.tone === 'dark' ? '#0A0908' : p.tone === 'accent' ? accent : '#fff',
            color: p.tone === 'paper' ? '#0A0908' : '#fff',
            boxShadow: '0 8px 22px rgba(20,15,30,0.08)',
            border: p.tone === 'paper' ? '0.5px solid var(--border)' : 0
          }}>
              {p.tone === 'dark' &&
            <div style={{ position: 'absolute', top: -30, right: -30, width: 120, height: 120, borderRadius: '50%', background: `radial-gradient(circle, ${accent}60, transparent 70%)` }} />
            }
              <div className="mono" style={{ fontSize: 9, letterSpacing: '0.24em', opacity: 0.7 }}>{p.tag}</div>
              <div className="serif" style={{ fontSize: 22, lineHeight: 1.1, marginTop: 10 }}>{p.title}</div>
              <div style={{ fontSize: 12, opacity: 0.7, marginTop: 4 }}>{p.sub}</div>
            </div>
          )}
        </div>

        {/* Wallet quick view */}
        <div style={{ marginTop: 18, padding: 16, borderRadius: 18, background: '#fff', border: '0.5px solid var(--border)', display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 46, height: 46, borderRadius: 14, background: accent + '14', color: accent, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="wallet" size={20} strokeWidth={1.7} />
          </div>
          <div style={{ flex: 1 }}>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.24em' }}>WALLET</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 5, marginTop: 2 }}>
              <span className="serif" style={{ fontSize: 26, letterSpacing: '-0.02em', lineHeight: 1 }}>42,180</span>
              <span className="mono" style={{ fontSize: 10, color: 'var(--text-2)' }}>SDG</span>
            </div>
          </div>
          <button onClick={() => nav('topup')} style={{ all: 'unset', cursor: 'pointer', fontSize: 12, fontWeight: 500, padding: '8px 12px', borderRadius: 999, background: 'var(--surface-2)' }}>Top up</button>
        </div>
      </div>

      <BottomNav active="home" onNav={nav} accent={accent} glass={glass} />
    </div>);

}

// ─────────────────────────────────────────────────────────────
// 06 — BOOKING SHEET (full screen)
// ─────────────────────────────────────────────────────────────
function BookingScreen({ nav, accent, lang, glass, mapStyle }) {
  const [selected, setSelected] = React.useState('car');
  const rides = [
  { id: 'raksha', icon: 'raksha', name: 'Raksha', eta: '2 min', cap: '1 seat', price: 1850, sub: 'Most affordable' },
  { id: 'car', icon: 'car', name: 'Car', eta: '3 min', cap: '4 seats', price: 4200, sub: 'Comfort & A/C' },
  { id: 'bike', icon: 'bike', name: 'Motorcycle', eta: '1 min', cap: '1 seat', price: 2400, sub: 'Beat the traffic' },
  { id: 'xl', icon: 'car', name: 'Car XL', eta: '5 min', cap: '6 seats', price: 6800, sub: 'Extra space' }];


  return (
    <div data-screen-label="06 Booking" style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        <MapView style={mapStyle} accent={accent} showRoute pulse drivers={4} />
      </div>

      {/* Top: back + addresses */}
      <div style={{ position: 'absolute', top: 60, left: 16, right: 16, zIndex: 10 }}>
        <button onClick={() => nav('home')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 0 rgba(255,255,255,0.7) inset, 0 4px 14px rgba(20,15,30,0.1)'
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>

        <Glass intensity={glass} style={{ marginTop: 12, borderRadius: 18, padding: '12px 14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
              <div style={{ width: 9, height: 9, borderRadius: '50%', background: '#1F8A5B' }} />
              <div style={{ width: 1.5, height: 22, background: 'var(--border-2)' }} />
              <div style={{ width: 9, height: 9, borderRadius: 2, background: accent }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ paddingBottom: 8, borderBottom: '0.5px solid var(--border)' }}>
                <div className="mono" style={{ fontSize: 8.5, color: 'var(--text-3)', letterSpacing: '0.22em' }}>PICKUP</div>
                <div style={{ fontSize: 13.5, fontWeight: 500, marginTop: 1 }}>Riyadh District · Block 32</div>
              </div>
              <div style={{ paddingTop: 8 }}>
                <div className="mono" style={{ fontSize: 8.5, color: 'var(--text-3)', letterSpacing: '0.22em' }}>DESTINATION</div>
                <div style={{ fontSize: 13.5, fontWeight: 500, marginTop: 1 }}>Khartoum Airport · KRT</div>
              </div>
            </div>
            <button style={{ all: 'unset', cursor: 'pointer', color: 'var(--text-2)' }}>
              <Icon name="plus" size={16} strokeWidth={1.8} />
            </button>
          </div>
        </Glass>
      </div>

      {/* Route stats floating chip */}
      <div style={{
        position: 'absolute', top: 240, left: '50%', transform: 'translateX(-50%)',
        zIndex: 8
      }}>
        <Glass intensity={glass} style={{
          borderRadius: 999, padding: '6px 14px',
          display: 'flex', alignItems: 'center', gap: 10,
          fontFamily: 'Geist Mono, monospace', fontSize: 11
        }}>
          <span style={{ color: 'var(--text-3)' }}>18 KM</span>
          <span style={{ width: 3, height: 3, borderRadius: '50%', background: 'var(--text-3)' }} />
          <span style={{ color: '#0A0908', fontWeight: 600 }}>22 MIN</span>
          <span style={{ width: 3, height: 3, borderRadius: '50%', background: 'var(--text-3)' }} />
          <span style={{ color: accent }}>VIA AFRICA RD</span>
        </Glass>
      </div>

      {/* Booking sheet */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 20,
        background: '#FBFAF6',
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '12px 18px 30px',
        boxShadow: '0 -10px 32px rgba(20,15,30,0.1)',
        animation: 'sheet-in 0.5s cubic-bezier(0.2,0.8,0.2,1)'
      }}>
        <div style={{ width: 38, height: 4, borderRadius: 2, background: 'var(--border-2)', margin: '0 auto 14px' }} />

        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
          <div className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em' }}>
            Choose a <span style={{ color: accent }}>ride</span>
          </div>
          <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.22em' }}>4 OPTIONS</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 14 }}>
          {rides.map((r) => {
            const active = r.id === selected;
            return (
              <button key={r.id} onClick={() => setSelected(r.id)} style={{
                appearance: 'none', cursor: 'pointer', textAlign: 'left',
                border: active ? `1.5px solid ${accent}` : '0.5px solid var(--border)',
                background: active ? '#fff' : 'transparent',
                borderRadius: 16, padding: '12px 14px',
                display: 'flex', alignItems: 'center', gap: 14,
                boxShadow: active ? `0 8px 22px ${accent}1A` : 'none',
                transition: 'all 0.15s'
              }}>
                <div style={{
                  width: 42, height: 42, borderRadius: 12,
                  background: active ? accent + '14' : 'var(--surface-2)',
                  color: active ? accent : '#0A0908',
                  display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}>
                  <Icon name={r.icon} size={20} strokeWidth={1.6} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                    <span style={{ fontSize: 14.5, fontWeight: 500 }}>{r.name}</span>
                    <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>· {r.cap}</span>
                  </div>
                  <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2 }}>
                    {r.sub} <span className="mono" style={{ color: 'var(--text-3)' }}>· {r.eta}</span>
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div className="serif" style={{ fontSize: 20, lineHeight: 1, letterSpacing: '-0.02em' }}>
                    {r.price.toLocaleString()}
                  </div>
                  <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.18em', marginTop: 2 }}>SDG</div>
                </div>
              </button>);

          })}
        </div>

        {/* Payment row */}
        <div style={{
          display: 'flex', gap: 8, marginBottom: 14
        }}>
          <button style={{
            flex: 1, height: 44, borderRadius: 12, border: '0.5px solid var(--border)',
            background: '#fff', cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 10, padding: '0 12px',
            fontFamily: 'inherit', fontSize: 13
          }}>
            <Icon name="wallet" size={16} strokeWidth={1.7} />
            <span style={{ flex: 1, textAlign: 'left' }}>Wallet</span>
            <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>42,180</span>
            <Icon name="chevDown" size={12} style={{ color: 'var(--text-3)' }} />
          </button>
          <button style={{
            height: 44, padding: '0 14px', borderRadius: 12, border: '0.5px solid var(--border)',
            background: '#fff', cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 8,
            fontFamily: 'inherit', fontSize: 13
          }}>
            <Icon name="gift" size={16} strokeWidth={1.7} />
            Promo
          </button>
        </div>

        <Btn full accent={accent} onClick={() => nav('offer')} icon="arrow">
          Send offer · {rides.find((r) => r.id === selected).price.toLocaleString()} SDG
        </Btn>
      </div>
    </div>);

}

// ─────────────────────────────────────────────────────────────
// 07 — LIVE TRACKING
// ─────────────────────────────────────────────────────────────
function TrackingScreen({ nav, accent, lang, glass, mapStyle }) {
  const [phase, setPhase] = React.useState('arriving'); // arriving | enroute
  return (
    <div data-screen-label="07 Tracking" style={{ position: 'absolute', inset: 0, overflow: 'hidden' }}>
      <div style={{ position: 'absolute', inset: 0 }}>
        <MapView style={mapStyle} accent={accent} showRoute pulse drivers={2} />
      </div>

      {/* Top minimize bar */}
      <div style={{ position: 'absolute', top: 60, left: 16, right: 16, zIndex: 10, display: 'flex', gap: 10 }}>
        <button onClick={() => nav('home')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.1)'
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <Glass intensity={glass} style={{
          flex: 1, borderRadius: 12, padding: '8px 14px',
          display: 'flex', alignItems: 'center', gap: 10
        }}>
          <div style={{ width: 8, height: 8, borderRadius: '50%', background: accent, boxShadow: `0 0 0 4px ${accent}30`, animation: 'pulse-soft 1.6s ease-in-out infinite' }} />
          <div style={{ flex: 1 }}>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em' }}>TRIP</div>
            <div style={{ fontSize: 13, fontWeight: 500 }}>{phase === 'arriving' ? 'Driver is arriving' : 'En route to airport'}</div>
          </div>
          <span className="mono" style={{ fontSize: 12, color: '#0A0908', fontWeight: 600 }}>
            {phase === 'arriving' ? '2:14' : '22:08'}
          </span>
        </Glass>
      </div>

      {/* Phase toggle (demo) */}
      <div style={{ position: 'absolute', top: 116, left: 16, right: 16, zIndex: 9, display: 'flex', gap: 6, justifyContent: 'flex-end' }}>
        <button onClick={() => setPhase(phase === 'arriving' ? 'enroute' : 'arriving')} style={{
          fontFamily: 'Geist Mono, monospace', fontSize: 9.5, letterSpacing: '0.22em',
          padding: '6px 10px', borderRadius: 999,
          background: '#0A0908', color: '#fff', border: 0, cursor: 'pointer'
        }}>↻ TOGGLE PHASE</button>
      </div>

      {/* Tracking sheet */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 20,
        background: '#FBFAF6',
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '12px 18px 36px',
        boxShadow: '0 -10px 32px rgba(20,15,30,0.1)'
      }}>
        <div style={{ width: 38, height: 4, borderRadius: 2, background: 'var(--border-2)', margin: '0 auto 14px' }} />

        {/* Driver card */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <Avatar size={56} label="OM" tone="warm" />
          <div style={{ flex: 1 }}>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em' }}>YOUR DRIVER</div>
            <div className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em', marginTop: 2, lineHeight: 1 }}>Omar Mahmoud</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4, fontSize: 11.5, color: 'var(--text-2)' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                <Icon name="star" size={12} style={{ color: '#E4B73B' }} /> 4.96
              </span>
              <span>·</span>
              <span className="mono">2,108 rides</span>
            </div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: 13, fontWeight: 500 }}>Corolla</div>
            <div className="mono" style={{ fontSize: 13, fontWeight: 600, marginTop: 2, letterSpacing: '0.16em' }}>KRT · 4421</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 4, justifyContent: 'flex-end' }}>
              <span style={{ width: 10, height: 10, borderRadius: 2, background: '#fff', border: '0.5px solid var(--border-2)' }} />
              <span style={{ fontSize: 11, color: 'var(--text-2)' }}>White</span>
            </div>
          </div>
        </div>

        {/* Action row */}
        <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
          <button style={{
            flex: 1, height: 50, borderRadius: 14, border: 0, cursor: 'pointer',
            background: '#0A0908', color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            fontFamily: 'inherit', fontSize: 13.5, fontWeight: 500
          }}>
            <Icon name="phone" size={16} strokeWidth={1.7} /> Call
          </button>
          <button style={{
            flex: 1, height: 50, borderRadius: 14, border: '0.5px solid var(--border)', cursor: 'pointer',
            background: '#fff', color: '#0A0908',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            fontFamily: 'inherit', fontSize: 13.5, fontWeight: 500
          }}>
            <Icon name="chat" size={16} strokeWidth={1.7} /> Message
          </button>
          <button onClick={() => nav('sos')} style={{
            height: 50, width: 50, borderRadius: 14, border: '0.5px solid var(--border)', cursor: 'pointer',
            background: '#fff', color: '#0A0908',
            display: 'flex', alignItems: 'center', justifyContent: 'center'
          }}>
            <Icon name="shield" size={18} strokeWidth={1.7} />
          </button>
        </div>

        {/* Trip timeline */}
        <div style={{ marginTop: 18, padding: 14, borderRadius: 14, background: '#fff', border: '0.5px solid var(--border)' }}>
          {[
          { icon: 'check', label: 'Request accepted', meta: '21:14', done: true },
          { icon: 'car', label: phase === 'arriving' ? 'Driver heading your way' : 'You\'re on the way', meta: phase === 'arriving' ? '2 min away' : '22 min remaining', active: true },
          { icon: 'pin', label: 'Arrive at destination', meta: 'KRT · Terminal 1', pending: true }].
          map((s, i, arr) =>
          <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 12, paddingBottom: i < arr.length - 1 ? 14 : 0, position: 'relative' }}>
              {i < arr.length - 1 && <div style={{ position: 'absolute', left: 13, top: 26, bottom: 0, width: 1.5, background: 'var(--border-2)' }} />}
              <div style={{
              width: 28, height: 28, borderRadius: '50%', flexShrink: 0,
              background: s.active ? accent : s.done ? '#0A0908' : 'var(--surface-2)',
              color: s.active || s.done ? '#fff' : 'var(--text-2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: s.active ? `0 0 0 4px ${accent}1F` : 'none'
            }}>
                <Icon name={s.icon} size={13} strokeWidth={2} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13.5, fontWeight: s.active ? 600 : 500, color: s.pending ? 'var(--text-2)' : '#0A0908' }}>{s.label}</div>
                <div className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.14em', marginTop: 2 }}>{s.meta}</div>
              </div>
            </div>
          )}
        </div>

        {/* Fare summary */}
        <button onClick={() => nav('complete')} style={{
          marginTop: 12, width: '100%', appearance: 'none', border: 0, cursor: 'pointer',
          display: 'flex', alignItems: 'center', gap: 10, padding: '12px 14px', borderRadius: 14, background: 'var(--surface-2)',
          textAlign: 'left'
        }}>
          <Icon name="wallet" size={16} strokeWidth={1.7} style={{ color: 'var(--text-2)' }} />
          <span style={{ fontSize: 13, color: 'var(--text-2)', flex: 1 }}>{lang === 'ar' ? 'المحفظة · الأجرة' : 'Wallet · ending fare'}</span>
          <span className="serif" style={{ fontSize: 20, letterSpacing: '-0.02em' }}>4,200</span>
          <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.18em' }}>SDG</span>
        </button>
      </div>
    </div>);

}

Object.assign(window, { HomeScreen, BookingScreen, TrackingScreen });
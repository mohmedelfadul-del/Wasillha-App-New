// ─────────────────────────────────────────────────────────────
// OFFER / NEGOTIATE SCREEN — Wasilha's signature fare bidding
// User sets a fare → nearby drivers counter-offer in real time.
// Inspired by inDrive, redesigned in Wasilha's editorial glass.
// ─────────────────────────────────────────────────────────────

function OfferScreen({ nav, accent, lang, glass, mapStyle }) {
  const t = lang === 'ar' ? {
    title: 'حدّد أجرتك',
    sub: 'سيُرسل عرضك إلى السائقين القريبين',
    your: 'عرضك',
    fair: 'النطاق العادل',
    sdg: 'ج.س',
    suggested: 'مقترح',
    searching: 'جاري البحث',
    nearby: 'سائق قريب',
    bids: 'العروض الواردة',
    accept: 'قبول',
    counter: 'عرض مضاد',
    matches: 'مطابق',
    cancel: 'إلغاء الطلب',
    raise: 'رفع العرض',
    eta: 'دقيقة',
  } : {
    title: 'Set your fare',
    sub: 'Your offer is sent to drivers nearby',
    your: 'YOUR OFFER',
    fair: 'FAIR RANGE',
    sdg: 'SDG',
    suggested: 'Fair',
    searching: 'Searching',
    nearby: 'drivers nearby',
    bids: 'Counter offers',
    accept: 'Accept',
    counter: 'counter',
    matches: 'matches',
    cancel: 'Cancel request',
    raise: 'Raise offer',
    eta: 'min',
  };

  const FAIR_LO = 3800;
  const FAIR_HI = 4600;
  const SUGGESTED = 4200;

  const [offer, setOffer] = React.useState(SUGGESTED);
  const [searching, setSearching] = React.useState(true);
  const [bids, setBids] = React.useState([]);

  const ALL_BIDS = React.useMemo(() => ([
    {
      id: 'b1', name: 'Mohamed A.', rating: 4.9, trips: 1284,
      car: 'Toyota Corolla · White', plate: 'KRT · 4821',
      vehicle: 'car', eta: 3, distance: 0.8, delta: +200, tone: 'sand',
    },
    {
      id: 'b2', name: 'Hassan O.', rating: 4.8, trips: 612,
      car: 'Hyundai Accent · Silver', plate: 'KRT · 9134',
      vehicle: 'car', eta: 5, distance: 1.4, delta: -200, tone: 'olive',
    },
    {
      id: 'b3', name: 'Omar K.', rating: 4.7, trips: 2014,
      car: 'Toyota Hilux · Beige', plate: 'OMD · 1209',
      vehicle: 'car', eta: 6, distance: 2.1, delta: +400, tone: 'clay',
    },
    {
      id: 'b4', name: 'Ahmed S.', rating: 5.0, trips: 318,
      car: 'Kia Picanto · Navy', plate: 'KRT · 7716',
      vehicle: 'car', eta: 4, distance: 1.1, delta: 0, tone: 'ink',
    },
  ]), []);

  // Stagger bid arrivals
  React.useEffect(() => {
    setBids([]);
    setSearching(true);
    const timers = [];
    ALL_BIDS.forEach((b, i) => {
      timers.push(setTimeout(() => {
        setBids((prev) => [...prev, b]);
      }, 600 + i * 750));
    });
    timers.push(setTimeout(() => setSearching(false), 600 + ALL_BIDS.length * 750 + 200));
    return () => timers.forEach(clearTimeout);
  }, [ALL_BIDS]);

  const fmt = (n) => n.toLocaleString();
  const within = offer >= FAIR_LO && offer <= FAIR_HI;
  const fairPct = Math.max(0, Math.min(100,
    ((offer - (FAIR_LO - 800)) / ((FAIR_HI + 800) - (FAIR_LO - 800))) * 100
  ));

  const quickAdjust = (delta) => setOffer((v) => Math.max(800, Math.min(15000, v + delta)));

  return (
    <div data-screen-label="08b Offer" style={{ position: 'absolute', inset: 0, overflow: 'hidden', background: '#FBFAF6' }}>
      {/* Faint map under everything */}
      <div style={{ position: 'absolute', inset: 0, opacity: 0.45 }}>
        <MapView style={mapStyle} accent={accent} showRoute pulse={false} drivers={6} />
      </div>
      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(180deg, rgba(251,250,246,0.4) 0%, rgba(251,250,246,0.92) 38%, #FBFAF6 60%)'
      }} />

      <div className="no-scroll" style={{ position: 'absolute', inset: 0, overflowY: 'auto', paddingTop: 56 }}>
        {/* Top nav */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 18px 4px' }}>
          <button onClick={() => nav('booking')} style={{
            width: 38, height: 38, borderRadius: 12, border: '0.5px solid var(--border)', cursor: 'pointer',
            background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 14px rgba(20,15,30,0.06)'
          }}>
            <Icon name="back" size={17} strokeWidth={1.7} />
          </button>
          <div style={{ flex: 1 }}>
            <div className="serif" style={{ fontSize: 20, lineHeight: 1.05, letterSpacing: '-0.02em' }}>
              {t.title}
            </div>
            <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2 }}>{t.sub}</div>
          </div>
          <div className="mono" style={{
            fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.22em',
            borderLeft: '0.5px solid var(--border-2)', paddingLeft: 10, textAlign: 'right'
          }}>
            22 MIN<br/>18 KM
          </div>
        </div>

        {/* Fare hero card */}
        <div style={{ padding: '14px 18px 0' }}>
          <div style={{
            position: 'relative',
            background: '#0A0908', color: '#fff',
            borderRadius: 24, padding: '18px 18px 16px',
            boxShadow: `0 18px 40px rgba(20,15,30,0.18), 0 0 0 1px rgba(255,255,255,0.04) inset`,
            overflow: 'hidden',
          }}>
            {/* Decorative ring */}
            <div style={{
              position: 'absolute', right: -60, top: -60, width: 200, height: 200,
              borderRadius: '50%',
              background: `radial-gradient(circle, ${accent}55 0%, transparent 65%)`,
              pointerEvents: 'none',
            }} />

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <span className="mono" style={{ fontSize: 9.5, letterSpacing: '0.28em', color: 'rgba(255,255,255,0.55)' }}>
                {t.your}
              </span>
              <span className="mono" style={{
                fontSize: 9.5, letterSpacing: '0.22em',
                color: within ? '#9DEACB' : '#F0B27A',
                display: 'flex', alignItems: 'center', gap: 6
              }}>
                <span style={{
                  width: 6, height: 6, borderRadius: '50%',
                  background: within ? '#1F8A5B' : '#E4A93A',
                  boxShadow: within ? '0 0 8px #1F8A5B' : '0 0 8px #E4A93A',
                }} />
                {within ? 'IN FAIR RANGE' : (offer < FAIR_LO ? 'BELOW FAIR' : 'ABOVE FAIR')}
              </span>
            </div>

            {/* Editable amount */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: 18,
              margin: '12px 0 6px'
            }}>
              <button onClick={() => quickAdjust(-200)} aria-label="decrease" style={{
                width: 44, height: 44, borderRadius: 16, border: '0.5px solid rgba(255,255,255,0.14)',
                background: 'rgba(255,255,255,0.05)', color: '#fff', cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="minus" size={18} strokeWidth={1.8} />
              </button>
              <div style={{ flex: 1, textAlign: 'center' }}>
                <div className="serif" style={{
                  fontSize: 56, lineHeight: 1, letterSpacing: '-0.04em',
                  fontFeatureSettings: '"tnum"',
                }}>
                  {fmt(offer)}
                </div>
                <div className="mono" style={{
                  fontSize: 10, letterSpacing: '0.34em', color: 'rgba(255,255,255,0.45)', marginTop: 4
                }}>
                  {t.sdg}
                </div>
              </div>
              <button onClick={() => quickAdjust(200)} aria-label="increase" style={{
                width: 44, height: 44, borderRadius: 16, border: `0.5px solid ${accent}66`,
                background: accent + '24', color: '#fff', cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: `0 0 14px ${accent}33`,
              }}>
                <Icon name="plus" size={18} strokeWidth={1.8} />
              </button>
            </div>

            {/* Fair-range track */}
            <div style={{ marginTop: 14 }}>
              <div style={{
                position: 'relative', height: 6, borderRadius: 3,
                background: 'rgba(255,255,255,0.08)',
                overflow: 'visible',
              }}>
                {/* Fair zone */}
                <div style={{
                  position: 'absolute',
                  left: `${(((FAIR_LO) - (FAIR_LO - 800)) / ((FAIR_HI + 800) - (FAIR_LO - 800))) * 100}%`,
                  right: `${100 - (((FAIR_HI) - (FAIR_LO - 800)) / ((FAIR_HI + 800) - (FAIR_LO - 800))) * 100}%`,
                  top: 0, bottom: 0, borderRadius: 3,
                  background: 'rgba(157,234,203,0.35)',
                }} />
                {/* Thumb */}
                <div style={{
                  position: 'absolute', top: '50%', left: `${fairPct}%`,
                  transform: 'translate(-50%, -50%)',
                  width: 14, height: 14, borderRadius: '50%',
                  background: accent,
                  boxShadow: `0 0 0 3px #0A0908, 0 0 12px ${accent}`,
                }} />
              </div>
              <div style={{
                display: 'flex', justifyContent: 'space-between',
                fontSize: 10, color: 'rgba(255,255,255,0.5)', marginTop: 6,
                fontFamily: 'Geist Mono, monospace', letterSpacing: '0.06em',
              }}>
                <span>{fmt(FAIR_LO - 800)}</span>
                <span style={{ color: '#9DEACB' }}>{fmt(FAIR_LO)} — {fmt(FAIR_HI)} {t.fair.toLowerCase()}</span>
                <span>{fmt(FAIR_HI + 800)}</span>
              </div>
            </div>

            {/* Quick chips */}
            <div style={{ display: 'flex', gap: 6, marginTop: 14 }}>
              {[
                { lbl: '−500', d: -500 },
                { lbl: '−200', d: -200 },
                { lbl: t.suggested, d: 'fair' },
                { lbl: '+200', d: 200 },
                { lbl: '+500', d: 500 },
              ].map((c, i) => (
                <button key={i}
                  onClick={() => c.d === 'fair' ? setOffer(SUGGESTED) : quickAdjust(c.d)}
                  style={{
                    flex: 1, height: 32, borderRadius: 10,
                    border: c.d === 'fair' ? `0.5px solid ${accent}80` : '0.5px solid rgba(255,255,255,0.1)',
                    background: c.d === 'fair' ? accent + '22' : 'rgba(255,255,255,0.04)',
                    color: '#fff', cursor: 'pointer',
                    fontFamily: c.d === 'fair' ? 'Instrument Serif, serif' : 'Geist Mono, monospace',
                    fontSize: c.d === 'fair' ? 14 : 11.5,
                    letterSpacing: c.d === 'fair' ? '-0.01em' : '0.08em',
                  }}>{c.lbl}</button>
              ))}
            </div>
          </div>
        </div>

        {/* Searching status */}
        <div style={{
          margin: '18px 18px 6px', display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{
            position: 'relative', width: 10, height: 10,
          }}>
            <div style={{
              position: 'absolute', inset: 0, borderRadius: '50%',
              background: searching ? accent : '#1F8A5B',
            }} />
            {searching && (
              <div style={{
                position: 'absolute', inset: -4, borderRadius: '50%',
                border: `1.5px solid ${accent}`,
                animation: 'ws-ping 1.2s ease-out infinite',
              }} />
            )}
          </div>
          <div style={{ fontSize: 12.5, color: '#0A0908', letterSpacing: '-0.005em' }}>
            {searching ? (
              <>
                <span style={{ fontWeight: 500 }}>{t.searching}</span>
                <span className="mono" style={{ color: 'var(--text-3)', fontSize: 10.5, marginLeft: 8, letterSpacing: '0.16em' }}>
                  · 12 {t.nearby.toUpperCase()}
                </span>
              </>
            ) : (
              <>
                <span style={{ fontWeight: 500 }}>{bids.length} {t.counter}{lang === 'en' ? 's' : ''}</span>
                <span className="mono" style={{ color: 'var(--text-3)', fontSize: 10.5, marginLeft: 8, letterSpacing: '0.16em' }}>
                  · TAP TO ACCEPT
                </span>
              </>
            )}
          </div>
          <div style={{ flex: 1 }} />
          <span className="mono" style={{
            fontSize: 9.5, letterSpacing: '0.22em', color: 'var(--text-3)',
            textTransform: 'uppercase',
          }}>{t.bids}</span>
        </div>

        {/* Bids list */}
        <div style={{ padding: '0 18px 24px', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {bids.map((b, i) => {
            const counter = offer + b.delta;
            const cheaper = b.delta < 0;
            const matches = b.delta === 0;
            return (
              <div key={b.id}
                style={{
                  background: '#fff',
                  borderRadius: 18, padding: '12px 14px',
                  border: '0.5px solid var(--border)',
                  boxShadow: '0 6px 18px rgba(20,15,30,0.05)',
                  display: 'flex', alignItems: 'center', gap: 12,
                  animation: 'ws-bid-in 0.42s cubic-bezier(0.2,0.85,0.2,1) both',
                }}>
                <Avatar size={42} label={b.name.split(' ').map(p => p[0]).join('')} tone={b.tone} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
                    <span style={{ fontSize: 13.5, fontWeight: 500, letterSpacing: '-0.005em' }}>{b.name}</span>
                    <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>★ {b.rating.toFixed(1)}</span>
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--text-2)', marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {b.car}
                  </div>
                  <div className="mono" style={{
                    fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.14em', marginTop: 3,
                    display: 'flex', gap: 8, alignItems: 'center',
                  }}>
                    <span>{b.eta} {t.eta.toUpperCase()}</span>
                    <span style={{ width: 2, height: 2, borderRadius: '50%', background: 'var(--text-3)' }} />
                    <span>{b.distance} KM</span>
                  </div>
                </div>
                <div style={{ textAlign: 'right', marginRight: 4 }}>
                  <div style={{
                    display: 'inline-flex', alignItems: 'baseline', gap: 4,
                  }}>
                    <span className="serif" style={{
                      fontSize: 22, letterSpacing: '-0.02em', lineHeight: 1,
                      color: matches ? '#1F8A5B' : '#0A0908',
                    }}>
                      {fmt(counter)}
                    </span>
                  </div>
                  <div style={{
                    fontSize: 9.5, marginTop: 3,
                    fontFamily: 'Geist Mono, monospace', letterSpacing: '0.14em',
                    color: matches ? '#1F8A5B' : (cheaper ? '#1F8A5B' : '#B05A1F'),
                  }}>
                    {matches ? t.matches.toUpperCase() : (b.delta > 0 ? `+${b.delta}` : `${b.delta}`)}
                  </div>
                </div>
                <button onClick={() => nav('tracking')} style={{
                  appearance: 'none', cursor: 'pointer',
                  background: accent, color: '#fff', border: 0,
                  width: 38, height: 38, borderRadius: 12,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: `0 6px 14px ${accent}55`,
                }} aria-label={t.accept}>
                  <Icon name="arrow" size={16} strokeWidth={2} />
                </button>
              </div>
            );
          })}

          {/* Skeleton placeholders while searching */}
          {searching && Array.from({ length: Math.max(0, 3 - bids.length) }).map((_, i) => (
            <div key={'sk' + i} style={{
              background: '#fff',
              borderRadius: 18, padding: '12px 14px',
              border: '0.5px dashed var(--border-2)',
              display: 'flex', alignItems: 'center', gap: 12,
              opacity: 0.65 - i * 0.18,
            }}>
              <div style={{
                width: 42, height: 42, borderRadius: '50%',
                background: 'var(--surface-2)',
                animation: 'ws-pulse 1.6s ease-in-out infinite',
              }} />
              <div style={{ flex: 1 }}>
                <div style={{ height: 10, width: '45%', background: 'var(--surface-2)', borderRadius: 4, animation: 'ws-pulse 1.6s ease-in-out infinite' }} />
                <div style={{ height: 8, width: '60%', background: 'var(--surface-2)', borderRadius: 4, marginTop: 6, animation: 'ws-pulse 1.6s ease-in-out infinite' }} />
              </div>
              <div style={{ width: 56, height: 24, background: 'var(--surface-2)', borderRadius: 6, animation: 'ws-pulse 1.6s ease-in-out infinite' }} />
            </div>
          ))}
        </div>

        {/* Bottom actions */}
        <div style={{ padding: '0 18px 32px', display: 'flex', gap: 8 }}>
          <button onClick={() => nav('home')} style={{
            flex: 1, height: 48, borderRadius: 14,
            border: '0.5px solid var(--border)',
            background: '#fff', color: '#0A0908', cursor: 'pointer',
            fontFamily: 'inherit', fontSize: 13.5, letterSpacing: '-0.005em',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
            <Icon name="close" size={14} strokeWidth={1.8} />
            {t.cancel}
          </button>
          <button onClick={() => quickAdjust(200)} style={{
            flex: 1, height: 48, borderRadius: 14, border: 0, cursor: 'pointer',
            background: '#0A0908', color: '#fff',
            fontFamily: 'inherit', fontSize: 13.5, letterSpacing: '-0.005em',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
            {t.raise} <span className="mono" style={{ fontSize: 11, letterSpacing: '0.1em', opacity: 0.7 }}>+200</span>
          </button>
        </div>
      </div>

      {/* Animations */}
      <style>{`
        @keyframes ws-bid-in {
          from { opacity: 0; transform: translateY(10px) scale(0.985); }
          to   { opacity: 1; transform: translateY(0) scale(1); }
        }
        @keyframes ws-ping {
          0% { transform: scale(0.6); opacity: 1; }
          100% { transform: scale(2.2); opacity: 0; }
        }
        @keyframes ws-pulse {
          0%, 100% { opacity: 0.5; }
          50% { opacity: 0.9; }
        }
      `}</style>
    </div>
  );
}

Object.assign(window, { OfferScreen });

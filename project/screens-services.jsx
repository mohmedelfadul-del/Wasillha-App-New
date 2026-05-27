// ─────────────────────────────────────────────────────────────
// EXTRA SERVICES — Food delivery, Parcel send, Driver requests feed
// Rounds out Wasilha's multi-service positioning.
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// FOOD DELIVERY — restaurant page with menu + floating cart
// ─────────────────────────────────────────────────────────────
function FoodScreen({ nav, accent, lang }) {
  const t = lang === 'ar' ? {
    title: 'عروس النيل',
    sub: 'مطبخ سوداني · الخرطوم',
    rating: 'تقييم',
    delivery: 'توصيل',
    fee: 'رسوم',
    categories: ['الأشهر', 'فطور', 'رئيسية', 'مشاوي', 'حلويات', 'مشروبات'],
    addToCart: 'إضافة',
    view: 'عرض السلة',
    items: 'صنف',
    sdg: 'ج.س',
  } : {
    title: 'Aroos al-Nile',
    sub: 'Sudanese kitchen · Khartoum',
    rating: 'RATING',
    delivery: 'DELIVERY',
    fee: 'FEE',
    categories: ['Popular', 'Breakfast', 'Mains', 'Grill', 'Sweets', 'Drinks'],
    addToCart: 'Add',
    view: 'View basket',
    items: 'items',
    sdg: 'SDG',
  };

  const menu = [
    { id: 'm1', name: lang === 'ar' ? 'فول مدمس' : 'Foul Medames', sub: lang === 'ar' ? 'فاصوليا، طحينة، زيت زيتون' : 'Fava beans, tahini, olive oil', price: 950, tone: '#E8DAB6' },
    { id: 'm2', name: lang === 'ar' ? 'كسرة بالملاح' : 'Kisra & Mullah', sub: lang === 'ar' ? 'خبز ذرة + مرق بامية' : 'Sorghum bread, okra stew', price: 1450, tone: '#C8B89C' },
    { id: 'm3', name: lang === 'ar' ? 'مشوي خرطومي' : 'Khartoumi Grill', sub: lang === 'ar' ? 'لحم ضأن مع سلطة' : 'Lamb, salad, lemon', price: 3850, tone: '#B86E4B' },
    { id: 'm4', name: lang === 'ar' ? 'شاي بالحليب' : 'Spiced Milk Tea', sub: lang === 'ar' ? 'هيل، قرنفل، زنجبيل' : 'Cardamom, clove, ginger', price: 380, tone: '#D7B889' },
  ];

  const [cart, setCart] = React.useState({ m1: 1, m3: 1 });
  const cartCount = Object.values(cart).reduce((a, b) => a + b, 0);
  const cartTotal = menu.reduce((sum, m) => sum + (cart[m.id] || 0) * m.price, 0);
  const [cat, setCat] = React.useState(t.categories[0]);

  const inc = (id) => setCart((c) => ({ ...c, [id]: (c[id] || 0) + 1 }));
  const dec = (id) => setCart((c) => ({ ...c, [id]: Math.max(0, (c[id] || 0) - 1) }));

  return (
    <div data-screen-label="Food" className="no-scroll" style={{
      position: 'absolute', inset: 0, overflow: 'auto', background: '#FBFAF6',
    }}>
      {/* Restaurant hero */}
      <div style={{
        position: 'relative', height: 240,
        background: `linear-gradient(135deg, #B86E4B 0%, #8C4B30 55%, #5A2E1E 100%)`,
        overflow: 'hidden',
      }}>
        {/* Decorative pattern */}
        <svg width="100%" height="100%" style={{ position: 'absolute', inset: 0, opacity: 0.15 }} preserveAspectRatio="none">
          <defs>
            <pattern id="grain" x="0" y="0" width="40" height="40" patternUnits="userSpaceOnUse">
              <circle cx="20" cy="20" r="0.8" fill="#FBFAF6" />
              <circle cx="0" cy="0" r="0.6" fill="#FBFAF6" />
              <circle cx="40" cy="40" r="0.6" fill="#FBFAF6" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#grain)" />
        </svg>
        {/* Back / share */}
        <div style={{ position: 'absolute', top: 56, left: 16, right: 16, display: 'flex', gap: 10, alignItems: 'center', zIndex: 2 }}>
          <button onClick={() => nav('home')} style={{
            width: 38, height: 38, borderRadius: 12, border: 0, cursor: 'pointer',
            background: 'rgba(255,255,255,0.9)', backdropFilter: 'blur(10px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><Icon name="back" size={17} strokeWidth={1.7} /></button>
          <div style={{ flex: 1 }} />
          <button style={{
            width: 38, height: 38, borderRadius: 12, border: 0, cursor: 'pointer',
            background: 'rgba(255,255,255,0.9)', backdropFilter: 'blur(10px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><Icon name="star" size={17} strokeWidth={1.7} /></button>
        </div>

        {/* Title block */}
        <div style={{ position: 'absolute', left: 18, right: 18, bottom: 22, color: '#FBFAF6', zIndex: 2 }}>
          <div className="mono" style={{ fontSize: 10, letterSpacing: '0.28em', opacity: 0.7 }}>S-04 · FOOD</div>
          <div className="serif" style={{ fontSize: 34, letterSpacing: '-0.02em', lineHeight: 1.05, marginTop: 6 }}>
            {t.title}
          </div>
          <div style={{ fontSize: 12.5, opacity: 0.85, marginTop: 4 }}>{t.sub}</div>
        </div>
      </div>

      {/* Stats strip */}
      <div style={{
        margin: '-22px 18px 0', position: 'relative', zIndex: 3,
        background: '#fff', borderRadius: 18, padding: '14px 16px',
        border: '0.5px solid var(--border)',
        boxShadow: '0 14px 32px rgba(20,15,30,0.10)',
        display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
      }}>
        {[
          { lbl: t.rating, val: '4.8', sub: '· 1.2k' },
          { lbl: t.delivery, val: '22', sub: 'min' },
          { lbl: t.fee, val: '350', sub: t.sdg },
        ].map((s, i) => (
          <div key={i} style={{
            paddingLeft: i > 0 ? 14 : 0,
            borderLeft: i > 0 ? '0.5px solid var(--border)' : 'none',
          }}>
            <div className="mono" style={{ fontSize: 9, letterSpacing: '0.22em', color: 'var(--text-3)' }}>
              {t.rating === s.lbl ? t.rating : s.lbl}
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 4 }}>
              <span className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em', lineHeight: 1 }}>{s.val}</span>
              <span style={{ fontSize: 10.5, color: 'var(--text-3)' }}>{s.sub}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Categories */}
      <div style={{
        margin: '20px 0 8px', padding: '0 18px',
        display: 'flex', gap: 6, overflowX: 'auto',
      }}>
        {t.categories.map((c) => (
          <button key={c} onClick={() => setCat(c)} style={{
            flexShrink: 0, padding: '8px 14px', borderRadius: 999, cursor: 'pointer',
            border: c === cat ? '0.5px solid #0A0908' : '0.5px solid var(--border)',
            background: c === cat ? '#0A0908' : '#fff',
            color: c === cat ? '#fff' : '#0A0908',
            fontFamily: 'inherit', fontSize: 12.5,
          }}>{c}</button>
        ))}
      </div>

      {/* Menu */}
      <div style={{ padding: '8px 18px 120px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {menu.map((m) => {
          const qty = cart[m.id] || 0;
          return (
            <div key={m.id} style={{
              background: '#fff', borderRadius: 18, padding: 12,
              border: '0.5px solid var(--border)',
              display: 'flex', gap: 12, alignItems: 'center',
            }}>
              <div style={{
                width: 72, height: 72, borderRadius: 14, flexShrink: 0,
                background: `linear-gradient(135deg, ${m.tone}, ${m.tone}cc)`,
                position: 'relative', overflow: 'hidden',
              }}>
                <div style={{ position: 'absolute', inset: 0, background: 'repeating-linear-gradient(135deg, rgba(255,255,255,0.0) 0 8px, rgba(255,255,255,0.08) 8px 16px)' }} />
                <div className="mono" style={{ position: 'absolute', left: 8, bottom: 6, fontSize: 8, color: 'rgba(0,0,0,0.4)', letterSpacing: '0.12em' }}>
                  DISH
                </div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 500, letterSpacing: '-0.005em' }}>{m.name}</div>
                <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {m.sub}
                </div>
                <div className="serif" style={{ fontSize: 18, marginTop: 4, letterSpacing: '-0.02em' }}>
                  {m.price.toLocaleString()} <span className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.2em' }}>{t.sdg}</span>
                </div>
              </div>
              {qty === 0 ? (
                <button onClick={() => inc(m.id)} style={{
                  border: '0.5px solid var(--border)', background: '#fff', cursor: 'pointer',
                  width: 34, height: 34, borderRadius: 10,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name="plus" size={16} strokeWidth={1.8} />
                </button>
              ) : (
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 4,
                  background: '#0A0908', borderRadius: 10, padding: 3,
                }}>
                  <button onClick={() => dec(m.id)} style={{ border: 0, background: 'transparent', cursor: 'pointer', color: '#fff', width: 26, height: 26, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Icon name="minus" size={14} strokeWidth={1.8} />
                  </button>
                  <span className="mono" style={{ color: '#fff', minWidth: 14, textAlign: 'center', fontSize: 12 }}>{qty}</span>
                  <button onClick={() => inc(m.id)} style={{ border: 0, background: 'transparent', cursor: 'pointer', color: '#fff', width: 26, height: 26, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Icon name="plus" size={14} strokeWidth={1.8} />
                  </button>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Floating cart */}
      {cartCount > 0 && (
        <div style={{
          position: 'absolute', left: 18, right: 18, bottom: 26, zIndex: 30,
          animation: 'ws-cart-in 0.4s cubic-bezier(0.2,0.85,0.2,1) both',
        }}>
          <button onClick={() => nav('tracking')} style={{
            width: '100%', height: 58, borderRadius: 18, border: 0, cursor: 'pointer',
            background: accent, color: '#fff',
            display: 'flex', alignItems: 'center', gap: 12, padding: '0 14px 0 18px',
            boxShadow: `0 14px 30px ${accent}55, 0 2px 0 rgba(255,255,255,0.2) inset`,
            fontFamily: 'inherit',
          }}>
            <span className="mono" style={{
              background: 'rgba(0,0,0,0.18)', borderRadius: 10,
              padding: '4px 10px', fontSize: 11, letterSpacing: '0.12em',
            }}>{cartCount} {t.items.toUpperCase()}</span>
            <span style={{ flex: 1, textAlign: 'left', fontSize: 14.5, letterSpacing: '-0.005em' }}>
              {t.view}
            </span>
            <span className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em' }}>
              {cartTotal.toLocaleString()}
            </span>
            <Icon name="arrow" size={16} strokeWidth={1.9} />
          </button>
        </div>
      )}

      <style>{`
        @keyframes ws-cart-in {
          from { opacity: 0; transform: translateY(20px); }
          to   { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// PARCEL DELIVERY — send a package
// ─────────────────────────────────────────────────────────────
function ParcelScreen({ nav, accent, lang, glass }) {
  const t = lang === 'ar' ? {
    title: 'إرسال طرد',
    sub: 'سيستلمه السائق من بابك',
    from: 'من',
    to: 'إلى',
    pickup: 'الرياض · بلوك ٣٢',
    drop: 'بحري · العزبة',
    sender: 'المرسل',
    receiver: 'المستلم',
    name: 'الاسم',
    phone: 'الهاتف',
    size: 'الحجم',
    notes: 'ملاحظات للسائق',
    notesPh: 'مثال: اتصل عند الوصول',
    sdg: 'ج.س',
    confirm: 'تأكيد الطلب',
    estimate: 'تقدير',
    sizes: [
      { id: 'xs', lbl: 'صغير', sub: 'وثائق', price: 1200 },
      { id: 's', lbl: 'متوسط', sub: 'حقيبة صغيرة', price: 1800 },
      { id: 'm', lbl: 'كبير', sub: 'صندوق', price: 2800 },
    ],
  } : {
    title: 'Send a parcel',
    sub: 'A driver picks up from your door',
    from: 'FROM',
    to: 'TO',
    pickup: 'Riyadh · Block 32',
    drop: 'Bahri · Al-Izba',
    sender: 'SENDER',
    receiver: 'RECEIVER',
    name: 'Name',
    phone: 'Phone',
    size: 'Package size',
    notes: 'Driver notes',
    notesPh: 'e.g. call on arrival',
    sdg: 'SDG',
    confirm: 'Confirm pickup',
    estimate: 'Estimate',
    sizes: [
      { id: 'xs', lbl: 'Envelope', sub: 'Docs · <1kg', price: 1200 },
      { id: 's', lbl: 'Small box', sub: 'Handbag · 1–5kg', price: 1800 },
      { id: 'm', lbl: 'Large box', sub: 'Suitcase · 5–15kg', price: 2800 },
    ],
  };

  const [size, setSize] = React.useState('s');
  const current = t.sizes.find((s) => s.id === size);

  return (
    <div data-screen-label="Parcel" className="no-scroll" style={{
      position: 'absolute', inset: 0, overflow: 'auto', background: '#FBFAF6',
    }}>
      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '64px 18px 6px' }}>
        <button onClick={() => nav('home')} style={{
          width: 38, height: 38, borderRadius: 12, border: '0.5px solid var(--border)', cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><Icon name="back" size={17} strokeWidth={1.7} /></button>
        <div style={{ flex: 1 }}>
          <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.22em', color: 'var(--text-3)' }}>S-03 · COURIER</div>
          <div className="serif" style={{ fontSize: 22, letterSpacing: '-0.02em', lineHeight: 1.05, marginTop: 2 }}>
            {t.title}
          </div>
          <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2 }}>{t.sub}</div>
        </div>
      </div>

      <div style={{ padding: '14px 18px 140px' }}>
        {/* From → To */}
        <div style={{
          background: '#fff', borderRadius: 18, padding: 14,
          border: '0.5px solid var(--border)',
          boxShadow: '0 6px 18px rgba(20,15,30,0.04)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
              <div style={{ width: 9, height: 9, borderRadius: '50%', background: '#1F8A5B' }} />
              <div style={{ width: 1.5, height: 22, background: 'var(--border-2)' }} />
              <div style={{ width: 9, height: 9, borderRadius: 2, background: accent }} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ paddingBottom: 8, borderBottom: '0.5px solid var(--border)' }}>
                <div className="mono" style={{ fontSize: 8.5, color: 'var(--text-3)', letterSpacing: '0.22em' }}>{t.from}</div>
                <div style={{ fontSize: 13.5, fontWeight: 500, marginTop: 1 }}>{t.pickup}</div>
              </div>
              <div style={{ paddingTop: 8 }}>
                <div className="mono" style={{ fontSize: 8.5, color: 'var(--text-3)', letterSpacing: '0.22em' }}>{t.to}</div>
                <div style={{ fontSize: 13.5, fontWeight: 500, marginTop: 1 }}>{t.drop}</div>
              </div>
            </div>
          </div>
        </div>

        {/* Sizes */}
        <div style={{ marginTop: 18 }}>
          <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.22em', color: 'var(--text-3)', marginBottom: 8 }}>
            {t.size.toUpperCase()}
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {t.sizes.map((s) => {
              const active = s.id === size;
              return (
                <button key={s.id} onClick={() => setSize(s.id)} style={{
                  flex: 1, appearance: 'none', cursor: 'pointer', textAlign: 'left',
                  background: active ? '#fff' : 'transparent',
                  border: active ? `1.5px solid ${accent}` : '0.5px solid var(--border)',
                  borderRadius: 14, padding: '12px 12px 14px',
                  boxShadow: active ? `0 8px 22px ${accent}1A` : 'none',
                }}>
                  <div style={{
                    width: 28, height: 28, borderRadius: 8,
                    background: active ? accent + '22' : 'var(--surface-2)',
                    color: active ? accent : '#0A0908',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <Icon name="bag" size={15} strokeWidth={1.7} />
                  </div>
                  <div style={{ fontSize: 12.5, fontWeight: 500, marginTop: 8, letterSpacing: '-0.005em' }}>{s.lbl}</div>
                  <div style={{ fontSize: 10.5, color: 'var(--text-2)', marginTop: 1 }}>{s.sub}</div>
                  <div className="serif" style={{ fontSize: 15, letterSpacing: '-0.02em', marginTop: 6 }}>
                    {s.price.toLocaleString()}
                    <span className="mono" style={{ fontSize: 8.5, color: 'var(--text-3)', letterSpacing: '0.2em', marginLeft: 3 }}>{t.sdg}</span>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Receiver info */}
        <div style={{ marginTop: 18 }}>
          <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.22em', color: 'var(--text-3)', marginBottom: 8 }}>
            {t.receiver}
          </div>
          <div style={{
            background: '#fff', borderRadius: 16, padding: 4,
            border: '0.5px solid var(--border)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', padding: '8px 12px', gap: 10, borderBottom: '0.5px solid var(--border)' }}>
              <Icon name="user" size={16} strokeWidth={1.7} style={{ color: 'var(--text-3)' }} />
              <input defaultValue={lang === 'ar' ? 'فاطمة محمد' : 'Fatima Mohamed'} placeholder={t.name} style={{
                flex: 1, border: 0, outline: 'none', background: 'transparent',
                fontFamily: 'inherit', fontSize: 13.5, color: '#0A0908',
              }} />
            </div>
            <div style={{ display: 'flex', alignItems: 'center', padding: '8px 12px', gap: 10 }}>
              <Icon name="phone" size={16} strokeWidth={1.7} style={{ color: 'var(--text-3)' }} />
              <input defaultValue="+249 91 234 5678" placeholder={t.phone} style={{
                flex: 1, border: 0, outline: 'none', background: 'transparent',
                fontFamily: 'inherit', fontSize: 13.5, color: '#0A0908',
              }} />
            </div>
          </div>
        </div>

        {/* Notes */}
        <div style={{ marginTop: 18 }}>
          <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.22em', color: 'var(--text-3)', marginBottom: 8 }}>
            {t.notes.toUpperCase()}
          </div>
          <textarea placeholder={t.notesPh} rows={2} style={{
            width: '100%', background: '#fff', borderRadius: 14, border: '0.5px solid var(--border)',
            padding: 12, fontFamily: 'inherit', fontSize: 13, resize: 'none', outline: 'none',
            color: '#0A0908', boxSizing: 'border-box',
          }} />
        </div>
      </div>

      {/* Bottom bar */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        padding: '14px 18px 26px',
        background: 'linear-gradient(180deg, rgba(251,250,246,0) 0%, #FBFAF6 30%)',
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12,
          padding: '10px 14px', borderRadius: 14,
          background: '#fff', border: '0.5px solid var(--border)',
        }}>
          <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.22em', color: 'var(--text-3)' }}>
            {t.estimate.toUpperCase()}
          </div>
          <div style={{ flex: 1 }} />
          <div className="serif" style={{ fontSize: 24, letterSpacing: '-0.02em', lineHeight: 1 }}>
            {current.price.toLocaleString()}
            <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.2em', marginLeft: 4 }}>{t.sdg}</span>
          </div>
        </div>
        <Btn full accent={accent} onClick={() => nav('tracking')} icon="arrow">
          {t.confirm}
        </Btn>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// DRIVER REQUESTS FEED — incoming ride bids, inDrive-style
// Symmetric to OfferScreen but from the driver's side.
// ─────────────────────────────────────────────────────────────
function DriverRequestsScreen({ nav, accent, lang, glass, mapStyle }) {
  const t = lang === 'ar' ? {
    online: 'متصل',
    earnings: 'الأرباح اليوم',
    feed: 'طلبات قريبة',
    nearby: 'سائق نشط',
    accept: 'قبول',
    counter: 'عرض مضاد',
    minAway: 'دقيقة',
    sdg: 'ج.س',
    decline: 'تجاهل',
    back: 'رجوع',
  } : {
    online: 'ONLINE',
    earnings: "TODAY'S EARNINGS",
    feed: 'NEARBY REQUESTS',
    nearby: 'active drivers',
    accept: 'Accept',
    counter: 'Counter',
    minAway: 'min away',
    sdg: 'SDG',
    decline: 'Skip',
    back: 'Back',
  };

  const ALL = [
    {
      id: 'r1', name: 'Amna H.', tone: 'sand', rating: 4.9,
      from: 'Riyadh District', to: 'Khartoum Airport',
      offer: 4400, distance: 18.2, etaMin: 4, pax: 1,
      vibe: 'high',
    },
    {
      id: 'r2', name: 'Salah K.', tone: 'olive', rating: 4.7,
      from: 'Khartoum 2', to: 'Souq Arabi',
      offer: 1800, distance: 4.6, etaMin: 2, pax: 2,
      vibe: 'low',
    },
    {
      id: 'r3', name: 'Layla M.', tone: 'clay', rating: 5.0,
      from: 'Garden City', to: 'Bahri Bridge',
      offer: 3200, distance: 9.1, etaMin: 6, pax: 1,
      vibe: 'mid',
    },
  ];

  const [requests, setRequests] = React.useState([]);
  const [skipped, setSkipped] = React.useState({});

  React.useEffect(() => {
    setRequests([]);
    const timers = [];
    ALL.forEach((r, i) => {
      timers.push(setTimeout(() => setRequests((prev) => [...prev, r]), 350 + i * 600));
    });
    return () => timers.forEach(clearTimeout);
  }, []);

  return (
    <div data-screen-label="Driver Feed" className="no-scroll" style={{
      position: 'absolute', inset: 0, overflow: 'auto', background: '#0A0908', color: '#FBFAF6',
    }}>
      {/* Top status */}
      <div style={{
        padding: '62px 18px 16px',
        background: 'linear-gradient(180deg, #14110F 0%, #0A0908 100%)',
        borderBottom: '0.5px solid rgba(255,255,255,0.06)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <button onClick={() => nav('driverHome')} style={{
            width: 38, height: 38, borderRadius: 12, border: '0.5px solid rgba(255,255,255,0.1)', cursor: 'pointer',
            background: 'rgba(255,255,255,0.04)', color: '#FBFAF6',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><Icon name="back" size={17} strokeWidth={1.7} /></button>

          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            background: 'rgba(31,138,91,0.16)',
            border: '0.5px solid rgba(31,138,91,0.4)',
            borderRadius: 999, padding: '6px 12px 6px 10px',
          }}>
            <span style={{
              width: 8, height: 8, borderRadius: '50%', background: '#1F8A5B',
              boxShadow: '0 0 8px #1F8A5B',
            }} />
            <span className="mono" style={{ fontSize: 10.5, letterSpacing: '0.22em', color: '#9DEACB' }}>
              {t.online}
            </span>
          </div>
          <div style={{ flex: 1 }} />
          <Avatar size={36} label="YA" tone="ink" />
        </div>

        {/* Earnings */}
        <div style={{ marginTop: 16, display: 'flex', alignItems: 'flex-end', gap: 18 }}>
          <div style={{ flex: 1 }}>
            <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.28em', color: 'rgba(255,255,255,0.45)' }}>
              {t.earnings}
            </div>
            <div className="serif" style={{ fontSize: 42, letterSpacing: '-0.03em', lineHeight: 1, marginTop: 6 }}>
              28,450
              <span className="mono" style={{ fontSize: 11, letterSpacing: '0.24em', color: 'rgba(255,255,255,0.45)', marginLeft: 6 }}>
                {t.sdg}
              </span>
            </div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.22em', color: 'rgba(255,255,255,0.45)' }}>
              TRIPS
            </div>
            <div style={{ fontSize: 22, marginTop: 4, fontFamily: 'Instrument Serif, serif', letterSpacing: '-0.02em' }}>
              9 <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.45)' }}>/ 12</span>
            </div>
          </div>
        </div>
      </div>

      {/* Feed header */}
      <div style={{ display: 'flex', alignItems: 'center', padding: '20px 18px 10px' }}>
        <div style={{
          width: 8, height: 8, borderRadius: '50%', background: accent,
          boxShadow: `0 0 10px ${accent}`,
          marginRight: 10,
        }} />
        <div className="mono" style={{ fontSize: 11, letterSpacing: '0.22em' }}>
          {t.feed}
        </div>
        <div style={{ flex: 1 }} />
        <span className="mono" style={{ fontSize: 9.5, letterSpacing: '0.18em', color: 'rgba(255,255,255,0.45)' }}>
          247 {t.nearby.toUpperCase()}
        </span>
      </div>

      {/* Requests */}
      <div style={{ padding: '0 18px 30px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {requests.filter((r) => !skipped[r.id]).map((r) => (
          <div key={r.id} style={{
            background: 'rgba(255,255,255,0.04)',
            border: '0.5px solid rgba(255,255,255,0.08)',
            borderRadius: 20, padding: '14px 14px 12px',
            animation: 'ws-bid-in 0.42s cubic-bezier(0.2,0.85,0.2,1) both',
            position: 'relative', overflow: 'hidden',
          }}>
            {/* glow accent */}
            {r.vibe === 'high' && (
              <div style={{
                position: 'absolute', right: -40, top: -40, width: 140, height: 140, borderRadius: '50%',
                background: `radial-gradient(circle, ${accent}40 0%, transparent 70%)`,
                pointerEvents: 'none',
              }} />
            )}

            {/* header */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <Avatar size={36} label={r.name.split(' ').map(p => p[0]).join('')} tone={r.tone} />
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
                  <span style={{ fontSize: 13.5, fontWeight: 500 }}>{r.name}</span>
                  <span className="mono" style={{ fontSize: 10, color: 'rgba(255,255,255,0.55)' }}>★ {r.rating.toFixed(1)}</span>
                </div>
                <div className="mono" style={{ fontSize: 9.5, color: 'rgba(255,255,255,0.45)', letterSpacing: '0.14em', marginTop: 2 }}>
                  {r.etaMin} {t.minAway.toUpperCase()} · {r.distance} KM · {r.pax} PAX
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div className="serif" style={{ fontSize: 26, letterSpacing: '-0.02em', lineHeight: 1 }}>
                  {r.offer.toLocaleString()}
                </div>
                <div className="mono" style={{ fontSize: 9, color: 'rgba(255,255,255,0.45)', letterSpacing: '0.22em', marginTop: 3 }}>
                  {t.sdg}
                </div>
              </div>
            </div>

            {/* route */}
            <div style={{
              marginTop: 12, display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 12px', borderRadius: 12,
              background: 'rgba(255,255,255,0.04)',
            }}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
                <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#9DEACB' }} />
                <div style={{ width: 1, height: 14, background: 'rgba(255,255,255,0.2)' }} />
                <div style={{ width: 6, height: 6, borderRadius: 1, background: accent }} />
              </div>
              <div style={{ flex: 1, minWidth: 0, fontSize: 11.5, lineHeight: 1.5 }}>
                <div style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.from}</div>
                <div style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', opacity: 0.7 }}>{r.to}</div>
              </div>
            </div>

            {/* actions */}
            <div style={{ display: 'flex', gap: 6, marginTop: 10 }}>
              <button onClick={() => setSkipped((s) => ({ ...s, [r.id]: true }))} style={{
                width: 44, height: 42, borderRadius: 12, border: '0.5px solid rgba(255,255,255,0.1)',
                background: 'rgba(255,255,255,0.04)', color: '#FBFAF6', cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }} aria-label={t.decline}>
                <Icon name="close" size={15} strokeWidth={1.8} />
              </button>
              <button style={{
                flex: 1, height: 42, borderRadius: 12,
                background: 'rgba(255,255,255,0.06)', color: '#FBFAF6',
                border: '0.5px solid rgba(255,255,255,0.1)', cursor: 'pointer',
                fontFamily: 'inherit', fontSize: 12.5, letterSpacing: '-0.005em',
              }}>{t.counter}</button>
              <button onClick={() => nav('driverDelivery')} style={{
                flex: 1.4, height: 42, borderRadius: 12, border: 0, cursor: 'pointer',
                background: accent, color: '#FBFAF6',
                fontFamily: 'inherit', fontSize: 13, letterSpacing: '-0.005em',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                boxShadow: `0 6px 18px ${accent}55`,
              }}>
                {t.accept}
                <Icon name="arrow" size={14} strokeWidth={2} />
              </button>
            </div>
          </div>
        ))}

        {requests.length === 0 && (
          <div style={{
            padding: '24px', borderRadius: 18,
            border: '0.5px dashed rgba(255,255,255,0.1)',
            color: 'rgba(255,255,255,0.55)',
            textAlign: 'center', fontSize: 12,
          }}>
            <div className="mono" style={{
              fontSize: 10.5, letterSpacing: '0.22em', color: 'rgba(255,255,255,0.4)',
            }}>
              · LISTENING ·
            </div>
            <div style={{ marginTop: 8 }}>Waiting for nearby riders to send offers.</div>
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { FoodScreen, ParcelScreen, DriverRequestsScreen });

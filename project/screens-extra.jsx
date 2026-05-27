// Wasilha — extended screens
// 13 Search · 14 Trip Complete + Rating · 15 Top-up · 16 SOS / Safety

// ─────────────────────────────────────────────────────────────
// 13 — DESTINATION SEARCH
// ─────────────────────────────────────────────────────────────
function SearchScreen({ nav, accent, lang, glass }) {
  const [q, setQ] = React.useState('');
  const t = lang === 'ar' ? {
    where: 'إلى أين؟', pickup: 'الانطلاق', recent: 'الأخيرة', saved: 'المحفوظة',
    suggested: 'مقترحة لك', placeholder: 'ابحث عن موقع أو حي…',
    cancel: 'إلغاء', confirm: 'تأكيد الوجهة',
  } : {
    where: 'Where to?', pickup: 'PICKUP', recent: 'RECENT', saved: 'SAVED',
    suggested: 'SUGGESTED', placeholder: 'Search place or district…',
    cancel: 'Cancel', confirm: 'Confirm destination',
  };

  const recent = lang === 'ar' ? [
    { icon: 'history', name: 'مطار الخرطوم الدولي', detail: 'المبنى ١ · ٢٢ كم' },
    { icon: 'history', name: 'سوق العربي', detail: 'وسط الخرطوم · ٦ كم' },
    { icon: 'history', name: 'برج المنارة', detail: 'العمارات · ٤ كم' },
  ] : [
    { icon: 'history', name: 'Khartoum Intl. Airport', detail: 'Terminal 1 · 22 km' },
    { icon: 'history', name: 'Souq Arabi', detail: 'Downtown Khartoum · 6 km' },
    { icon: 'history', name: 'Al Manara Tower', detail: 'Amarat · 4 km' },
  ];
  const saved = lang === 'ar' ? [
    { icon: 'home', name: 'المنزل', detail: 'بلوك ٣٢، حي الرياض' },
    { icon: 'work', name: 'العمل', detail: 'شارع أفريقيا، برج B' },
  ] : [
    { icon: 'home', name: 'Home', detail: 'Block 32, Riyadh District' },
    { icon: 'work', name: 'Work', detail: 'Africa Road, Tower B' },
  ];
  const suggestions = lang === 'ar' ? [
    { icon: 'pin', name: 'جامعة الخرطوم', detail: '٣٫٢ كم · ١٢ دقيقة', tag: 'POPULAR' },
    { icon: 'pin', name: 'مستشفى رويال كير', detail: '٢٫٤ كم · ٩ دقائق', tag: '24H' },
    { icon: 'pin', name: 'افنيو مول', detail: '٥٫٨ كم · ١٧ دقيقة', tag: 'OPEN' },
    { icon: 'pin', name: 'محطة الموقف الجديد', detail: '٧٫١ كم · ٢١ دقيقة', tag: 'TRANSIT' },
  ] : [
    { icon: 'pin', name: 'University of Khartoum', detail: '3.2 km · 12 min', tag: 'POPULAR' },
    { icon: 'pin', name: 'Royal Care Hospital', detail: '2.4 km · 9 min', tag: '24H' },
    { icon: 'pin', name: 'Avenue Mall', detail: '5.8 km · 17 min', tag: 'OPEN' },
    { icon: 'pin', name: 'Mawqif Bus Station', detail: '7.1 km · 21 min', tag: 'TRANSIT' },
  ];

  return (
    <div data-screen-label="13 Search" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', display: 'flex', flexDirection: 'column' }}>
      {/* Top */}
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', gap: 10 }}>
        <button onClick={() => nav('home')} style={{
          appearance: 'none', border: 0, background: 'transparent', cursor: 'pointer',
          fontFamily: 'inherit', fontSize: 13, color: 'var(--text-2)',
        }}>{t.cancel}</button>
        <div style={{ flex: 1 }} />
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          DESTINATION · الوجهة
        </span>
        <div style={{ flex: 1 }} />
        <div style={{ width: 40 }} />
      </div>

      {/* Editorial */}
      <div style={{ padding: '16px 18px 0' }}>
        <div className="serif" style={{ fontSize: 40, lineHeight: 1, letterSpacing: '-0.025em' }}>
          {lang === 'ar' ? <>إلى <span style={{ color: accent }}>أين؟</span></> : <>{t.where.slice(0,-1)} <span style={{ color: accent }}>{t.where.slice(-1)}</span></>}
        </div>
        <div style={{ fontSize: 13, color: 'var(--text-2)', marginTop: 6 }}>
          {lang === 'ar' ? 'ابحث، أو اختر من أماكنك المحفوظة.' : 'Search or tap a saved place to begin.'}
        </div>
      </div>

      {/* Stops field */}
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          background: '#fff', borderRadius: 18, padding: '4px',
          border: '0.5px solid var(--border)',
          boxShadow: '0 1px 0 rgba(255,255,255,0.7) inset, 0 8px 22px rgba(20,15,30,0.05)',
        }}>
          {/* Pickup row */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '14px',
            borderBottom: '0.5px solid var(--border)',
          }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#1F8A5B', flexShrink: 0 }} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="mono" style={{ fontSize: 8.5, color: 'var(--text-3)', letterSpacing: '0.22em' }}>{t.pickup}</div>
              <div style={{ fontSize: 13.5, fontWeight: 500, marginTop: 1 }}>
                {lang === 'ar' ? 'الموقع الحالي · حي الرياض' : 'Current location · Riyadh District'}
              </div>
            </div>
            <Icon name="target" size={14} style={{ color: 'var(--text-3)' }} />
          </div>
          {/* Destination input */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px' }}>
            <div style={{ width: 8, height: 8, borderRadius: 2, background: accent, flexShrink: 0 }} />
            <input
              autoFocus
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder={t.placeholder}
              dir={lang === 'ar' ? 'rtl' : 'ltr'}
              style={{
                flex: 1, border: 0, outline: 'none', background: 'transparent',
                fontFamily: 'inherit', fontSize: 15, fontWeight: 500,
                color: '#0A0908', minWidth: 0,
              }}
            />
            {q && (
              <button onClick={() => setQ('')} style={{
                width: 22, height: 22, borderRadius: '50%', border: 0, cursor: 'pointer',
                background: 'var(--surface-2)', display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="close" size={12} strokeWidth={2} />
              </button>
            )}
          </div>
        </div>

        {/* Add stop button */}
        <button style={{
          marginTop: 10, padding: '10px 14px', borderRadius: 999,
          border: '0.5px dashed var(--border-2)', background: 'transparent', cursor: 'pointer',
          fontFamily: 'inherit', fontSize: 12.5, color: 'var(--text-2)',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <Icon name="plus" size={13} strokeWidth={2} />
          {lang === 'ar' ? 'إضافة محطة' : 'Add a stop'}
        </button>
      </div>

      {/* Quick actions row */}
      <div style={{ padding: '20px 18px 0', display: 'flex', gap: 8 }}>
        {[
          { icon: 'home', label: lang === 'ar' ? 'المنزل' : 'Home' },
          { icon: 'work', label: lang === 'ar' ? 'العمل' : 'Work' },
          { icon: 'plane', label: lang === 'ar' ? 'المطار' : 'Airport' },
          { icon: 'plus', label: lang === 'ar' ? 'إضافة' : 'Add' },
        ].map((s, i) => (
          <button key={i} style={{
            flex: 1, appearance: 'none', border: 0, cursor: 'pointer',
            background: i === 3 ? 'transparent' : '#fff',
            borderRadius: 14, padding: '12px 0',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
            borderTop: i === 3 ? '0.5px dashed var(--border-2)' : 0,
            borderRight: i === 3 ? '0.5px dashed var(--border-2)' : 0,
            borderBottom: i === 3 ? '0.5px dashed var(--border-2)' : 0,
            borderLeft: i === 3 ? '0.5px dashed var(--border-2)' : 0,
            boxShadow: i !== 3 ? '0 1px 2px rgba(0,0,0,0.04)' : 'none',
            color: i === 3 ? 'var(--text-2)' : '#0A0908',
          }}>
            <Icon name={s.icon} size={16} strokeWidth={1.7} />
            <span style={{ fontSize: 11 }}>{s.label}</span>
          </button>
        ))}
      </div>

      {/* Results */}
      <div style={{ flex: 1, padding: '22px 18px 30px', overflowY: 'auto' }} className="no-scroll">
        {q.length === 0 && (
          <>
            <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginBottom: 8 }}>{t.saved}</div>
            <div style={{ background: '#fff', borderRadius: 14, padding: '0 14px', border: '0.5px solid var(--border)', marginBottom: 18 }}>
              {saved.map((s, i, arr) => (
                <button key={i} onClick={() => nav('booking')} style={{
                  appearance: 'none', border: 0, cursor: 'pointer', width: '100%', background: 'transparent',
                  padding: '12px 0', display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left',
                  borderBottom: i < arr.length - 1 ? '0.5px solid var(--border)' : 0,
                }}>
                  <div style={{
                    width: 36, height: 36, borderRadius: 10,
                    background: accent + '14', color: accent,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}><Icon name={s.icon} size={16} strokeWidth={1.7} /></div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13.5, fontWeight: 500 }}>{s.name}</div>
                    <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 1 }}>{s.detail}</div>
                  </div>
                  <Icon name="arrow" size={14} style={{ color: 'var(--text-3)' }} />
                </button>
              ))}
            </div>

            <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginBottom: 8 }}>{t.recent}</div>
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              {recent.map((r, i) => (
                <button key={i} onClick={() => nav('booking')} style={{
                  appearance: 'none', border: 0, cursor: 'pointer', width: '100%', background: 'transparent',
                  padding: '12px 0', display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left',
                  borderBottom: '0.5px solid var(--border)',
                }}>
                  <Icon name="history" size={16} strokeWidth={1.7} style={{ color: 'var(--text-3)' }} />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13.5, fontWeight: 500 }}>{r.name}</div>
                    <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 1 }}>{r.detail}</div>
                  </div>
                </button>
              ))}
            </div>

            <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', margin: '22px 0 10px' }}>{t.suggested}</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              {suggestions.map((s, i) => (
                <button key={i} onClick={() => nav('booking')} style={{
                  appearance: 'none', border: 0, cursor: 'pointer', textAlign: 'left',
                  background: '#fff', borderRadius: 14, padding: 12,
                  border: '0.5px solid var(--border)',
                  display: 'flex', flexDirection: 'column', gap: 8,
                  position: 'relative',
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div style={{
                      width: 30, height: 30, borderRadius: 9, background: 'var(--surface-2)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <Icon name={s.icon} size={14} strokeWidth={1.7} />
                    </div>
                    <span className="mono" style={{ fontSize: 8, padding: '2px 6px', borderRadius: 999, background: '#0A0908', color: '#fff', letterSpacing: '0.18em' }}>{s.tag}</span>
                  </div>
                  <div>
                    <div style={{ fontSize: 12.5, fontWeight: 500, letterSpacing: '-0.005em' }}>{s.name}</div>
                    <div style={{ fontSize: 10.5, color: 'var(--text-2)', marginTop: 2 }}>{s.detail}</div>
                  </div>
                </button>
              ))}
            </div>
          </>
        )}
        {q.length > 0 && (
          <div style={{ background: '#fff', borderRadius: 14, padding: '0 14px', border: '0.5px solid var(--border)' }}>
            {[...recent, ...suggestions].filter(x => x.name.toLowerCase().includes(q.toLowerCase())).slice(0, 6).map((r, i, arr) => (
              <button key={i} onClick={() => nav('booking')} style={{
                appearance: 'none', border: 0, cursor: 'pointer', width: '100%', background: 'transparent',
                padding: '12px 0', display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left',
                borderBottom: i < arr.length - 1 ? '0.5px solid var(--border)' : 0,
              }}>
                <div style={{
                  width: 34, height: 34, borderRadius: 10, background: 'var(--surface-2)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}><Icon name="pin" size={14} strokeWidth={1.7} /></div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 500 }}>{r.name}</div>
                  <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 1 }}>{r.detail}</div>
                </div>
                <Icon name="arrow" size={14} style={{ color: 'var(--text-3)' }} />
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 14 — TRIP COMPLETE + RATING
// ─────────────────────────────────────────────────────────────
function CompleteScreen({ nav, accent, lang }) {
  const [stars, setStars] = React.useState(5);
  const [tip, setTip] = React.useState(500);
  const [tags, setTags] = React.useState(new Set(['Smooth ride', 'Friendly']));
  const t = lang === 'ar' ? {
    kicker: 'الرحلة مكتملة', headline: 'وصلت بسلام.', sub: 'كيف كانت رحلتك مع عمر؟',
    fare: 'الإجمالي', paidWith: 'دُفع عبر المحفظة', distance: 'المسافة', time: 'المدة',
    tipTitle: 'شكرًا للسائق', tipNote: 'كل القرشة تذهب لعمر مباشرة.',
    submit: 'إرسال التقييم', skip: 'تخطي', receipt: 'تنزيل الإيصال',
  } : {
    kicker: 'TRIP COMPLETE', headline: 'You\'ve arrived.', sub: 'How was your ride with Omar?',
    fare: 'Total', paidWith: 'Paid with Wallet', distance: 'Distance', time: 'Duration',
    tipTitle: 'Tip your driver', tipNote: '100% goes directly to Omar.',
    submit: 'Submit rating', skip: 'Skip', receipt: 'Download receipt',
  };
  const compliments = lang === 'ar'
    ? ['قيادة هادئة', 'ودود', 'سيارة نظيفة', 'وصول سريع', 'موسيقى لطيفة', 'مساعد']
    : ['Smooth ride', 'Friendly', 'Clean car', 'Quick arrival', 'Great music', 'Helpful'];

  return (
    <div data-screen-label="14 Trip Complete" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('home')} style={{ all: 'unset', cursor: 'pointer', fontSize: 13, color: 'var(--text-2)' }}>{t.skip}</button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>RECEIPT · 248-5712</span>
        <div style={{ width: 40 }} />
      </div>

      <div style={{ padding: '24px 18px 0' }}>
        <div className="mono" style={{ fontSize: 10, color: accent, letterSpacing: '0.32em' }}>● {t.kicker}</div>
        <div className="serif" style={{ fontSize: 46, lineHeight: 1, letterSpacing: '-0.03em', marginTop: 10 }}>
          {lang === 'ar' ? <>وصلت <span style={{ color: accent }}>بسلام.</span></> : <>You've <span style={{ color: accent }}>arrived.</span></>}
        </div>
        <div style={{ fontSize: 14, color: 'var(--text-2)', marginTop: 8 }}>{t.sub}</div>
      </div>

      {/* Driver + rating card */}
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          background: '#fff', borderRadius: 22, padding: 20, border: '0.5px solid var(--border)',
          boxShadow: '0 10px 28px rgba(20,15,30,0.06)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <Avatar size={56} label="OM" tone="warm" />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 16, fontWeight: 500 }}>Omar Mahmoud</div>
              <div className="mono" style={{ fontSize: 11, color: 'var(--text-2)', marginTop: 4, letterSpacing: '0.08em' }}>KRT · 4421 · CAR</div>
            </div>
          </div>
          {/* Stars */}
          <div style={{ display: 'flex', gap: 10, justifyContent: 'center', marginTop: 22, marginBottom: 16 }}>
            {[1,2,3,4,5].map(n => (
              <button key={n} onClick={() => setStars(n)} style={{
                appearance: 'none', border: 0, cursor: 'pointer', background: 'transparent',
                color: n <= stars ? '#E4B73B' : 'var(--border-2)',
                transition: 'transform 0.15s, color 0.2s',
                transform: n <= stars ? 'scale(1.05)' : 'scale(1)',
              }}>
                <Icon name="star" size={38} strokeWidth={1} />
              </button>
            ))}
          </div>
          <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--text-2)' }}>
            {stars === 5 ? (lang === 'ar' ? 'ممتاز!' : 'Outstanding!') : stars >= 3 ? (lang === 'ar' ? 'جيد' : 'Good') : (lang === 'ar' ? 'يحتاج تحسين' : 'Could be better')}
          </div>

          {/* Tags */}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 16, justifyContent: 'center' }}>
            {compliments.map(c => {
              const on = tags.has(c);
              return (
                <button key={c} onClick={() => {
                  setTags(prev => { const n = new Set(prev); n.has(c) ? n.delete(c) : n.add(c); return n; });
                }} style={{
                  appearance: 'none', cursor: 'pointer',
                  border: on ? `1px solid ${accent}` : '0.5px solid var(--border)',
                  background: on ? accent + '12' : '#fff', color: on ? accent : '#0A0908',
                  padding: '6px 12px', borderRadius: 999,
                  fontFamily: 'inherit', fontSize: 11.5, fontWeight: 500,
                }}>{c}</button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Tip */}
      <div style={{ padding: '14px 18px 0' }}>
        <div style={{ background: '#fff', borderRadius: 18, padding: 16, border: '0.5px solid var(--border)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontSize: 14, fontWeight: 500 }}>{t.tipTitle}</div>
              <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 3 }}>{t.tipNote}</div>
            </div>
            <Icon name="gift" size={18} style={{ color: accent }} />
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
            {[0, 500, 1000, 2000].map(v => {
              const active = tip === v;
              return (
                <button key={v} onClick={() => setTip(v)} style={{
                  flex: 1, appearance: 'none', cursor: 'pointer',
                  border: active ? `1.5px solid ${accent}` : '0.5px solid var(--border)',
                  background: active ? accent + '12' : '#fff',
                  color: active ? accent : '#0A0908',
                  borderRadius: 12, padding: '10px 0',
                  fontFamily: 'inherit', fontSize: 13, fontWeight: 500,
                }}>
                  {v === 0 ? (lang === 'ar' ? 'بدون' : 'None') : v.toLocaleString()}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Fare summary */}
      <div style={{ padding: '14px 18px 0' }}>
        <div style={{ background: '#0A0908', color: '#fff', borderRadius: 18, padding: 18, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -30, right: -30, width: 150, height: 150, borderRadius: '50%', background: `radial-gradient(circle, ${accent}50, transparent 70%)` }} />
          <div className="mono" style={{ fontSize: 9, opacity: 0.55, letterSpacing: '0.3em', position: 'relative' }}>{t.fare.toUpperCase()}</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 8, position: 'relative' }}>
            <span className="serif" style={{ fontSize: 52, lineHeight: 1, letterSpacing: '-0.03em' }}>{(4200 + tip).toLocaleString()}</span>
            <span className="mono" style={{ fontSize: 11, opacity: 0.6 }}>SDG</span>
          </div>
          <div style={{ display: 'flex', gap: 16, marginTop: 14, position: 'relative' }}>
            <div>
              <div className="mono" style={{ fontSize: 8.5, opacity: 0.5, letterSpacing: '0.22em' }}>{t.distance.toUpperCase()}</div>
              <div style={{ fontSize: 13, marginTop: 3 }}>18.2 km</div>
            </div>
            <div>
              <div className="mono" style={{ fontSize: 8.5, opacity: 0.5, letterSpacing: '0.22em' }}>{t.time.toUpperCase()}</div>
              <div style={{ fontSize: 13, marginTop: 3 }}>23 min</div>
            </div>
            <div style={{ flex: 1 }} />
            <div style={{ textAlign: 'right' }}>
              <div className="mono" style={{ fontSize: 8.5, opacity: 0.5, letterSpacing: '0.22em' }}>{lang === 'ar' ? 'الدفع' : 'PAYMENT'}</div>
              <div style={{ fontSize: 13, marginTop: 3 }}>{t.paidWith}</div>
            </div>
          </div>
        </div>
      </div>

      {/* Submit */}
      <div style={{ padding: '16px 18px 40px' }}>
        <Btn full accent={accent} onClick={() => nav('home')} icon="check">
          {t.submit}
        </Btn>
        <button onClick={() => {}} style={{
          marginTop: 10, width: '100%', appearance: 'none', border: '0.5px solid var(--border)', background: '#fff',
          cursor: 'pointer', height: 48, borderRadius: 14,
          fontFamily: 'inherit', fontSize: 13.5, color: '#0A0908',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        }}>
          <Icon name="receipt" size={15} strokeWidth={1.7} /> {t.receipt}
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 15 — TOP-UP
// ─────────────────────────────────────────────────────────────
function TopupScreen({ nav, accent, lang }) {
  const [amount, setAmount] = React.useState(25000);
  const [method, setMethod] = React.useState('bok');
  const presets = [10000, 25000, 50000, 100000];
  const methods = lang === 'ar' ? [
    { id: 'bok', icon: 'wallet', name: 'بنك الخرطوم', detail: '•• ٤٤٧١', primary: true },
    { id: 'mbok', icon: 'phone', name: 'بنكك موبايل', detail: '+٢٤٩ ٩١ *** ٥٦٧٨' },
    { id: 'cash', icon: 'plus', name: 'نقدًا في الوكيل', detail: 'أقرب وكيل · ١٫٢ كم' },
  ] : [
    { id: 'bok', icon: 'wallet', name: 'Bank of Khartoum', detail: '•• 4471', primary: true },
    { id: 'mbok', icon: 'phone', name: 'Bankak Mobile', detail: '+249 91 *** 5678' },
    { id: 'cash', icon: 'plus', name: 'Cash at agent', detail: 'Nearest agent · 1.2 km' },
  ];

  return (
    <div data-screen-label="15 Top-up" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('wallet')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          TOP-UP · شحن
        </span>
        <div style={{ width: 40 }} />
      </div>

      <div style={{ padding: '24px 18px 0' }}>
        <div className="mono" style={{ fontSize: 10, color: accent, letterSpacing: '0.32em' }}>
          {lang === 'ar' ? '● شحن الرصيد' : '● ADD FUNDS'}
        </div>
        <div className="serif" style={{ fontSize: 40, lineHeight: 1, letterSpacing: '-0.025em', marginTop: 10 }}>
          {lang === 'ar' ? <>كم تريد أن <span style={{ color: accent }}>تضيف؟</span></> : <>How much to <span style={{ color: accent }}>add?</span></>}
        </div>
      </div>

      {/* Amount display */}
      <div style={{ padding: '28px 18px 0', textAlign: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, justifyContent: 'center' }}>
          <span className="serif" style={{ fontSize: 86, lineHeight: 0.95, letterSpacing: '-0.035em' }}>{amount.toLocaleString()}</span>
          <span className="mono" style={{ fontSize: 14, color: 'var(--text-2)', letterSpacing: '0.14em' }}>SDG</span>
        </div>
        <div className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.24em', marginTop: 6 }}>
          {lang === 'ar' ? `الرصيد الجديد · ${(42180 + amount).toLocaleString()} ج.س` : `NEW BALANCE · ${(42180 + amount).toLocaleString()} SDG`}
        </div>
      </div>

      {/* Presets */}
      <div style={{ padding: '24px 18px 0', display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
        {presets.map(p => {
          const active = amount === p;
          return (
            <button key={p} onClick={() => setAmount(p)} style={{
              appearance: 'none', cursor: 'pointer',
              border: active ? `1.5px solid ${accent}` : '0.5px solid var(--border)',
              background: active ? accent + '10' : '#fff',
              color: active ? accent : '#0A0908',
              borderRadius: 14, padding: '10px 0',
              fontFamily: 'Geist Mono, monospace', fontSize: 12.5, fontWeight: 500,
            }}>+{(p / 1000)}K</button>
          );
        })}
      </div>

      {/* Slider */}
      <div style={{ padding: '20px 18px 0' }}>
        <input type="range" min="5000" max="200000" step="1000" value={amount} onChange={(e) => setAmount(+e.target.value)} style={{
          width: '100%', accentColor: accent, height: 4,
        }} />
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
          <span className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)' }}>5,000</span>
          <span className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)' }}>200,000 SDG</span>
        </div>
      </div>

      {/* Method */}
      <div style={{ padding: '24px 18px 0' }}>
        <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginBottom: 10 }}>
          {lang === 'ar' ? 'طريقة الدفع' : 'PAYMENT METHOD'}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {methods.map(m => {
            const active = method === m.id;
            return (
              <button key={m.id} onClick={() => setMethod(m.id)} style={{
                appearance: 'none', cursor: 'pointer', textAlign: 'left',
                border: active ? `1.5px solid ${accent}` : '0.5px solid var(--border)',
                background: '#fff',
                borderRadius: 16, padding: 14,
                display: 'flex', alignItems: 'center', gap: 14,
              }}>
                <div style={{
                  width: 42, height: 42, borderRadius: 12,
                  background: active ? accent + '12' : 'var(--surface-2)',
                  color: active ? accent : '#0A0908',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name={m.icon} size={18} strokeWidth={1.7} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 500 }}>{m.name}</div>
                  <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2 }}>{m.detail}</div>
                </div>
                <div style={{
                  width: 20, height: 20, borderRadius: '50%',
                  border: `1.5px solid ${active ? accent : 'var(--border-2)'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {active && <div style={{ width: 9, height: 9, borderRadius: '50%', background: accent }} />}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ padding: '20px 18px 50px' }}>
        <Btn full accent={accent} onClick={() => nav('wallet')} icon="arrow">
          {lang === 'ar' ? `إضافة ${amount.toLocaleString()} ج.س` : `Add ${amount.toLocaleString()} SDG`}
        </Btn>
        <div style={{ fontSize: 10.5, color: 'var(--text-3)', textAlign: 'center', marginTop: 10, lineHeight: 1.5 }}>
          {lang === 'ar' ? 'بدون رسوم · معالجة فورية · 256-bit مشفّر' : 'No fees · Instant processing · 256-bit encrypted'}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 16 — SOS / SAFETY
// ─────────────────────────────────────────────────────────────
function SOSScreen({ nav, accent, lang }) {
  const [holding, setHolding] = React.useState(false);
  const [progress, setProgress] = React.useState(0);
  React.useEffect(() => {
    if (!holding) { setProgress(0); return; }
    const i = setInterval(() => setProgress(p => Math.min(p + 4, 100)), 50);
    return () => clearInterval(i);
  }, [holding]);

  const danger = '#E4452E';
  const t = lang === 'ar' ? {
    kicker: 'وضع الأمان', headline: 'لست وحدك.', sub: 'اضغط مع الاستمرار لاستدعاء فريق الأمان.',
    contacts: 'اتصال بأحد المعارف', share: 'شارك رحلتي مباشرة', report: 'الإبلاغ عن مشكلة',
    police: 'شرطة المرور', medical: 'الإسعاف', women: 'دعم المرأة',
    hold: 'اضغط مطولاً', release: 'اتركه للإلغاء', dispatching: 'جارٍ التواصل…',
  } : {
    kicker: 'SAFETY MODE', headline: 'You are not alone.', sub: 'Hold to dispatch our safety team.',
    contacts: 'Call a trusted contact', share: 'Share my ride live', report: 'Report a problem',
    police: 'Traffic police', medical: 'Medical', women: 'Women support',
    hold: 'Hold to call', release: 'Release to cancel', dispatching: 'Dispatching…',
  };

  return (
    <div data-screen-label="16 Safety / SOS" style={{
      position: 'absolute', inset: 0,
      background: `linear-gradient(180deg, #1A0C0C 0%, #0A0908 100%)`,
      color: '#fff', overflowY: 'auto',
    }} className="no-scroll">
      {/* danger glow */}
      <div style={{
        position: 'absolute', top: 240, left: '50%', transform: 'translate(-50%, -50%)',
        width: 500, height: 500, borderRadius: '50%',
        background: `radial-gradient(circle, ${danger}30 0%, transparent 60%)`,
        pointerEvents: 'none',
      }} />

      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', position: 'relative' }}>
        <button onClick={() => nav('tracking')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: 'rgba(255,255,255,0.08)', color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="close" size={18} strokeWidth={1.8} />
        </button>
        <span className="mono" style={{ fontSize: 10, opacity: 0.55, letterSpacing: '0.3em' }}>SAFETY · الأمان</span>
        <div style={{ width: 40 }} />
      </div>

      <div style={{ padding: '24px 18px 0', position: 'relative' }}>
        <div className="mono" style={{ fontSize: 10, color: danger, letterSpacing: '0.32em' }}>● {t.kicker}</div>
        <div className="serif" style={{ fontSize: 46, lineHeight: 1, letterSpacing: '-0.03em', marginTop: 10 }}>
          {lang === 'ar' ? <>لست <span style={{ color: danger }}>وحدك.</span></> : <>You are not <span style={{ color: danger }}>alone.</span></>}
        </div>
        <div style={{ fontSize: 13.5, opacity: 0.65, marginTop: 8 }}>{t.sub}</div>
      </div>

      {/* SOS hold button */}
      <div style={{ padding: '40px 18px 0', display: 'flex', flexDirection: 'column', alignItems: 'center', position: 'relative' }}>
        <button
          onMouseDown={() => setHolding(true)} onMouseUp={() => setHolding(false)} onMouseLeave={() => setHolding(false)}
          onTouchStart={() => setHolding(true)} onTouchEnd={() => setHolding(false)}
          style={{
            position: 'relative',
            width: 200, height: 200, borderRadius: '50%', border: 0, cursor: 'pointer',
            background: danger, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column',
            boxShadow: `0 0 0 8px ${danger}30, 0 24px 60px ${danger}50`,
            transform: holding ? 'scale(0.98)' : 'scale(1)',
            transition: 'transform 0.15s',
          }}>
          <svg width="200" height="200" viewBox="0 0 200 200" style={{ position: 'absolute', inset: 0, transform: 'rotate(-90deg)' }}>
            <circle cx="100" cy="100" r="92" fill="none" stroke="rgba(255,255,255,0.15)" strokeWidth="4" />
            <circle cx="100" cy="100" r="92" fill="none" stroke="#fff" strokeWidth="4"
              strokeDasharray={`${(progress / 100) * 578} 578`} strokeLinecap="round" />
          </svg>
          <span className="serif" style={{ fontSize: 52, letterSpacing: '0.08em', lineHeight: 1 }}>SOS</span>
          <span className="mono" style={{ fontSize: 10, opacity: 0.7, letterSpacing: '0.24em', marginTop: 4 }}>
            {progress >= 100 ? t.dispatching.toUpperCase() : holding ? t.release.toUpperCase() : t.hold.toUpperCase()}
          </span>
        </button>
        {/* pulse ring */}
        <div style={{
          position: 'absolute', top: 40, left: '50%', transform: 'translateX(-50%)',
          width: 200, height: 200, borderRadius: '50%',
          background: danger, opacity: 0.18,
          animation: 'pulse-ring 2.4s ease-out infinite',
          pointerEvents: 'none',
        }} />
      </div>

      {/* Quick contacts */}
      <div style={{ padding: '40px 18px 0' }}>
        <div className="mono" style={{ fontSize: 9.5, opacity: 0.5, letterSpacing: '0.3em', marginBottom: 10 }}>
          {lang === 'ar' ? 'تواصل سريع' : 'QUICK DISPATCH'}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          {[
            { icon: 'shield', label: t.police, num: '777' },
            { icon: 'plus', label: t.medical, num: '333' },
            { icon: 'user', label: t.women, num: '188' },
          ].map((q, i) => (
            <button key={i} style={{
              appearance: 'none', border: 0, cursor: 'pointer',
              background: 'rgba(255,255,255,0.06)', color: '#fff',
              borderRadius: 16, padding: '14px 8px',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              border: '0.5px solid rgba(255,255,255,0.08)',
            }}>
              <Icon name={q.icon} size={18} strokeWidth={1.7} />
              <span style={{ fontSize: 11, fontWeight: 500 }}>{q.label}</span>
              <span className="mono" style={{ fontSize: 10, opacity: 0.5 }}>{q.num}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Secondary actions */}
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{ background: 'rgba(255,255,255,0.06)', borderRadius: 18, padding: '0 16px', border: '0.5px solid rgba(255,255,255,0.08)' }}>
          {[
            { icon: 'user', label: t.contacts, detail: lang === 'ar' ? '٢ معارف' : '2 trusted' },
            { icon: 'eye', label: t.share, detail: lang === 'ar' ? 'بث مباشر' : 'Live tracking link' },
            { icon: 'help', label: t.report, detail: lang === 'ar' ? 'دعم ٢٤/٧' : '24/7 support' },
          ].map((r, i, arr) => (
            <button key={i} style={{
              appearance: 'none', border: 0, cursor: 'pointer', width: '100%', background: 'transparent',
              color: '#fff', padding: '14px 0', display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left',
              borderBottom: i < arr.length - 1 ? '0.5px solid rgba(255,255,255,0.06)' : 0,
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: 'rgba(255,255,255,0.06)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><Icon name={r.icon} size={16} strokeWidth={1.7} /></div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 500 }}>{r.label}</div>
                <div style={{ fontSize: 11.5, opacity: 0.5, marginTop: 2 }}>{r.detail}</div>
              </div>
              <Icon name="chevron" size={14} style={{ opacity: 0.5 }} />
            </button>
          ))}
        </div>
      </div>

      <div style={{ padding: '30px 18px 40px', textAlign: 'center' }}>
        <div className="mono" style={{ fontSize: 10, opacity: 0.4, letterSpacing: '0.24em', lineHeight: 1.7 }}>
          {lang === 'ar'
            ? 'WASILHA SAFETY · فريق متخصص ٢٤/٧\nموقعك يُشارك تلقائيًا عند تفعيل SOS'
            : 'WASILHA SAFETY · 24/7 RESPONSE\nYOUR LOCATION IS SHARED ON ACTIVATION'}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { SearchScreen, CompleteScreen, TopupScreen, SOSScreen });

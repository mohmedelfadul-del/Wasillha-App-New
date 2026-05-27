// Wasilha — auxiliary tabs (Wallet, History, Notifications, Saved, Settings)

// ─────────────────────────────────────────────────────────────
// 08 — WALLET
// ─────────────────────────────────────────────────────────────
function WalletScreen({ nav, accent, lang, glass }) {
  const txs = [
    { icon: 'car',    label: 'Ride · Bahri → Khartoum 2',    when: 'Today · 18:22',   amount: -4200, kind: 'spend' },
    { icon: 'plus',   label: 'Top-up · Bank of Khartoum',     when: 'Today · 09:04',   amount: 25000, kind: 'add' },
    { icon: 'bag',    label: 'Delivery · Souq Arabi',         when: 'Yesterday',       amount: -1800, kind: 'spend' },
    { icon: 'gift',   label: 'Referral bonus · Sara A.',      when: 'Yesterday',       amount: 1000,  kind: 'add' },
    { icon: 'raksha', label: 'Raksha · Riyadh → Amarat',      when: 'Mon · 21:10',     amount: -1850, kind: 'spend' },
    { icon: 'bowl',   label: 'Food · Solitaire Café',         when: 'Sun · 14:30',     amount: -3650, kind: 'spend' },
  ];
  return (
    <div data-screen-label="08 Wallet" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('home')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          WALLET · المحفظة
        </span>
        <button style={{ width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer', background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="settings" size={16} strokeWidth={1.7} />
        </button>
      </div>

      {/* Balance hero */}
      <div style={{ padding: '28px 18px 0' }}>
        <div className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>AVAILABLE BALANCE</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 10 }}>
          <span className="serif" style={{ fontSize: 76, lineHeight: 0.95, letterSpacing: '-0.035em', color: '#0A0908' }}>42,180</span>
          <span className="mono" style={{ fontSize: 13, color: 'var(--text-2)', letterSpacing: '0.16em' }}>SDG</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
          <span className="ar-serif" style={{ fontFamily: 'Amiri', fontSize: 18, color: 'var(--text-2)' }}>اثنان وأربعون ألفًا</span>
          <span style={{ fontSize: 12, color: accent, padding: '2px 8px', borderRadius: 999, background: accent + '12' }}>+ 6,400 this month</span>
        </div>
      </div>

      {/* Actions */}
      <div style={{ padding: '20px 18px 0', display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
        {[
          { icon: 'plus',    label: 'Top up',   primary: true, onClick: () => nav('topup') },
          { icon: 'arrow',   label: 'Send' },
          { icon: 'receipt', label: 'Pay bill' },
          { icon: 'gift',    label: 'Rewards' },
        ].map((a, i) => (
          <button key={i} onClick={a.onClick} style={{
            appearance: 'none', border: 0, cursor: 'pointer',
            background: a.primary ? '#0A0908' : '#fff', color: a.primary ? '#fff' : '#0A0908',
            borderRadius: 16, padding: '14px 0', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
            boxShadow: a.primary ? '0 8px 22px rgba(10,9,8,0.18)' : '0 1px 2px rgba(0,0,0,0.04)',
            position: 'relative', overflow: 'hidden',
          }}>
            {a.primary && (
              <div style={{ position: 'absolute', top: -20, right: -20, width: 60, height: 60, borderRadius: '50%', background: `radial-gradient(circle, ${accent}80, transparent 70%)` }} />
            )}
            <Icon name={a.icon} size={18} strokeWidth={1.7} style={{ position: 'relative', zIndex: 1 }} />
            <span style={{ fontSize: 11.5, position: 'relative', zIndex: 1 }}>{a.label}</span>
          </button>
        ))}
      </div>

      {/* Card */}
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{
          position: 'relative', overflow: 'hidden',
          borderRadius: 18, padding: '16px 18px', background: '#0A0908', color: '#fff',
          boxShadow: '0 14px 30px rgba(10,9,8,0.22)',
        }}>
          <div style={{ position: 'absolute', top: -40, right: -40, width: 200, height: 200, borderRadius: '50%', background: `radial-gradient(circle, ${accent}80, transparent 60%)` }} />
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', position: 'relative' }}>
            <div>
              <div className="mono" style={{ fontSize: 9, opacity: 0.55, letterSpacing: '0.3em' }}>WASILHA CARD</div>
              <div className="serif" style={{ fontSize: 22, marginTop: 8, letterSpacing: '-0.01em' }}>Ahmed Hassan</div>
            </div>
            <div className="ar" style={{ fontFamily: 'Amiri, serif', fontSize: 28, lineHeight: 1 }}>وصلها</div>
          </div>
          <div className="mono" style={{ fontSize: 16, letterSpacing: '0.22em', marginTop: 20, position: 'relative' }}>
            •••• •••• •••• 4421
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8, fontSize: 10, opacity: 0.6, position: 'relative' }} className="mono">
            <span>EXP 09/29</span>
            <span>VIRTUAL · NFC</span>
          </div>
        </div>
      </div>

      {/* Transactions */}
      <div style={{ padding: '24px 18px 120px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
          <div className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>RECENT ACTIVITY</div>
          <button style={{ all: 'unset', cursor: 'pointer', fontSize: 12, color: accent }}>See all</button>
        </div>
        <div style={{ background: '#fff', borderRadius: 18, padding: '0 16px', border: '0.5px solid var(--border)' }}>
          {txs.map((t, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '14px 0',
              borderBottom: i < txs.length - 1 ? '0.5px solid var(--border)' : 0,
            }}>
              <div style={{
                width: 38, height: 38, borderRadius: 11,
                background: t.kind === 'add' ? '#1F8A5B14' : 'var(--surface-2)',
                color: t.kind === 'add' ? '#1F8A5B' : '#0A0908',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={t.icon} size={16} strokeWidth={1.7} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{t.label}</div>
                <div className="mono" style={{ fontSize: 10, color: 'var(--text-3)', marginTop: 2, letterSpacing: '0.1em' }}>{t.when.toUpperCase()}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div className="mono" style={{ fontSize: 14, fontWeight: 600, color: t.kind === 'add' ? '#1F8A5B' : '#0A0908' }}>
                  {t.kind === 'add' ? '+' : '−'}{Math.abs(t.amount).toLocaleString()}
                </div>
                <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.18em' }}>SDG</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <BottomNav active="wallet" onNav={nav} accent={accent} glass={glass} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 09 — HISTORY
// ─────────────────────────────────────────────────────────────
function HistoryScreen({ nav, accent, lang, glass }) {
  const groups = [
    {
      day: 'TODAY · 21 MAY', items: [
        { icon: 'car', from: 'Riyadh District', to: 'Khartoum Airport (KRT)', when: '18:22', dist: '18 km · 24 min', fare: 4200, driver: 'Omar M.', status: 'completed' },
      ]
    },
    {
      day: 'YESTERDAY · 20 MAY', items: [
        { icon: 'bag', from: 'Souq Arabi', to: 'Block 32, Riyadh', when: '13:08', dist: '6.4 km · 18 min', fare: 1800, driver: 'Mostafa I.', status: 'completed' },
        { icon: 'raksha', from: 'University of Khartoum', to: 'Amarat St. 41', when: '09:14', dist: '3.1 km · 12 min', fare: 1200, driver: 'Babiker H.', status: 'completed' },
      ]
    },
    {
      day: 'EARLIER · 18 MAY', items: [
        { icon: 'bike', from: 'Africa Road Mall', to: 'Burri', when: '20:55', dist: '7.2 km · 16 min', fare: 2400, driver: 'Yousef A.', status: 'cancelled' },
      ]
    }
  ];

  return (
    <div data-screen-label="09 History" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('home')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          HISTORY · السجل
        </span>
        <button style={{ width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer', background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="search" size={16} strokeWidth={1.7} />
        </button>
      </div>

      {/* Editorial header */}
      <div style={{ padding: '24px 18px 0' }}>
        <div className="serif" style={{ fontSize: 40, lineHeight: 1, letterSpacing: '-0.025em' }}>
          Where you've <span style={{ color: accent }}>been.</span>
        </div>
        <div style={{ display: 'flex', gap: 18, marginTop: 14 }}>
          <div>
            <div className="serif" style={{ fontSize: 28, letterSpacing: '-0.02em', lineHeight: 1 }}>128</div>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em', marginTop: 2 }}>TRIPS · YTD</div>
          </div>
          <div style={{ width: 0.5, background: 'var(--border-2)' }} />
          <div>
            <div className="serif" style={{ fontSize: 28, letterSpacing: '-0.02em', lineHeight: 1 }}>841<span className="mono" style={{ fontSize: 13, color: 'var(--text-3)' }}> km</span></div>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em', marginTop: 2 }}>DISTANCE</div>
          </div>
          <div style={{ width: 0.5, background: 'var(--border-2)' }} />
          <div>
            <div className="serif" style={{ fontSize: 28, letterSpacing: '-0.02em', lineHeight: 1 }}>4.92</div>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em', marginTop: 2 }}>YOUR RATING</div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div style={{ padding: '20px 18px 0', display: 'flex', gap: 6, overflowX: 'auto' }} className="no-scroll">
        {['All', 'Rides', 'Delivery', 'Food', 'Scheduled'].map((f, i) => (
          <button key={f} style={{
            appearance: 'none', border: 0, cursor: 'pointer',
            background: i === 0 ? '#0A0908' : '#fff', color: i === 0 ? '#fff' : '#0A0908',
            borderRadius: 999, padding: '8px 14px', fontSize: 12.5, fontWeight: 500,
            border: i === 0 ? 0 : '0.5px solid var(--border)',
            flexShrink: 0,
          }}>{f}</button>
        ))}
      </div>

      {/* Groups */}
      <div style={{ padding: '24px 18px 120px' }}>
        {groups.map(g => (
          <div key={g.day} style={{ marginBottom: 18 }}>
            <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginBottom: 8 }}>{g.day}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {g.items.map((it, i) => (
                <div key={i} style={{
                  background: '#fff', borderRadius: 18, padding: 16,
                  border: '0.5px solid var(--border)',
                  position: 'relative', overflow: 'hidden',
                }}>
                  {it.status === 'cancelled' && (
                    <div className="mono" style={{
                      position: 'absolute', top: 12, right: 12,
                      fontSize: 9, padding: '3px 8px', borderRadius: 999,
                      background: '#F3D7D2', color: '#A23B25', letterSpacing: '0.2em',
                    }}>CANCELLED</div>
                  )}
                  <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
                    <div style={{
                      width: 40, height: 40, borderRadius: 12,
                      background: 'var(--surface-2)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      <Icon name={it.icon} size={18} strokeWidth={1.7} />
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13.5, fontWeight: 500 }}>
                        <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1 }}>{it.from}</span>
                        <Icon name="arrow" size={12} style={{ color: 'var(--text-3)', flexShrink: 0 }} />
                        <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', flex: 1 }}>{it.to}</span>
                      </div>
                      <div className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.14em', marginTop: 4 }}>
                        {it.when} · {it.dist.toUpperCase()} · {it.driver.toUpperCase()}
                      </div>
                    </div>
                  </div>
                  <div style={{
                    marginTop: 12, paddingTop: 12, borderTop: '0.5px dashed var(--border-2)',
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                  }}>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <button style={{
                        appearance: 'none', border: '0.5px solid var(--border)', background: '#fff', cursor: 'pointer',
                        padding: '6px 12px', borderRadius: 999, fontSize: 11.5, fontFamily: 'inherit',
                      }}>Re-book</button>
                      <button style={{
                        appearance: 'none', border: '0.5px solid var(--border)', background: '#fff', cursor: 'pointer',
                        padding: '6px 12px', borderRadius: 999, fontSize: 11.5, fontFamily: 'inherit',
                      }}>Receipt</button>
                    </div>
                    <div>
                      {it.status === 'completed' ? (
                        <span className="serif" style={{ fontSize: 18, letterSpacing: '-0.01em' }}>
                          {it.fare.toLocaleString()} <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)' }}>SDG</span>
                        </span>
                      ) : (
                        <span className="mono" style={{ fontSize: 11, color: 'var(--text-3)' }}>NO CHARGE</span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      <BottomNav active="history" onNav={nav} accent={accent} glass={glass} />
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 10 — NOTIFICATIONS
// ─────────────────────────────────────────────────────────────
function NotificationsScreen({ nav, accent, lang, glass }) {
  const groups = [
    {
      day: 'TODAY',
      items: [
        { icon: 'sparkle', tone: 'accent', title: 'Your driver is 2 minutes away', body: 'Omar M. · Toyota Corolla · KRT-4421', meta: '5 min ago', unread: true },
        { icon: 'gift', tone: 'dark', title: '20% off your next 3 rides', body: 'Limited offer — use code WASILHA20 at checkout.', meta: '2 h ago', unread: true },
        { icon: 'check', tone: 'paper', title: 'Trip complete · Bahri → KRT', body: 'Rate your trip · 4,200 SDG paid from Wallet', meta: '3 h ago' },
      ]
    },
    {
      day: 'EARLIER',
      items: [
        { icon: 'wallet', tone: 'paper', title: 'Top-up successful', body: '25,000 SDG added from Bank of Khartoum (• 4471)', meta: 'Yesterday' },
        { icon: 'shield', tone: 'paper', title: 'New device signed in', body: 'iPhone 17 Pro · Khartoum · 09:42', meta: '20 May' },
        { icon: 'flame', tone: 'paper', title: 'You\'re a Wasilha Loyal', body: '50 trips milestone — enjoy faster pickup priority.', meta: '18 May' },
      ]
    }
  ];

  return (
    <div data-screen-label="10 Notifications" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('home')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          NOTIFICATIONS
        </span>
        <button style={{ all: 'unset', cursor: 'pointer', fontSize: 12, color: accent }}>Clear all</button>
      </div>

      <div style={{ padding: '24px 18px 0' }}>
        <div className="serif" style={{ fontSize: 38, lineHeight: 1, letterSpacing: '-0.025em' }}>
          What's <span style={{ color: accent }}>new.</span>
        </div>
        <div style={{ fontSize: 13, color: 'var(--text-2)', marginTop: 8 }}>2 unread · 6 total</div>
      </div>

      <div style={{ padding: '24px 18px 100px' }}>
        {groups.map(g => (
          <div key={g.day} style={{ marginBottom: 18 }}>
            <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginBottom: 8 }}>{g.day}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {g.items.map((n, i) => {
                const tone = {
                  accent: { bg: '#0A0908', fg: '#fff', iconBg: accent, iconFg: '#fff' },
                  dark:   { bg: '#0A0908', fg: '#fff', iconBg: 'rgba(255,255,255,0.12)', iconFg: '#fff' },
                  paper:  { bg: '#fff',    fg: '#0A0908', iconBg: 'var(--surface-2)', iconFg: '#0A0908' },
                }[n.tone];
                return (
                  <div key={i} style={{
                    position: 'relative',
                    background: tone.bg, color: tone.fg,
                    borderRadius: 18, padding: 16,
                    border: n.tone === 'paper' ? '0.5px solid var(--border)' : 0,
                    overflow: 'hidden',
                  }}>
                    {n.tone === 'accent' && (
                      <div style={{ position: 'absolute', top: -40, right: -30, width: 180, height: 180, borderRadius: '50%', background: `radial-gradient(circle, ${accent}80, transparent 60%)` }} />
                    )}
                    <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start', position: 'relative' }}>
                      <div style={{
                        width: 38, height: 38, borderRadius: 11,
                        background: tone.iconBg, color: tone.iconFg,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        flexShrink: 0,
                      }}>
                        <Icon name={n.icon} size={16} strokeWidth={1.7} />
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <div style={{ fontSize: 14, fontWeight: 500, letterSpacing: '-0.005em' }}>{n.title}</div>
                          {n.unread && <div style={{ width: 6, height: 6, borderRadius: '50%', background: accent, flexShrink: 0 }} />}
                        </div>
                        <div style={{ fontSize: 12.5, opacity: 0.7, marginTop: 4, lineHeight: 1.5 }}>{n.body}</div>
                        <div className="mono" style={{ fontSize: 9.5, opacity: 0.5, letterSpacing: '0.18em', marginTop: 8 }}>{n.meta.toUpperCase()}</div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 11 — SAVED PLACES
// ─────────────────────────────────────────────────────────────
function SavedScreen({ nav, accent, lang, glass, mapStyle }) {
  const places = [
    { icon: 'home', label: 'Home',   addr: 'Block 32, Riyadh District · Khartoum', primary: true },
    { icon: 'work', label: 'Work',   addr: 'Africa Road, Tower B · 5th floor' },
    { icon: 'plane', label: 'Airport', addr: 'Khartoum Intl. Airport · Terminal 1' },
    { icon: 'pin', label: 'Mother',  addr: 'Amarat St. 41 · Khartoum' },
    { icon: 'pin', label: 'Gym',     addr: 'Solitaire Wellness Club · Riyadh' },
  ];
  return (
    <div data-screen-label="11 Saved" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('home')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          SAVED PLACES
        </span>
        <button style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: accent, color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 6px 16px ${accent}40`,
        }}>
          <Icon name="plus" size={18} strokeWidth={1.8} />
        </button>
      </div>

      {/* Map preview */}
      <div style={{ margin: '24px 18px 0', borderRadius: 22, overflow: 'hidden', height: 200, position: 'relative', boxShadow: '0 10px 28px rgba(20,15,30,0.08)' }}>
        <MapView style={mapStyle} accent={accent} drivers={0} width={364} height={200} />
        {/* fake pins */}
        {[
          { top: '36%', left: '24%', tone: 'dark' },
          { top: '58%', left: '62%', tone: 'accent' },
          { top: '74%', left: '28%', tone: 'dark' },
          { top: '24%', left: '70%', tone: 'dark' },
        ].map((p, i) => (
          <div key={i} style={{
            position: 'absolute', top: p.top, left: p.left, transform: 'translate(-50%, -50%)',
            width: 14, height: 14, borderRadius: '50%',
            background: p.tone === 'accent' ? accent : '#0A0908',
            border: '2.5px solid #fff',
            boxShadow: '0 4px 10px rgba(0,0,0,0.2)',
          }} />
        ))}
        <div className="mono" style={{
          position: 'absolute', top: 12, left: 14, fontSize: 9, letterSpacing: '0.24em',
          color: 'var(--text-3)', background: 'rgba(255,255,255,0.85)', padding: '4px 8px', borderRadius: 999,
        }}>5 PLACES</div>
      </div>

      <div style={{ padding: '20px 18px 0' }}>
        <div className="serif" style={{ fontSize: 32, lineHeight: 1.02, letterSpacing: '-0.025em' }}>
          Your <span style={{ color: accent }}>shortcuts.</span>
        </div>
        <div style={{ fontSize: 13, color: 'var(--text-2)', marginTop: 8, lineHeight: 1.5 }}>
          Save the places you go most. We'll surface them as one-tap options on the home screen.
        </div>
      </div>

      <div style={{ padding: '20px 18px 60px' }}>
        <div style={{ background: '#fff', borderRadius: 18, padding: '0 16px', border: '0.5px solid var(--border)' }}>
          {places.map((p, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '14px 0',
              borderBottom: i < places.length - 1 ? '0.5px solid var(--border)' : 0,
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 12,
                background: p.primary ? accent + '14' : 'var(--surface-2)',
                color: p.primary ? accent : '#0A0908',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={p.icon} size={18} strokeWidth={1.7} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 500 }}>{p.label}</div>
                <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2 }}>{p.addr}</div>
              </div>
              <Icon name="chevron" size={14} style={{ color: 'var(--text-3)' }} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 12 — SETTINGS / ACCOUNT
// ─────────────────────────────────────────────────────────────
function SettingsScreen({ nav, accent, lang, glass }) {
  const sections = [
    {
      title: 'ACCOUNT',
      rows: [
        { icon: 'user', title: 'Profile & ID', detail: 'Ahmed Hassan · +249 91 *** 5678' },
        { icon: 'pin', title: 'Saved places', detail: '5 shortcuts', onClick: () => nav('saved') },
        { icon: 'shield', title: 'Emergency contacts', detail: '2 contacts' },
      ]
    },
    {
      title: 'EXPERIENCE',
      rows: [
        { icon: 'earth', title: 'Language', detail: 'English · العربية' },
        { icon: 'bell', title: 'Notifications', detail: 'Push, email · 6 categories' },
        { icon: 'moon', title: 'Appearance', detail: 'System' },
      ]
    },
    {
      title: 'SUPPORT',
      rows: [
        { icon: 'help', title: 'Help center' },
        { icon: 'receipt', title: 'Trip receipts' },
        { icon: 'star', title: 'Rate Wasilha' },
      ]
    },
    {
      title: '',
      rows: [
        { icon: 'logout', title: 'Sign out', danger: true },
      ]
    }
  ];

  return (
    <div data-screen-label="12 Settings" style={{ position: 'absolute', inset: 0, background: '#FBFAF6', overflowY: 'auto' }} className="no-scroll">
      <div style={{ paddingTop: 60, padding: '60px 18px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('home')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 14px rgba(20,15,30,0.06)',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          ACCOUNT · الحساب
        </span>
        <div style={{ width: 40 }} />
      </div>

      {/* Profile hero */}
      <div style={{ padding: '24px 18px 0', display: 'flex', alignItems: 'center', gap: 14 }}>
        <Avatar size={72} label="AH" tone="warm" />
        <div style={{ flex: 1 }}>
          <div className="serif" style={{ fontSize: 28, letterSpacing: '-0.02em', lineHeight: 1 }}>Ahmed Hassan</div>
          <div className="mono" style={{ fontSize: 11, color: 'var(--text-2)', letterSpacing: '0.08em', marginTop: 6 }}>+249 91 *** 5678</div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, marginTop: 6, padding: '2px 10px', borderRadius: 999, background: accent + '14', color: accent, fontSize: 11 }}>
            <Icon name="flame" size={11} strokeWidth={2} /> Loyal · 128 trips
          </div>
        </div>
      </div>

      {/* Stats strip */}
      <div style={{ padding: '20px 18px 0' }}>
        <div style={{ background: '#0A0908', color: '#fff', borderRadius: 18, padding: 16, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -30, right: -20, width: 150, height: 150, borderRadius: '50%', background: `radial-gradient(circle, ${accent}60, transparent 70%)` }} />
          <div style={{ display: 'flex', justifyContent: 'space-between', position: 'relative' }}>
            <div>
              <div className="mono" style={{ fontSize: 9, opacity: 0.5, letterSpacing: '0.24em' }}>YOUR RATING</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 6 }}>
                <span className="serif" style={{ fontSize: 36, letterSpacing: '-0.02em', lineHeight: 1 }}>4.92</span>
                <Icon name="star" size={14} style={{ color: '#E4B73B' }} />
              </div>
            </div>
            <div>
              <div className="mono" style={{ fontSize: 9, opacity: 0.5, letterSpacing: '0.24em' }}>MEMBER SINCE</div>
              <div className="serif" style={{ fontSize: 36, letterSpacing: '-0.02em', lineHeight: 1, marginTop: 6 }}>'24</div>
            </div>
            <div>
              <div className="mono" style={{ fontSize: 9, opacity: 0.5, letterSpacing: '0.24em' }}>CO₂ SAVED</div>
              <div className="serif" style={{ fontSize: 36, letterSpacing: '-0.02em', lineHeight: 1, marginTop: 6 }}>62<span className="mono" style={{ fontSize: 13, opacity: 0.6 }}>kg</span></div>
            </div>
          </div>
        </div>
      </div>

      <div style={{ padding: '20px 18px 100px' }}>
        {sections.map((s, i) => (
          <div key={i} style={{ marginBottom: 18 }}>
            {s.title && (
              <div className="mono" style={{ fontSize: 9.5, color: 'var(--text-3)', letterSpacing: '0.3em', marginBottom: 8 }}>{s.title}</div>
            )}
            <div style={{ background: '#fff', borderRadius: 18, padding: '0 16px', border: '0.5px solid var(--border)' }}>
              {s.rows.map((r, j) => (
                <button
                  key={j}
                  onClick={r.onClick}
                  style={{
                    appearance: 'none', border: 0, cursor: 'pointer', width: '100%',
                    background: 'transparent', textAlign: 'left',
                    padding: '14px 0',
                    borderBottom: j < s.rows.length - 1 ? '0.5px solid var(--border)' : 0,
                    display: 'flex', alignItems: 'center', gap: 12,
                  }}>
                  <div style={{
                    width: 38, height: 38, borderRadius: 11,
                    background: r.danger ? '#F3D7D2' : 'var(--surface-2)',
                    color: r.danger ? '#A23B25' : '#0A0908',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <Icon name={r.icon} size={16} strokeWidth={1.7} />
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14, fontWeight: 500, color: r.danger ? '#A23B25' : '#0A0908' }}>{r.title}</div>
                    {r.detail && <div style={{ fontSize: 11.5, color: 'var(--text-2)', marginTop: 2 }}>{r.detail}</div>}
                  </div>
                  {!r.danger && <Icon name="chevron" size={14} style={{ color: 'var(--text-3)' }} />}
                </button>
              ))}
            </div>
          </div>
        ))}

        <div className="mono" style={{ textAlign: 'center', fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.24em', marginTop: 24 }}>
          WASILHA · v 1.0.0 (build 248)<br />MADE IN KHARTOUM · 🇸🇩
        </div>
      </div>

      <BottomNav active="settings" onNav={nav} accent={accent} glass={glass} />
    </div>
  );
}

Object.assign(window, { WalletScreen, HistoryScreen, NotificationsScreen, SavedScreen, SettingsScreen });

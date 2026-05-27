// Wasilha — Diagonal Split Card System
// Original card geometry: each card is a rounded rectangle internally split by a
// diagonal/angled cut into two regions. Press animates the halves apart.

const WASILHA = {
  purple:     '#9D00FF',
  lavender:   '#DBD4FF',
  ivory:      '#FFFFE3',
  deepPurple: '#723480',
  ink:        '#0A0908',
  paper:      '#FFFFFF',
};

// ─────────────────────────────────────────────────────────────
// SplitCard — generic two-region card with diagonal cut.
// `cut` is a polygon spec describing region A; region B is its complement.
// ─────────────────────────────────────────────────────────────
function SplitCard({
  cut,              // { aPoly, bPoly, line: {x1,y1,x2,y2} } in % coords
  bgA, bgB,         // background fills for the two regions
  glassA = false,   // glass treatment on region A
  glassB = false,   // glass treatment on region B
  inkA = '#fff',    // text color for region A
  inkB = '#0A0908', // text color for region B
  contentA, contentB,
  overflow,         // optional element drawn over the card with overflow visible
  height = 160,
  onPress,
  pressed,
  glow,
  rounded = 28,
}) {
  const [active, setActive] = React.useState(false);
  const handleDown = () => setActive(true);
  const handleUp = () => setActive(false);
  const isPressed = pressed ?? active;

  return (
    <button
      type="button"
      onPointerDown={handleDown}
      onPointerUp={handleUp}
      onPointerCancel={handleUp}
      onPointerLeave={handleUp}
      onClick={onPress}
      style={{
        appearance: 'none', border: 0, padding: 0, background: 'transparent',
        cursor: 'pointer', font: 'inherit',
        position: 'relative', width: '100%', height,
        outline: 'none',
        WebkitTapHighlightColor: 'transparent',
      }}
    >
      {/* glow underlay */}
      <div style={{
        position: 'absolute', inset: -8, borderRadius: rounded + 8,
        background: `radial-gradient(60% 60% at 50% 60%, ${glow || WASILHA.purple}26, transparent 70%)`,
        opacity: isPressed ? 1 : 0.55,
        transition: 'opacity 280ms cubic-bezier(0.2,0.8,0.2,1)',
        pointerEvents: 'none', filter: 'blur(2px)',
      }} />

      {/* clip wrapper — keeps the two polygon regions inside rounded edges */}
      <div style={{
        position: 'absolute', inset: 0, borderRadius: rounded,
        overflow: 'hidden',
        boxShadow: '0 10px 28px rgba(20,15,30,0.10), 0 1px 0 rgba(255,255,255,0.7) inset',
        background: WASILHA.paper,
      }}>
        {/* Region A */}
        <div
          aria-hidden="true"
          style={{
            position: 'absolute', inset: 0,
            clipPath: `polygon(${cut.aPoly})`,
            background: bgA,
            backdropFilter: glassA ? 'blur(14px) saturate(1.1)' : 'none',
            transform: isPressed ? 'translate(-3px,-2px)' : 'translate(0,0)',
            transition: 'transform 340ms cubic-bezier(0.2,0.8,0.2,1)',
          }}
        />
        {/* Region B */}
        <div
          aria-hidden="true"
          style={{
            position: 'absolute', inset: 0,
            clipPath: `polygon(${cut.bPoly})`,
            background: bgB,
            backdropFilter: glassB ? 'blur(14px) saturate(1.1)' : 'none',
            transform: isPressed ? 'translate(3px,2px)' : 'translate(0,0)',
            transition: 'transform 340ms cubic-bezier(0.2,0.8,0.2,1)',
          }}
        />

        {/* Hairline separator (drawn as SVG line for crispness across browsers) */}
        <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none"
             style={{
               position: 'absolute', inset: 0, pointerEvents: 'none',
               mixBlendMode: 'normal',
             }}>
          <line
            x1={cut.line.x1} y1={cut.line.y1} x2={cut.line.x2} y2={cut.line.y2}
            stroke="rgba(255,255,255,0.85)" strokeWidth="0.35"
            vectorEffect="non-scaling-stroke" strokeLinecap="round"
          />
        </svg>

        {/* Content layer A */}
        <div style={{
          position: 'absolute', inset: 0,
          color: inkA, pointerEvents: 'none',
          transform: isPressed ? 'translate(-3px,-2px)' : 'translate(0,0)',
          transition: 'transform 340ms cubic-bezier(0.2,0.8,0.2,1)',
        }}>
          {contentA}
        </div>
        {/* Content layer B */}
        <div style={{
          position: 'absolute', inset: 0,
          color: inkB, pointerEvents: 'none',
          transform: isPressed ? 'translate(3px,2px)' : 'translate(0,0)',
          transition: 'transform 340ms cubic-bezier(0.2,0.8,0.2,1)',
        }}>
          {contentB}
        </div>

        {/* Inner white edge (glass rim) */}
        <div style={{
          position: 'absolute', inset: 0, borderRadius: rounded,
          border: '0.5px solid rgba(255,255,255,0.65)',
          pointerEvents: 'none',
        }} />
      </div>

      {/* Overflow illustration (lives OUTSIDE the clipped wrapper) */}
      {overflow && (
        <div style={{
          position: 'absolute', inset: 0, pointerEvents: 'none',
          transform: isPressed ? 'translate(1px,-2px)' : 'translate(0,0)',
          transition: 'transform 340ms cubic-bezier(0.2,0.8,0.2,1)',
        }}>
          {overflow}
        </div>
      )}
    </button>
  );
}

// ─────────────────────────────────────────────────────────────
// Mini line icons drawn at scale (24 viewbox)
// ─────────────────────────────────────────────────────────────
function MiniIcon({ name, size = 36, color = 'currentColor', strokeWidth = 1.4 }) {
  const props = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  switch (name) {
    case 'raksha': return (
      <svg {...props}>
        <path d="M3 14 L4 9 L11 9 L14 6 L18 6 L20 14" />
        <path d="M3 14 L21 14" />
        <circle cx="7" cy="17" r="2.2" />
        <circle cx="17" cy="17" r="2.2" />
        <path d="M14 6 L14 14" />
        <path d="M11 9 L11 14" />
      </svg>
    );
    case 'car': return (
      <svg {...props}>
        <path d="M3 14 L4.5 9 C5 8 6 7.5 7 7.5 L17 7.5 C18 7.5 19 8 19.5 9 L21 14" />
        <path d="M3 14 L3 17 L5 17 L5 15" />
        <path d="M21 14 L21 17 L19 17 L19 15" />
        <path d="M3 14 L21 14" />
        <circle cx="7" cy="15.5" r="1.6" fill="currentColor"/>
        <circle cx="17" cy="15.5" r="1.6" fill="currentColor"/>
      </svg>
    );
    case 'bike': return (
      <svg {...props}>
        <circle cx="5" cy="16" r="3" />
        <circle cx="19" cy="16" r="3" />
        <path d="M5 16 L10 9 L14 9 L16 13 L19 16" />
        <path d="M10 9 L13 5 L16 5" />
        <path d="M14 9 L17 7" />
      </svg>
    );
    case 'bag': return (
      <svg {...props}>
        <path d="M5 8 L19 8 L18 19 L6 19 Z" />
        <path d="M9 8 V6 a3 3 0 0 1 6 0 V8" />
        <path d="M9 12 L15 12" />
      </svg>
    );
    case 'bowl': return (
      <svg {...props}>
        <path d="M3 11 L21 11 a9 9 0 0 1 -18 0 Z" />
        <path d="M2 11 L22 11" />
        <path d="M9 7 C9 5 11 5 11 7" />
        <path d="M13 6 C13 4 15 4 15 6" />
      </svg>
    );
    case 'clock': return (
      <svg {...props}>
        <circle cx="12" cy="12" r="9" />
        <path d="M12 7 L12 12 L15.5 14" />
      </svg>
    );
    case 'pin': return (
      <svg {...props}>
        <path d="M12 21 C8 17 5 13.5 5 10 a7 7 0 0 1 14 0 c0 3.5 -3 7 -7 11 Z"/>
        <circle cx="12" cy="10" r="2.5"/>
      </svg>
    );
    case 'arrow': return (
      <svg {...props}>
        <path d="M5 12 L19 12" />
        <path d="M14 7 L19 12 L14 17" />
      </svg>
    );
    case 'star': return (
      <svg {...props}>
        <path d="M12 4 L14.4 9.4 L20 10 L15.8 13.8 L17 19.5 L12 16.6 L7 19.5 L8.2 13.8 L4 10 L9.6 9.4 Z" fill="currentColor" stroke="none"/>
      </svg>
    );
    default: return null;
  }
}

// ─────────────────────────────────────────────────────────────
// Tiny shapes used inside cards
// ─────────────────────────────────────────────────────────────
function MiniRoute({ accent = WASILHA.purple, ink = WASILHA.deepPurple }) {
  // a glance-able route line for the Car card's right region
  return (
    <svg viewBox="0 0 100 60" width="100%" height="100%" preserveAspectRatio="none">
      {/* roads */}
      <path d="M0 50 Q 25 50 35 40 T 60 30 T 100 18" stroke={ink + '22'} strokeWidth="6" fill="none" strokeLinecap="round"/>
      <path d="M0 50 Q 25 50 35 40 T 60 30 T 100 18" stroke={accent} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeDasharray="3 2.5"/>
      <path d="M10 10 L 28 22" stroke={ink + '12'} strokeWidth="2" fill="none"/>
      <path d="M70 50 L 85 55" stroke={ink + '12'} strokeWidth="2" fill="none"/>
      {/* endpoints */}
      <circle cx="0" cy="50" r="2.6" fill="#1F8A5B"/>
      <circle cx="100" cy="18" r="2.6" fill={accent}/>
    </svg>
  );
}

function AvatarBlob({ label = 'OM', size = 38 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: 'linear-gradient(135deg, #FFFFE3 0%, #DBD4FF 100%)',
      color: WASILHA.deepPurple,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Instrument Serif, serif', fontSize: size * 0.45, letterSpacing: '-0.02em',
      boxShadow: 'inset 0 0 0 1.5px rgba(255,255,255,0.9)',
      flexShrink: 0,
    }}>{label}</div>
  );
}

// ─────────────────────────────────────────────────────────────
// Individual cards — each has its own unique cut geometry
// ─────────────────────────────────────────────────────────────

// ① RAKSHA — / diagonal, deep purple over ivory
function RakshaCard({ lang, onPress }) {
  const cut = {
    aPoly: '0 0, 100% 0, 100% 38%, 0 100%',     // big upper-left trapezoid
    bPoly: '100% 38%, 100% 100%, 0 100%',       // lower-right triangle
    line:  { x1: 0, y1: 100, x2: 100, y2: 38 },
  };
  return (
    <SplitCard
      cut={cut} height={170}
      bgA={`linear-gradient(135deg, ${WASILHA.deepPurple} 0%, #4F1F5C 100%)`}
      bgB={WASILHA.ivory}
      inkA="#FFFFE3" inkB={WASILHA.deepPurple}
      glow={WASILHA.purple}
      contentA={
        <div style={{ position: 'absolute', top: 18, left: 22, right: 22, display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <div>
            <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.32em', opacity: 0.62 }}>S-01 · TUKTUK</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 6 }}>
              <span className="serif" style={{ fontSize: 34, lineHeight: 1, letterSpacing: '-0.025em' }}>Raksha</span>
              <span className="ar" style={{ fontSize: 18, opacity: 0.7 }}>راكشة</span>
            </div>
            <div style={{ marginTop: 10, fontSize: 11.5, opacity: 0.75, maxWidth: 180, lineHeight: 1.35 }}>
              {lang === 'ar' ? 'الأسرع في الزحمة، الأرخص في الجيب.' : 'Quickest through traffic, easiest on pocket.'}
            </div>
          </div>
          <div style={{ width: 46, height: 46, borderRadius: 14, background: 'rgba(255,255,231,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '0.5px solid rgba(255,255,231,0.18)' }}>
            <MiniIcon name="raksha" size={26} color={WASILHA.ivory}/>
          </div>
        </div>
      }
      contentB={
        <div style={{ position: 'absolute', right: 18, bottom: 14, textAlign: 'right' }}>
          <div className="mono" style={{ fontSize: 9, letterSpacing: '0.28em', color: WASILHA.deepPurple, opacity: 0.55 }}>FROM</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, justifyContent: 'flex-end', marginTop: 2 }}>
            <span className="serif" style={{ fontSize: 30, lineHeight: 1, letterSpacing: '-0.025em', color: WASILHA.deepPurple }}>1,850</span>
            <span className="mono" style={{ fontSize: 10, letterSpacing: '0.18em', color: WASILHA.deepPurple, opacity: 0.65 }}>SDG</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 6, justifyContent: 'flex-end' }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#1F8A5B' }}/>
            <span className="mono" style={{ fontSize: 10, letterSpacing: '0.18em', color: WASILHA.deepPurple }}>2 MIN AWAY</span>
          </div>
        </div>
      }
      onPress={onPress}
    />
  );
}

// ② CAR — vertical-ish diagonal (\), driver on the lavender left, mini map on purple right
function CarCard({ lang, onPress }) {
  const cut = {
    aPoly: '0 0, 56% 0, 44% 100%, 0 100%',         // left slab leaning right
    bPoly: '56% 0, 100% 0, 100% 100%, 44% 100%',   // right slab
    line:  { x1: 56, y1: 0, x2: 44, y2: 100 },
  };
  return (
    <SplitCard
      cut={cut} height={172}
      bgA={WASILHA.lavender}
      bgB={`linear-gradient(155deg, ${WASILHA.purple} 0%, ${WASILHA.deepPurple} 100%)`}
      glassA
      inkA={WASILHA.deepPurple} inkB="#FFFFE3"
      glow={WASILHA.purple}
      contentA={
        <div style={{ position: 'absolute', top: 16, left: 18, width: '48%' }}>
          <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.3em', opacity: 0.55 }}>S-02 · YOUR DRIVER</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 10 }}>
            <AvatarBlob label="OM" size={42}/>
            <div>
              <div className="serif" style={{ fontSize: 20, lineHeight: 1, letterSpacing: '-0.02em' }}>Omar M.</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 3, fontSize: 11 }}>
                <MiniIcon name="star" size={11} color="#E4B73B" strokeWidth={1.4}/>
                <span style={{ fontWeight: 600 }}>4.96</span>
                <span style={{ opacity: 0.5 }}>· Corolla</span>
              </div>
            </div>
          </div>
          <div style={{ marginTop: 14, display: 'inline-flex', alignItems: 'center', gap: 8,
                        padding: '6px 10px', borderRadius: 999,
                        background: 'rgba(255,255,255,0.55)',
                        border: '0.5px solid rgba(255,255,255,0.7)' }}>
            <span className="mono" style={{ fontSize: 10, letterSpacing: '0.18em' }}>KRT · 4421</span>
          </div>
        </div>
      }
      contentB={
        <>
          {/* mini map */}
          <div style={{ position: 'absolute', right: 16, top: 18, width: '42%', height: 70, borderRadius: 12, overflow: 'hidden', border: '0.5px solid rgba(255,255,231,0.18)' }}>
            <MiniRoute accent={WASILHA.ivory} ink="#FFFFE3"/>
          </div>
          <div style={{ position: 'absolute', right: 18, bottom: 16, textAlign: 'right' }}>
            <div className="mono" style={{ fontSize: 9, letterSpacing: '0.28em', opacity: 0.62 }}>{lang === 'ar' ? 'وقت الوصول' : 'ARRIVES IN'}</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 5, justifyContent: 'flex-end', marginTop: 2 }}>
              <span className="serif" style={{ fontSize: 32, lineHeight: 1, letterSpacing: '-0.025em' }}>3</span>
              <span className="mono" style={{ fontSize: 11, letterSpacing: '0.18em', opacity: 0.75 }}>MIN</span>
            </div>
            <div style={{ marginTop: 6, fontSize: 11, opacity: 0.78 }}>
              <span className="ar" style={{ marginRight: 4 }}>·</span>
              {lang === 'ar' ? '4,200 ج.س' : '4,200 SDG'}
            </div>
          </div>
        </>
      }
      onPress={onPress}
    />
  );
}

// ③ MOTORCYCLE — horizontal split with a tilted angled cut at ~12°
function MotoCard({ lang, onPress }) {
  // top region is large ivory band with a sloping bottom edge;
  // bottom region is a thin deep-purple band with the sloping top edge
  const cut = {
    aPoly: '0 0, 100% 0, 100% 58%, 0 78%',
    bPoly: '0 78%, 100% 58%, 100% 100%, 0 100%',
    line:  { x1: 0, y1: 78, x2: 100, y2: 58 },
  };
  return (
    <SplitCard
      cut={cut} height={148}
      bgA={WASILHA.ivory}
      bgB={`linear-gradient(95deg, ${WASILHA.deepPurple} 0%, ${WASILHA.purple} 100%)`}
      inkA={WASILHA.deepPurple} inkB="#FFFFE3"
      glow={WASILHA.purple}
      contentA={
        <div style={{ position: 'absolute', top: 16, left: 22, right: 22, display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <div>
            <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.3em', opacity: 0.55 }}>S-03 · TWO-WHEEL</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 6 }}>
              <span className="serif" style={{ fontSize: 28, lineHeight: 1, letterSpacing: '-0.025em' }}>Motorcycle</span>
              <span className="ar" style={{ fontSize: 16, opacity: 0.6 }}>دراجة</span>
            </div>
            <div style={{ marginTop: 6, fontSize: 11, opacity: 0.62 }}>
              {lang === 'ar' ? 'يتجاوز الزحام · راكب واحد' : 'Skip traffic · 1 rider'}
            </div>
          </div>
          <div style={{
            width: 54, height: 54, borderRadius: 16,
            background: 'rgba(157,0,255,0.08)', color: WASILHA.deepPurple,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: '0.5px solid rgba(114,52,128,0.15)',
            transform: 'rotate(-4deg)',
          }}>
            <MiniIcon name="bike" size={30} color={WASILHA.deepPurple} strokeWidth={1.5}/>
          </div>
        </div>
      }
      contentB={
        <div style={{ position: 'absolute', left: 22, right: 22, bottom: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#FFFFE3', boxShadow: '0 0 0 4px rgba(255,255,231,0.18)' }}/>
            <span className="mono" style={{ fontSize: 10, letterSpacing: '0.22em' }}>ETA · 1 MIN</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
            <span className="serif" style={{ fontSize: 20, letterSpacing: '-0.02em', lineHeight: 1 }}>2,400</span>
            <span className="mono" style={{ fontSize: 9, letterSpacing: '0.2em', opacity: 0.7 }}>SDG</span>
          </div>
        </div>
      }
      onPress={onPress}
    />
  );
}

// ④ DELIVERY — \ diagonal, package illustration peeking out top-right
function DeliveryCard({ lang, onPress }) {
  const cut = {
    aPoly: '0 0, 70% 0, 30% 100%, 0 100%',         // left trapezoid
    bPoly: '70% 0, 100% 0, 100% 100%, 30% 100%',   // right trapezoid
    line:  { x1: 70, y1: 0, x2: 30, y2: 100 },
  };
  return (
    <SplitCard
      cut={cut} height={160}
      bgA={WASILHA.lavender}
      bgB={`linear-gradient(160deg, ${WASILHA.purple} 0%, ${WASILHA.deepPurple} 100%)`}
      glassA
      inkA={WASILHA.deepPurple} inkB="#FFFFE3"
      glow={WASILHA.purple}
      contentA={
        <div style={{ position: 'absolute', top: 18, left: 22, width: '54%' }}>
          <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.3em', opacity: 0.55 }}>S-04 · COURIER</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
            <span className="serif" style={{ fontSize: 30, lineHeight: 1, letterSpacing: '-0.025em' }}>Delivery</span>
          </div>
          <div className="ar" style={{ fontSize: 14, opacity: 0.65, marginTop: 2 }}>توصيل طرود</div>
          <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
            <MiniIcon name="pin" size={13} color={WASILHA.deepPurple} strokeWidth={1.6}/>
            <span style={{ fontSize: 11, opacity: 0.72 }}>{lang === 'ar' ? 'حتى ٥ كجم · أي مكان في الخرطوم' : 'Up to 5 kg · anywhere in Khartoum'}</span>
          </div>
        </div>
      }
      contentB={
        <div style={{ position: 'absolute', right: 18, bottom: 16, textAlign: 'right' }}>
          <div className="mono" style={{ fontSize: 9, letterSpacing: '0.28em', opacity: 0.62 }}>FROM</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, justifyContent: 'flex-end', marginTop: 2 }}>
            <span className="serif" style={{ fontSize: 28, lineHeight: 1, letterSpacing: '-0.025em' }}>1,200</span>
            <span className="mono" style={{ fontSize: 10, letterSpacing: '0.18em', opacity: 0.75 }}>SDG</span>
          </div>
          <div className="mono" style={{ fontSize: 10, letterSpacing: '0.2em', opacity: 0.7, marginTop: 8 }}>~ 20 MIN</div>
        </div>
      }
      // package illustration extending out of the top-right corner
      overflow={
        <div style={{
          position: 'absolute', top: -22, right: -14,
          width: 88, height: 88,
          transform: 'rotate(14deg)',
        }}>
          <svg viewBox="0 0 100 100" width="100%" height="100%">
            <defs>
              <linearGradient id="pkgGrad" x1="0" x2="1" y1="0" y2="1">
                <stop offset="0" stopColor="#FFFFE3"/>
                <stop offset="1" stopColor="#DBD4FF"/>
              </linearGradient>
            </defs>
            <path d="M20 30 L50 12 L80 30 L80 72 L50 90 L20 72 Z" fill="url(#pkgGrad)" stroke={WASILHA.deepPurple} strokeWidth="1.6"/>
            <path d="M20 30 L50 48 L80 30" fill="none" stroke={WASILHA.deepPurple} strokeWidth="1.6"/>
            <path d="M50 48 L50 90" fill="none" stroke={WASILHA.deepPurple} strokeWidth="1.6"/>
            <path d="M35 21 L65 39" stroke={WASILHA.purple} strokeWidth="3" strokeLinecap="round"/>
          </svg>
        </div>
      }
      onPress={onPress}
    />
  );
}

// ⑤ FOOD — chevron split (V going down-left), purple wedge inside lavender
function FoodCard({ lang, onPress }) {
  const cut = {
    aPoly: '0 0, 100% 0, 100% 100%, 0 100%, 0 100%, 38% 0, 62% 100%, 100% 100%, 100% 0, 0 0',
    // simpler: outer region everywhere, inner wedge punched as B
    bPoly: '38% 0, 62% 0, 78% 100%, 22% 100%',  // angled parallelogram band
    line:  { x1: 38, y1: 0, x2: 22, y2: 100 },
  };
  // Re-define A as everything-minus-B by using two trapezoids merged via fill rule? Simpler:
  // Use A = whole card; B is painted on top. We'll fake by overriding aPoly to full rect.
  cut.aPoly = '0 0, 100% 0, 100% 100%, 0 100%';
  return (
    <SplitCard
      cut={cut} height={156}
      bgA={WASILHA.lavender}
      bgB={`linear-gradient(110deg, ${WASILHA.purple} 0%, ${WASILHA.deepPurple} 100%)`}
      glassA
      inkA={WASILHA.deepPurple} inkB="#FFFFE3"
      glow={WASILHA.purple}
      contentA={
        <div style={{ position: 'absolute', top: 16, left: 22, width: '52%' }}>
          <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.3em', opacity: 0.55 }}>S-05 · MEAL</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 6 }}>
            <span className="serif" style={{ fontSize: 30, lineHeight: 1, letterSpacing: '-0.025em' }}>Food</span>
            <span className="ar" style={{ fontSize: 16, opacity: 0.6 }}>طعام</span>
          </div>
          <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: 'rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '0.5px solid rgba(255,255,255,0.8)' }}>
              <MiniIcon name="bowl" size={20} color={WASILHA.deepPurple} strokeWidth={1.5}/>
            </div>
            <div style={{ fontSize: 11, opacity: 0.72, lineHeight: 1.3 }}>
              {lang === 'ar' ? '٤٢ مطعم قريب' : '42 spots near you'}<br/>
              <span style={{ opacity: 0.7 }}>{lang === 'ar' ? 'فطور · غدا · عشا' : 'Breakfast · lunch · dinner'}</span>
            </div>
          </div>
        </div>
      }
      contentB={
        <div style={{ position: 'absolute', right: 14, top: 0, bottom: 0, width: 110, display: 'flex', flexDirection: 'column', alignItems: 'flex-end', justifyContent: 'center', paddingRight: 6 }}>
          <div className="mono" style={{ fontSize: 9, letterSpacing: '0.28em', opacity: 0.72 }}>DELIVERY IN</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 3, marginTop: 4 }}>
            <span className="serif" style={{ fontSize: 30, lineHeight: 1, letterSpacing: '-0.025em' }}>25</span>
            <span className="mono" style={{ fontSize: 11, opacity: 0.7 }}>–40</span>
          </div>
          <div className="mono" style={{ fontSize: 9, letterSpacing: '0.28em', opacity: 0.65, marginTop: 2 }}>MIN</div>
          <div style={{ marginTop: 14, padding: '5px 10px', borderRadius: 999, background: 'rgba(255,255,255,0.15)', border: '0.5px solid rgba(255,255,255,0.28)', fontSize: 10 }}>
            <span className="mono" style={{ letterSpacing: '0.18em' }}>FREE → 3KM</span>
          </div>
        </div>
      }
      onPress={onPress}
    />
  );
}

// ⑥ SCHEDULE — L-cut (small notch carved from the top-right corner)
function ScheduleCard({ lang, onPress }) {
  // A = main body (most of card minus the top-right rectangle)
  // B = top-right rectangle
  const cut = {
    aPoly: '0 0, 60% 0, 60% 38%, 100% 38%, 100% 100%, 0 100%',
    bPoly: '60% 0, 100% 0, 100% 38%, 60% 38%',
    line:  { x1: 60, y1: 0, x2: 60, y2: 38 }, // L line drawn via 2 segments — keep one for now
  };
  return (
    <div style={{ position: 'relative' }}>
      <SplitCard
        cut={cut} height={150}
        bgA={`linear-gradient(165deg, ${WASILHA.purple} 0%, ${WASILHA.deepPurple} 100%)`}
        bgB={WASILHA.ivory}
        inkA="#FFFFE3" inkB={WASILHA.deepPurple}
        glow={WASILHA.purple}
        contentA={
          <div style={{ position: 'absolute', left: 22, bottom: 16, right: 22, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
            <div>
              <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.3em', opacity: 0.6 }}>S-06 · LATER</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginTop: 6 }}>
                <span className="serif" style={{ fontSize: 28, lineHeight: 1, letterSpacing: '-0.025em' }}>Schedule</span>
                <span className="ar" style={{ fontSize: 15, opacity: 0.65 }}>مجدول</span>
              </div>
              <div style={{ marginTop: 6, fontSize: 11, opacity: 0.72 }}>
                {lang === 'ar' ? 'احجز رحلتك قبل ٢٤ ساعة' : 'Book up to 24 hours ahead'}
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 10px', borderRadius: 999, background: 'rgba(255,255,231,0.12)', border: '0.5px solid rgba(255,255,231,0.22)' }}>
              <MiniIcon name="arrow" size={12} color="#FFFFE3" strokeWidth={1.8}/>
            </div>
          </div>
        }
        contentB={
          <div style={{ position: 'absolute', top: 8, right: 14, width: '34%', height: 50, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
            <MiniIcon name="clock" size={22} color={WASILHA.deepPurple} strokeWidth={1.6}/>
            <div style={{ textAlign: 'left' }}>
              <div className="serif" style={{ fontSize: 16, lineHeight: 1, letterSpacing: '-0.02em' }}>06:40</div>
              <div className="mono" style={{ fontSize: 8.5, letterSpacing: '0.22em', opacity: 0.7, marginTop: 2 }}>TOMORROW</div>
            </div>
          </div>
        }
        onPress={onPress}
      />
    </div>
  );
}

Object.assign(window, {
  WASILHA, SplitCard, MiniIcon, MiniRoute, AvatarBlob,
  RakshaCard, CarCard, MotoCard, DeliveryCard, FoodCard, ScheduleCard,
});

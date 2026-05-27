// Wasilha — Connected Pair Cards (v2)
// Each pair is TWO real cards sharing a geometric edge. Pressing one side
// morphs the shared edge: the active half expands; the other shrinks.

const W = (typeof WASILHA !== 'undefined') ? WASILHA : {
  purple:     '#9D00FF',
  lavender:   '#DBD4FF',
  ivory:      '#FFFFE3',
  deepPurple: '#723480',
  ink:        '#0A0908',
  paper:      '#FFFFFF',
};

// ─────────────────────────────────────────────────────────────
// Pair geometries — each defines three states with the SAME number of
// polygon vertices so clip-path can smoothly transition between them.
// ─────────────────────────────────────────────────────────────
const PAIR_GEOM = {
  // ① Diagonal split — left & right wedges meeting at a sloped line
  // 4 vertices each.
  diagonal: {
    rest:    { a: '0 0, 54% 0, 46% 100%, 0 100%',
               b: '54% 0, 100% 0, 100% 100%, 46% 100%' },
    aActive: { a: '0 0, 72% 0, 62% 100%, 0 100%',
               b: '72% 0, 100% 0, 100% 100%, 62% 100%' },
    bActive: { a: '0 0, 38% 0, 28% 100%, 0 100%',
               b: '38% 0, 100% 0, 100% 100%, 28% 100%' },
  },
  // ② Trapezoid horizontal — top half wider on the right
  // 4 vertices each.
  trapezoid: {
    rest:    { a: '0 0, 100% 0, 100% 42%, 0 60%',
               b: '0 60%, 100% 42%, 100% 100%, 0 100%' },
    aActive: { a: '0 0, 100% 0, 100% 60%, 0 76%',
               b: '0 76%, 100% 60%, 100% 100%, 0 100%' },
    bActive: { a: '0 0, 100% 0, 100% 22%, 0 38%',
               b: '0 38%, 100% 22%, 100% 100%, 0 100%' },
  },
  // ③ Chevron cut — V-shaped notch dividing top/bottom
  // 5 vertices each.
  chevron: {
    rest:    { a: '0 0, 100% 0, 100% 48%, 50% 64%, 0 48%',
               b: '0 48%, 50% 64%, 100% 48%, 100% 100%, 0 100%' },
    aActive: { a: '0 0, 100% 0, 100% 64%, 50% 80%, 0 64%',
               b: '0 64%, 50% 80%, 100% 64%, 100% 100%, 0 100%' },
    bActive: { a: '0 0, 100% 0, 100% 32%, 50% 48%, 0 32%',
               b: '0 32%, 50% 48%, 100% 32%, 100% 100%, 0 100%' },
  },
  // ④ Hex zigzag — vertical split with zigzag mid edge (3 zigs)
  // 7 vertices each.
  hexZig: {
    rest:    { a: '0 0, 52% 0, 46% 28%, 52% 50%, 46% 72%, 52% 100%, 0 100%',
               b: '52% 0, 100% 0, 100% 100%, 52% 100%, 46% 72%, 52% 50%, 46% 28%' },
    aActive: { a: '0 0, 70% 0, 64% 28%, 70% 50%, 64% 72%, 70% 100%, 0 100%',
               b: '70% 0, 100% 0, 100% 100%, 70% 100%, 64% 72%, 70% 50%, 64% 28%' },
    bActive: { a: '0 0, 34% 0, 28% 28%, 34% 50%, 28% 72%, 34% 100%, 0 100%',
               b: '34% 0, 100% 0, 100% 100%, 34% 100%, 28% 72%, 34% 50%, 28% 28%' },
  },
};

// ─────────────────────────────────────────────────────────────
// ConnectedPair — renders two real, independently-clickable cards
// joined by a morphable shared edge.
// ─────────────────────────────────────────────────────────────
function ConnectedPair({
  geom = 'diagonal',
  height = 170,
  rounded = 28,
  a, b,                   // { bg, ink, glassy?, content, label } each
  onTapA, onTapB,
  initiallyActive = null, // 'a' | 'b' | null
}) {
  const [active, setActive] = React.useState(initiallyActive);
  const state = active === 'a' ? 'aActive' : active === 'b' ? 'bActive' : 'rest';
  const polys = PAIR_GEOM[geom][state];

  // Separator line endpoints differ per geom — compute from polygons by
  // taking the first vertex on the shared edge from each polygon. We hard-code
  // these because the geometry is fixed, and so the user gets a crisp line.
  const sepPath = computeSep(geom, state);

  const aGlow = active === 'a';
  const bGlow = active === 'b';

  return (
    <div style={{ position: 'relative', width: '100%', height,
                  isolation: 'isolate' }}>
      {/* Glow underlays — colored under each active side */}
      <div aria-hidden="true" style={{
        position: 'absolute', inset: -10, borderRadius: rounded + 10,
        background: `radial-gradient(45% 70% at 30% 50%, ${a.glow || W.purple}30, transparent 70%)`,
        opacity: aGlow ? 1 : 0,
        transition: 'opacity 360ms cubic-bezier(0.2,0.8,0.2,1)',
        pointerEvents: 'none', filter: 'blur(2px)', zIndex: 0,
      }} />
      <div aria-hidden="true" style={{
        position: 'absolute', inset: -10, borderRadius: rounded + 10,
        background: `radial-gradient(45% 70% at 70% 50%, ${b.glow || W.purple}30, transparent 70%)`,
        opacity: bGlow ? 1 : 0,
        transition: 'opacity 360ms cubic-bezier(0.2,0.8,0.2,1)',
        pointerEvents: 'none', filter: 'blur(2px)', zIndex: 0,
      }} />

      {/* Clip wrapper */}
      <div style={{
        position: 'absolute', inset: 0, borderRadius: rounded,
        overflow: 'hidden',
        boxShadow: '0 14px 32px rgba(20,15,30,0.10), 0 1px 0 rgba(255,255,255,0.7) inset',
      }}>
        {/* Side A — actual clickable card */}
        <div
          onClick={() => { setActive('a'); onTapA?.(); }}
          onMouseEnter={() => setActive('a')}
          onMouseLeave={() => setActive(null)}
          role="button" tabIndex={0}
          aria-label={a.label}
          style={{
            position: 'absolute', inset: 0,
            cursor: 'pointer',
            background: a.bg,
            color: a.ink || '#fff',
            clipPath: `polygon(${polys.a})`,
            WebkitClipPath: `polygon(${polys.a})`,
            backdropFilter: a.glassy ? 'blur(14px) saturate(1.1)' : 'none',
            transition: 'clip-path 520ms cubic-bezier(0.22,0.85,0.22,1), filter 360ms ease',
            filter: bGlow ? 'brightness(0.94) saturate(0.92)' : 'none',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          <div style={{
            position: 'absolute', inset: 0,
            opacity: bGlow ? 0.55 : 1,
            transform: bGlow ? 'scale(0.97)' : 'scale(1)',
            transition: 'opacity 360ms ease, transform 360ms cubic-bezier(0.2,0.8,0.2,1)',
            transformOrigin: '20% 50%',
          }}>
            {a.content}
          </div>
        </div>

        {/* Side B — actual clickable card */}
        <div
          onClick={() => { setActive('b'); onTapB?.(); }}
          onMouseEnter={() => setActive('b')}
          onMouseLeave={() => setActive(null)}
          role="button" tabIndex={0}
          aria-label={b.label}
          style={{
            position: 'absolute', inset: 0,
            cursor: 'pointer',
            background: b.bg,
            color: b.ink || '#fff',
            clipPath: `polygon(${polys.b})`,
            WebkitClipPath: `polygon(${polys.b})`,
            backdropFilter: b.glassy ? 'blur(14px) saturate(1.1)' : 'none',
            transition: 'clip-path 520ms cubic-bezier(0.22,0.85,0.22,1), filter 360ms ease',
            filter: aGlow ? 'brightness(0.94) saturate(0.92)' : 'none',
            WebkitTapHighlightColor: 'transparent',
          }}
        >
          <div style={{
            position: 'absolute', inset: 0,
            opacity: aGlow ? 0.55 : 1,
            transform: aGlow ? 'scale(0.97)' : 'scale(1)',
            transition: 'opacity 360ms ease, transform 360ms cubic-bezier(0.2,0.8,0.2,1)',
            transformOrigin: '80% 50%',
          }}>
            {b.content}
          </div>
        </div>

        {/* Hairline separator — drawn between the two halves */}
        <svg
          width="100%" height="100%" viewBox="0 0 100 100"
          preserveAspectRatio="none"
          style={{
            position: 'absolute', inset: 0, pointerEvents: 'none',
            transition: 'all 520ms cubic-bezier(0.22,0.85,0.22,1)',
          }}
        >
          <path
            d={sepPath}
            fill="none"
            stroke="rgba(255,255,255,0.92)"
            strokeWidth="0.45"
            strokeLinecap="round"
            strokeLinejoin="round"
            vectorEffect="non-scaling-stroke"
          />
        </svg>

        {/* Inner white rim */}
        <div style={{
          position: 'absolute', inset: 0, borderRadius: rounded,
          border: '0.5px solid rgba(255,255,255,0.55)',
          pointerEvents: 'none',
        }} />
      </div>
    </div>
  );
}

// Separator path geometry per geom + state
function computeSep(geom, state) {
  if (geom === 'diagonal') {
    const map = { rest: [54, 46], aActive: [72, 62], bActive: [38, 28] };
    const [topX, botX] = map[state];
    return `M ${topX} 0 L ${botX} 100`;
  }
  if (geom === 'trapezoid') {
    const map = { rest: [42, 60], aActive: [60, 76], bActive: [22, 38] };
    const [rightY, leftY] = map[state];
    return `M 0 ${leftY} L 100 ${rightY}`;
  }
  if (geom === 'chevron') {
    const map = { rest: 48, aActive: 64, bActive: 32 };
    const y = map[state];
    return `M 0 ${y} L 50 ${y + 16} L 100 ${y}`;
  }
  if (geom === 'hexZig') {
    const map = { rest: [52, 46], aActive: [70, 64], bActive: [34, 28] };
    const [n, f] = map[state];
    return `M ${n} 0 L ${f} 28 L ${n} 50 L ${f} 72 L ${n} 100`;
  }
  return '';
}

// ─────────────────────────────────────────────────────────────
// Inline mini icons — small set used by pair sides
// (Re-uses MiniIcon from split-cards.jsx if available)
// ─────────────────────────────────────────────────────────────
function PI({ name, size = 28, color = 'currentColor', sw = 1.5 }) {
  if (typeof MiniIcon !== 'undefined') {
    return <MiniIcon name={name} size={size} color={color} strokeWidth={sw} />;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────
// Side content helpers — left-, right-, top-, bottom-anchored layouts
// ─────────────────────────────────────────────────────────────
function SideLeft({ label, name, ar, sub, price, eta, icon, accent }) {
  return (
    <div style={{ position: 'absolute', top: 18, left: 22, width: '48%', pointerEvents: 'none' }}>
      <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.3em', opacity: 0.55 }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
        <span className="serif" style={{ fontSize: 28, lineHeight: 1, letterSpacing: '-0.025em' }}>{name}</span>
        {ar && <span className="ar" style={{ fontSize: 15, opacity: 0.65 }}>{ar}</span>}
      </div>
      {sub && <div style={{ marginTop: 6, fontSize: 11, opacity: 0.68, lineHeight: 1.35, maxWidth: 160 }}>{sub}</div>}
      {(price || eta) && (
        <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 10 }}>
          {eta && (
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
              <span style={{ width: 6, height: 6, borderRadius: '50%', background: 'currentColor', opacity: 0.7 }}/>
              <span className="mono" style={{ fontSize: 10, letterSpacing: '0.18em' }}>{eta}</span>
            </span>
          )}
          {price && (
            <span style={{ display: 'inline-flex', alignItems: 'baseline', gap: 3 }}>
              <span className="serif" style={{ fontSize: 18, letterSpacing: '-0.02em', lineHeight: 1 }}>{price}</span>
              <span className="mono" style={{ fontSize: 9, letterSpacing: '0.18em', opacity: 0.7 }}>SDG</span>
            </span>
          )}
        </div>
      )}
      {icon && (
        <div style={{ position: 'absolute', top: -2, right: -10, opacity: 0.85 }}>
          <PI name={icon} size={30} color="currentColor" sw={1.5}/>
        </div>
      )}
    </div>
  );
}

function SideRight({ label, name, ar, sub, price, eta, icon }) {
  return (
    <div style={{ position: 'absolute', top: 18, right: 22, width: '46%', textAlign: 'right', pointerEvents: 'none' }}>
      <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.3em', opacity: 0.62 }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6, justifyContent: 'flex-end' }}>
        <span className="serif" style={{ fontSize: 26, lineHeight: 1, letterSpacing: '-0.025em' }}>{name}</span>
        {ar && <span className="ar" style={{ fontSize: 14, opacity: 0.7 }}>{ar}</span>}
      </div>
      {sub && <div style={{ marginTop: 6, fontSize: 11, opacity: 0.72, lineHeight: 1.35, marginLeft: 'auto', maxWidth: 150 }}>{sub}</div>}
      {(price || eta) && (
        <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'flex-end' }}>
          {eta && (
            <span className="mono" style={{ fontSize: 10, letterSpacing: '0.18em', opacity: 0.85 }}>{eta}</span>
          )}
          {price && (
            <span style={{ display: 'inline-flex', alignItems: 'baseline', gap: 3 }}>
              <span className="serif" style={{ fontSize: 18, letterSpacing: '-0.02em', lineHeight: 1 }}>{price}</span>
              <span className="mono" style={{ fontSize: 9, letterSpacing: '0.18em', opacity: 0.7 }}>SDG</span>
            </span>
          )}
        </div>
      )}
      {icon && (
        <div style={{ position: 'absolute', top: -2, left: -10 }}>
          <PI name={icon} size={28} color="currentColor" sw={1.5}/>
        </div>
      )}
    </div>
  );
}

function SideTop({ label, name, ar, sub, price, eta, icon }) {
  return (
    <div style={{ position: 'absolute', top: 14, left: 22, right: 22, display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 14, pointerEvents: 'none' }}>
      <div>
        <div className="mono" style={{ fontSize: 9.5, letterSpacing: '0.3em', opacity: 0.55 }}>{label}</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 4 }}>
          <span className="serif" style={{ fontSize: 24, lineHeight: 1, letterSpacing: '-0.025em' }}>{name}</span>
          {ar && <span className="ar" style={{ fontSize: 14, opacity: 0.6 }}>{ar}</span>}
        </div>
        {sub && <div style={{ marginTop: 4, fontSize: 11, opacity: 0.65 }}>{sub}</div>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        {price && (
          <div style={{ textAlign: 'right' }}>
            <div className="serif" style={{ fontSize: 18, letterSpacing: '-0.02em', lineHeight: 1 }}>{price}</div>
            <div className="mono" style={{ fontSize: 9, letterSpacing: '0.18em', opacity: 0.7, marginTop: 2 }}>SDG</div>
          </div>
        )}
        {icon && <PI name={icon} size={26} color="currentColor" sw={1.5}/>}
      </div>
    </div>
  );
}

function SideBottom({ label, name, ar, eta, price, icon, mono }) {
  return (
    <div style={{ position: 'absolute', left: 22, right: 22, bottom: 12, display: 'flex', alignItems: 'center', justifyContent: 'space-between', pointerEvents: 'none' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        {icon && <PI name={icon} size={22} color="currentColor" sw={1.5}/>}
        <div>
          <div className="mono" style={{ fontSize: 9, letterSpacing: '0.28em', opacity: 0.65 }}>{label}</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 2 }}>
            <span style={{ fontSize: 13, fontWeight: 500 }}>{name}</span>
            {ar && <span className="ar" style={{ fontSize: 12, opacity: 0.6 }}>{ar}</span>}
          </div>
        </div>
      </div>
      {(eta || price) && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {eta && <span className="mono" style={{ fontSize: 10, letterSpacing: '0.2em', opacity: 0.78 }}>{eta}</span>}
          {price && (
            <span style={{ display: 'inline-flex', alignItems: 'baseline', gap: 3 }}>
              <span className="serif" style={{ fontSize: 17, letterSpacing: '-0.02em' }}>{price}</span>
              <span className="mono" style={{ fontSize: 9, opacity: 0.7 }}>SDG</span>
            </span>
          )}
        </div>
      )}
    </div>
  );
}

Object.assign(window, {
  PAIR_GEOM, ConnectedPair, SideLeft, SideRight, SideTop, SideBottom,
});

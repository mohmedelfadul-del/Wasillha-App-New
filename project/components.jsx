// Wasilha — shared components & icons
const { useState, useEffect, useRef, useMemo, useCallback } = React;

// ─────────────────────────────────────────────────────────────
// Icons — line, 24px viewBox, currentColor stroke
// ─────────────────────────────────────────────────────────────
function Icon({ name, size = 22, strokeWidth = 1.6, style = {} }) {
  const s = strokeWidth;
  const props = {
    width: size, height: size, viewBox: '0 0 24 24',
    fill: 'none', stroke: 'currentColor', strokeWidth: s,
    strokeLinecap: 'round', strokeLinejoin: 'round',
    style: { flexShrink: 0, ...style }
  };
  const paths = {
    search: <>
      <circle cx="11" cy="11" r="7" />
      <path d="m21 21-4.3-4.3" />
    </>,
    bell: <>
      <path d="M18 16v-5a6 6 0 0 0-12 0v5l-2 2v1h16v-1l-2-2Z" />
      <path d="M10 21a2 2 0 0 0 4 0" />
    </>,
    pin: <>
      <path d="M12 22s7-6.5 7-12a7 7 0 1 0-14 0c0 5.5 7 12 7 12Z" />
      <circle cx="12" cy="10" r="2.5" />
    </>,
    pindot: <>
      <circle cx="12" cy="12" r="9" />
      <circle cx="12" cy="12" r="3" fill="currentColor" />
    </>,
    car: <>
      <path d="M4 14V11l2-5h12l2 5v3" />
      <path d="M3 14h18v4H3z" />
      <circle cx="7.5" cy="18" r="1.5" />
      <circle cx="16.5" cy="18" r="1.5" />
    </>,
    raksha: <>
      {/* tuk-tuk silhouette: 3 wheels */}
      <path d="M3 16V12l3-5h9l3 5v4" />
      <path d="M3 16h18" />
      <circle cx="6" cy="18" r="1.6" />
      <circle cx="12" cy="18" r="1.6" />
      <circle cx="18" cy="18" r="1.6" />
      <path d="M10 7v5" />
    </>,
    bike: <>
      <circle cx="6" cy="17" r="3" />
      <circle cx="18" cy="17" r="3" />
      <path d="M6 17l4-8h4l3 8" />
      <path d="M10 9l-1-3h-2" />
    </>,
    bag: <>
      <path d="M5 8h14l-1 12H6z" />
      <path d="M9 8V6a3 3 0 0 1 6 0v2" />
    </>,
    bowl: <>
      <path d="M3 11h18a9 9 0 0 1-18 0Z" />
      <path d="M3 11c0-2 4-4 9-4s9 2 9 4" />
      <path d="M12 4v3" />
    </>,
    clock: <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3 2" />
    </>,
    arrow: <>
      <path d="M5 12h14" />
      <path d="m13 5 7 7-7 7" />
    </>,
    chevron: <>
      <path d="m9 6 6 6-6 6" />
    </>,
    chevDown: <>
      <path d="m6 9 6 6 6-6" />
    </>,
    back: <>
      <path d="M19 12H5" />
      <path d="m12 19-7-7 7-7" />
    </>,
    close: <>
      <path d="m6 6 12 12" />
      <path d="m18 6-12 12" />
    </>,
    plus: <>
      <path d="M12 5v14" />
      <path d="M5 12h14" />
    </>,
    minus: <>
      <path d="M5 12h14" />
    </>,
    home: <>
      <path d="M3 11 12 3l9 8" />
      <path d="M5 10v10h14V10" />
    </>,
    wallet: <>
      <path d="M3 7v12a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-9H5a2 2 0 0 1 0-4h12V5" />
      <circle cx="17" cy="14" r="1.2" fill="currentColor" />
    </>,
    history: <>
      <path d="M3 12a9 9 0 1 0 3-6.7" />
      <path d="M3 4v5h5" />
      <path d="M12 8v5l3 2" />
    </>,
    user: <>
      <circle cx="12" cy="8" r="4" />
      <path d="M4 21a8 8 0 0 1 16 0" />
    </>,
    star: <>
      <path d="m12 3 2.7 5.7L21 9.6l-4.7 4.4 1.2 6.4L12 17.3 6.5 20.4l1.2-6.4L3 9.6l6.3-.9z" />
    </>,
    phone: <>
      <path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2Z" />
    </>,
    chat: <>
      <path d="M21 12a8 8 0 0 1-12 7l-5 1 1-5a8 8 0 1 1 16-3Z" />
    </>,
    shield: <>
      <path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6Z" />
    </>,
    plane: <>
      <path d="M22 12 4 4l2 8-2 8z" />
      <path d="m6 12 14 0" />
    </>,
    work: <>
      <rect x="3" y="7" width="18" height="13" rx="2" />
      <path d="M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2" />
    </>,
    moon: <>
      <path d="M21 13A9 9 0 1 1 11 3a7 7 0 0 0 10 10Z" />
    </>,
    sun: <>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4 7 17M17 7l1.4-1.4" />
    </>,
    settings: <>
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 0 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 0 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 0 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 0 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z" />
    </>,
    check: <>
      <path d="m5 12 5 5 9-11" />
    </>,
    target: <>
      <circle cx="12" cy="12" r="9" />
      <circle cx="12" cy="12" r="5" />
      <circle cx="12" cy="12" r="1" fill="currentColor" />
    </>,
    nav: <>
      <path d="m3 11 18-8-8 18-2-8z" />
    </>,
    eye: <>
      <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7S1 12 1 12Z" />
      <circle cx="12" cy="12" r="3" />
    </>,
    flame: <>
      <path d="M12 2s4 5 4 9a4 4 0 0 1-8 0c0-1 .5-2 1-3-2 1-3 3-3 5a6 6 0 0 0 12 0c0-5-6-11-6-11Z" />
    </>,
    gift: <>
      <rect x="3" y="8" width="18" height="4" />
      <path d="M5 12v10h14V12M12 8v14" />
      <path d="M12 8s-2-5-5-5-2 5 5 5ZM12 8s2-5 5-5 2 5-5 5Z" />
    </>,
    receipt: <>
      <path d="M5 3h14v18l-2-2-2 2-2-2-2 2-2-2-2 2-2-2z" />
      <path d="M8 8h8M8 12h8M8 16h5" />
    </>,
    earth: <>
      <circle cx="12" cy="12" r="9" />
      <path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18" />
    </>,
    help: <>
      <circle cx="12" cy="12" r="9" />
      <path d="M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .8-1 1.7" />
      <circle cx="12" cy="17" r="0.6" fill="currentColor" />
    </>,
    logout: <>
      <path d="M10 17l-5-5 5-5" />
      <path d="M5 12h12" />
      <path d="M21 5v14" />
    </>,
    sparkle: <>
      <path d="M12 3v6M12 15v6M3 12h6M15 12h6" />
    </>
  };
  return <svg {...props} style={{ stroke: "rgb(0, 0, 0)" }}>{paths[name]}</svg>;
}

// ─────────────────────────────────────────────────────────────
// Glass surface
// ─────────────────────────────────────────────────────────────
function Glass({ children, style = {}, intensity = 60, dark = false, className = '' }) {
  const blur = 8 + intensity / 100 * 24;
  const tint = dark ?
  `rgba(20, 18, 16, ${0.5 + intensity / 400})` :
  `rgba(255, 255, 255, ${0.4 + intensity / 250})`;
  return (
    <div className={className} style={{
      position: 'relative',
      background: tint,
      backdropFilter: `blur(${blur}px) saturate(160%)`,
      WebkitBackdropFilter: `blur(${blur}px) saturate(160%)`,
      border: dark ? '0.5px solid rgba(255,255,255,0.08)' : '0.5px solid rgba(255,255,255,0.7)',
      boxShadow: dark ?
      '0 1px 0 rgba(255,255,255,0.05) inset, 0 10px 30px rgba(0,0,0,0.3)' :
      '0 1px 0 rgba(255,255,255,0.7) inset, 0 8px 28px rgba(20, 15, 30, 0.08), 0 2px 6px rgba(20, 15, 30, 0.04)',
      ...style
    }}>{children}</div>);

}

// ─────────────────────────────────────────────────────────────
// Map — stylized SVG. Nile curve, roads, parks, optional pins.
// ─────────────────────────────────────────────────────────────
function MapView({ style = 'white', accent = '#9D00FF', showRoute = false, drivers = 0, pulse = false, width = 402, height = 874 }) {
  // palettes
  const P = {
    white: { bg: '#F4F1EA', road: '#E4DFD3', roadHi: '#FFFFFF', water: '#DDE6E8', park: '#E3E5D8', label: '#A8A296' },
    dark: { bg: '#15161A', road: '#26282E', roadHi: '#3A3D45', water: '#1B2730', park: '#1C2620', label: '#5C5F66' },
    illustrated: { bg: '#F1ECDF', road: '#E5DFCC', roadHi: '#FAF5E6', water: '#BBD3D8', park: '#D2DEB8', label: '#9C957F' }
  }[style] || {};
  return (
    <svg width="100%" height="100%" viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="xMidYMid slice" style={{ display: 'block' }}>
      <rect width="100%" height="100%" fill={P.bg} />
      {/* Nile curve (left to right with a meander, suggestion of Khartoum confluence) */}
      <path d="M-20 320 C 80 280, 130 380, 200 360 S 360 280, 460 320 L 460 410 C 360 380, 240 460, 160 440 S 30 470, -20 430 Z" fill={P.water} opacity="0.95" />
      {/* secondary blue branch */}
      <path d="M120 -20 C 140 80, 200 180, 200 360" stroke={P.water} strokeWidth="44" fill="none" opacity="0.9" />
      {/* parks */}
      <ellipse cx="60" cy="180" rx="80" ry="42" fill={P.park} opacity="0.85" />
      <ellipse cx="340" cy="560" rx="100" ry="70" fill={P.park} opacity="0.8" />
      <ellipse cx="90" cy="700" rx="120" ry="60" fill={P.park} opacity="0.7" />
      <ellipse cx="380" cy="120" rx="60" ry="50" fill={P.park} opacity="0.5" />

      {/* Roads — grid + diagonals */}
      <g stroke={P.road} strokeWidth="14" fill="none" strokeLinecap="round">
        <path d="M-20 90 L 460 110" />
        <path d="M-20 220 L 460 240" />
        <path d="M-20 520 L 460 510" />
        <path d="M-20 640 L 460 660" />
        <path d="M-20 780 L 460 800" />
        <path d="M70 -20 L 90 894" />
        <path d="M210 -20 L 220 360" />
        <path d="M210 420 L 230 894" />
        <path d="M330 -20 L 340 894" />
      </g>
      {/* thin highlight inside roads */}
      <g stroke={P.roadHi} strokeWidth="3" fill="none" strokeLinecap="round" opacity="0.9">
        <path d="M-20 90 L 460 110" />
        <path d="M-20 520 L 460 510" />
        <path d="M70 -20 L 90 894" />
        <path d="M330 -20 L 340 894" />
      </g>
      {/* diagonal connector — gives organic feel */}
      <g stroke={P.road} strokeWidth="10" fill="none" strokeLinecap="round">
        <path d="M-20 460 Q 200 470, 460 660" />
        <path d="M40 894 Q 200 720, 460 760" />
      </g>

      {/* Route line (purple, glowing) */}
      {showRoute &&
      <>
          <path d="M 100 640 Q 140 540, 220 510 T 320 280" stroke={accent} strokeOpacity="0.18" strokeWidth="18" fill="none" strokeLinecap="round" />
          <path d="M 100 640 Q 140 540, 220 510 T 320 280" stroke={accent} strokeWidth="5" fill="none" strokeLinecap="round" strokeDasharray="0 1" />
          {/* origin dot */}
          <circle cx="100" cy="640" r="9" fill="#fff" stroke={accent} strokeWidth="3.5" />
          {/* destination pin */}
          <g transform="translate(320 280)">
            <circle r="14" fill={accent} />
            <circle r="5" fill="#fff" />
          </g>
        </>
      }

      {/* tiny labels — district hints */}
      <g fill={P.label} fontFamily="Geist Mono, monospace" fontSize="9" letterSpacing="0.12em">
        <text x="40" y="80" opacity="0.85">OMDURMAN</text>
        <text x="260" y="80" opacity="0.85">KHARTOUM N.</text>
        <text x="240" y="710" opacity="0.85">KHARTOUM</text>
        <text x="40" y="600" opacity="0.7">RIVERSIDE</text>
      </g>

      {/* driver pulses */}
      {Array.from({ length: drivers }).map((_, i) => {
        const positions = [
        [180, 220], [300, 340], [120, 480], [280, 590], [80, 730], [360, 680], [200, 130]];

        const [cx, cy] = positions[i % positions.length];
        return (
          <g key={i} transform={`translate(${cx} ${cy})`}>
            <circle r="6" fill="#0A0908" stroke="#fff" strokeWidth="2" />
            <circle r="3" fill="#fff" />
          </g>);

      })}

      {/* pulse on origin */}
      {pulse &&
      <g transform="translate(100 640)">
          <circle r="22" fill={accent} opacity="0.12">
            <animate attributeName="r" values="14;32;14" dur="2.4s" repeatCount="indefinite" />
            <animate attributeName="opacity" values="0.18;0;0.18" dur="2.4s" repeatCount="indefinite" />
          </circle>
        </g>
      }
    </svg>);

}

// ─────────────────────────────────────────────────────────────
// Bottom nav (Home / Wallet / History / Profile)
// ─────────────────────────────────────────────────────────────
function BottomNav({ active, onNav, accent, glass }) {
  const items = [
  { id: 'home', label: 'Home', icon: 'home' },
  { id: 'wallet', label: 'Wallet', icon: 'wallet' },
  { id: 'history', label: 'History', icon: 'history' },
  { id: 'settings', label: 'Account', icon: 'user' }];

  return (
    <div style={{
      position: 'absolute', left: 12, right: 12, bottom: 22,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 30, pointerEvents: 'none'
    }}>
      <Glass intensity={glass} style={{
        borderRadius: 999, padding: '8px', display: 'flex', gap: 4,
        pointerEvents: 'auto'
      }}>
        {items.map((it) => {
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
              transition: 'background 0.2s, color 0.2s'
            }}>
              <Icon name={it.icon} size={18} strokeWidth={1.7} />
              {isActive && <span>{it.label}</span>}
            </button>);

        })}
      </Glass>
    </div>);

}

// ─────────────────────────────────────────────────────────────
// Service card
// ─────────────────────────────────────────────────────────────
function ServiceCard({ icon, name, ar, sub, accent, layout = 'grid', onTap, primary = false, lang = 'en' }) {
  if (layout === 'row') {
    return (
      <button onClick={onTap} style={{
        appearance: 'none', border: 0, cursor: 'pointer', width: '100%',
        padding: '14px 16px', borderRadius: 16,
        background: primary ? '#0A0908' : '#fff',
        color: primary ? '#fff' : '#0A0908',
        boxShadow: '0 1px 0 rgba(255,255,255,0.6) inset, 0 6px 16px rgba(20,15,30,0.06)',
        display: 'flex', alignItems: 'center', gap: 14,
        textAlign: 'left'
      }}>
        <div style={{
          width: 44, height: 44, borderRadius: 12,
          background: primary ? 'rgba(255,255,255,0.1)' : 'var(--surface-2)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: primary ? accent : '#0A0908'
        }}>
          <Icon name={icon} size={22} strokeWidth={1.6} />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 500, letterSpacing: '-0.01em' }}>
            {lang === 'ar' ? <span className="ar">{ar}</span> : name}
          </div>
          <div style={{ fontSize: 12, color: primary ? 'rgba(255,255,255,0.55)' : 'var(--text-2)', marginTop: 2 }}>
            {sub}
          </div>
        </div>
        <Icon name="chevron" size={16} strokeWidth={1.6} style={{ opacity: 0.5 }} />
      </button>);

  }
  return (
    <button onClick={onTap} style={{ ...{
        appearance: 'none', border: 0, cursor: 'pointer',
        padding: '16px 14px 14px', borderRadius: 18,
        background: primary ? '#0A0908' : '#fff',
        color: primary ? '#fff' : '#0A0908',
        boxShadow: primary ?
        '0 8px 22px rgba(10,9,8,0.18)' :
        '0 1px 0 rgba(255,255,255,0.7) inset, 0 6px 16px rgba(20,15,30,0.06)',
        display: 'flex', flexDirection: 'column', gap: 10,
        textAlign: 'left', position: 'relative', overflow: 'hidden',
        minHeight: 108
      }, backgroundImage: "initial", backgroundPosition: "initial", backgroundSize: "initial", backgroundRepeat: "initial", backgroundAttachment: "initial", backgroundOrigin: "initial", backgroundClip: "initial", opacity: "1", color: "rgb(0, 0, 0)", background: "rgb(243, 240, 245)", margin: "0px", borderStyle: "none", borderColor: "currentcolor", borderImage: "initial", borderWidth: "2px 2px 2px 0px", borderRadius: "18px", border: "2px solid rgb(244, 244, 244)" }}>
      {primary &&
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(circle at 80% 10%, ${accent}55, transparent 60%)`,
        pointerEvents: 'none'
      }} />
      }
      <div style={{
        width: 38, height: 38, borderRadius: 10,
        background: primary ? 'rgba(255,255,255,0.1)' : 'var(--surface-2)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: primary ? '#fff' : '#0A0908',
        position: 'relative', zIndex: 1
      }}>
        <Icon name={icon} size={20} strokeWidth={1.6} />
      </div>
      <div style={{ marginTop: 'auto', position: 'relative', zIndex: 1 }}>
        <div style={{ fontSize: 15, fontWeight: 500, letterSpacing: '-0.01em' }}>
          {lang === 'ar' ? <span className="ar">{ar}</span> : name}
        </div>
        <div style={{ fontSize: 11, color: primary ? 'rgba(255,255,255,0.55)' : 'var(--text-2)', marginTop: 1, letterSpacing: '0.02em' }}>
          {sub}
        </div>
      </div>
    </button>);

}

// ─────────────────────────────────────────────────────────────
// Button — primary purple, secondary, ghost
// ─────────────────────────────────────────────────────────────
function Btn({ children, variant = 'primary', accent, full = false, onClick, icon, dark = false, style = {} }) {
  const bgs = {
    primary: accent,
    dark: '#0A0908',
    secondary: dark ? 'rgba(255,255,255,0.08)' : 'var(--surface-2)',
    ghost: 'transparent',
    light: '#fff'
  };
  const colors = {
    primary: '#fff',
    dark: '#fff',
    secondary: dark ? '#fff' : '#0A0908',
    ghost: dark ? '#fff' : '#0A0908',
    light: '#0A0908'
  };
  return (
    <button onClick={onClick} style={{
      appearance: 'none', border: variant === 'ghost' ? '0.5px solid rgba(255,255,255,0.2)' : 0,
      cursor: 'pointer',
      background: bgs[variant], color: colors[variant],
      height: 52, padding: '0 22px', borderRadius: 16,
      fontFamily: 'inherit', fontSize: 15, fontWeight: 500, letterSpacing: '-0.01em',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      width: full ? '100%' : 'auto',
      boxShadow: variant === 'primary' ?
      `0 8px 22px ${accent}40, 0 1px 0 rgba(255,255,255,0.3) inset` :
      variant === 'dark' ? '0 8px 22px rgba(10,9,8,0.25)' : 'none',
      transition: 'transform 0.1s',
      ...style
    }}
    onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.98)'}
    onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
    onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}>
      
      {children}
      {icon && <Icon name={icon} size={18} strokeWidth={1.8} />}
    </button>);

}

// Avatar placeholder
function Avatar({ size = 40, label = 'AH', tone = 'warm' }) {
  const tones = {
    warm: 'linear-gradient(135deg, #E8D9C4 0%, #C9B59A 100%)',
    cool: 'linear-gradient(135deg, #D4DDE5 0%, #A8B5C2 100%)',
    purple: 'linear-gradient(135deg, #E0CCEF 0%, #B894D3 100%)',
    olive: 'linear-gradient(135deg, #D6D6BC 0%, #A8A88A 100%)'
  };
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: tones[tone] || tones.warm,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'Geist', fontSize: size * 0.32, fontWeight: 600, letterSpacing: '0.04em',
      color: '#fff', flexShrink: 0,
      boxShadow: 'inset 0 -2px 4px rgba(0,0,0,0.1)'
    }}>{label}</div>);

}

// Surface row (used in lists)
function Row({ icon, title, detail, right, onClick, dark = false }) {
  return (
    <button onClick={onClick} style={{
      appearance: 'none', border: 0, cursor: 'pointer', width: '100%',
      padding: '14px 0', display: 'flex', alignItems: 'center', gap: 14,
      background: 'transparent', color: dark ? '#fff' : '#0A0908',
      textAlign: 'left', borderBottom: dark ? '0.5px solid rgba(255,255,255,0.06)' : '0.5px solid var(--border)'
    }}>
      {icon &&
      <div style={{
        width: 38, height: 38, borderRadius: 11,
        background: dark ? 'rgba(255,255,255,0.06)' : 'var(--surface-2)',
        display: 'flex', alignItems: 'center', justifyContent: 'center'
      }}>
          <Icon name={icon} size={18} strokeWidth={1.6} />
        </div>
      }
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14.5, fontWeight: 500, letterSpacing: '-0.005em' }}>{title}</div>
        {detail &&
        <div style={{ fontSize: 12, color: dark ? 'rgba(255,255,255,0.55)' : 'var(--text-2)', marginTop: 2 }}>{detail}</div>
        }
      </div>
      {right}
    </button>);

}

Object.assign(window, { Icon, Glass, MapView, BottomNav, ServiceCard, Btn, Avatar, Row });
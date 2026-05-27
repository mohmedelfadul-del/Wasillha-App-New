// Wasilha — pre-auth screens (Splash, Onboarding, Login, OTP)

// ─────────────────────────────────────────────────────────────
// 01 — SPLASH
// ─────────────────────────────────────────────────────────────
function SplashScreen({ nav, accent, lang }) {
  React.useEffect(() => {
    const t = setTimeout(() => nav('onboarding'), 2800);
    return () => clearTimeout(t);
  }, [nav]);
  return (
    <div data-screen-label="01 Splash" style={{
      position: 'absolute', inset: 0,
      background: '#FBFAF6',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      overflow: 'hidden',
    }}>
      {/* ambient glow */}
      <div style={{
        position: 'absolute', top: '40%', left: '50%', transform: 'translate(-50%, -50%)',
        width: 420, height: 420, borderRadius: '50%',
        background: `radial-gradient(circle, ${accent}1A 0%, transparent 65%)`,
        animation: 'pulse-soft 4s ease-in-out infinite',
      }} />
      <div style={{ position: 'relative', zIndex: 2, textAlign: 'center', animation: 'fade-up 0.8s' }}>
        <img
          src="assets/wasilha-logo.png"
          alt="Wasilha — وصلها"
          style={{
            width: 220, height: 'auto', display: 'block', margin: '0 auto',
            filter: 'drop-shadow(0 8px 24px rgba(30, 42, 78, 0.18))',
          }}
        />
        <div className="mono" style={{
          fontSize: 10, letterSpacing: '0.5em',
          marginTop: 24, color: 'var(--text-2)',
          textTransform: 'uppercase', paddingLeft: 8,
        }}>MOBILITY FOR SUDAN</div>
      </div>
      <div style={{
        position: 'absolute', bottom: 70, left: '50%', transform: 'translateX(-50%)',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
      }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {[0,1,2].map(i => (
            <div key={i} style={{
              width: 6, height: 6, borderRadius: '50%',
              background: accent, opacity: 0.4,
              animation: `pulse-soft 1.2s ease-in-out infinite`,
              animationDelay: `${i * 0.2}s`,
            }} />
          ))}
        </div>
        <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          {lang === 'ar' ? 'مرحبا بالسودان' : 'CONNECTING SUDAN'}
        </div>
      </div>
      {/* corner editorial mark */}
      <div className="mono" style={{
        position: 'absolute', top: 60, left: 24, fontSize: 9, color: 'var(--text-3)',
        letterSpacing: '0.24em',
      }}>EST · 2026 · KRT</div>
      <div className="mono" style={{
        position: 'absolute', top: 60, right: 24, fontSize: 9, color: 'var(--text-3)',
        letterSpacing: '0.24em',
      }}>v 1.0</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 02 — ONBOARDING (3 slides)
// ─────────────────────────────────────────────────────────────
function OnboardingScreen({ nav, accent, lang }) {
  const [i, setI] = React.useState(0);
  const slides = lang === 'ar' ? [
    {
      hero: 'raksha',
      kicker: 'الحركة',
      ar: 'كل وسائل النقل',
      en: 'Every way to move.',
      body: 'راكشة، سيارة، دراجة، توصيل — كلها في تطبيق واحد.',
    },
    {
      hero: 'pricing',
      kicker: 'الشفافية',
      ar: 'السعر قبل الركوب',
      en: 'Price before you ride.',
      body: 'بدون مفاجآت. التسعير واضح وعادل قبل تأكيد الرحلة.',
    },
    {
      hero: 'trust',
      kicker: 'الثقة',
      ar: 'سائقون موثوقون',
      en: 'Drivers you can trust.',
      body: 'كل سائق متحقق منه، مع تتبع مباشر وزر طوارئ.',
    },
  ] : [
    {
      hero: 'raksha',
      kicker: 'MOTION',
      ar: 'كل وسائل النقل',
      en: 'Every way to move.',
      body: 'Raksha, car, motorcycle, delivery — one tap to anywhere across Khartoum.',
    },
    {
      hero: 'pricing',
      kicker: 'CLARITY',
      ar: 'السعر قبل الركوب',
      en: 'Price before you ride.',
      body: 'No surprises. See the fare and route up front, every single trip.',
    },
    {
      hero: 'trust',
      kicker: 'TRUST',
      ar: 'سائقون موثوقون',
      en: 'Drivers you trust.',
      body: 'Every driver verified, every ride tracked. One tap for help, anywhere.',
    },
  ];
  const s = slides[i];

  return (
    <div data-screen-label="02 Onboarding" style={{
      position: 'absolute', inset: 0,
      background: '#FBFAF6',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* top bar */}
      <div style={{
        paddingTop: 60, padding: '60px 24px 0',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <span className="mono" style={{ fontSize: 10, letterSpacing: '0.3em', color: 'var(--text-2)' }}>
          {String(i + 1).padStart(2, '0')} / 03
        </span>
        <button onClick={() => nav('login')} style={{
          border: 0, background: 'transparent', cursor: 'pointer',
          fontFamily: 'inherit', fontSize: 13, color: 'var(--text-2)', letterSpacing: '-0.005em',
        }}>{lang === 'ar' ? 'تخطي' : 'Skip'}</button>
      </div>

      {/* hero area */}
      <div style={{ flex: 1, padding: '20px 24px', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
        <div style={{
          flex: 1, position: 'relative', marginBottom: 36,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <OnboardHero kind={s.hero} accent={accent} />
        </div>

        <div className="mono" style={{ fontSize: 10, letterSpacing: '0.32em', color: accent, marginBottom: 14 }}>
          {s.kicker}
        </div>
        <div className="serif" style={{
          fontSize: 46, lineHeight: 1.02, letterSpacing: '-0.02em', color: '#0A0908',
        }} key={`en-${i}`}>
          {s.en.split(' ').slice(0, -1).join(' ')} <span style={{ color: accent }}>{s.en.split(' ').slice(-1)[0]}</span>
        </div>
        <div className="ar-serif" style={{
          fontFamily: 'Amiri, serif', fontSize: 22, color: 'var(--text-2)', marginTop: 8,
        }} key={`ar-${i}`}>{s.ar}</div>
        <div style={{
          fontSize: 14, lineHeight: 1.55, color: 'var(--text-2)', marginTop: 14,
          maxWidth: 320,
        }} key={`body-${i}`}>{s.body}</div>
      </div>

      {/* footer */}
      <div style={{
        padding: '24px 24px 50px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {[0,1,2].map(d => (
            <div key={d} style={{
              width: d === i ? 22 : 6, height: 6, borderRadius: 3,
              background: d === i ? accent : 'var(--border-2)',
              transition: 'all 0.3s',
            }} />
          ))}
        </div>
        <button
          onClick={() => i < 2 ? setI(i + 1) : nav('login')}
          style={{
            width: 56, height: 56, borderRadius: '50%', border: 0, cursor: 'pointer',
            background: accent, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 10px 24px ${accent}40`,
          }}>
          <Icon name="arrow" size={20} strokeWidth={1.8} />
        </button>
      </div>
    </div>
  );
}

// Onboarding hero illustration (abstract editorial)
function OnboardHero({ kind, accent }) {
  if (kind === 'raksha') {
    return (
      <div style={{ position: 'relative', width: 280, height: 280 }}>
        {/* tilted card stack */}
        <div style={{
          position: 'absolute', inset: 0,
          background: '#0A0908', borderRadius: 24,
          transform: 'rotate(-6deg) translate(-12px, 8px)',
          opacity: 0.05,
        }} />
        <div style={{
          position: 'absolute', inset: 0,
          background: `linear-gradient(135deg, ${accent}28 0%, ${accent}08 100%)`,
          borderRadius: 24,
          transform: 'rotate(-3deg) translate(-6px, 4px)',
          border: `0.5px solid ${accent}30`,
        }} />
        <div style={{
          position: 'absolute', inset: 0,
          background: '#fff', borderRadius: 24,
          boxShadow: '0 24px 60px rgba(20,15,30,0.12)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: '#0A0908',
        }}>
          <div style={{ transform: 'scale(4.5)' }}>
            <Icon name="raksha" size={36} strokeWidth={1.2} />
          </div>
          <div className="mono" style={{
            position: 'absolute', bottom: 18, left: 20,
            fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em',
          }}>RAKSHA · KRT</div>
          <div className="mono" style={{
            position: 'absolute', top: 18, right: 20,
            fontSize: 9, color: accent, letterSpacing: '0.22em',
          }}>● LIVE</div>
        </div>
      </div>
    );
  }
  if (kind === 'pricing') {
    return (
      <div style={{ position: 'relative', width: 280, height: 280 }}>
        <div style={{
          position: 'absolute', inset: 0,
          background: '#fff', borderRadius: 24,
          boxShadow: '0 24px 60px rgba(20,15,30,0.1)',
          padding: 22,
          display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
        }}>
          <div>
            <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.22em' }}>FARE PREVIEW</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 12 }}>
              <span className="serif" style={{ fontSize: 64, lineHeight: 1, color: '#0A0908', letterSpacing: '-0.02em' }}>4,200</span>
              <span className="mono" style={{ fontSize: 11, color: 'var(--text-2)' }}>SDG</span>
            </div>
            <div style={{ fontSize: 12, color: 'var(--text-2)', marginTop: 6 }}>Khartoum 2 → Bahri</div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {['Raksha','Car','Bike'].map((r, i) => (
              <div key={r} style={{
                flex: 1, padding: '8px 0', borderRadius: 10, textAlign: 'center',
                background: i === 1 ? '#0A0908' : 'var(--surface-2)',
                color: i === 1 ? '#fff' : '#0A0908',
                fontSize: 11, fontWeight: 500,
              }}>{r}</div>
            ))}
          </div>
        </div>
        <div className="serif" style={{
          position: 'absolute', top: -10, right: -10,
          background: accent, color: '#fff',
          padding: '8px 14px', borderRadius: 999,
          fontSize: 18,
          transform: 'rotate(8deg)',
          boxShadow: `0 8px 18px ${accent}50`,
        }}>fair</div>
      </div>
    );
  }
  // trust
  return (
    <div style={{ position: 'relative', width: 280, height: 280 }}>
      <div style={{
        position: 'absolute', inset: 0,
        background: '#fff', borderRadius: 24,
        boxShadow: '0 24px 60px rgba(20,15,30,0.1)',
        padding: 22, display: 'flex', flexDirection: 'column',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Avatar size={54} label="OM" tone="warm" />
          <div>
            <div style={{ fontSize: 16, fontWeight: 500 }}>Omar M.</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--text-2)', fontSize: 12 }}>
              <Icon name="star" size={12} style={{ color: '#E4B73B' }} /> 4.96 · 2,108 rides
            </div>
          </div>
        </div>
        <div style={{
          marginTop: 18, padding: 14, background: 'var(--surface-2)', borderRadius: 14,
        }}>
          <div className="mono" style={{ fontSize: 9, color: 'var(--text-3)', letterSpacing: '0.2em' }}>VEHICLE</div>
          <div style={{ fontSize: 14, marginTop: 4 }}>Toyota Corolla · White</div>
          <div className="mono" style={{ fontSize: 14, fontWeight: 600, marginTop: 8, letterSpacing: '0.18em' }}>KRT · 4421</div>
        </div>
        <div style={{ marginTop: 'auto', display: 'flex', gap: 8 }}>
          <div style={{
            flex: 1, padding: '10px 0', borderRadius: 10, textAlign: 'center',
            background: 'var(--surface-2)', fontSize: 11, color: 'var(--text-2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}><Icon name="shield" size={13} />Verified</div>
          <div style={{
            flex: 1, padding: '10px 0', borderRadius: 10, textAlign: 'center',
            background: accent + '14', color: accent, fontSize: 11,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}><Icon name="eye" size={13} />Tracked</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 03 — LOGIN
// ─────────────────────────────────────────────────────────────
function LoginScreen({ nav, accent, lang }) {
  const [phone, setPhone] = React.useState('91 234 5678');
  return (
    <div data-screen-label="03 Login" style={{
      position: 'absolute', inset: 0, background: '#FBFAF6',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ paddingTop: 60, padding: '60px 24px 24px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <img
          src="assets/wasilha-logo.png"
          alt="Wasilha"
          style={{ height: 56, width: 'auto' }}
        />
      </div>

      <div style={{ padding: '40px 24px 0' }}>
        <div className="mono" style={{ fontSize: 10, color: accent, letterSpacing: '0.32em', marginBottom: 14 }}>
          STEP 01 / WELCOME
        </div>
        <div className="serif" style={{ fontSize: 52, lineHeight: 1, letterSpacing: '-0.02em', color: '#0A0908' }}>
          Welcome
          <span style={{ display: 'block', color: accent }}>back.</span>
        </div>
        <div className="ar-serif" style={{ fontFamily: 'Amiri, serif', fontSize: 24, color: 'var(--text-2)', marginTop: 10 }}>
          أهلاً بعودتك
        </div>
        <div style={{ fontSize: 14, color: 'var(--text-2)', marginTop: 16, lineHeight: 1.5 }}>
          Enter your phone number. We'll send a one-time code to verify it's really you.
        </div>
      </div>

      <div style={{ padding: '40px 24px 0' }}>
        <div style={{
          background: '#fff', borderRadius: 18, padding: '6px',
          display: 'flex', alignItems: 'center', gap: 6,
          boxShadow: '0 1px 0 rgba(255,255,255,0.6) inset, 0 8px 22px rgba(20,15,30,0.05)',
          border: '0.5px solid var(--border)',
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '12px 14px', borderRadius: 14,
            background: 'var(--surface-2)',
          }}>
            <span style={{ fontSize: 18 }}>🇸🇩</span>
            <span className="mono" style={{ fontSize: 14, fontWeight: 500 }}>+249</span>
            <Icon name="chevDown" size={14} style={{ color: 'var(--text-2)' }} />
          </div>
          <input value={phone} onChange={(e) => setPhone(e.target.value)} style={{
            flex: 1, border: 0, outline: 'none', background: 'transparent',
            fontFamily: 'Geist Mono, monospace', fontSize: 16, letterSpacing: '0.04em',
            padding: '0 10px', color: '#0A0908', minWidth: 0,
          }} />
        </div>

        <div style={{ marginTop: 18 }}>
          <Btn full accent={accent} onClick={() => nav('otp')} icon="arrow">
            Send code
          </Btn>
        </div>

        <div style={{
          display: 'flex', alignItems: 'center', gap: 10, margin: '28px 0 20px',
          color: 'var(--text-3)', fontSize: 11, letterSpacing: '0.16em',
        }}>
          <div style={{ flex: 1, height: '0.5px', background: 'var(--border-2)' }} />
          <span className="mono">OR CONTINUE WITH</span>
          <div style={{ flex: 1, height: '0.5px', background: 'var(--border-2)' }} />
        </div>

        <div style={{ display: 'flex', gap: 10 }}>
          {[
            { l: 'Apple', g: '' },
            { l: 'Google', g: '' },
            { l: 'Email', g: '' },
          ].map(o => (
            <button key={o.l} style={{
              flex: 1, height: 52, borderRadius: 14,
              border: '0.5px solid var(--border)', background: '#fff',
              fontFamily: 'inherit', fontSize: 13, cursor: 'pointer',
              color: '#0A0908',
            }}>{o.l}</button>
          ))}
        </div>
      </div>

      <div style={{
        marginTop: 'auto', padding: '20px 36px 50px', textAlign: 'center',
        fontSize: 11, color: 'var(--text-3)', lineHeight: 1.5,
      }}>
        By continuing you agree to Wasilha's{' '}
        <span style={{ color: '#0A0908', textDecoration: 'underline' }}>Terms</span> &{' '}
        <span style={{ color: '#0A0908', textDecoration: 'underline' }}>Privacy</span>.
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 04 — OTP
// ─────────────────────────────────────────────────────────────
function OTPScreen({ nav, accent, lang }) {
  const [digits, setDigits] = React.useState(['9','1','8','','','']);
  const [resend, setResend] = React.useState(47);
  React.useEffect(() => {
    if (resend <= 0) return;
    const t = setTimeout(() => setResend(r => r - 1), 1000);
    return () => clearTimeout(t);
  }, [resend]);
  return (
    <div data-screen-label="04 OTP" style={{
      position: 'absolute', inset: 0, background: '#FBFAF6',
      display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ paddingTop: 60, padding: '60px 24px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={() => nav('login')} style={{
          width: 40, height: 40, borderRadius: 12, border: 0, cursor: 'pointer',
          background: '#fff', boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="back" size={18} strokeWidth={1.7} />
        </button>
        <span className="mono" style={{ fontSize: 10, color: 'var(--text-3)', letterSpacing: '0.3em' }}>
          STEP 02 / VERIFY
        </span>
      </div>

      <div style={{ padding: '40px 24px 0' }}>
        <div className="serif" style={{ fontSize: 44, lineHeight: 1.02, letterSpacing: '-0.02em', color: '#0A0908' }}>
          Six digits.<br /><span style={{ color: accent }}>One ride away.</span>
        </div>
        <div style={{ fontSize: 14, color: 'var(--text-2)', marginTop: 16, lineHeight: 1.5 }}>
          We sent a code to <span className="mono" style={{ color: '#0A0908' }}>+249 91 *** 5678</span>
        </div>
      </div>

      <div style={{ padding: '36px 24px 0' }}>
        <div style={{ display: 'flex', gap: 8 }}>
          {digits.map((d, i) => (
            <div key={i} style={{
              flex: 1, height: 64, borderRadius: 16,
              background: '#fff',
              border: d ? `1.5px solid ${accent}` : '0.5px solid var(--border)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Geist Mono, monospace', fontSize: 28, fontWeight: 500,
              color: '#0A0908',
              boxShadow: d ? `0 6px 18px ${accent}20` : '0 1px 2px rgba(0,0,0,0.03)',
              transition: 'all 0.2s',
              position: 'relative',
            }}>
              {d || <div style={{
                width: 2, height: 28, background: i === digits.findIndex(x => !x) ? accent : 'transparent',
                animation: 'pulse-soft 1s ease-in-out infinite',
              }} />}
            </div>
          ))}
        </div>

        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          marginTop: 24,
        }}>
          <span style={{ fontSize: 13, color: 'var(--text-2)' }}>Didn't get it?</span>
          <span className="mono" style={{ fontSize: 12, color: resend > 0 ? 'var(--text-3)' : accent, letterSpacing: '0.06em' }}>
            {resend > 0 ? `RESEND IN 0:${String(resend).padStart(2, '0')}` : 'TAP TO RESEND'}
          </span>
        </div>

        <div style={{ marginTop: 32 }}>
          <Btn full accent={accent} onClick={() => nav('role')} icon="arrow">
            Verify & continue
          </Btn>
        </div>
      </div>

      {/* numeric keypad mock */}
      <div style={{ marginTop: 'auto', padding: '0 12px 30px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
          {['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k, i) => (
            <button
              key={i}
              onClick={() => {
                if (k === '⌫') {
                  setDigits(d => { const last = [...d].reverse().findIndex(x => x); if (last < 0) return d; const idx = 5 - last; const nd = [...d]; nd[idx] = ''; return nd; });
                } else if (k) {
                  setDigits(d => { const idx = d.findIndex(x => !x); if (idx < 0) return d; const nd = [...d]; nd[idx] = k; return nd; });
                }
              }}
              disabled={!k}
              style={{
                height: 48, border: 0, borderRadius: 14,
                background: k ? 'rgba(255,255,255,0.6)' : 'transparent',
                fontFamily: k === '⌫' ? 'Geist' : 'Geist Mono, monospace',
                fontSize: 22, fontWeight: 500, color: '#0A0908',
                cursor: k ? 'pointer' : 'default',
                boxShadow: k ? '0 1px 2px rgba(0,0,0,0.04)' : 'none',
              }}>{k}</button>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { SplashScreen, OnboardingScreen, LoginScreen, OTPScreen });

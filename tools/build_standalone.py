# Builds ../Wasilha.html: a self-contained copy of project/Wasilha.html with all JSX, CSS and the logo inlined.
# Usage: python3 tools/build_standalone.py
import re, base64, pathlib
P = pathlib.Path(__file__).resolve().parent.parent / 'project'
html = (P/'Wasilha.html').read_text()

def must_sub(old, new, s, count=1):
    assert old in s, old[:60]
    return s.replace(old, new, count)

# 1. Strip SRI attrs (keep pinned CDN URLs)
html = re.sub(r'\s+integrity="[^"]+"', '', html)

# 2. Inline styles.css + global keyframes previously injected by screens
css = (P/'styles.css').read_text()
extra = """
/* Keyframes hoisted from screen-level <style> tags so every screen can use them */
@keyframes ws-bid-in { from { opacity: 0; transform: translateY(10px) scale(0.985); } to { opacity: 1; transform: translateY(0) scale(1); } }
@keyframes ws-ping { 0% { transform: scale(0.6); opacity: 1; } 100% { transform: scale(2.2); opacity: 0; } }
@keyframes ws-pulse { 0%, 100% { opacity: 0.5; } 50% { opacity: 0.9; } }
@keyframes ws-cart-in { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
.tweaks-fab {
  position: fixed; right: 20px; bottom: 20px; z-index: 2147483000;
  appearance: none; border: 0.5px solid rgba(255,255,255,0.14); cursor: pointer;
  background: rgba(20,18,16,0.82); color: #fff;
  backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px);
  font: 500 12px/1 'Geist', system-ui, sans-serif; letter-spacing: 0.02em;
  padding: 11px 16px; border-radius: 999px; display: flex; align-items: center; gap: 8px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.25);
}
.tweaks-fab:hover { background: rgba(30,27,24,0.92); }
.tweaks-fab .dot { width: 7px; height: 7px; border-radius: 50%; background: #9D00FF; }
"""
html = must_sub('<link rel="stylesheet" href="styles.css" />',
                '<style>\n' + css + extra + '</style>', html)

# 3. Inline each JSX file
logo = 'data:image/png;base64,' + base64.b64encode((P/'assets/wasilha-logo.png').read_bytes()).decode()
def inline(m):
    name = m.group(1)
    src = (P/name).read_text()
    if name == 'components.jsx':
        src = must_sub('return <svg {...props} style={{ stroke: "rgb(0, 0, 0)" }}>{paths[name]}</svg>;',
                       'return <svg {...props}>{paths[name]}</svg>;', src)
    if name == 'screens-pre.jsx':
        src = src.replace('"assets/wasilha-logo.png"', '{WASILHA_LOGO}')
        src = 'const WASILHA_LOGO = "' + logo + '";\n' + src
    assert '</script' not in src
    return f'<script type="text/babel" data-src="{name}">\n// ---- {name} ----\n{src}\n</script>'
html, n = re.subn(r'<script type="text/babel" src="([^"]+)"></script>', inline, html)
assert n == 13, n

# 4. App fixes: TweakSection takes `label`; TweaksPanel owns its open state, so render it
#    unconditionally and add a standalone FAB that activates it in the same window.
html = html.replace('<TweakSection title=', '<TweakSection label=')
html = must_sub('{tweaksOpen && (\n            <TweaksPanel title="Tweaks" onClose={closeTweaks}>',
                '{(\n            <TweaksPanel title="Tweaks">', html)
html = must_sub("""    const root = ReactDOM.createRoot(document.getElementById('app'));
    root.render(<App />);""",
"""    // Standalone toggle: outside the design host there is no toolbar, so this
    // posts the same activation message the host would send.
    function TweaksFAB() {
      return (
        <button className="tweaks-fab" onClick={() => window.postMessage({ type: '__activate_edit_mode' }, '*')}>
          <span className="dot" /> Tweaks
        </button>
      );
    }

    const root = ReactDOM.createRoot(document.getElementById('app'));
    root.render(<><App /><TweaksFAB /></>);""", html)
html = html.replace('Use the Tweaks panel (toolbar)', 'Use the Tweaks button (bottom-right)')

(P.parent/'Wasilha.html').write_text(html)
print('ok', len(html))

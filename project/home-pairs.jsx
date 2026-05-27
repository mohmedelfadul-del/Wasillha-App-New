// Wasilha — Home connected-pair puzzle (Card System v2 applied to Home)
// 4 pairs, 8 services, staggered widths so they read as one ecosystem.

// Use globals exported by split-cards.jsx / connected-pairs.jsx
const HP_W = (typeof WASILHA !== 'undefined') ? WASILHA : {
  purple: '#9D00FF', lavender: '#DBD4FF', ivory: '#FFFFE3',
  deepPurple: '#723480', ink: '#0A0908', paper: '#FFFFFF',
};

function HP_PairBlock({ children, offset = 0, overlap = 0 }) {
  return (
    <div style={{
      marginTop: overlap ? -overlap : 0,
      marginLeft: offset > 0 ? offset : 0,
      marginRight: offset < 0 ? -offset : 0,
    }}>
      {children}
    </div>
  );
}

function RakshaMotorPair({ lang, onTap }) {
  const a = {
    bg: `linear-gradient(150deg, ${HP_W.deepPurple} 0%, #4F1F5C 100%)`,
    ink: '#FFFFE3', glow: HP_W.purple, label: 'Raksha',
    content: <SideLeft
      label={lang === 'ar' ? 'ركشة · الأسرع' : 'S-01 · RAKSHA'}
      name="Raksha" ar={lang === 'ar' ? 'راكشة' : null}
      sub={lang === 'ar' ? 'الأرخص · الأسرع في الزحمة' : 'Cheapest · cuts traffic'}
      price="1,850" eta={lang === 'ar' ? '٢ دقيقة' : '2 MIN'}
      icon="raksha"
    />,
  };
  const b = {
    bg: HP_W.ivory, ink: HP_W.deepPurple, glow: HP_W.purple, label: 'Motorcycle',
    content: <SideRight
      label={lang === 'ar' ? 'موتر · راكب واحد' : 'S-02 · MOTOR'}
      name="Motor" ar={lang === 'ar' ? 'موتر' : null}
      sub={lang === 'ar' ? 'يتسلل من الزحام' : 'Beats every queue'}
      price="2,400" eta={lang === 'ar' ? '١ دقيقة' : '1 MIN'}
      icon="bike"
    />,
  };
  return <ConnectedPair geom="diagonal" height={184} a={a} b={b}
    onTapA={() => onTap?.('raksha')} onTapB={() => onTap?.('bike')} />;
}

function DeliveryRidesPair({ lang, onTap }) {
  const a = {
    bg: HP_W.lavender, ink: HP_W.deepPurple, glassy: true, glow: HP_W.purple, label: 'Delivery',
    content: <SideTop
      label={lang === 'ar' ? 'توصيل طلبات' : 'S-03 · COURIER'}
      name="Delivery" ar={lang === 'ar' ? 'توصيل' : null}
      sub={lang === 'ar' ? 'حتى ٥ كجم · أي مكان' : 'Up to 5 kg · anywhere'}
      icon="bag"
    />,
  };
  const b = {
    bg: `linear-gradient(160deg, ${HP_W.purple} 0%, ${HP_W.deepPurple} 100%)`,
    ink: '#FFFFE3', glow: HP_W.purple, label: 'Rides',
    content: <SideBottom
      label={lang === 'ar' ? 'مشاوير · سيارة' : 'S-04 · RIDES'}
      name="Ride" ar={lang === 'ar' ? 'مشوار' : null}
      eta={lang === 'ar' ? 'الآن · ٣ دقيقة' : 'NOW · 3 MIN'} price="4,200"
      icon="car"
    />,
  };
  return <ConnectedPair geom="trapezoid" height={170} a={a} b={b}
    onTapA={() => onTap?.('delivery')} onTapB={() => onTap?.('car')} />;
}

function CarShippingPair({ lang, onTap }) {
  const a = {
    bg: HP_W.ivory, ink: HP_W.deepPurple, glow: HP_W.purple, label: 'Car',
    content: <SideTop
      label={lang === 'ar' ? 'سيارة · ٤ ركاب' : 'S-05 · CAR'}
      name="Car" ar={lang === 'ar' ? 'سيارة' : null}
      sub={lang === 'ar' ? 'مكيّفة · فسيحة' : 'A/C · spacious'}
      price="4,200" icon="car"
    />,
  };
  const b = {
    bg: `linear-gradient(140deg, #B86E4B 0%, #5A2E1E 100%)`,
    ink: '#FFFFE3', glow: '#E4A93A', label: 'Food',
    content: <SideBottom
      label={lang === 'ar' ? 'طعام · مطاعم' : 'S-06 · FOOD'}
      name="Food" ar={lang === 'ar' ? 'طعام' : null}
      eta={lang === 'ar' ? '٢٢–٤٠ دقيقة' : '22–40 MIN'} price="950+"
      icon="bowl"
    />,
  };
  return <ConnectedPair geom="chevron" height={186} a={a} b={b}
    onTapA={() => onTap?.('car')} onTapB={() => onTap?.('food')} />;
}

function StoreTrackingPair({ lang, onTap }) {
  const a = {
    bg: `linear-gradient(135deg, ${HP_W.lavender} 0%, #BFB1F0 100%)`,
    ink: HP_W.deepPurple, glassy: true, glow: HP_W.purple, label: 'Store',
    content: <SideLeft
      label={lang === 'ar' ? 'متجر وصلها' : 'S-07 · STORE'}
      name="Store" ar={lang === 'ar' ? 'متجر' : null}
      sub={lang === 'ar' ? 'بقالة · أدوية · فطور' : 'Groceries · pharmacy'}
      icon="bowl"
    />,
  };
  const b = {
    bg: `linear-gradient(160deg, ${HP_W.deepPurple} 0%, #3A1A45 100%)`,
    ink: '#FFFFE3', glow: HP_W.purple, label: 'Tracking',
    content: <SideRight
      label={lang === 'ar' ? 'تتبع طلبك' : 'S-08 · TRACK'}
      name="Track" ar={lang === 'ar' ? 'تتبع' : null}
      sub={lang === 'ar' ? '٢ طلبات نشطة' : '2 active orders'}
      eta={lang === 'ar' ? '٨ دقيقة' : '8 MIN'} icon="pin"
    />,
  };
  return <ConnectedPair geom="hexZig" height={164} a={a} b={b}
    onTapA={() => onTap?.('store')} onTapB={() => onTap?.('tracking')} />;
}

// Puzzle wrapper — entry animation + stagger
function ConnectedPairsPuzzle({ lang, offset = 14, onTap }) {
  return (
    <div className="ws-puzzle">
      <HP_PairBlock>
        <RakshaMotorPair lang={lang} onTap={onTap} />
      </HP_PairBlock>
      <HP_PairBlock offset={offset} overlap={10}>
        <DeliveryRidesPair lang={lang} onTap={onTap} />
      </HP_PairBlock>
      <HP_PairBlock offset={-offset} overlap={10}>
        <CarShippingPair lang={lang} onTap={onTap} />
      </HP_PairBlock>
      <HP_PairBlock overlap={6}>
        <StoreTrackingPair lang={lang} onTap={onTap} />
      </HP_PairBlock>
    </div>
  );
}

Object.assign(window, {
  ConnectedPairsPuzzle,
  RakshaMotorPair, DeliveryRidesPair, CarShippingPair, StoreTrackingPair,
});

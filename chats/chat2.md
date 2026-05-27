# Wasla Card System Design

_Started 2026-05-26 09:30 UTC_

---

## User

صمم نظام بطاقات مبتكر وعصري لتطبيق “وصلها” مستوحى من فلسفة inDrive لكن بأسلوب أكثر جرأة وحداثة.
البطاقات ليست مربعات تقليدية، بل عبارة عن بطاقات مستطيلة كبيرة ذات زوايا ناعمة وانحناءات فاخرة، ويتم تقسيم كل بطاقة بخط قطري أو خط هندسي في المنتصف ليحوّلها بصريًا إلى مثلثين أو قسمين ديناميكيين، بحيث تبدو وكأنها بطاقتان متداخلتان داخل بطاقة واحدة.

كل بطاقة تحتوي على:

* قسم رئيسي كبير للخدمة الأساسية.
* قسم ثانوي أصغر مدمج داخل نفس الشكل لإظهار معلومات إضافية أو اختصار سريع.
* الخط الفاصل يكون مائلًا بزاوية أنيقة ليعطي إحساس بالحركة والانسيابية.
* عند الضغط على البطاقة تتحرك الأجزاء بشكل subtle animation وكأن المثلثات تنزلق أو تتمدد.
* استخدم Glassmorphism خفيف مع شفافية ناعمة وظلال عصرية.
* الخلفية بيضاء ناصعة مع استخدام ألوان وصلها الحديثة:

  * Purple #9D00FF
  * Lavender #DBD4FF
  * Ivory #FFFFE3
  * Deep Purple #723480
* الأيقونات كبيرة وواضحة داخل أحد المثلثات.
* النصوص توضع في الجزء المقابل بتوازن بصري احترافي.
* بعض البطاقات يمكن أن تحتوي على صورة vehicle أو illustration تخرج جزئيًا خارج حدود البطاقة لإضافة عمق.
* استخدم نظام stacking بحيث تتداخل البطاقات قليلًا فوق بعضها عند التمرير.
* البطاقات تتحرك داخل Bottom Sheet أو ستارة سفلية قابلة للسحب للأعلى مثل Uber وinDrive.
* الحركة يجب أن تكون ناعمة جدًا مع micro-interactions احترافية.
* التصميم يجب أن يبدو Premium، Minimal، Futuristic، ومناسب لتطبيق توصيل ومشاوير سوداني حديث.

أمثلة على تقسيم البطاقات:

* بطاقة الركشة:
  مثلث للصورة والأيقونة + مثلث للمعلومات والسعر.
* بطاقة الموتر:
  قسم علوي للمشوار + قسم سفلي للحالة أو ETA.
* بطاقة السيارة:
  تقسيم قطري يعرض السائق في جهة والخريطة المصغرة في الجهة الأخرى.
* بطاقة الطلبات:
  قسم للمتجر + قسم للسعر والزمن.

اجعل كل بطاقة مختلفة قليلًا في شكل التقسيم الهندسي حتى يشعر المستخدم بالتجدد البصري وعدم التكرار، مع الحفاظ على نفس الـ Design Language في كامل التطبيق.

## Assistant

_[tool: list_files]_

_[tool: read_file]_

_[tool: read_file]_

_[tool: read_file]_

_[tool: grep]_

_[tool: grep]_

I'll note the system reminder — Wasilha is the user's own brand, and they explicitly want an *original* bolder system that's only inspired by inDrive's philosophy, not a recreation. Designing original geometry only.

Let me peek at the iOS frame API quickly and then build.

_[tool: write_file]_

Plan is clear. I'm going to design an **original** diagonal-split card system for Wasilha — your own brand, original geometry. I'll build:

1. **`split-cards.jsx`** — six diagonal-split card components, each with unique geometry (raksha trapezoid split, car vertical-diagonal, motorcycle angled-band, delivery inverse-diagonal, food chevron, schedule L-cut)
2. **`Cards System.html`** — showcase inside the iOS frame, hosting a draggable bottom sheet that stacks the cards with slight overlap and soft micro-interactions

Design language locked in:
- Type: existing Geist + Instrument Serif + IBM Plex Arabic
- Colors: only your four — Purple `#9D00FF`, Lavender `#DBD4FF`, Ivory `#FFFFE3`, Deep Purple `#723480` — on white
- Glass: light backdrop-blur on the soft halves, crisp ink on the dark halves
- Each card uses `clip-path` polygons with a thin white separator line; on press, the two halves slide apart ~3px and a glow blooms underneath

Let me build it.

_[tool: write_file]_

_[tool: done]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: multi_screenshot]_

Looks good! Let me check the expanded state to see all cards.

_[tool: save_screenshot]_

The screenshot is just cropping the device — only top half visible. Let me check at full device height by scrolling the page.

_[tool: view_image]_

_[tool: str_replace_edit]_

The cards look beautiful. One issue: the title "to go?" is being clipped by the Raksha card. Let me fix the spacing and title.

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: grep]_

_[tool: show_html]_

_[tool: done]_

_[tool: fork_verifier_agent]_

Built a new **`Cards System.html`** with six original diagonal-split cards, each with unique geometry:

- **Raksha** — `/` diagonal, deep-purple wedge + ivory triangle
- **Car** — vertical-leaning `\` cut, lavender driver-side + purple map-side  
- **Motorcycle** — angled horizontal band cut at ~12°
- **Delivery** — `\` cut with a package illustration breaking out the top-right corner
- **Food** — chevron parallelogram band carved through lavender
- **Schedule** — L-notch cut from the top-right corner

Each card uses `clip-path` polygons + a hairline white separator. Press a card and the two halves slide apart ~3px with a glow bloom underneath.

The cards live in a **draggable bottom sheet** (drag the handle to peek/open) with **negative-margin stacking** (overlap is tweakable). Backdrop is white-to-lavender with a faint map underneath. RTL Arabic switch in Tweaks.

Open the Tweaks panel to flip language, change stack overlap, or toggle sheet state.

## User

صمم نظام بطاقات مترابطة ومتصلة ببعضها داخل تطبيق “وصلها” بأسلوب مبتكر مستوحى من inDrive لكن بفكرة هندسية أكثر ذكاءً وحداثة.
الفكرة الأساسية أن البطاقة الواحدة عند تقسيمها لا تصبح مجرد قسمين بصريين، بل تتحول إلى بطاقتين فعليتين متصلتين ببعضهما وكأنهما قطعة واحدة تخدم خدمتين مختلفتين داخل نفس العنصر.

التصميم يكون كالتالي:

* بطاقة مستطيلة كبيرة ذات زوايا دائرية ناعمة.
* يتم تقسيم البطاقة بخط قطري أو هندسي في المنتصف.
* كل جزء بعد التقسيم يصبح بطاقة مستقلة لكن متصلة مباشرة بالبطاقة الأخرى بدون فراغ.
* الاتصال يكون عبر ضلع مشترك أو تداخل هندسي ذكي يجعل البطاقتين تبدوان وكأنهما قطعة واحدة متدفقة.
* كل بطاقة تمثل خدمة مختلفة:

  * الركشة + الموتر
  * توصيل طلبات + مشاوير
  * سيارة + شحن
  * متجر + تتبع
* عند الضغط على أي جزء يتم تفعيله وحده مع Animation منفصل.

شكل البطاقات:

* بعض البطاقات تكون على شكل:

  * مثلث + مستطيل
  * شبه منحرف + مربع
  * بطاقتين متداخلتين diagonal split
  * Hexagon split style
* البطاقات يجب أن تبدو وكأنها “شبكة خدمات متصلة” وليس عناصر منفصلة تقليدية.
* استخدم خطوط تقسيم ديناميكية تعطي إحساس بالحركة والسرعة.
* يمكن أن تمتد إحدى البطاقات قليلًا فوق الأخرى لخلق Depth احترافي.

التفاعل:

* عند الـ Hover أو الضغط:

  * الجزء المحدد يتمدد قليلًا.
  * الجزء الآخر يتقلص بشكل ناعم.
  * يظهر Glow خفيف بلون الخدمة.
* الانتقالات تعتمد على Fluid Motion وMicro-interactions.

الألوان:

* White background premium.
* Purple #9D00FF للخدمات الأساسية.
* Lavender #DBD4FF للخلفيات الناعمة.
* Deep Purple #723480 للعناصر المهمة.
* Ivory #FFFFE3 لإضاءة بعض البطاقات.
* استخدم Glassmorphism خفيف جدًا مع ظلال ناعمة.

الترتيب:

* البطاقات توضع داخل Bottom Sheet سحب للأعلى.
* ترتيبها يكون مثل Puzzle متصل.
* لا تجعل كل البطاقات بنفس الحجم حتى يبدو التصميم حيًّا.
* استخدم نظام staggered connected cards مثل واجهات المستقبل.

الإحساس النهائي:
Modern, futuristic, premium, dynamic, geometric, connected ecosystem.
التطبيق يجب أن يبدو وكأنه منصة ذكية مترابطة وليس مجرد قائمة خدمات تقليدية.

## Assistant

_[tool: write_file]_

Got it — this is a real evolution: not visually split, but two *actual connected cards* sharing a geometric edge that **morphs** when you press a side. The active half expands, the other contracts. Plus a puzzle-piece layout.

I'll keep v1 intact and build **`Cards System v2.html`** with a new `connected-pairs.jsx`. Four pair geometries with morphing `clip-path` transitions: diagonal, trapezoid, chevron-cut, and hex zigzag.

_[tool: write_file]_

_[tool: done]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: show_html]_

Sheet renders but the cards area is empty. Let me check what's happening.

_[tool: get_webview_logs]_

_[tool: eval_js]_

_[tool: grep]_

_[tool: read_file]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: grep]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: show_html]_

_[tool: str_replace_edit]_

Let me debug by adding a forced default and exposing state:

_[tool: save_screenshot]_

_[tool: show_html]_

_[tool: sleep]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: get_webview_logs]_

_[tool: sleep]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: show_html]_

_[tool: str_replace_edit]_

_[tool: sleep]_

_[tool: show_html]_

_[tool: save_screenshot]_

_[tool: show_html]_

_[tool: save_screenshot]_

_[tool: done]_

_[tool: save_screenshot]_

_[tool: show_html]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: screenshot_user_view]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: eval_js]_

## Assistant

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: save_screenshot]_

## User

شعار التطبيق

## Assistant

_[tool: copy_files]_

Thanks for the logo. I notice the brand actually uses **navy blue + teal + coral** — different from the purple/lavender palette you specified earlier for the cards. Let me save it and ask which direction you want.

_[tool: questions_v2]_

## User

ممتاز

## Assistant

_[tool: show_html]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: str_replace_edit]_

Cards still invisible. Let me fix by swapping buttons for divs — there's a Chrome quirk with `clip-path` + `<button>` + `appearance: none`.

_[tool: show_html]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: screenshot_user_view]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: str_replace_edit]_

The animation hasn't run yet — screenshot fires before it completes. Let me remove the entry animation since it's blocking us, or make it shorter:

_[tool: show_html]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: eval_js]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: str_replace_edit]_

Cards render beautifully — the entry animation was stuck in a pending state. Let me fix by removing the animation block and ensuring base styles are opacity:1 from the start:

_[tool: str_replace_edit]_

_[tool: show_html]_

_[tool: save_screenshot]_

_[tool: show_html]_

_[tool: save_screenshot]_

_[tool: show_html]_

_[tool: sleep]_

_[tool: save_screenshot]_

_[tool: done]_

_[tool: save_screenshot]_

_[tool: view_image]_

_[tool: fork_verifier_agent]_

Cards now render. The bug was a CSS animation that got stuck in a "pending" state inside the screenshot iframe — opacity stayed at 0 forever. Removed the opacity from the keyframe; just transform+scale on entry now, opacity always 1.

You can see the first connected pair (Raksha + Motor) clearly: diagonal split, Raksha in deep purple on the left, Motor in ivory on the right, joined at a shared diagonal edge. Hover/tap either side and the shared edge morphs — active half expands, the other shrinks.

On the logo + palette question — you said "ممتاز" without picking, so I'm holding off on a sweeping palette swap. The logo is saved at `assets/wasilha-logo.png` ready to drop in. When you want, tell me whether to:
- Switch the whole app to the logo's navy/teal/coral
- Keep purple primary, use navy as a deep supporting tone
- Just stamp the logo on the splash and leave the restEnding my turn — let me know which palette direction you want next.

## User

Questions timed out; go with defaults

## User

Save this design as a PDF: Wasilha.html


# Homepage Redesign — Review Notes

Branch: `redesign/homepage-product-split`
Spec: `privify-homepage-redesign-spec.md`
Date: 11 August 2026

Read this before merging. It records every copy change, every claim I verified against
source, and the decisions where I departed from the spec.

---

## 1. Claims verified against source

Every number and technical claim on the new homepage was checked against `../AgentDiscovery`
rather than carried over on trust.

| Claim | Source | Result |
|---|---|---|
| 12 DLP patterns | `core_engine/scanners.py` → `DLP_PATTERNS` | ✅ exactly 12 |
| 10 threat signatures | `core_engine/scanners.py` → `THREAT_SIGNATURES` | ✅ exactly 10 |
| 11 SIEM platforms | `core_engine/compliance.py` CC7.3 | ✅ consistent |
| Compliance frameworks | `core_engine/compliance.py` → `FRAMEWORKS` | ⚠️ **13, not 11** |
| Four discovery probes | `probes/` (endpoint, network, file, behaviour) | ✅ |
| Local LLM detection | `probes/endpoint_probe/probe.py` — Ollama :11434, LM Studio :1234, llama.cpp :8080 | ✅ |
| Inline kernel blocking | `probes/windows/kernel/ForgeProbe` — WFP callout, ALE_AUTH_CONNECT | ✅ Windows only |
| Browser AI interception | `browser-extension/content/interceptor.js` | ✅ |

### Framework count corrected: 11 → 13

The site said 11, the engineering doc said 12, the code defines 13. You were underselling.
The two missing from the site are **PDPA (SG/TH)** and **ISO 42001**.

Full list: SOC 2, HIPAA, PCI DSS, GDPR, CCPA/CPRA, DPDP Act (India), PDPA (SG/TH),
PIPEDA (Canada), EU AI Act, DSA, CA SB 53/AB 853, NIST AI RMF, ISO 42001.

**Action:** `platform/index.html` still says 11 in several places. Worth aligning in a
follow-up — I left it alone to keep this diff reviewable.

---

## 2. The Runlayer / "network layer" claim — spec §6

The spec asked me to verify the founder's "FORGE governs at the network layer, Runlayer at
the MCP protocol layer" claim before publishing it. **I did not publish it.**

**What's true:** FORGE enforces inline in the OS network stack via a WFP callout driver, and
intercepts HTTPS to AI APIs via the Go MITM proxy in `ai-activity-monitor/`. Coverage is
genuinely protocol-agnostic — it does not depend on an agent choosing to speak MCP.

**Why "network layer" is the wrong phrase:** in enterprise security that wording means an
inline appliance or tap. `docs/engineering/forge-context.md:738` lists
"Network appliance (transparent HTTPS + TLS interception + DLP)" as a **new component**,
i.e. not built. A buyer hearing "network layer" will expect a gateway and won't find one in
the POC. FORGE is **endpoint/kernel-level**, which is a different and defensible claim.

**What I published instead** — "A gateway only sees what routes through it", built on four
verifiable points:

1. Local models are invisible to gateways (endpoint probe catches Ollama etc.)
2. Direct REST API calls bypass the protocol layer entirely
3. Enforcement happens in the OS network stack at TCP connect
4. Browser AI is covered by the extension

Point 1 is the strongest: it's a *categorical* gap in the gateway architecture, not a feature
gap, so it survives competitive scrutiny in a way a feature checklist doesn't.

**Runlayer is not named.** I wrote it at category level ("MCP gateways"), which covers them
without the legal and tonal risk of naming a competitor on your homepage. Say the word if you
want it named.

**Honesty disclosure included.** The FORGE section carries an explicit note that inline
blocking is Windows-only today, with macOS/Linux monitored and enforcement parity on the
roadmap. Security buyers find this out in the POC regardless; saying it first buys credibility.
Related: the WFP driver still needs EV code signing (WKD-010) — not mentioned on the site,
but it will come up in procurement.

### Revision: the section was rebuilt after review

The first version was flat — four uniform cards bolted inside the "How FORGE actually works"
section with no boundary between them, immediately after three uniform cards. It read as more
of the same and got skimmed. Three fixes:

1. **It became a real `<section>`** on its own ground (`--surface`), so a visual break exists.
2. **It moved ahead of "How FORGE actually works."** A reader already comparing us to a gateway
   needs the wedge before the mechanism — the wedge is what earns them the mechanism.
3. **It got a diagram.** The argument is about *coverage* — what falls inside a gateway's view
   versus outside it — which is a spatial claim that was being made in prose. The new coverage
   map shows a small dashed "what an MCP gateway sees" box inside a coral boundary labelled
   "your environment — where FORGE runs", with the three blind spots visibly outside it.

Built from CSS boxes rather than SVG so labels stay selectable and it reflows to one column on
narrow screens. **No copy was lost** — all four differentiator cards keep their full text
beneath the diagram, which summarises rather than replaces them.

The three stage cards were also restyled into a connected sequence rail (01 → 02 → 03), since
Discover → Observe → Govern genuinely is a sequence. All twelve detail bullets preserved
verbatim. Page rhythm is now bordered containment → borderless sequence → dashed placeholders,
instead of one card component repeated.

New headline: **"The agents your gateway will never see"**, under the eyebrow
"Why not just use a gateway?" — the buyer's own internal objection, in their words.

---

## 3. SOC 2 badge — spec §5

You confirmed **no auditor is engaged**, so "Audit In Progress" was not available.

**Published wording:** "Security Practices Aligned with SOC 2", with the sub-line
"Controls mapped to Trust Services Criteria · Independent audit not yet completed".

The footer additionally states plainly: *"Privify is not SOC 2 certified."* `security.html`
carries a status table spelling out exactly what does and doesn't exist.

> ⚠️ **This still needs your confirmation.** "Aligned with" asserts you actually operate
> against the Trust Services Criteria internally. If that's aspirational, the badge is a
> liability in a vendor questionnaire, not an asset. Tell me and I'll pull it.

### Color: monochrome + coral, not cyan

Spec §5 asked for cyan; spec §7 said don't invent brand colors. I resolved it against cyan
for two reasons — it appears nowhere else in the palette, and (more importantly) red/coral as
the *dominant* color on a compliance badge reads as "alert/fail" in security UI. The badge is
white/slate type on `--surface`, with coral used only as the shield outline stroke.

**Built as inline SVG, not Canva.** For an on-site badge, SVG scales on retina, inherits your
tokens and costs ~1KB against ~50KB for a PNG. Canva is worth using for a *shareable* version
(deck slide, LinkedIn) — say the word and I'll generate one.

---

## 4. Copy changes — before / after

### Hero

| | |
|---|---|
| **Before** | `Two products. One mission.` → "Put people and enterprises in control of AI" → single CTA "Our products" |
| **After** | `AI control infrastructure` → same headline → **no hero CTA**; the fork *is* the CTA |

The hero was `min-height:100vh`, which pushed the product split entirely below the fold. It's
now `padding:9rem 2rem 3.5rem` so the fork is the first thing resolved, per spec §1.

**Sub-headline**

- **Before:** "Privify builds tools for a world where AI is everywhere. For enterprises running hundreds of agents. For individuals whose data trains models without consent."
- **After:** "Two products, built for two very different problems. Enterprises can't see what their AI agents are doing. Individuals can't stop their data training models they never agreed to."

### Product cards → the fork

- **Before:** two cards below a full-viewport hero, both coral, SHIELD's label in grey. Header "Two products. Both in early access."
- **After:** cards directly under the headline behind a "Choose your path" label, each with a top gradient rule, its own accent, an audience line ("For enterprises" / "For individuals") and a status chip.

**New: SHIELD track color `--cyan: #22D3EE`.** Spec §1 requires distinct visual treatment per
track and none existed — both product pages ship an identical coral-only token set. Cyan-400
matches the site's Tailwind-derived greys, sits near-complementary to coral so the tracks are
instantly separable, and reads as protective rather than alarming.

### CTAs — spec §2

| Location | Before | After |
|---|---|---|
| Nav pill | Request Access → `platform#interest` | **Contact Sales** → `contact.html` |
| Hero | "Our products" → `#products` | *(removed — fork carries it)* |
| FORGE card | "Explore FORGE" | **Request a demo** + Explore FORGE |
| SHIELD card | "Join the SHIELD waitlist" | **Join the waitlist** + Explore SHIELD |
| Pricing | *(did not exist)* | **Contact us for pricing** |
| Final | *(did not exist)* | **Request a demo** + interactive demo |

The spec guessed SHIELD's CTA might be "Get Started"/"Sign Up". It isn't — SHIELD is
pre-launch and every CTA on `privacy/index.html` is already "Join Waitlist". Kept as waitlist.

All CTAs fire named Plausible events (`CTA_ForgeDemo`, `CTA_ShieldWaitlist`,
`CTA_ContactPricing`, `CTA_FinalDemo`, `ContactFormSubmit`) so you can see which path converts.

### New sections

- **How FORGE actually works** — three stages with concrete mechanics, addressing spec §4's "not just vision language"
- **A gateway only sees what routes through it** — verified competitive positioning
- **Social proof** — dashed placeholder slots, 5 logos + 2 quote/case-study slots
- **Pricing** — no numbers, contact-us model per spec §3
- **SHIELD track** — kept mission/emotion-driven per spec §4
- **Final CTA**

### Moved

**Mission section** now sits below the fork and both product tracks, per spec §1. Copy
unchanged except the framework stat, 11 → 13.

### Untouched claims

`66 API endpoints`, `116 AI providers`, `24 production-ready features` are carried over from
the previous homepage. I did **not** verify these — out of scope for this pass, flagging so
they don't get mistaken for checked.

---

## 4a. Text contrast — the grey ramp

Vishal pointed at the body copy on `platform/index.html` ("Every AI agent in your enterprise
shaped, governed…") and asked for that colour on smaller text. That colour is `--gray-400`
`#9CA3AF`, which the homepage already used for `.section-sub` — so the real problem was
everything *below* it. Measured against `--surface` `#0d0d0d`:

| Token | Hex | Contrast | WCAG AA (4.5:1) |
|---|---|---|---|
| `--gray-400` | `#9CA3AF` | 7.66:1 | pass |
| `--gray-500` | `#6B7280` | 4.02:1 | large text only |
| `--gray-600` | `#4B5563` | **2.57:1** | **fail** |
| `--gray-700` | `#374151` | **1.89:1** | **fail** |

The *smallest* type was on the *lowest* contrast — mono detail bullets, coverage-map chip
subs, the SOC 2 sub-line, pricing factors. 24 declarations sat below the accessibility floor.

**Fix:** a three-step ramp where every step carrying reading text clears AA.

- `#FFFFFF` — headings (19.4:1)
- `#9CA3AF` — body and secondary copy (7.66:1) ← the colour requested
- `#858C97` — new `--text-3`, small detail and mono lists (5.73:1)
- `#6B7280` — de-emphasised labels only (4.02:1)

`--gray-600` and `--gray-700` remain in the file but now style **borders and placeholder
outlines only, never text**.

**Hue was left alone deliberately.** The greys are cool (~218°) against a warm coral accent.
That is a working pairing — the cool text is what makes the coral read as an accent. The
defect was luminance, not hue, so warming the neutrals would have been a change for its own
sake. Applied to all five pages in this branch, not just the homepage.

---

## 5. Pricing — spec §3

FORGE only, no numeric prices. Three factors named (environment size, deployment model,
enforcement scope), four inclusions, one CTA.

**SHIELD deliberately has no pricing section.** The spec floated Free/Pro tiers; publishing
tiers for an unlaunched product invents a model that doesn't exist. Revisit at launch.

---

## 6. The four broken stub pages

`contact.html`, `privacy.html`, `security.html` and `terms.html` were **byte-identical**
(md5 `9cf0355a…`), every one rendering "Privacy Policy — Coming soon" with no nav, no styling
and the wrong title. All four were linked from the live footer.

- **`contact.html`** — real contact page. Reuses the existing Formspree endpoint
  (`maqalveb`, already wired to your and Bhaskar's inboxes), so no new infrastructure.
  Reads `?intent=` from the CTA that referred the visitor and preselects the enquiry type.
- **`security.html`** — real content: compliance status table, FORGE architecture, kernel
  component note, vulnerability disclosure.
- **`privacy.html`** — written from observed behaviour, not boilerplate. Site sets no cookies,
  no localStorage, no ad trackers; Plausible is cookieless. Discloses Plausible, Formspree and
  the CDN/font hosts.
- **`terms.html`** — website terms of use, explicitly scoped *away* from product terms.

> ⚠️ **`privacy.html` and `terms.html` need your counsel's review before you rely on them.**
> They are accurate descriptions of observed behaviour and reasonable standard terms, but I am
> not a lawyer and these are legal instruments. They are a large improvement on four pages that
> all claimed to be a privacy policy and said "coming soon" — but that's the bar they clear.

New addresses referenced: `security@privify.io`, `privacy@privify.io`, `legal@privify.io`.
**These need to exist or route somewhere.**

---

## 7. Bug found in Photo Scrubber

While verifying a homepage claim, I found the tool is not purely client-side:

1. **`analyzeWithCloudAI` (`tools/photoScrubber/app.js:1086`) is dead code.** It base64-encodes
   the full image and POSTs it to `/api/analyze-image`, falling back to `localhost:3000`.
   Nothing calls it, so no images are uploaded today — but it's a loaded gun in a privacy tool.
   **Recommend deleting it.**

2. **Reverse geocoding is live and automatic** (`app.js:823`). When a photo carries GPS EXIF,
   the coordinates are sent to `nominatim.openstreetmap.org` (falling back to
   `photon.komoot.io`) with **no opt-in**. Only lat/lon leave, never the image — but for a
   privacy tool this deserves either an opt-in toggle or in-tool disclosure.

This falsified draft homepage copy I'd written ("nothing is uploaded anywhere"). Corrected to
"your photos are never uploaded to us", and `privacy.html` discloses the geocoding behaviour
in full.

---

## 8. Verification performed

- ✅ All internal links and anchors across the five pages resolve (scripted check)
- ✅ Full desktop render reviewed at 1440px — every section
- ✅ SOC 2 badge, trust strip, fork, pricing card, footer confirmed visually
- ✅ Fixed a bug found during review: global `a` rule was underlining the PRIVIFY logo
- ❌ **Mobile not visually verified** — the browser tool wouldn't render below desktop width.
  Breakpoints follow the existing site's 768/480 structure plus a 900px tier, and all new grids
  collapse to single column, but **please check on a real phone before merging.**

---

## 9. Open decisions

1. **Is "aligned with SOC 2" actually true?** Gates the badge.
2. **Do `security@`, `privacy@`, `legal@privify.io` exist?**
3. **Name Runlayer explicitly?** Currently category-level only.
4. **Align `platform/index.html` to 13 frameworks?**
5. **Delete the dead cloud-upload path in Photo Scrubber?**
6. **Counsel review of `privacy.html` / `terms.html`.**
7. **Canva version of the badge** for decks and social?

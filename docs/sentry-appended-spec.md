# Sentry — Appended Spec

**Companion to `docs/sentry-spec.md`. Read that first if you haven't.**

Seven changes to the shipped Phase 1 build. Nothing here supersedes the original spec's hard boundaries (Part 3.4) or its privacy posture (Part 8) — those still hold, and two of the items below tighten them further.

---

## Part 0 — How to hand this to Claude Code

Same discipline as last time. Do **not** paste this whole file and say "do it."

1. Put this file at `docs/sentry-appended-spec.md`, on a branch off the current main.
2. Open with: *"Read `docs/sentry-appended-spec.md` in full. Then do Item 1 only — start with the diagnosis step and report back before changing anything."*
3. Review, confirm, then release the next item.

Items 1 and 5 are **diagnosis first, fix second**. Do not let them be collapsed into one step — in both cases the cause determines whether there is any code to change at all.

Item 3 is the largest by a distance. It is a new endpoint plus a new UI, and it handles prospect transcripts. It gets its own review pass.

**Suggested order:** 1 → 2 → 7 → 5 → 3 → 6 → 4.

Items 2 and 7 are both system-prompt edits and could be done together, but do them separately anyway — prompt changes are easy to over-write, and you want to be able to see which edit caused which change in behaviour.

**Before every prompt edit, ask for the diff, not just a summary of it.**

---

## Item 1 — Bookings is publishing 14 days, Sentry is showing one day / four slots

### 1.1 Diagnose before touching anything

The original spec (Part 6.5) called for **embedding the Bookings page in an iframe**. If that's what was built, there is no slot-fetching code and the truncation is a Bookings-side configuration problem — no amount of code editing will fix it.

Ask Claude Code, before it changes anything:

> How is the booking slot picker implemented — an iframe of the Microsoft Bookings page, or a custom UI backed by an API call?
>
> If it's a custom UI: show me the exact request, including the date range parameters, any page size / `$top` / `$skip` limit, and whether the response is paginated with an `@odata.nextLink` we're ignoring.
>
> If it's an iframe: confirm that, and stop — the problem is on the Bookings service side, not in our code.

### 1.2 If it's a custom API call

Three causes, in order of likelihood:

| Cause | What it looks like | Fix |
|---|---|---|
| Hardcoded date window | Start and end both "today", or a 1-day span | Query `now` → `now + 14 days`, and make the horizon configurable as `BOOKING_HORIZON_DAYS` (default 14) |
| Unpaginated first page | Exactly the same small number of slots every time | Follow `@odata.nextLink` until exhausted, or raise `$top` |
| Timezone collapse | Slots appear/disappear depending on time of day | Request and render in the visitor's timezone; never assume UTC is display-ready |

"One day, four slots" with a 14-day publication is the classic signature of the first two happening together.

Whatever the cause, the fix must not hardcode 14. The horizon belongs in config alongside the other settings in Part 3.8.

### 1.3 If it's an iframe — check these Bookings settings

Nothing to change in the repo. Check in the Bookings admin, in this order:

- **Maximum lead time** — how far ahead a customer may book. If this is set to 1 day, the page is behaving correctly and showing you one day.
- **Staff availability** — slots only appear where an assigned staff member is free. Four slots on one day usually means one person's calendar, not a bug.
- **Minimum lead time** — if set high, today and tomorrow vanish.
- **Service duration vs buffer time** — long buffers thin out the grid fast.
- Whether the **service** (not just the booking page) has its own availability override.

### 1.4 Either way

Add a fallback: if fewer than three slots are available across the whole horizon, Sentry should not present a thin, sad calendar. It should say the calendar is looking full and offer the email route instead (see Item 7). A near-empty picker reads as "nobody wants to talk to you" and costs you the lead.

### 1.5 As built

**Diagnosis.** A custom API call, not an iframe — 1.3 does not apply. Both
predicted causes were present: a hardcoded 5-day window (`AVAILABILITY_WINDOW_DAYS`)
and a `slice(0, 4)` shortlist. Pagination was *not* a cause: `getStaffAvailability`
is a POST action returning no `@odata.nextLink`. The shortlist was the dominant
cause — even the 5-day window was already enumerating 71 open slots across 4
days before being cut to the first 4, which all fell on the first open day.

**Fix.** `BOOKING_HORIZON_DAYS` (default 14, clamped 1–30) replaces the
hardcoded window. The shortlist is now grouped by the visitor's *own* calendar
day, capped at 3 days × 6 slots, and sampled at bucket centres within each day
so the offer reads like a person's ("Tuesday at 10 or 2") rather than the
8am/7:30pm extremes an even spread picks, with the soonest slot always kept.
`check_availability` additionally returns `horizonDays` and `thinCalendar`.

**`thinCalendar` is told, not inferred.** The shortlist is capped, so a full
calendar and a nearly-empty one both return a handful of slots — only the
pre-shortlist `totalOpen` distinguishes them. The prompt presents whatever
slots exist *alongside* the email route rather than instead of them; the
turn-cap wrap-up, the one path where the model does not write the reply, has
its own empty-calendar copy.

**Two defects found while verifying, both pre-existing.** The conflict guard's
±1-day window was letting duplicates through (see the main spec's Section 6.5),
and text streamed before and after a tool call ran together in one bubble with
no break. Both fixed.

**Residual, not fixed.** The calendar is published in Pacific working hours, so
a visitor in London or Tokyo is legitimately offered late-evening or
early-morning local times. Those slots are real and the labels are correct;
filtering them would be a business-hours policy decision, not a bug fix.

---

## Item 2 — Scope and depth: stay high-level, deflect properly

### 2.1 The change

Add a **Scope and depth** section to `src/prompts/sentry.ts`. It sits under the existing hard boundaries and does not replace them.

Sentry answers at the level of:

- what the product does
- who it's for
- what problem it solves
- roughly how it fits into an existing environment

Sentry does **not** go into:

- architecture, internals, or model behaviour
- integration mechanics, APIs, schemas, or data flow specifics
- deployment topology, scaling, or performance characteristics
- anything requiring a number it cannot source from published material
- comparative technical claims about named competitors (already barred by Part 3.4 — restated here because depth questions are where that boundary gets tested)

### 2.2 How the deflection must sound

The deflection is doing sales work. It is not an apology and it is not a wall.

The reason is always **precision**, never secrecy:

> "I'd rather not approximate that one — it's the kind of detail our engineer will answer exactly, and it's worth ten minutes of their time. Want me to find a slot?"

**Banned phrasings.** These read as evasive and cost credibility with exactly the audience Privify is selling to:

- "I can't discuss that"
- "I'm not able to share that information"
- "That's proprietary"
- "You'd have to ask sales" *(passive — Sentry books the call itself)*

**A deflection must always carry an exit.** Never a dead end. See Item 7.

### 2.3 On persuasion technique — read this before writing the prompt

The instruction here is deliberately **not** "apply Cialdini's principles." Do not build scarcity, urgency, social proof, or reciprocity *tactics* into this prompt.

The reason is the audience. Security buyers recognise persuasion technique on sight — recognising manipulation is the job — and a bot that deploys it converts worse, not better, because it burns the credibility the deflection depends on. "Only two slots left this week" from an AI agent on a governance vendor's site is a self-inflicted wound.

What does work with this audience is the honest form of the same underlying dynamics:

- **Genuine reciprocity** — Scout, free, ungated, offered before anything is asked for (Part 6.6 already sequences this correctly)
- **Earned authority** — being precisely right within scope, and visibly declining to guess outside it
- **Real consistency** — small true commitments in sequence: download Scout, run it, read the report together

Those are the versions that survive a sceptical reader. The deflection itself is the strongest conversion instrument in the whole system: *an AI that refuses to bullshit a CISO is selling the product.* Let it do that work.

### 2.4 Acceptance

Test with these, and check the response is high-level, non-evasive, and ends with a route forward:

1. "How does FORGE actually intercept agent traffic?"
2. "What's your p99 latency overhead?"
3. "Walk me through your data model."
4. "How is this different from Runlayer under the hood?"
5. "Does it work with LangChain?" *(scope-legal at a high level — should get a real answer, not a deflection)*

Number 5 is the control. If Sentry deflects that one too, the section is over-tuned and it will feel useless.

---

## Item 3 — Transcript logging and admin view

### 3.1 What exists and what doesn't

Transcripts are **already being stored** — Part 3.2 puts full session state in Table Storage server-side, with a 30-day TTL. The data is there.

What's missing is a way to read it. The Anthropic Console does not provide this: it reports usage and spend, not conversation content. Anthropic is not storing prospect transcripts for browsing. This is entirely ours to build.

### 3.2 Admin endpoints

| Route | Method | Purpose |
|---|---|---|
| `/api/admin/sessions` | GET | List sessions, filtered and paginated |
| `/api/admin/sessions/{id}` | GET | Full transcript for one session |

`/api/admin/sessions` query parameters: `from`, `to` (ISO dates), `status`, `hasLead` (bool), `page`, `pageSize`, `sort`.

Both endpoints are strictly **read-only**. No delete, no edit, no replay. Purging stays with the existing timer-triggered retention job.

### 3.3 Authentication — do this properly

**Entra ID via App Service Authentication ("Easy Auth"), restricted to the Privify tenant.** Not a shared secret, not a bearer token in a query string, not an unguessable URL.

This is a governance company holding prospect conversations that may contain details about the prospect's own AI estate. A CISO who discovers the vendor's sales transcripts sat behind a secret URL will not buy the product, and would be right not to. The auth on this endpoint is part of the sales pitch whether or not anyone ever looks at it.

Easy Auth is configuration, not code — it costs almost nothing to do correctly.

Additionally:

- CORS on `/api/admin/*` restricted to the admin origin only, separate from the widget's `privify.io` rule
- Every admin read logged to App Insights: who, what session, when. Metadata only.
- Rate limit the list endpoint. It's a bulk-export vector.

### 3.4 The view

A single static page — same stack as the widget, no framework needed. Two screens:

**Session list.** Table, newest first, with a date range filter driving the query:

| Column | Notes |
|---|---|
| Started | Local time |
| Duration | Last active − created |
| Turns | Message count |
| Status | `active` / `captured` / `booked` / `abandoned` |
| Lead | Name and company if captured, else em dash |
| Entry page | Which page the widget was opened from |
| Cost | See Item 6 |

Sortable on Started, Turns, and Cost. Filterable on status and on whether a lead was captured.

**Transcript view.** The conversation rendered as a conversation — user and assistant turns distinguished, timestamps, and a sidebar showing the accumulated `captured` lead object and which tools fired when. Seeing *why* `offer_booking` fired at turn 9 is most of the value of this screen.

### 3.5 Redaction

If the visitor pasted something credential-shaped, Sentry is already instructed to stop them (Part 3.4) — but it may already be in the transcript. Mask anything matching common key/token patterns at render time, with a click-to-reveal for a genuine investigation. Don't store the unmasked form in any new place.

---

## Item 4 — Attach transcripts to the Salesforce lead

### 4.1 Behaviour

On lead capture, the fan-out (Part 6.1) already writes to Salesforce. Extend it: attach the conversation transcript to the Lead record.

Attach as a **Note or File on the Lead**, not a long text field — the transcripts will exceed field limits and the salesperson wants to read it as a document.

Content: the full conversation, plus a short header block with entry page, session duration, turn count, captured fields, and total cost (Item 6).

### 4.2 Timing

Attach at **session end**, not at capture — the interesting part of the conversation usually happens after the email address is given. Session end means: `booked`, or 30 minutes idle, or the abandonment sweep marking it `abandoned`.

If a lead is captured and the session then continues, update the attachment rather than creating a second one.

### 4.3 Retention, and the split

Two independent clocks, deliberately:

| Store | Retention | Controlled by |
|---|---|---|
| Table Storage | 30 days, **configurable** via `TRANSCRIPT_RETENTION_DAYS` | Purge job in the Function |
| Salesforce | Normal CRM retention, decided separately | Salesforce admin |

Table Storage is the working store; Salesforce is the record of a real sales interaction attached to a real lead. They should not share a clock.

`TRANSCRIPT_RETENTION_DAYS` defaults to 30 and drives the existing timer-triggered purge. No hardcoded 30 anywhere in the codebase — including in the privacy copy, which should read the value or be updated deliberately alongside it.

### 4.4 Privacy consequence — do not skip this

Part 8 currently states transcripts are held 30 days. Attaching them to Salesforce makes that **incomplete**: transcripts now persist in the CRM beyond that window.

The privacy page and Sentry's own disclosure need updating to say so, in plain terms — something to the effect that if you share your contact details, the conversation is kept with your record in our CRM.

Get this wording right before shipping the item. Privify sells governance; a retention statement that doesn't match what the system actually does is the single most damaging small error available here. Have a human approve the final wording.

### 4.5 Stubbing

If Salesforce credentials still aren't in place, this stays behind the no-op interface from Part 6.4. Build it, test it against the interface, ship it dark.

---

## Item 5 — Azure cost audit (read-only)

### 5.1 Purpose

The original estimate (Part 9) was roughly $2–4/month at 100 conversations, dominated by Anthropic tokens, with Azure rounding to near-zero. That assumed a consumption-plan Function and nothing else expensive alongside it.

Verify the assumption held. Surprise Azure cost almost never comes from the Function — it comes from what got provisioned next to it.

### 5.2 The audit prompt

Give Claude Code this, verbatim:

> Audit the deployed Azure resources for the Sentry agent. **This is read-only — report findings, change nothing.**
>
> For every resource in the resource group, report the resource type, SKU/pricing tier, and whether it bills per-use or has a fixed monthly floor.
>
> Specifically confirm:
> 1. The Function App is on a **Consumption (Y1)** plan — not Premium (EP1/EP2/EP3), not an App Service plan (B1/S1/P1v3). What is the actual `sku` on the server farm?
> 2. No **Always On**, and no pre-warmed or minimum instance count configured.
> 3. The **Storage account** tier and replication — Standard LRS is expected. GRS/RA-GRS costs multiples for no benefit here.
> 4. Whether **Application Insights** was provisioned, and if so: its daily cap, sampling percentage, and retention in days. Report the defaults it was created with.
> 5. Whether a **Log Analytics workspace** was created, and its retention and daily cap.
> 6. Whether a **Key Vault** exists and which tier (Standard vs Premium/HSM).
> 7. Anything else in the resource group I haven't listed.
>
> Flag anything that is not pay-per-use, and anything with a fixed monthly cost regardless of traffic.

### 5.3 What to look for in the answer

- **Premium plan Function.** Would be roughly $150+/month for a workload that should cost cents. If Claude Code chose Premium to avoid cold starts, that trade is wrong at this traffic level — say so and move it.
- **Application Insights on defaults.** The most likely culprit by far. Ingestion is billed per GB and default sampling is generous. Set a daily cap and reduce retention to 30–90 days.
- **Log Analytics.** Same story, sometimes provisioned silently alongside App Insights.
- **GRS storage.** Easy accidental default, several times the cost of LRS.

### 5.4 After the audit

Set an **Azure budget alert** on the resource group, and confirm the **Anthropic spend alert** from Part 9 actually exists. Both are two-minute jobs that are only ever done retroactively at the wrong moment.

---

## Item 6 — Cost telemetry: per session and per period

### 6.1 Separate the API key first

If Sentry is running on the same Anthropic API key as Claude Code or anything else, its spend cannot be isolated in the Console.

Give Sentry **its own API key** — same account, separate key. Two benefits: the Console's usage view can then filter to Sentry alone with no code required, and a leaked widget key rotates independently of everything else.

If the account supports **workspaces**, put Sentry in its own workspace and set a spend limit on it. That's the real protection — a runaway loop hits a ceiling instead of a credit card.

*(Noted as done — this is here so the reasoning is on the record.)*

### 6.2 Capture usage per turn

Every Messages API response carries a `usage` block. Persist all four fields onto the session record on every turn:

```ts
usage: {
  inputTokens: number;
  outputTokens: number;
  cacheCreationInputTokens: number;   // billed at 1.25× input
  cacheReadInputTokens: number;       // billed at 0.1× input
}
```

Accumulate a running total on the session, and keep the per-turn detail — per-turn is what tells you *where* an expensive session went expensive.

### 6.3 Compute cost

Rates go in **config, not code**. Pricing has already changed once during this project.

```
ANTHROPIC_RATE_INPUT_PER_MTOK        = 2.00
ANTHROPIC_RATE_OUTPUT_PER_MTOK       = 10.00
ANTHROPIC_RATE_CACHE_WRITE_PER_MTOK  = 2.50
ANTHROPIC_RATE_CACHE_READ_PER_MTOK   = 0.20
```

Verify against https://platform.claude.com/docs/en/about-claude/pricing before shipping, and reconcile the dashboard's first-week total against the Console's figure for the same period. If they diverge by more than a few percent, the cache accounting is wrong.

### 6.4 Surface it in the dashboard

**Per session — a row-level number.** Each session in the list carries its own cost, independent of any filter. Sortable. This is the number that shows one prospect burned $0.40 while ninety others cost two cents each — and the outliers are either your best leads or someone probing the thing, both worth knowing about.

On the transcript view, show per-turn cost alongside the conversation.

**Per period — driven by the date filter.** The aggregate reflects exactly the range selected in the session list, not a fixed calendar month. Change the filter, the totals move with it.

Show for the selected period:

| Metric | Why |
|---|---|
| Conversations | Denominator for everything else |
| Total spend | The bill |
| Average cost per conversation | Drift here means the prompt is growing or caching broke |
| Leads captured | |
| **Cost per qualified lead** | The number that decides whether this is worth running |
| Cache hit rate | Directly drives the other numbers |

Cost per qualified lead is the headline. Against any other channel Privify uses, it should win by an order of magnitude, and being able to state it precisely is worth more than the saving itself.

Watch average cost per conversation over time. If it climbs, either the system prompt has grown or prompt caching has silently stopped working — the second is common and invisible without this metric.

---

## Item 7 — Never lose a lead

### 7.1 The principle

Every conversation must offer a way to reach Privify. Always visible, never a dead end — including when Sentry has just declined to answer something (Item 2), which is precisely the moment a lead is most likely to leave.

The distinction, stated plainly for the prompt: **entice, don't trap.**

### 7.2 Three exits, always available

1. **Book a slot** — the Bookings picker, the preferred path
2. **Leave contact details** — for someone who won't book but will be contacted
3. **Email Privify directly** — the address, plainly, for someone who wants nothing to do with a bot

The third one matters more than it looks. A CISO who doesn't want to talk to an AI should not have to fight the AI to find an email address. Giving it up freely is itself credible.

### 7.3 In the prompt

- Every deflection ends with a route forward. Never a bare "I can't help with that."
- If the visitor declines to book, ask once for an email so someone can follow up. **Once.** If they decline again, give them the direct address and stop.
- If the visitor asks for a human at any point, stop qualifying immediately and hand over the booking link and the email address. Already in Part 3.4 — reinforce it here.
- If the conversation is winding down without capture, offer the exits once, warmly, and let them go.

### 7.4 Explicitly banned

No dark patterns. Specifically:

- No exit-intent interception or "wait, before you go"
- No repeated asks after a decline
- No false scarcity on calendar slots
- No withholding an answer to force a booking
- No guilt framing ("are you sure you don't want help?")

Every one of these is recognisable to this audience, and each converts a warm lead into someone who tells a peer that Privify's site pesters you.

### 7.5 In the widget

- Booking and email actions available from the panel header at all times, not only when Sentry offers them
- The email address is real, selectable text — not an obfuscated mailto trick
- If the backend errors or the API is unreachable, the widget degrades to a static card with the booking link and email address. **A broken Sentry must still capture leads.** This is the single highest-value line in this item.

### 7.6 Acceptance

1. Ask a deep technical question → get a deflection **with an exit**
2. Decline the booking once → get an email ask
3. Decline again → get the direct address, and no third ask
4. Say "I just want to talk to a person" at turn 1 → immediate handover, no qualification
5. Kill the backend, load the page → static fallback card with booking link and email

---

## Acceptance for the whole addendum

- [ ] Bookings shows the full configured horizon, with slots across multiple days
- [ ] Thin-calendar fallback works when genuinely few slots exist
- [ ] Deep technical questions deflect gracefully; in-scope questions still answered properly
- [ ] No scarcity, urgency, or manufactured social proof anywhere in the prompt
- [ ] Admin view lists sessions, filters by date, opens transcripts
- [ ] Admin endpoints behind Entra ID, tenant-restricted; admin reads audited
- [ ] Transcripts attach to Salesforce Lead at session end
- [ ] `TRANSCRIPT_RETENTION_DAYS` drives the purge job; no hardcoded 30
- [ ] Privacy page and Sentry's disclosure updated for CRM retention, human-approved
- [ ] Azure audit complete; nothing billing on a fixed monthly floor; budget alert set
- [ ] Sentry on its own API key; Anthropic spend alert set
- [ ] Per-session cost visible and sortable; per-period totals follow the date filter
- [ ] Cost per qualified lead displayed
- [ ] Dashboard total reconciles with Console for the same period
- [ ] Three exits available at all times; static fallback works with the backend down

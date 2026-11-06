# 10 — AI Assistant ("Buddy")

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-010 to D-018, D-036, D-043 to D-046, D-062, D-063, D-066, D-072, D-077, D-079, D-080, D-100 (agent)._

Requirement format: **ID** `[release]` statement. Releases: R1 owner · R2 friends · R3 public · Later.

## 1. Role

Buddy is the main way to put data into the app. You write (or photograph) what happened, and Buddy turns it into a **proposal** that you confirm. Buddy also answers questions about your own data, suggests what to eat, and writes a weekly review. Since D-100 Buddy is an **agent**: it works in steps (look up, compute, check, act) and holds a conversation (§15).

- **AI-001** `[R1]` Buddy is reached from the input bar, which is always visible at the bottom of the Today screen (D-043) and the Workouts screen. Typing in the bar opens the chat sheet over the current screen, and the screen's numbers stay visible above it (see `30-ux-principles.md`).
- **AI-002** `[R1]` Buddy handles: food logging, diary corrections, weigh-ins, workouts, batch dishes, personal foods and memory ("remember that…"), questions about your data, food suggestions, and the weekly review.
- **AI-003** `[R1]` Buddy politely declines anything outside nutrition, body weight and training, and anything medical (see `21-safety-and-wellbeing.md`).

## 2. Inputs

- **AI-010** `[R1]` Typed text in English, Arabic (any dialect, Palestinian/Levantine first), Arabizi/Franco ("akalt 2 ta3meya w 3esh"), and any mix of these in one message (D-063).
- **AI-011** `[R1]` Photo + optional text ("this is about 300g"). The photo helps identify the food. Portion size from a photo alone is always marked as an estimate (D-045).
- **AI-012** `[R1]` Nutrition-label photo → creates a personal food (flow in `11-foods-and-data-quality.md` §5).
- **AI-013** `[R2]` Recipe URL → recipe proposal (`12-diary-meals-recipes.md` §6).
- **AI-014** `[Later]` Voice input.
- **AI-015** `[R1]` One message may contain several things ("breakfast was 2 eggs and labaneh, lunch a shawarma, also weighed 97.2"). Buddy produces **one proposal card per affected meal or record**, grouped in one reply.
- **AI-016** `[R1]` Typos, missing units and shorthand are tolerated ("chiken brest 250 cookd", "3x8 80", "110k").

## 3. Understanding a food message

For each food, Buddy works out the following. Where it can't tell, it uses a default and shows that as an assumption (§5).

| Aspect | Examples |
|---|---|
| Food identity | "chicken breast", "shawarma arabi", "maqluba with eggplant", a brand |
| Amount + unit | grams, ml, pieces, household measures (spoon, cup, glass), local measures (رغيف loaf, صحن plate, حبة piece, كاسة glass), fractions of a dish |
| State | raw / cooked / dry / drained / fried |
| Cooking method & added fat | "fried in 1 tbsp olive oil", "cooked with an onion" |
| Who ate it | "my share", "we were 6", "I had about a quarter" (D-072) |
| When | "now", "for lunch", "yesterday dinner", "2 hours ago" (D-017) |
| Which meal slot | explicit, or inferred from time (D-050) |
| References | "the usual", "same as yesterday", "leftover chicken rice", "my shake" |

- **AI-020** `[R1]` Weighed ingredients cooked together ("200g rice, 200g chicken breast raw, cooked with an onion") are logged **as separate ingredient lines** grouped under one dish name, so each line stays editable.
- **AI-021** `[R1]` A named dish without ingredients ("plate of mom's mloukhiyeh with rice") is matched to a **reference dish** (`11` §6) with a typical portion, and marked as an estimate.
- **AI-022** `[R1]` Cooking fat that's mentioned is logged as its own line (e.g. "olive oil 1 tbsp — 119 kcal"). If fat is likely but not mentioned, see §5.
- **AI-023** `[R1]` Raw/cooked conversions use yield factors (`11` §7), so "200g cooked rice" and "200g dry rice" give correctly different numbers.

## 4. The proposal card (confirm before logging, D-079)

This is the most important interaction in the app. It must feel **instant, clear and one tap away from done**. It must never feel like filling a form.

### 4.1 What appears

```
┌───────────────────────────────────────────┐
│ Breakfast · 08:40                    ✎    │
│ Fried egg                                  │
│   Egg, large ×1 · 50 g        72 kcal  ⓓ  │
│   Olive oil · 1 tbsp          119 kcal ⓓ  │
│   ┌ assumed: all oil eaten ▾ ┐            │
│ ───────────────────────────────────────── │
│ 191 kcal   P 6   C 0   F 18   Fib 0       │
│ Today after this: 1,240 left              │
│                                            │
│ [ Discard ]              [ ✓ Log it ]      │
└───────────────────────────────────────────┘
 ⓓ database  ⓛ label  ⓡ reference dish  ~ estimate
```

- **AI-030** `[R1]` After a simple logging message is sent, a proposal card appears in the chat sheet **within 5 s in 9 out of 10 cases** (D-060). Buddy's live progress (AI-170) shows within 1 s, so the user never stares at nothing. Multi-step requests (suggestions, questions over weeks of data) may take longer, and show each step while they run (D-100).
- **AI-031** `[R1]` The card shows: target meal slot and time; a dish name when items were cooked together; one line per item (name, amount + unit, kcal, source badge); the card's total kcal, protein, carbs, fat and fiber; and **what today's remaining calories will be after logging** it.
- **AI-032** `[R1]` Estimated values show a `~` marker. Tapping it shows the likely range and why (D-045). Your own estimates (DY-005, DY-006) have no range: tapping "~" shows "~ Your estimate" with Edit and Swap for foods (D-096).
- **AI-033** `[R1]` Every assumption Buddy made is shown on the card as a tappable **assumption chip** (e.g. "raw weight", "1 tsp oil assumed", "chicken maqluba", "your share: ¼"). Tapping a chip shows the alternatives, and picking one updates the numbers immediately.
- **AI-034** `[R1]` A clarifying question (§5) appears **inside the card** as tappable answer chips, never as a separate step. Until it's answered, the card shows the default answer's numbers, labelled as such.

### 4.2 Confirming

- **AI-035** `[R1]` **One tap on "Log it" confirms.** The card collapses into a compact "logged ✓" row with a short Buddy reply (D-062), and the Today numbers update with a subtle animation. Undo stays available for a few seconds.
- **AI-036** `[R1]` Nothing from a proposal counts toward totals, charts, targets or memory until it's confirmed (D-079).
- **AI-037** `[R1]` "Discard" removes the proposal. Nothing is logged.

### 4.3 Adjusting before confirming

- **AI-040** `[R1]` Tap an amount to change it inline with a number pad and unit picker. Totals update live.
- **AI-041** `[R1]` Tap an item name to swap the matched food: up to 3 alternatives are shown first (one best guess per distinct option, never duplicates, PR-5), with search below them.
- **AI-042** `[R1]` Swipe an item to remove it. "+ add item" adds one by text or search.
- **AI-043** `[R1]` Tap the slot or time to change it.
- **AI-044** `[R1]` Typing a follow-up while a card is open ("make it 2 eggs", "the rice was cooked") **updates that card** instead of creating a new one. What changed is briefly highlighted. Follow-ups work across the whole conversation (AI-164), not only on the newest card.

### 4.4 Unconfirmed proposals

- **AI-045** `[R1]` If the user leaves without confirming or discarding, the proposal is kept as **pending**. Today's Buddy bar shows "{n} waiting", and one tap reopens Buddy at the pending cards (D-094). Pending proposals never count toward totals.
- **AI-046** `[R1]` Pending proposals stay until handled. The optional reminder is in `17-notifications.md`.
- **AI-047** `[R1]` Messages sent while offline become pending items marked "will process when you're online" (D-049). Once processed, they show up as normal proposals to confirm.

### 4.5 What does *not* need a proposal

- **AI-048** `[R1]` Actions the user takes directly apply immediately, with undo, and don't go through a proposal: tapping a quick-add chip, choosing an amount after a barcode scan, editing a number in the diary by hand, deleting with a swipe (D-079, rule of thumb).
- **AI-049** `[R1]` Answers to questions (§10) change nothing, so they need no confirmation.

### 4.6 Proposals for other record types

The same card pattern (summary, assumption chips, one-tap confirm, inline adjust) is used for:

- **AI-050** `[R1]` **Diary edits** ("the rice was 150g", "move the shawarma to lunch"): the card shows a **before → after** comparison of the affected entry and the new totals.
- **AI-051** `[R1]` **Deletions** ("delete the pepsi"): the card shows exactly what will be removed.
- **AI-052** `[R1]` **Weigh-ins** ("weighed 97.3 today"): value, date and change versus trend.
- **AI-053** `[R1]` **Workouts** ("push day bench 3x8 80…"): see `15-workouts.md` §4.
- **AI-054** `[R1]` **Batch dishes** and **personal foods** ("my shake is 40g whey + 300ml milk").
- **AI-055** `[R1]` **Memory changes** ("I always weigh rice raw").
- **AI-056** `[R1]` **Target changes** suggested by the weekly adaptive check-in (`13-targets-and-goals.md` §4).
- **AI-057** `[R1]` **Imports** from pasted text: the card becomes a review table (`14-weight-and-body.md` §4).

## 5. Asking vs. assuming (D-012)

- **AI-060** `[R1]` Buddy asks a clarifying question only when **both**: (a) the possible answers change the item's calories by more than **20% and more than 50 kcal**, and (b) the user has no saved default that settles it. _(These thresholds are starting values to tune during testing.)_
- **AI-061** `[R1]` At most **2 questions per message**. If more things are ambiguous, the least important ones fall back to defaults, shown as assumption chips.
- **AI-062** `[R1]` Typical question triggers: raw vs. cooked weight for grains, legumes and meats; cooking fat for fried or sautéed food; dish variant when the variants differ a lot (e.g. maqluba with chicken vs. cauliflower); portion when nothing hints at it and the range is wide.
- **AI-063** `[R1]` Answers use chips with 2–4 options plus "other", never free typing (though typing is always accepted).
- **AI-064** `[R1]` If fat is likely but unmentioned (fried, sautéed, "cooked with onion"), Buddy uses the user's cooking-fat default, or otherwise asks once (D-013). The result is always visible as a chip.
- **AI-065** `[R1]` If the user gives the same answer to the same kind of question twice, Buddy offers to remember it ("Always treat rice as raw weight?"). The memory change is itself a proposal (AI-055).

## 6. Where numbers come from (D-011, D-046)

- **AI-070** `[R1]` Buddy's job is to **understand**. Numbers come from the food data, in this priority order:
  1. the user's own foods (personal foods, label scans, saved meals, batch dishes),
  2. verified food data (generic and branded), matched to the right state (raw/cooked),
  3. reviewed reference dishes for local and mixed dishes,
  4. an AI estimate, used **only** when nothing above matches, and always marked `~ estimate` with source "AI estimate".
- **AI-071** `[R1]` Every logged item keeps its source and shows it as a badge. The user can always see where a number came from (SC-4).
- **AI-072** `[R1]` Buddy never replaces a database value with its own number. If the user disagrees with a value, they can override it on the item, and that's recorded as "edited by you".

## 7. Memory & personalisation (D-016)

- **AI-080** `[R1]` Buddy remembers: personal foods ("my shake"), personal portions ("my bowl" ≈ 350 g), saved meals ("the usual breakfast"), defaults (weighing habits, cooking fat, preferred variants), favourite brands, and nicknames/aliases.
- **AI-081** `[R1]` Memory is learned only from **confirmed** data, or added explicitly. It's never learned from unconfirmed proposals.
- **AI-082** `[R1]` A **"Buddy remembers"** screen lists everything remembered, in plain language, and each item can be edited or deleted. Nothing is remembered in secret.
- **AI-083** `[R1]` Matching prefers the user's history: "yogurt" means your usual yogurt, "coffee" means how you usually have it.
- **AI-084** `[R1]` Occasional weighing nudge (D-077): for an estimated food the user logs often (e.g. weekly or more), Buddy may, at most once per food per month, suggest weighing it once and saving it as a personal portion.

## 8. Corrections & diary edits by chat (D-015)

- **AI-090** `[R1]` Any diary entry on any date can be changed by chat: change amount, swap food, move slot or day, delete, add to an existing meal, duplicate ("same as yesterday's lunch").
- **AI-091** `[R1]` References are resolved by context: "the rice" (most recent entry with rice), "yesterday's dinner", "the snack". If a reference could mean two different entries, Buddy asks with chips showing both.
- **AI-092** `[R1]` Every edit is a proposal with a before → after view (AI-050).

## 9. Batch & shared dishes

Details are in `12-diary-meals-recipes.md` §5. Buddy's part:

- **AI-100** `[R1]` Understands "cooked a pot of…" as a batch, and offers the quick path (log the whole batch or your share now) or saving it as leftovers to portion later (D-044).
- **AI-101** `[R1]` Understands portions as grams, fractions, plates or shares ("we were 6") (D-072).
- **AI-102** `[R1]` Understands references to open batches ("leftover chicken rice, a plate").
- **AI-103** `[R1]` A shared dish logged without an amount ("had maqluba with the family") defaults to **one person's typical portion**, shown as an assumption with −/+ on the card. An explicit amount ("half the pot", "big plate", "we were 6") overrides it; Buddy asks only when it's truly ambiguous (D-086).

## 10. Questions about your data

- **AI-110** `[R1]` Answers questions about the user's own data: remaining calories and macros, past days and weeks, averages, weight trend, goal progress, workout history and PRs. Examples: "how much protein left", "avg calories last week", "when did I last do legs", "how much did I lose since ramadan".
- **AI-111** `[R1]` Numbers in answers are **calculated from the data, never made up by the AI**. If the data can't answer, Buddy says so. Every number in a Buddy reply must come from a lookup or calculation made in that turn; a reply with any other number is rewritten or replaced (AI-175).
- **AI-112** `[R1]` Where it helps, an answer includes a tappable link to the relevant chart or diary day.

## 11. Suggestions (D-066)

- **AI-120** `[R1]` On request ("what can I eat with 600 kcal left?"), Buddy suggests 2–4 options that fit remaining calories and protein, preferring foods the user already eats, open batches/leftovers, and local foods. Halal only when the setting is on (D-064).
- **AI-121** `[R1]` Tapping a suggestion creates a proposal card. Nothing is logged automatically.
- **AI-122** `[R1]` Buddy doesn't offer unrequested food advice in chat replies (D-062). The weekly review (§12) is the exception, because the user asked for it.

## 12. Weekly review (D-031, D-066)

- **AI-130** `[R1]` At the start of each week (D-070), Buddy writes a short review: average intake vs. budget, protein days hit, weight trend change, workouts done and PRs, and at most 2 observations or suggestions. If the adaptive check-in proposes new targets, they're attached as a proposal card (AI-056).
- **AI-131** `[R1]` The tone is factual and kind, with no shaming (PR-12). It takes under 30 seconds to read.
- **AI-132** `[R1]` Past reviews are kept and viewable from the weekly summary (`16-insights-and-home.md`).

## 13. Tone & language (D-062, D-063, D-080)

- **AI-140** `[R1]` Friendly and short. Confirmation replies are one line ("Logged ✓ 191 kcal — 1,240 left today").
- **AI-141** `[R2]` Replies in the language and script the user wrote in (English, Arabic, or Arabizi) (moved from R1 by D-080).
- **AI-143** `[R1]` Replies in English, whatever language or script the message was written in. Understanding is unaffected (AI-010) (D-080).
- **AI-142** `[R1]` No food judgements ("bad", "cheat", "guilty"). Opinions only when asked, plus the weekly review.

## 14. Failure handling

- **AI-150** `[R1]` Not understood → Buddy says what it didn't get and asks, with chips where possible. It never logs a guess silently. When a multi-step turn fails part-way, Buddy keeps what it already proposed and says what it couldn't finish (AI-177).
- **AI-151** `[R1]` Food not found anywhere → an estimated proposal (clearly marked), plus options: scan the label, search, or create a personal food.
- **AI-152** `[R1]` Vague message ("ate a lot at the wedding") → Buddy asks what was eaten, offering typical items for that kind of occasion as chips.
- **AI-153** `[R1]` AI service unavailable → pending item, as for offline (AI-047), and the manual search path stays available.
- **AI-154** `[R3]` Daily AI allowance used up (`02-monetization.md`) → Buddy says so once, clearly. Manual search, barcode and quick-add keep working. Nothing already typed is lost; it stays pending until the allowance resets.

## 15. Buddy as an agent (D-100)

Buddy works in **steps**: for each message it decides what to look up, has the app or server compute what's needed, checks the result, and then answers, asks, or proposes actions. Everything in §1–§14 still holds; this section says how the agent behaves.

### 15.1 Deciding and acting

- **AI-160** `[R1]` For each message Buddy may take several steps (look up foods or dishes, read part of your data, compute, check a fit) before it replies. It takes only the steps the message needs: "2 eggs" goes straight to a card.
- **AI-161** `[R1]` Buddy's actions are always **proposals** (D-079): log food, edit, move, copy or delete diary entries, weigh-ins, measurements, workouts, saved meals, batches, personal foods, memory changes and imports. Buddy can't write anything itself; only your confirmation applies a card (AQ-01).
- **AI-162** `[R1]` One reply may carry **several cards** (AI-015). When it carries two or more, an **Apply all** button confirms every still-open card of that reply, as currently shown, in one tap, with one Undo; each card can still be adjusted, confirmed or discarded on its own first.
- **AI-163** `[R1]` Buddy may answer without any card: a question about your data (§10), a suggestion (§11), or a short conversational reply ("nice, protein's on track"). It still never gives unrequested food advice (AI-122).

### 15.2 Conversation

- **AI-164** `[R1]` Buddy remembers the **recent conversation**: your last messages, its replies, and what happened to each card (confirmed, changed, discarded). So "make it 2", "actually that was yesterday" and "what about dinner then?" work without repeating yourself.
- **AI-165** `[R1]` Older conversation is kept as a **short summary** on the phone, so Buddy keeps the thread of a long chat. The summary is shown under "Buddy remembers" (AI-082) and can be cleared.
- **AI-166** `[R1]` When Buddy can't decide something that matters, it **asks** with 2–4 chips (AI-063). It asks at most 2 questions per message (AI-061); the answer continues the same task. Questions inside a card stay as they are (AI-034).
- **AI-167** `[R1]` The conversation, its summary and Buddy's memory are stored **on the phone** and sync like your other data, so they survive a phone change. Buddy itself works only from what the phone sends with each message: it keeps nothing of the conversation between messages and never reads the synced copy.

### 15.3 What Buddy can see

- **AI-168** `[R1]` **Shared knowledge comes from the server**: the food catalog, branded foods, reference dishes, barcodes, portions, cooking yields, nutrition maths and halal flags. Using them sends nothing about you.
- **AI-169** `[R1]` **Your data comes from your phone, only when needed**: your own foods, saved meals, open batches, diary, weight, measurements, workouts and memory. Each message carries a small snapshot (the time, today's totals and targets, your meal slots and open cards) and the few of your own foods and saved meals whose names match the message, so "my shake" is matched at once. For more, Buddy asks the phone for the one piece the message needs (for example "same as yesterday", "how did I do last week"). The phone decides how much it hands over: each kind of read has a limit (for example at most a month of diary entries), and one message can never read more than a small, fixed amount in total. No name, email or account details ever reach the AI (AC-041).

### 15.4 Seeing it work

- **AI-170** `[R1]` While Buddy works, the chat shows its **current step** in plain words ("searching foods…", "checking your diary…", "working out what fits…"), and the reply text streams in as it's written.
- **AI-171** `[R1]` You can **stop** Buddy while it works. Nothing it was preparing is applied; cards already shown stay. If the connection drops mid-reply, Buddy picks the same message up again once without showing cards twice or counting it twice.
- **AI-172** `[R1]` A **trace view**, only in developer builds and the owner's build, shows each step of a turn: what Buddy looked up, what came back, how long it took and what it cost. The trace stays on the phone and is never sent anywhere.

### 15.5 Limits and safety

- **AI-173** `[R1]` A turn has a **step limit and a time limit**. When it runs out, Buddy replies with what it has (cards so far, or a question) instead of failing.
- **AI-174** `[R1]` Every step counts toward the daily AI allowance (AI-154, `02-monetization.md`). A single message costs one message of the allowance however many steps it takes.
- **AI-175** `[R1]` **Numbers in Buddy's own words** (replies, questions and their chips, suggestions, the weekly review, the summary) are filled in by the app's code from that turn's lookups and calculations, each with its own unit and period, never typed by the AI. A reply with any other number (apart from times, dates and small counts) is rewritten once, then replaced by a plain template (AI-111).
- **AI-176** `[R1]` Medical, off-topic and supplement-dosing requests get the **templated** replies of AI-003 and `21-safety-and-wellbeing.md`, never improvised text. Buddy's words never use food judgements (AI-142).
- **AI-177** `[R1]` If something fails part-way (the AI service drops, the phone goes offline), cards already shown stay, and Buddy says what it couldn't finish. An unprocessed message stays pending (AI-047, AI-153).
- **AI-178** `[R1]` Buddy's AI quality is judged by **experiments and the owner's use** (D-100), against the targets in `40-acceptance-criteria.md` §2. There's no AI test suite; the only automated Buddy check is that nothing is written without confirmation (AQ-01).

## Open questions

None currently. Thresholds in AI-060 and AI-084 will be tuned in testing (`40-acceptance-criteria.md`).

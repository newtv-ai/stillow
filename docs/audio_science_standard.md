# Stillow sleep-audio admission standard

Version: 1 · 2026-08-15

This policy is a **product-content screening standard**, not proof that an
individual recording treats insomnia or improves objective sleep architecture.
Stillow should describe content as sleep support / relaxation / masking, not as
a medical treatment.

## Evidence roles

Every approved entry in `assets/content/audio_catalog.json` must have exactly
one role tag.

### `role_trial_aligned_music`

Use for instrumental music that is reasonably aligned with music interventions
used in sleep studies.

Required product criteria:

- instrumental / no lyrics;
- low-arousal arrangement, no abrupt percussion or obvious climax;
- stable dynamics and no startling transitions;
- when tempo can be measured reliably, target roughly **60–85 BPM**;
- target a **20–30 minute** continuous master before calling the asset mature;
- short source loops may remain provisionally, but must carry
  `needs_long_form_master` and receive a complete listening review.

The BPM range and duration are trial-alignment heuristics, not clinical
thresholds. User preference still matters.

### `role_guided_relaxation`

Use for body scan, slow breathing, progressive muscle relaxation, or similarly
low-arousal guided exercises.

Product criteria:

- calm, non-urgent delivery;
- no diagnosis, treatment promise, or pressure to fall asleep;
- normally around 10–25 minutes;
- enough pauses that the recording does not become a continuous information
  stream.

### `role_supporting_music`

Use for music that is calm and potentially useful but has a material limitation,
such as an unusually short loop. It may be browsed and learned from user
feedback, but receives less automatic recommendation weight than
`role_trial_aligned_music`.

### `role_masking_only`

Use for brown noise, rain, ocean, fan-like, or other steady sounds whose primary
mechanism is **masking environmental noise**.

Rules:

- include `mask_noise`;
- do not tag it as `quiet_mind`, `relax_body`, `not_sleepy`, or
  `sleep_pressure`;
- do not make it the default answer for ordinary insomnia;
- a user may still explicitly prefer it, especially in a noisy room;
- keep a default timer/fade rather than encouraging indiscriminate all-night
  broadband-noise use.

### `role_comfort_only`

Use for ordinary readings, encyclopedia material, essays, or other pleasant
spoken content that was not purpose-designed as a low-arousal bedtime
intervention.

Rules:

- it can be offered when the user explicitly wants human voice / company;
- it must not carry core sleep-goal tags;
- it must not automatically outrank trial-aligned music or guided relaxation.

## Engineering guardrails

These are Stillow engineering defaults, **not clinically validated cutoffs**.

### Music

- Prefer long-form masters: 20–30 minutes.
- Avoid melodic loops shorter than 60 seconds. If unavoidable, tag
  `short_loop_risk`.
- Prefer crossfaded / non-obvious loop boundaries.
- Avoid sudden level changes, bright transients, alarms, speech fragments,
  strong bass hits, or attention-grabbing stereo effects.
- Keep final playback comfortable at low device volume; do not normalize sleep
  material to commercial-loudness targets.

### Nature / masking

- Prefer source segments of at least 2–5 minutes.
- Manually listen across the loop boundary with headphones.
- Reject thunder cracks, bird calls, horns, voices, door slams, or other
  intermittent events likely to capture attention.
- Treat the category as contextual masking, not universal sleep improvement.

### Spoken content

Purpose-built bedtime material should favor:

- low information density;
- low conflict and low emotional salience;
- predictable pacing;
- gentle voice with adequate pauses;
- typically 15–45 minutes for story-like content.

Generic articles, factual lectures, and literary pieces remain
`role_comfort_only` until separately reviewed as purpose-built sleep content.

## Recommendation policy

Initial recommendations should follow this hierarchy:

1. match the user's stated state / goal;
2. prefer trial-aligned music or guided relaxation for general sleep support;
3. use masking sounds primarily for a noisy environment or explicit nature/noise
   preference;
4. use comfort-only spoken content when the user explicitly asks for voice /
   company;
5. allow repeated individual feedback to personalize within these guardrails.

Night-waking mode follows the same rule: masking sounds are not the automatic
default unless the user has a masking/nature preference; an explicit saved
night preset is still respected.

## Candidate queue

`assets/content/audio_candidates.json` is **review tooling**, not production
content.

- The normal app startup path must not load it.
- Candidates never enter automatic recommendations.
- Spoken-knowledge candidates are review material for comfort content, not core
  sleep audio.
- Soundscape candidates are reviewed as masking material.
- Music candidates require complete listening plus tempo/dynamics/loop review
  before promotion.

Run:

```bash
python tools/audit_sleep_audio.py
```

The audit verifies role boundaries, bundled-file SHA256 values, short-loop
flags, and candidate-queue assumptions. Warnings identify work that still needs
human listening or a long-form master.

## Research basis used for this policy

The repository policy is intentionally conservative and is based on the pattern
of evidence rather than on a claim that every matching sound is effective.

- Music for insomnia / sleep quality: PMID **29100201**.
- Systematic review of continuous noise for sleep: PMID **33007706**.
- 2024 meta-analysis of sleep apps: PMID **39213858**.
- 2026 randomized trial comparing sleep sounds, bedtime stories, sleep skills,
  and a digital control: PMID **42223503**.
- 2026 controlled study raising concerns about all-night pink-noise exposure:
  PMID **41627391**.

When the evidence changes, update this document and bump
`sciencePolicyVersion` in the approved catalog.

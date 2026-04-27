# Hermes Learning Loop — Technical Specification

## Feedback Threshold

- User rating ≥ 4/5 → add to learning buffer
- 5+ similar queries → skill generation candidate
- Similarity threshold: cosine similarity ≥ 0.75

---

## Pattern Detection

1. Extract intent from query
2. Extract key entities
3. Score similarity to prior queries
4. Cluster similar queries

---

## Skill Generation Pipeline

1. Identify common underlying question in cluster
2. Generate skill prompt template
3. Tag as `v1.0`
4. Test on past queries (must score >85%)
5. Deploy if passing

---

## Versioning

| Version | Meaning | Rollback trigger |
|---------|---------|-----------------|
| v1.0 | Initial generation | — |
| v1.1 | Minor improvement | — |
| v2.0 | Major rewrite | accuracy drops >5% on 10+ queries |

---

## Current Skills

| Skill | Version | Status | Accuracy |
|-------|---------|--------|----------|
| QuantumShield | v1.2 | Stable | 94% |
| TruthEngine | v1.0 | Stable | 88% |
| DeepResearch | v1.1 | Stable | 91% |
| HonestFriend | v1.0 | Stable | 89% |
| GrokSkills | v1.3 | Stable | 92% |

---

## Safe Words

| Word | Effect |
|------|--------|
| `pineapple` | Exit skill mode, return to general agent |
| `blue moon` | Activate humility mode in TruthEngine |

---

## Learning Loop

```
User Query
  → Agent Response
  → User Rates (1–5)
  → Buffer if ≥ 4
  → Cluster Detection
  → Skill Generation
  → Test (>85% accuracy required)
  → Deploy
  → Monitor
  → Iterate
```

# Data Quality

Great Expectations validates the platform at three control points:

- Bronze landing checks: schema and corrupt record detection.
- Silver conformance checks: not-null, uniqueness, type, and allowed values.
- Gold business checks: referential integrity, ranges, freshness, and aggregate sanity.

Run locally:

```bash
great_expectations checkpoint run enterprise_gold_checkpoint --directory quality/great_expectations
```

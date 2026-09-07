# Data layouts

Verified column lists for every dataset this project touches.

**Rule (CLAUDE.md #2):** before a dataset is used anywhere, its metadata or a
5-row sample is pulled, its columns recorded here, and the sample cached under
`data/raw/`. Anything in the project prompt about a dataset's schema is an
assumption to be checked against what is written below — not a fact.

Each section records: the source URL, the endpoint actually called, the fields
found, and any surprises (renamed fields, unexpected types, coded values,
suppression flags, vintage differences).

*Populated in Phase 1. Empty at the end of Phase 0.*

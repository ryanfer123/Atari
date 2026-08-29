# Assets

Store shared static assets here:

- `icons/` for application and progression icons
- `animations/` for focus, reward, and state-transition assets
- `models/` for local model placement during development

Model weights are not committed to Git. Application-bundled assets may later move
closer to the feature that owns them when colocation improves maintainability.

The initial generator candidate is Gemma 3 1B Instruct QAT Q4_0. Developers must
accept the Gemma terms before downloading it; see `research/model-runtime.md`.

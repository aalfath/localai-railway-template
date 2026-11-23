# Changelog

Breaking changes are listed first in each entry.

## v5.0.1 (2026-11-23)

- First release of the Railway template.
- LocalAI v5.0.1 official CPU image, pinned by digest, with the matching llama.cpp CPU backend built in.
- Default model SmolLM2 360M Instruct (Q4_K_M), downloaded once into the `/localai` volume.
- Generated `LOCALAI_API_KEY` protects the API and web UI; health check on `/readyz`.

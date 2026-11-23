[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/localai-3?utm_medium=integration&utm_source=button&utm_campaign=localai)

# LocalAI on Railway

One-click [LocalAI](https://github.com/mudler/LocalAI) v5.0.1: an OpenAI-compatible API and web UI that runs open models (chat, embeddings, speech, images) on CPU.

## What the template deploys

| Service | Built from | What it does |
|---|---|---|
| `LocalAI` | this repo (`Dockerfile`) | LocalAI server on a public Railway domain, health check `/readyz`, one volume at `/localai` |

- Base image: `localai/localai:v5.0.1@sha256:7240f75f2b7f00eeb4e77ff2921c25f77ab265b4e5888933e702e0c3b49d876d` (official CPU image).
- llama.cpp CPU backend: `localai/localai-backends:v5.0.1-cpu-llama-cpp@sha256:9f9f2ad2aa8f3c517065bb5668c7f83577d52f3638f39daead60e8093a3cbc31`, built into the image. Upstream's core image downloads this backend at first use from an unpinned `latest` tag; here it ships with the image, so the first chat call works and matches the server version.
- Default model: SmolLM2 360M Instruct (Apache-2.0, Q4_K_M, about 270 MB), pinned to a Hugging Face commit and checksum. It is downloaded once on the first boot into the volume.
- Everything LocalAI writes (models, backends you install, settings, chats) lives on the `/localai` volume, so restarts and redeploys keep it.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `LOCALAI_API_KEY` | `${{secret(48)}}` | Generated at deploy. Protects the API and the web UI. Comma-separate several keys if you need them. |
| `PORT` | `8080` | Port LocalAI listens on; the public domain points here. |

Optional (add them yourself): `LOCALAI_THREADS` (inference threads, default = the service's vCPU limit), `LOCALAI_SEED_DEFAULT_MODEL=false` (skip the default model on a fresh volume), `LOCALAI_MAX_ACTIVE_BACKENDS` (models kept in memory; 1 below 2 GB RAM), and anything from [LocalAI's CLI reference](https://localai.io/reference/cli-reference/).

## After deploy

1. Copy `LOCALAI_API_KEY` from the service's Variables tab.
2. Open the public URL and sign in with the key, or call the API:

```sh
curl https://YOUR-DOMAIN/v1/chat/completions \
  -H "Authorization: Bearer YOUR-LOCALAI-API-KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "smollm2-360m-instruct", "messages": [{"role": "user", "content": "Hello"}]}'
```

OpenAI-compatible clients: base URL `https://YOUR-DOMAIN/v1`, API key = `LOCALAI_API_KEY`. From another service in the same project: `http://${{LocalAI.RAILWAY_PRIVATE_DOMAIN}}:8080/v1`.

## RAM

There is no GPU on Railway; models run on CPU.

- The default model works in a 0.5 GB / 1 vCPU service (tested: about 255 MB in use, first answer in about 25 s including the model load, later answers faster).
- Real models need more memory. At 4-bit quantization: about 1.5 GB for a 1B model, 3 GB for 3B, 6 GB for 7–8B. Raise the service's memory limit first, then install the model from the **Models** page.
- More vCPUs make answers faster; threads follow the service's vCPU limit.

## Not included

- GPU images (Railway has no GPUs) and the all-in-one `aio` images (they download several GB of models at start).
- Docker-based agent sandboxes: they need privileged mode, which Railway doesn't offer.
- Distributed mode (NATS, Postgres, workers): not needed for a single server.

## Updates

The service builds from this repo, which pins LocalAI and its backend by version and digest. When a new LocalAI release has been tested, `main` gets the new pins and a [CHANGELOG](CHANGELOG.md) entry, and Railway shows deployers an update notice; you choose when to apply it. Your volume is kept. Backends and models you install from the web UI stay on the volume and are not changed by an update.

## Files

- `Dockerfile`: the pinned LocalAI image plus the pinned llama.cpp CPU backend.
- `railway-start.sh`: keeps all paths on `/localai`, refuses to start without an API key, sizes threads to the vCPU limit, seeds the default model once, then runs the upstream entrypoint.
- `default-model.yaml`: the default model's config (small context and batch so it fits 0.5 GB).
- `OVERVIEW.md`: the Railway marketplace overview.

LocalAI is MIT-licensed by Ettore Di Giacinto and contributors. This repo only packages it for Railway.

# Deploy and Host LocalAI on Railway

LocalAI is an open-source, MIT-licensed server that runs open models (chat LLMs, embeddings, speech and images) behind an OpenAI-compatible REST API, with a web UI for chatting and installing models. It runs on plain CPUs, so any OpenAI SDK or tool can talk to your own private model server.

## About Hosting LocalAI

This template runs one LocalAI v5.0.1 service built from the official CPU image, pinned by digest, with the matching llama.cpp CPU backend built in. Everything LocalAI writes (models, backends, settings, chats) lives on one Railway volume at `/localai`, so restarts and redeploys keep it. A random 48-character API key is generated at deploy time and protects the API and the web UI; only `/readyz` and the login page answer without it. On the first boot it downloads SmolLM2-360M Instruct (about 270 MB), so the first chat call works within a minute. There is no GPU on Railway: small models run on CPU, bigger ones need more RAM.

## Common Use Cases

* A private OpenAI-compatible endpoint for apps, scripts and agents that support a custom base URL
* Trying open models (Llama, Qwen, Gemma, Mistral, SmolLM) from the built-in model gallery without sending data to a third party
* Local embeddings and chat for RAG tools, chat front ends and automation workflows on the same Railway project

## Dependencies for LocalAI Hosting

* The LocalAI service (built from this template's GitHub repo) with one volume mounted at `/localai`
* Internet access on first boot to download the default model (and any model you install later) from Hugging Face

### Deployment Dependencies

* LocalAI documentation: https://localai.io
* LocalAI v5.0.1 release: https://github.com/mudler/LocalAI/releases/tag/v5.0.1
* Template repo: https://github.com/aalfath/localai-railway-template

### Implementation Details

**What you get.** One service, `LocalAI`, on a public Railway domain, with a volume at `/localai` and a health check on `/readyz`. No prompts at deploy time.

**After deploy.** Copy `LOCALAI_API_KEY` from the service's Variables tab. Open the public URL and paste the key to sign in to the web UI, or call the API:

```
curl https://YOUR-DOMAIN/v1/chat/completions \
  -H "Authorization: Bearer YOUR-LOCALAI-API-KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "smollm2-360m-instruct", "messages": [{"role": "user", "content": "Hello"}]}'
```

OpenAI-compatible clients use base URL `https://YOUR-DOMAIN/v1` and the same key. Other Railway services can use `http://${{LocalAI.RAILWAY_PRIVATE_DOMAIN}}:8080/v1`.

**RAM.** The default model chats within a 0.5 GB service (tested at 1 vCPU, about 235 MB in use). Real models need more: about 1.5 GB for a 1B model, 3 GB for a 3B model and 6 GB for a 7–8B model at 4-bit quantization. Raise the service's memory before installing them from the Models page. Speed depends on vCPUs; set `LOCALAI_THREADS` if you want a fixed thread count.

**Optional settings.** `LOCALAI_SEED_DEFAULT_MODEL=false` skips the default model on a fresh volume. Multi-user accounts (`LOCALAI_AUTH=true`), OAuth/OIDC and other settings are described in LocalAI's documentation. Docker-based sandboxes for agents need privileged mode and are not available on Railway.

**Updates.** The service builds from the template's GitHub repo, which pins the LocalAI image and backend by version and digest. When a new LocalAI release is tested, the repo is updated with a CHANGELOG entry and Railway shows you an update notice; you choose when to apply it. Your volume is kept.

## Why Deploy LocalAI on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying LocalAI on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->

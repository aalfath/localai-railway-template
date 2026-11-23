# LocalAI for Railway: the official CPU image, pinned by version and digest,
# plus the matching llama.cpp CPU backend baked in, so the first chat call
# works without downloading an unpinned backend at runtime.
FROM localai/localai-backends:v5.0.1-cpu-llama-cpp@sha256:9f9f2ad2aa8f3c517065bb5668c7f83577d52f3638f39daead60e8093a3cbc31 AS llama_cpp

FROM localai/localai:v5.0.1@sha256:7240f75f2b7f00eeb4e77ff2921c25f77ab265b4e5888933e702e0c3b49d876d

# System backend: LocalAI reads /var/lib/local-ai/backends read-only and
# prefers it until a deployer installs a newer llama-cpp from the gallery.
COPY --from=llama_cpp /run.sh /var/lib/local-ai/backends/cpu-llama-cpp/run.sh
COPY --from=llama_cpp /lib /var/lib/local-ai/backends/cpu-llama-cpp/lib
COPY --from=llama_cpp /llama-cpp-cpu-all /var/lib/local-ai/backends/cpu-llama-cpp/llama-cpp-cpu-all
COPY backend-metadata.json /var/lib/local-ai/backends/cpu-llama-cpp/metadata.json
COPY default-model.yaml /etc/railway-localai/default-model.yaml
COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 755 /usr/local/bin/railway-start.sh /var/lib/local-ai/backends/cpu-llama-cpp/run.sh

# Everything LocalAI writes lives on one Railway volume mounted at /localai.
ENV LOCALAI_HOME=/localai \
    LOCALAI_VRAM_WARM_LIMIT=0 \
    LOCALAI_LOG_LEVEL=info

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]

#!/bin/bash
# Railway wrapper for LocalAI: keeps all state on one volume, sizes threads to
# the service's CPU limit, seeds a small default model on the first boot, then
# hands over to the upstream entrypoint (which drops root and execs local-ai,
# so a crash exits non-zero and Railway restarts the service).
set -euo pipefail

home="${LOCALAI_HOME:-/localai}"
mkdir -p "$home"/{models,backends,configuration,data,generated,upload,downloading}

export LOCALAI_MODELS_PATH="${LOCALAI_MODELS_PATH:-$home/models}"
export LOCALAI_BACKENDS_PATH="${LOCALAI_BACKENDS_PATH:-$home/backends}"
export LOCALAI_CONFIG_DIR="${LOCALAI_CONFIG_DIR:-$home/configuration}"
export LOCALAI_DATA_PATH="${LOCALAI_DATA_PATH:-$home/data}"
export LOCALAI_GENERATED_CONTENT_PATH="${LOCALAI_GENERATED_CONTENT_PATH:-$home/generated}"
export LOCALAI_UPLOAD_PATH="${LOCALAI_UPLOAD_PATH:-$home/upload}"
export LOCALAI_DOWNLOAD_STAGING_PATH="${LOCALAI_DOWNLOAD_STAGING_PATH:-$home/downloading}"
export LOCALAI_ADDRESS="${LOCALAI_ADDRESS:-:${PORT:-8080}}"
# The upstream entrypoint hands these folders to the unprivileged user.
export LOCALAI_DATA_DIRS="$home"

if [ -z "${LOCALAI_API_KEY:-}" ]; then
	echo "railway-start: LOCALAI_API_KEY is empty; refusing to start an open LocalAI" >&2
	exit 1
fi

# Railway shows every host CPU inside the container. Use the cgroup CPU limit
# (or 2 when there is none) so llama.cpp and Go don't start dozens of threads.
cpus=""
if [ -r /sys/fs/cgroup/cpu.max ]; then
	read -r quota period < /sys/fs/cgroup/cpu.max || true
	if [ "${quota:-max}" != "max" ] && [ -n "${period:-}" ]; then
		cpus=$(( (quota + period - 1) / period ))
	fi
fi
[ -n "$cpus" ] && [ "$cpus" -gt 0 ] || cpus=2
host_cpus=$(nproc 2>/dev/null || echo "$cpus")
[ "$cpus" -le "$host_cpus" ] || cpus="$host_cpus"
export LOCALAI_THREADS="${LOCALAI_THREADS:-$cpus}"
export GOMAXPROCS="${GOMAXPROCS:-$(( cpus < 2 ? 2 : cpus ))}"
# Keep the Go server small so the model gets the memory: a soft heap limit
# (the llama.cpp backend is C++ and ignores it).
export GOMEMLIMIT="${GOMEMLIMIT:-96MiB}"
export GOGC="${GOGC:-50}"

# Seed the default model once. Deleting it later from the UI keeps it deleted.
marker="$LOCALAI_MODELS_PATH/.railway-default-model"
if [ "${LOCALAI_SEED_DEFAULT_MODEL:-true}" = "true" ] && [ ! -e "$marker" ]; then
	cp /etc/railway-localai/default-model.yaml "$LOCALAI_MODELS_PATH/smollm2-360m-instruct.yaml"
	date -u +%FT%TZ > "$marker"
	echo "railway-start: seeded the default model smollm2-360m-instruct (downloads about 270 MB on this first boot)"
fi

echo "railway-start: threads=$LOCALAI_THREADS GOMAXPROCS=$GOMAXPROCS address=$LOCALAI_ADDRESS home=$home"
exec /entrypoint.sh "$@"

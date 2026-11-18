# Training image for the NOVA benchmark (ACT, SmolVLA, X-VLA, pi0, pi0.5).
# Goal: the SAME LeRobot commit, Python and torch as the local NOVA runs, so every
# model is trained with identical code.
#
# Local env this mirrors (read from ~/venvs/lerobot and ~/lerobot):
#   Python 3.12.3, torch 2.11.0+cu130, torchvision 0.26.0, lerobot eb7a54c,
#   installed with: pip install -e ".[smolvla,libero]"
# Nautilus differences: torch uses the cu126 build (node drivers vary, cu130 needs a
# very new driver), and libero is skipped because there is no simulator here.
#
# Build args (set as CI variables in .gitlab-ci.yml):
#   PYTHON_VERSION, TORCH_VERSION, TORCHVISION_VERSION, TORCH_INDEX, LEROBOT_COMMIT
#   LEROBOT_REPO     git URL that contains LEROBOT_COMMIT (use your fork if the
#                    commit has local patches)
#   LEROBOT_EXTRAS   "smolvla" reproduces the local env; add ",pi" only after the
#                    dry-run check (the pi extra may change transformers)
ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim

ARG TORCH_VERSION
ARG TORCHVISION_VERSION
ARG TORCH_INDEX=https://download.pytorch.org/whl/cu126
ARG LEROBOT_REPO=https://github.com/huggingface/lerobot
ARG LEROBOT_COMMIT
ARG LEROBOT_EXTRAS=smolvla

RUN test -n "$TORCH_VERSION" && test -n "$TORCHVISION_VERSION" && test -n "$LEROBOT_COMMIT"

RUN apt-get update && apt-get install -y --no-install-recommends \
      git ffmpeg build-essential libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# torch wheels bundle their CUDA libraries, so no CUDA base image is needed.
RUN pip install --no-cache-dir "torch==${TORCH_VERSION}" "torchvision==${TORCHVISION_VERSION}" --index-url "${TORCH_INDEX}"

RUN git clone "${LEROBOT_REPO}" /opt/lerobot \
    && cd /opt/lerobot && git checkout "${LEROBOT_COMMIT}" \
    && pip install --no-cache-dir -e ".[${LEROBOT_EXTRAS}]"

ENV PYTHONUNBUFFERED=1
WORKDIR /opt/lerobot

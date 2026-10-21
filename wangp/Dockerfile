# WanGP (deepbeepmeep) para RunPod: Gradio en :7860, Jupyter en :8888, SSH en :22.
# WanGP es de deepbeepmeep y se distribuye bajo WanGP Community License 2.0;
# se conserva /opt/WanGP/LICENSE.txt (la licencia pide preservar avisos al redistribuir).
FROM nvidia/cuda:13.0.2-runtime-ubuntu22.04

LABEL org.opencontainers.image.title="wangp" \
      org.opencontainers.image.description="WanGP (deepbeepmeep) sobre CUDA 13.0 para RunPod" \
      org.opencontainers.image.licenses="WanGP Community License 2.0 (WanGP, deepbeepmeep); ver /opt/WanGP/LICENSE.txt"

ENV DEBIAN_FRONTEND=noninteractive

# ── Fix apt mirrors (igual que la imagen raiz) ──
RUN sed -i 's|http://archive.ubuntu.com|https://us.archive.ubuntu.com|g' /etc/apt/sources.list && \
    echo "Acquire::Retries 5;" > /etc/apt/apt.conf.d/80retry

# ── Dependencias del sistema ──
# gcc/g++/build-essential: Triton compila kernels en el primer uso y necesita compilador C.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates ffmpeg openssh-server \
    gcc g++ build-essential \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /root/.ssh \
    && chmod 700 /root/.ssh

# ── uv + Python 3.11 dentro de la imagen (uv baja Python; incluye headers) ──
ENV UV_PYTHON_INSTALL_DIR=/opt/uv-python
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh && \
    uv venv -p 3.11 /opt/wangp-venv

# ── WanGP (commit fijado) ──
ARG WANGP_REF=dee66357bc67c61958c30546f50344e9b8f59e94
RUN git clone https://github.com/deepbeepmeep/WanGP /opt/WanGP && \
    git -C /opt/WanGP checkout $WANGP_REF

# ── Dependencias Python (versiones de docs/INSTALLATION.md de WanGP) ──
ENV VIRTUAL_ENV=/opt/wangp-venv
RUN uv pip install --no-cache -p /opt/wangp-venv/bin/python \
      torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 \
      --index-url https://download.pytorch.org/whl/cu130 && \
    uv pip install --no-cache -p /opt/wangp-venv/bin/python -r /opt/WanGP/requirements.txt && \
    uv pip install --no-cache -p /opt/wangp-venv/bin/python \
      "https://github.com/deepbeepmeep/SageAttention/releases/download/v2.2.0-linux.cg1/sageattention-2.2.0+cu130torch2.10.0.cg1-cp311-cp311-linux_x86_64.whl" && \
    uv pip install --no-cache -p /opt/wangp-venv/bin/python jupyterlab && \
    (uv cache clean || true) && \
    /opt/wangp-venv/bin/python -c "import importlib.util as u, torch, torchvision, torchaudio; assert u.find_spec('sageattention'), 'falta sageattention'; print(torch.__version__)"

ENV HF_XET_HIGH_PERFORMANCE=1 \
    PATH=/opt/wangp-venv/bin:$PATH \
    PYTHONUNBUFFERED=1

# ── Herramientas y script de inicio ──
COPY run_jobs.py /opt/wangp-tools/run_jobs.py
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 7860 8888 22
CMD ["bash","/start.sh"]

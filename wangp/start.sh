#!/bin/bash
# start.sh — arranque de WanGP en RunPod (sin -e: un servicio caido no tumba el contenedor)
set -uo pipefail

echo "========================================="
echo "  WanGP - Rafael Boni"
echo "========================================="

# ── SSH ──────────────────────────────────────────────────────────────────────
mkdir -p /run/sshd /root/.ssh
chmod 700 /root/.ssh
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
ssh-keygen -A 2>/dev/null

# Clave desde la variable de entorno (RunPod inyecta SSH_PUBLIC_KEY)
if [[ -n "${SSH_PUBLIC_KEY:-}" ]]; then
  echo "$SSH_PUBLIC_KEY" >> /root/.ssh/authorized_keys
  echo "✅ SSH key injected from env"
fi

# Clave del Mac de Rafael — siempre presente
RAFAEL_PUB='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICqquqVPNxuxQhC7CcaEj9TJcsnK4H7AGkYZtY+xtHbY rafaboni'
if ! grep -q 'qquqVPNxux' /root/.ssh/authorized_keys 2>/dev/null; then
  echo "$RAFAEL_PUB" >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  echo "✅ Rafael's SSH key added"
fi

chown -R root:root /root/.ssh
sshd -t 2>&1
service ssh start 2>/dev/null || true
echo "SSH running: $(ss -tlnp | grep :22 || echo 'check manually')"

# ── Jupyter Lab (:8888, raiz /) ──────────────────────────────────────────────
echo "[1/2] Jupyter Lab..."
(cd / && jupyter lab --allow-root --no-browser --port=8888 --ip=0.0.0.0 \
  --ServerApp.token='' \
  --ServerApp.password='' \
  --ServerApp.allow_origin='*' \
  --ServerApp.allow_remote_access=True \
  --ServerApp.disable_check_xsrf=True \
  > /var/log/jupyter.log 2>&1) &

# ── WanGP (:7860) ────────────────────────────────────────────────────────────
echo "[2/2] Iniciando WanGP (log /var/log/wangp.log)..."
WANGP_ARGS=(--listen --server-port 7860 --attention sage2)
# WanGP lee WANGP_AUTH_PASSWORD cuando se usa --auth (el valor no se imprime)
if [[ -n "${WANGP_AUTH_PASSWORD:-}" ]]; then
  WANGP_ARGS+=(--auth)
  echo "Auth activada (WANGP_AUTH_PASSWORD definida)"
fi
if [[ -n "${RUNPOD_POD_ID:-}" ]]; then
  WANGP_ARGS+=(--public-url "https://${RUNPOD_POD_ID}-7860.proxy.runpod.net")
fi
(cd /opt/WanGP && python wgp.py "${WANGP_ARGS[@]}" > /var/log/wangp.log 2>&1) &

echo "========================================="
sleep infinity

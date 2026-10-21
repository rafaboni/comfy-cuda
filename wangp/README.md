# WanGP para RunPod

Imagen `rafaboni/wangp`: [WanGP](https://github.com/deepbeepmeep/WanGP) (deepbeepmeep, WanGP Community License 2.0; se conserva `/opt/WanGP/LICENSE.txt`) sobre CUDA 13.0, Python 3.11, torch 2.10 cu130 y SageAttention 2.2. Commit de WanGP fijado con `WANGP_REF`.

## Puertos
- 7860: WanGP (Gradio)
- 8888: Jupyter Lab (raíz `/`, sin token)
- 22: SSH (solo claves)

## Variables
- `WANGP_AUTH_PASSWORD`: si está definida, WanGP arranca con `--auth` y la usa como contraseña.
- `HF_XET_HIGH_PERFORMANCE=1`: ya viene activa; acelera las descargas de Hugging Face.
- `RUNPOD_POD_ID` (la pone RunPod): se usa para `--public-url`.

Logs: `/var/log/wangp.log` y `/var/log/jupyter.log`.

## Lotes headless
```
python /opt/wangp-tools/run_jobs.py jobs.json
```
`jobs.json` es una lista de `{"name", "template" | "base", "set"}`:
- `template`: ruta relativa a `shared/deepy/settings` de WanGP.
- `base`: dict de ajustes de partida.
- `set`: overrides sobre lo anterior.

Resultados en `/workspace/results.jsonl` (o `/opt/WanGP/results.jsonl` si no hay `/workspace`): archivos, segundos, VRAM pico y errores por job.

## Pods
Crear siempre con `--min-cuda-version 13.0` (imagen cu130). Para MiniMax H3, datacenter fuera de EE.UU./UK/UE/Corea por la licencia de H3.

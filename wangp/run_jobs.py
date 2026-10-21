"""Corre en el pod con /opt/wangp-venv: python run_jobs.py jobs.json
Cada job: {"name", "template" (ruta relativa a shared/deepy/settings) o "base" (dict), "set" (overrides)}.
Escribe una línea por job en results.jsonl (archivos, segundos, VRAM pico, errores)."""
import json, sys, time
from pathlib import Path

ROOT = Path("/opt/WanGP")
sys.path.insert(0, str(ROOT))
import os
os.chdir(ROOT)
import torch
from shared.api import init

jobs = json.load(open(sys.argv[1]))
RESULTS = "/workspace/results.jsonl" if os.path.isdir("/workspace") else "/opt/WanGP/results.jsonl"
out = open(RESULTS, "a")
session = init(root=ROOT, cli_args=["--attention", "sage2"])

for job in jobs:
    settings = {}
    if "template" in job:
        settings.update(json.load(open(ROOT / "shared/deepy/settings" / job["template"])))
    settings.update(job.get("base", {}))
    settings.update(job["set"])
    settings["prompt_enhancer"] = ""
    print(f"=== {job['name']} {settings.get('model_type')}", flush=True)
    torch.cuda.reset_peak_memory_stats()
    t0 = time.time()
    rec = {"name": job["name"], "model_type": settings.get("model_type")}
    try:
        res = session.submit_task(settings).result()
        rec.update(ok=res.success, files=[str(f) for f in res.generated_files],
                   errors=[e.message for e in res.errors])
    except Exception as e:
        rec.update(ok=False, errors=[repr(e)])
    rec["seconds"] = round(time.time() - t0, 1)
    rec["peak_vram_gb"] = round(torch.cuda.max_memory_allocated() / 2**30, 1)
    print(json.dumps(rec), flush=True)
    out.write(json.dumps(rec) + "\n"); out.flush()
print("ALL_DONE", flush=True)

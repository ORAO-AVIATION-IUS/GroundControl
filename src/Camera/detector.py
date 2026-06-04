import sys
import struct
import json
import os
import numpy as np
from sahi import AutoDetectionModel
from sahi.predict import get_sliced_prediction
# from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
from google import genai

# detect if cuda is available or not
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
print(f"[detector] Using device: {DEVICE}", file=sys.stderr, flush=True)

# loading sahi
detection_model = AutoDetectionModel.from_pretrained(
    model_type="yolov8",
    model_path="yolov8n.pt",
    confidence_threshold=0.4,
    device=DEVICE,
)

# load qwen
# Qwen2.5-0.5B is fast enough on CPU; swap for 1.5B if you have ~8GB RAM
# QWEN_MODEL = "Qwen/Qwen2.5-0.5B-Instruct"
# print(f"[detector] Loading {QWEN_MODEL} on {DEVICE}...", file=sys.stderr, flush=True)

# tokenizer = AutoTokenizer.from_pretrained(QWEN_MODEL)
# qwen = AutoModelForCausalLM.from_pretrained(
#     QWEN_MODEL,
#     dtype=DTYPE,           # fixed deprecation warning
#     device_map=DEVICE,
# )
# qwen.eval()
# print("[detector] Qwen loaded.", file=sys.stderr, flush=True)

# QWEN_EVERY_N = 15  # call less often on CPU — tune to your machine
# frame_count  = 0
# last_alert   = ""

API_KEY = os.environ.get("GEMINI_API_KEY", "")
if not API_KEY:
    print("[detector] ERROR: GEMINI_API_KEY not set", file=sys.stderr, flush=True)
    sys.exit(1)

client = genai.Client(api_key=API_KEY)
MODEL  = "gemma-4-26b-a4b-it"   # free in AI Studio; swap to gemini-2.0-flash for even better results
print(f"[detector] Using {MODEL} via Gemini API", file=sys.stderr, flush=True)

QWEN_EVERY_N = 10
frame_count  = 0
last_alert   = ""

SYSTEM_PROMPT = (
    "You are an AI assistant for a drone ground control station. "
    "You receive object detection results from a live camera feed. "
    "Flag threats, anomalies, or mission-critical observations in one "
    "concise sentence (max 20 words). "
    "If nothing notable is detected, respond with exactly: OK"
)

def analyze(boxes: list) -> str:
    if not boxes:
        return ""

    notable = [b for b in boxes if b["score"] > 0.6]
    positions = []
    for b in notable[:5]:
        cx   = b["x"] + b["w"] / 2
        cy   = b["y"] + b["h"] / 2
        quad = ("top" if cy < 0.5 else "bottom") + "-" + ("left" if cx < 0.5 else "right")
        positions.append(f"{b['label']} at {quad} ({b['score']:.0%})")

    if not positions:
        counts: dict[str, int] = {}
        for b in boxes:
            counts[b["label"]] = counts.get(b["label"], 0) + 1
        detail = ", ".join(f"{v}x {k}" for k, v in counts.items())
    else:
        detail = "; ".join(positions)

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=f"{SYSTEM_PROMPT}\n\nDetections: {detail}",
        )
        result = response.text.strip()
        print(f"[gemini] raw: {repr(result)}", file=sys.stderr, flush=True)
        return "" if result == "OK" else result
    except Exception as e:
        print(f"[gemini] error: {e}", file=sys.stderr, flush=True)
        return ""

# def analyze_with_qwen(boxes: list) -> str:
#     if not boxes:
#         return ""

#     counts: dict[str, int] = {}
#     for b in boxes:
#         counts[b["label"]] = counts.get(b["label"], 0) + 1

#     notable = [b for b in boxes if b["score"] > 0.6]
#     positions = []
#     for b in notable[:5]:
#         cx = b["x"] + b["w"] / 2
#         cy = b["y"] + b["h"] / 2
#         quad = ("top" if cy < 0.5 else "bottom") + "-" + ("left" if cx < 0.5 else "right")
#         positions.append(f"{b['label']} at {quad} ({b['score']:.0%})")

#     detail = "; ".join(positions) if positions else ", ".join(
#         f"{v}x {k}" for k, v in counts.items()
#     )

#     messages = [
#         {"role": "system", "content": SYSTEM_PROMPT},
#         {"role": "user",   "content": f"Detections: {detail}"},
#     ]

#     text   = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
#     inputs = tokenizer(text, return_tensors="pt").to(qwen.device)

#     with torch.no_grad():
#         output = qwen.generate(
#             **inputs,
#             max_new_tokens=40,
#             do_sample=False,
#             pad_token_id=tokenizer.eos_token_id,
#         )

#     new_tokens = output[0][inputs["input_ids"].shape[1]:]
#     result = tokenizer.decode(new_tokens, skip_special_tokens=True).strip()
#     return "" if result == "OK" else result



def read_frame():
    header = sys.stdin.buffer.read(8)
    if len(header) < 8:
        return None, 0, 0
    w, h = struct.unpack("ii", header)
    expected = w * h * 3
    data = b""
    while len(data) < expected:
        chunk = sys.stdin.buffer.read(expected - len(data))
        if not chunk:
            return None, 0, 0
        data += chunk
    return np.frombuffer(data, np.uint8).reshape(h, w, 3), w, h

while True:
    frame, w, h = read_frame()
    if frame is None:
        break

    frame_count += 1

    result = get_sliced_prediction(
        frame, detection_model,
        slice_height=512, slice_width=512,
        overlap_height_ratio=0.2,
        overlap_width_ratio=0.2,
    )

    boxes = []
    for pred in result.object_prediction_list:
        b = pred.bbox
        boxes.append({
            "x":     b.minx / w,
            "y":     b.miny / h,
            "w":     (b.maxx - b.minx) / w,
            "h":     (b.maxy - b.miny) / h,
            "label": pred.category.name,
            "score": round(pred.score.value, 3),
        })

    if frame_count % QWEN_EVERY_N == 0:
        last_alert = analyze(boxes)

    sys.stdout.write(json.dumps({"boxes": boxes, "alert": last_alert}) + "\n")
    sys.stdout.flush()
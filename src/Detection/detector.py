import contextlib
import io
import json
import os
import struct
import sys
from pathlib import Path
from typing import Any

import numpy as np
import torch
from google import genai
from sahi import AutoDetectionModel
from sahi.predict import get_sliced_prediction

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
CONFIDENCE_THRESHOLD = float(os.environ.get("AGC_DETECTION_CONFIDENCE", "0.4"))
ALERT_INTERVAL_FRAMES = int(os.environ.get("AGC_DETECTION_ALERT_INTERVAL", "10"))
GEMINI_MODEL = os.environ.get("AGC_DETECTION_LLM_MODEL", "gemma-4-26b-a4b-it")
MODEL_PATH = Path(os.environ.get("AGC_DETECTION_MODEL_PATH", Path(__file__).with_name("yolov8n.pt")))

PROTOCOL_STDOUT = sys.stdout

SYSTEM_PROMPT = (
    "You are an AI assistant for a drone ground control station. "
    "You receive object detection results from a live camera feed. "
    "Flag threats, anomalies, or mission-critical observations in one "
    "concise sentence (max 20 words). "
    "If nothing notable is detected, respond with exactly: OK"
)


def log(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


def create_gemini_client() -> genai.Client | None:
    api_key = os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        log("[detector] GEMINI_API_KEY is not set; object alerts are disabled")
        return None

    log(f"[detector] Using {GEMINI_MODEL} via Gemini API")
    return genai.Client(api_key=api_key)


def summarize_boxes(boxes: list[dict[str, Any]]) -> str:
    notable = [box for box in boxes if box["score"] > 0.6]
    positions = []
    for box in notable[:5]:
        center_x = box["x"] + box["w"] / 2
        center_y = box["y"] + box["h"] / 2
        quadrant = ("top" if center_y < 0.5 else "bottom") + "-" + (
            "left" if center_x < 0.5 else "right"
        )
        positions.append(f"{box['label']} at {quadrant} ({box['score']:.0%})")

    if positions:
        return "; ".join(positions)

    counts: dict[str, int] = {}
    for box in boxes:
        label = str(box["label"])
        counts[label] = counts.get(label, 0) + 1
    return ", ".join(f"{count}x {label}" for label, count in counts.items())


def analyze(boxes: list[dict[str, Any]], client: genai.Client | None) -> str:
    if not boxes or client is None:
        return ""

    try:
        with contextlib.redirect_stdout(sys.stderr):
            response = client.models.generate_content(
                model=GEMINI_MODEL,
                contents=f"{SYSTEM_PROMPT}\n\nDetections: {summarize_boxes(boxes)}",
            )
        result = (response.text or "").strip()
        return "" if result == "OK" else result
    except Exception as error:  # noqa: BLE001 - keep detector process alive.
        log(f"[gemini] error: {error}")
        return ""


def read_frame() -> tuple[np.ndarray[Any, Any] | None, int, int]:
    header = sys.stdin.buffer.read(8)
    if len(header) < 8:
        return None, 0, 0

    width, height = struct.unpack("ii", header)
    expected = width * height * 3
    chunks = bytearray()
    while len(chunks) < expected:
        chunk = sys.stdin.buffer.read(expected - len(chunks))
        if not chunk:
            return None, 0, 0
        chunks.extend(chunk)

    return np.frombuffer(chunks, np.uint8).reshape(height, width, 3), width, height


def detect_boxes(frame: np.ndarray[Any, Any], width: int, height: int) -> list[dict[str, Any]]:
    with contextlib.redirect_stdout(io.StringIO()):
        result = get_sliced_prediction(
            frame,
            detection_model,
            slice_height=512,
            slice_width=512,
            overlap_height_ratio=0.2,
            overlap_width_ratio=0.2,
        )

    boxes = []
    for prediction in result.object_prediction_list:
        box = prediction.bbox
        boxes.append(
            {
                "x": float(box.minx / width),
                "y": float(box.miny / height),
                "w": float((box.maxx - box.minx) / width),
                "h": float((box.maxy - box.miny) / height),
                "label": str(prediction.category.name),
                "score": float(round(float(prediction.score.value), 3)),
            }
        )
    return boxes


log(f"[detector] Using device: {DEVICE}")
log(f"[detector] Loading model: {MODEL_PATH}")
with contextlib.redirect_stdout(sys.stderr):
    detection_model = AutoDetectionModel.from_pretrained(
        model_type="yolov8",
        model_path=str(MODEL_PATH),
        confidence_threshold=CONFIDENCE_THRESHOLD,
        device=DEVICE,
    )
gemini_client = create_gemini_client()

frame_count = 0
last_alert = ""

while True:
    frame, frame_width, frame_height = read_frame()
    if frame is None:
        break

    frame_count += 1
    detected_boxes = detect_boxes(frame, frame_width, frame_height)

    if frame_count % ALERT_INTERVAL_FRAMES == 0:
        last_alert = analyze(detected_boxes, gemini_client)

    PROTOCOL_STDOUT.write(json.dumps({"boxes": detected_boxes, "alert": last_alert}) + "\n")
    PROTOCOL_STDOUT.flush()

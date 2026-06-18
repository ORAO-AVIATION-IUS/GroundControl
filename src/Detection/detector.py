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
from sahi import AutoDetectionModel
from sahi.predict import get_sliced_prediction

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
CONFIDENCE_THRESHOLD = float(os.environ.get("AGC_DETECTION_CONFIDENCE", "0.3"))
MODEL_PATH = Path(os.environ.get("AGC_DETECTION_MODEL_PATH", Path(__file__).with_name("yolov8s.pt")))
MODEL_SOURCE = str(MODEL_PATH if MODEL_PATH.exists() else "yolov8s.pt")
PERSON_CLASS_ID = 0

PROTOCOL_STDOUT = sys.stdout


def log(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


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


def is_person_prediction(prediction: Any) -> bool:
    category_id = getattr(prediction.category, "id", None)
    if category_id is not None:
        try:
            if int(category_id) == PERSON_CLASS_ID:
                return True
        except (TypeError, ValueError):
            pass
    return str(prediction.category.name).lower() == "person"


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
        if not is_person_prediction(prediction):
            continue

        box = prediction.bbox
        boxes.append(
            {
                "x": float(box.minx / width),
                "y": float(box.miny / height),
                "w": float((box.maxx - box.minx) / width),
                "h": float((box.maxy - box.miny) / height),
                "label": "person",
                "score": float(round(float(prediction.score.value), 3)),
            }
        )
    return boxes


log(f"[detector] Using device: {DEVICE}")
log(f"[detector] Loading model: {MODEL_SOURCE}")
log(f"[detector] Person confidence threshold: {CONFIDENCE_THRESHOLD:.2f}")
with contextlib.redirect_stdout(sys.stderr):
    detection_model = AutoDetectionModel.from_pretrained(
        model_type="yolov8",
        model_path=MODEL_SOURCE,
        confidence_threshold=CONFIDENCE_THRESHOLD,
        device=DEVICE,
    )

while True:
    frame, frame_width, frame_height = read_frame()
    if frame is None:
        break

    detected_boxes = detect_boxes(frame, frame_width, frame_height)
    PROTOCOL_STDOUT.write(json.dumps({"boxes": detected_boxes, "alert": ""}) + "\n")
    PROTOCOL_STDOUT.flush()

import sys, struct, json
import numpy as np
from sahi import AutoDetectionModel
from sahi.predict import get_sliced_prediction

model = AutoDetectionModel.from_pretrained(
    model_type="yolov8",
    model_path="yolov8n.pt",          # swap for your weights
    confidence_threshold=0.4,
    device="cuda",                     # or "cpu"
)

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
    frame = np.frombuffer(data, np.uint8).reshape(h, w, 3)
    return frame, w, h

while True:
    frame, w, h = read_frame()
    if frame is None:
        break

    result = get_sliced_prediction(
        frame, model,
        slice_height=512, slice_width=512,
        overlap_height_ratio=0.2,
        overlap_width_ratio=0.2,
    )

    boxes = []
    for pred in result.object_prediction_list:
        b = pred.bbox
        boxes.append({
            "x": b.minx / w,  "y": b.miny / h,
            "w": (b.maxx - b.minx) / w,
            "h": (b.maxy - b.miny) / h,
            "label": pred.category.name,
            "score": round(pred.score.value, 3),
        })

    sys.stdout.write(json.dumps(boxes) + "\n")
    sys.stdout.flush()
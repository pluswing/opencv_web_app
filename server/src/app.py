from flask import Flask, request, jsonify
from flask_cors import CORS
from typing import Any, Tuple
from uuid import uuid4
import os
import cv2
import numpy as np

app = Flask(__name__, static_folder='../static')
CORS(app)
app.config["MAX_CONTENT_LENGTH"] = 1 * 1024 * 1024  # 1MB

SRC_DIR = os.path.dirname(__file__)
TASK_DIR = os.path.join(
    os.path.dirname(
        os.path.dirname(__file__)
    ),
    "static", "task")


def image_path(task_id: str, id: str) -> str:
    return os.path.join(TASK_DIR, task_id, f"{id}.jpg")


def error_res(message: str) -> Tuple[Any, int]:
    return jsonify({"error": message}), 400


@app.route("/")
def hello() -> str:
    return "Hello, World!"


@app.route("/upload_image", methods=["POST"])
def upload_image() -> Any:
    # <input type="file" name="uploadFile"
    if "uploadFile" not in request.files:
        return error_res("required upload file")
    file = request.files["uploadFile"]
    file_name = file.filename
    if "" == file_name:
        return error_res("filename must not empty.")

    task_id = str(uuid4())
    id = str(uuid4())
    save_path = image_path(task_id, id)
    os.makedirs(os.path.dirname(save_path))
    # file.save(save_path)
    img = cv2.imdecode(np.fromstring(
        file.read(), np.uint8), cv2.IMREAD_UNCHANGED)
    # TODO 配列が空だったらエラーにする
    cv2.imwrite(save_path, img)

    return jsonify({
        "result": {
            "image": {
                "task_id": task_id,
                "id": id,
            }
        }
    })


@app.route("/grayscale", methods=["POST"])
def grayscale() -> Any:
    data = request.json
    # {task_id: XXX, id: XXX}
    task_id = data.get("task_id", "")
    path = image_path(task_id, data.get("id", ""))
    if not os.path.exists(path):
        error_res("filename not exists")

    img = cv2.imread(path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    new_id = str(uuid4())
    write_path = image_path(task_id, new_id)
    cv2.imwrite(write_path, gray)

    return jsonify({
        "result": {
            "image": {
                "task_id": task_id,
                "id": new_id,
            }
        }
    })


@app.route("/threshold", methods=["POST"])
def threshold() -> Any:
    data = request.json
    task_id = data.get("task_id", "")
    path = image_path(task_id, data.get("id", ""))
    if not os.path.exists(path):
        error_res("filename not exists")
    t = data.get("threshold")
    threshold = int(t if t else 0)

    img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)

    if threshold == 0:
        threshold, img_thresh = cv2.threshold(img, 0, 255, cv2.THRESH_OTSU)
    else:
        _, img_thresh = cv2.threshold(img, threshold, 255, cv2.THRESH_BINARY)

    new_id = str(uuid4())
    write_path = image_path(task_id, new_id)
    cv2.imwrite(write_path, img_thresh)

    return jsonify({
        "result": {
            "image": {
                "task_id": task_id,
                "id": new_id,
            },
            "params": {
                "threshold": str(int(threshold))
            }
        }
    })


face_cascade = cv2.CascadeClassifier(os.path.join(
    SRC_DIR, 'haarcascade_frontalface_default.xml'))


@app.route("/face_detection", methods=["POST"])
def face_detection() -> Any:
    try:
        data = request.json
        task_id = data.get("task_id", "")
        path = image_path(task_id, data.get("id", ""))
        if not os.path.exists(path):
            error_res("filename not exists")

        img = cv2.imread(path)
        img_with_rect = img.copy()
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        faces = face_cascade.detectMultiScale(gray, 1.3, 5)
        face_data = []
        for (x, y, w, h) in faces:
            cv2.rectangle(
                img_with_rect, (x, y), (x+w, y+h), (255, 0, 0), 2)

            face_img = img[y:y+h, x:x+w]
            new_id = str(uuid4())
            write_path = image_path(task_id, new_id)
            cv2.imwrite(write_path, face_img)
            face_data.append({
                "task_id": task_id,
                "id": new_id,
                "x": int(x),
                "y": int(y),
                "width": int(w),
                "height": int(h),
            })

        new_id = str(uuid4())
        write_path = image_path(task_id, new_id)
        cv2.imwrite(write_path, img_with_rect)

        return jsonify({
            "result": {
                "image": {
                    "task_id": task_id,
                    "id": new_id,
                    "x": 0,
                    "y": 0,
                    "width": img.shape[1],
                    "height": img.shape[0],
                },
                "faces": face_data
            }
        })
    except Exception as e:
        print(e)

# グレースケール
# -> フィルター系（パラメータなし。画像のみ）

# ２値化 白黒にするやつ
#
# 矩形の切り取り
# -> パラメータあり。
#    画像＋？

# 顔認識
# 数字認識
# (Object Detection)
# -> パラメータなし（ある場合もある）
# -> 戻り値が画像＋？
#    -> 矩形の座標、値。

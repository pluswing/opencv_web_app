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


"""
threshold = 100
ret, img_thresh = cv2.threshold(img, threshold, 255, cv2.THRESH_BINARY)

ret2, img_otsu = cv2.threshold(img, 0, 255, cv2.THRESH_OTSU)

#閾値がいくつになったか確認
print("ret2: {}".format(ret2))
"""

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

from flask import Flask, request, jsonify
from flask_cors import CORS
from typing import Any, Tuple, Callable, Optional
from uuid import uuid4
import os
import cv2
import numpy as np
import easyocr

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


def filter_api(
        action: Callable[
            [dict[str, Any], np.ndarray],
            Tuple[np.ndarray, Optional[dict[str, Any]]]
        ]) -> Any:
    data = request.json
    # {task_id: XXX, id: XXX}
    task_id = data.get("task_id", "")
    path = image_path(task_id, data.get("id", ""))
    if not os.path.exists(path):
        error_res("filename not exists")

    img = cv2.imread(path)
    img, params = action(data, img)
    new_id = str(uuid4())
    write_path = image_path(task_id, new_id)
    cv2.imwrite(write_path, img)

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
            "params": params
        }
    })


@app.route("/grayscale", methods=["POST"])
def grayscale() -> Any:
    def gray(
            data: dict[str, Any],
            img: np.ndarray) -> Tuple[np.ndarray, None]:
        return cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), None

    return filter_api(gray)


@app.route("/threshold", methods=["POST"])
def threshold() -> Any:
    def thre(
            data: dict[str, Any],
            img: np.ndarray) -> Tuple[np.ndarray, dict[str, Any]]:
        t = data.get("threshold")
        threshold = int(t if t else 0)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        if threshold == 0:
            threshold, img = cv2.threshold(img, 0, 255, cv2.THRESH_OTSU)
        else:
            _, img = cv2.threshold(img, threshold, 255, cv2.THRESH_BINARY)
        return img, {"threshold": str(int(threshold))}

    return filter_api(thre)


face_cascade = cv2.CascadeClassifier(os.path.join(
    SRC_DIR, 'haarcascade_frontalface_default.xml'))


@app.route("/face_detection", methods=["POST"])
def face_detection() -> Any:
    def fd(
            data: dict[str, Any],
            img: np.ndarray) -> Tuple[np.ndarray, dict[str, Any]]:
        task_id = data.get("task_id", "")
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
        return img_with_rect, {"faces": face_data}

    return filter_api(fd)


ocr_reader = easyocr.Reader(['ja', 'en'])


@app.route("/ocr", methods=["POST"])
def ocr() -> Any:
    def _ocr(
            data: dict[str, Any],
            img: np.ndarray) -> Tuple[np.ndarray, dict[str, Any]]:
        task_id = data.get("task_id", "")
        path = image_path(task_id, data.get("id", ""))
        result = ocr_reader.readtext(path)
        img_with_rect = img.copy()
        data_list = []
        for (points, text, score) in result:
            x = points[0][0]
            y = points[0][1]
            w = points[2][0] - x
            h = points[2][1] - y
            cv2.rectangle(
                img_with_rect, (x, y), (x+w, y+h), (255, 0, 0), 2)

            _img = img[y:y+h, x:x+w]
            new_id = str(uuid4())
            write_path = image_path(task_id, new_id)
            cv2.imwrite(write_path, _img)

            data_list.append({
                "image": {
                    "task_id": task_id,
                    "id": new_id,
                    "x": int(x),
                    "y": int(y),
                    "width": int(w),
                    "height": int(h),
                },
                "text": text,
                "score": score,
            })
        return img_with_rect, {"texts": data_list}

    return filter_api(_ocr)


@app.route("/contours", methods=["POST"])
def contours() -> Any:
    def con(
            data: dict[str, Any],
            img: np.ndarray) -> Tuple[np.ndarray, dict[str, Any]]:
        # task_id = data.get("task_id", "")
        img_with_rect = img.copy()
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        threshold, thre = cv2.threshold(gray, 0, 255, cv2.THRESH_OTSU)

        contours, hierarchy = cv2.findContours(
            thre, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        img_with_rect = cv2.drawContours(
            img_with_rect, contours, -1, (0, 0, 255, 255), 2, cv2.LINE_AA)

        # TODO 抽出画像を別途保存
        # TODO 四角の箇所のみ抽出。台形補正もやる

        return img_with_rect, {}

    return filter_api(con)


@app.route("/bitwise_not", methods=["POST"])
def bitwise_not() -> Any:
    def _not(
            data: dict[str, Any],
            img: np.ndarray) -> Tuple[np.ndarray, None]:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        threshold, thre = cv2.threshold(gray, 0, 255, cv2.THRESH_OTSU)
        return cv2.bitwise_not(thre), None

    return filter_api(_not)

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

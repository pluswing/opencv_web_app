from flask import Flask, request, jsonify, make_response
from uuid import uuid4
import os

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 1 * 1024 * 1024　# 1MB

TASK_DIR = os.path.join(
    os.path.dirname(__file__),
    "static", "task")

@app.route("/")
def hello() -> str:
    return "Hello, World!"

@app.route('/upload_image', methods=['POST'])
def upload_image():
  # <input type="file" name="uploadFile"
  if 'uploadFile' not in request.files:
      return jsonify({'error': 'uploadFile is required.'}), 400
  file = request.files['uploadFile']
  file_name = file.filename
  if '' == file_name:
      return jsonify({'error': 'filename must not empty.'}), 400
  pass

  task_id = str(uuid4())
  id = str(uuid4())
  save_path = os.path.join(TASK_DIR, task_id, f"{id}.jpg")
  file.save(save_path)
  return jsonify({
    'result': {
      "image": {
        "task_id": task_id,
        "id": id,
      }
    }
  })

"""
def grayscale():
  request.path # uuid/original.jpg

  ## ...
  uuid/uuid.jpg

  return {
    # uuid, uuid2
  }
"""

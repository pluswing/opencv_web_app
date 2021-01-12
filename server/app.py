from flask import Flask, request, jsonify, make_response

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 1 * 1024 * 1024　# 1MB

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

  uuid = uuidv4()
  save_path = "" #  TODO os.path.join(UPLOAD_DIR, save_path)
  file.save(save_path)
  return jsonify({
    'result': {
      "uuid": uuid
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

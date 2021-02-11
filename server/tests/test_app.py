import os
import shutil
from src.app import app, image_path

client = app.test_client()


def test_usecase() -> None:
    res = client.post("/upload_image")
    assert res.status_code == 400
    assert res.get_json() == {'error': 'required upload file'}

    # TODO
    # filename not exists test
    # success test


def test_image_path() -> None:
    assert image_path("a", "b") == "/server/static/task/a/b.jpg"


def test_face_detection() -> None:
    task_id = "test"
    id = "a"
    path = image_path(task_id, id)

    # copy img
    if not os.path.exists(os.path.dirname(path)):
        os.makedirs(os.path.dirname(path))
    cur = os.path.dirname(__file__)
    shutil.copy(f"{cur}/img/lena.jpg", path)

    res = client.post("/face_detection", json={
        'task_id': task_id,
        'id': id,
    })
    print(res)

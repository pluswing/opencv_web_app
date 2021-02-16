import os
import pytest
import shutil
from typing import Any
from src.app import app, image_path

client = app.test_client()
task_id = "test"
id = "a"


@pytest.fixture(scope='function', autouse=True)
def setup_each_function() -> Any:
    clear_image()
    yield
    clear_image()


def test_image_path() -> None:
    assert image_path("a", "b") == "/server/static/task/a/b.jpg"


def test_upload_image() -> None:
    res = client.post("/upload_image")
    assert res.status_code == 400
    assert res.get_json() == {'error': 'required upload file'}

    # TODO
    # filename not exists test
    # success test


def clear_image() -> None:
    path = image_path(task_id, id)
    if os.path.exists(os.path.dirname(path)):
        shutil.rmtree(os.path.dirname(path))


def copy_image() -> Any:
    path = image_path(task_id, id)
    if not os.path.exists(os.path.dirname(path)):
        os.makedirs(os.path.dirname(path))
    cur = os.path.dirname(__file__)
    shutil.copy(f"{cur}/img/lena.jpg", path)

    return {
        "task_id": task_id,
        "id": id,
    }


def test_grayscale() -> None:
    res = client.post("/grayscale", json=copy_image())
    assert res.status_code == 200
    data = res.get_json()
    assert data["result"]["image"].pop("id")
    assert data == {
        'result': {
            'image': {
                'task_id': 'test',
                'x': 0,
                'y': 0,
                'height': 512,
                'width': 512,
            },
            "params": None,
        }
    }


def test_threshold() -> None:
    res = client.post("/threshold", json=copy_image())
    assert res.status_code == 200
    data = res.get_json()
    assert data["result"]["image"].pop("id")
    assert data == {
        'result': {
            'image': {
                'task_id': 'test',
                'x': 0,
                'y': 0,
                'height': 512,
                'width': 512,
            },
            'params': {
                'threshold': '117'
            }
        }
    }

    # TODO threshold指定パターン


def test_face_detection() -> None:
    res = client.post("/face_detection", json=copy_image())

    assert res.status_code == 200
    data = res.get_json()
    assert data["result"]["image"].pop("id")
    assert len(data["result"]["params"]["faces"]) == 1
    assert data["result"]["params"]["faces"][0].pop("id")
    assert data == {
        'result': {
            'image': {
                # 'id': '4e2955c7-9578-475e-90dc-0278cfd3b27c',
                'task_id': 'test',
                'x': 0,
                'y': 0,
                'height': 512,
                'width': 512,
            },
            'params': {
                'faces': [{
                    'height': 171,
                    # 'id': '4bd1079e-c66a-4d61-b872-68320bafa1cf',
                    'task_id': 'test',
                    'width': 171,
                    'x': 218,
                    'y': 204}
                ],
            }
        }
    }

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


def copy_image(name: str = "lena.jpg") -> Any:
    path = image_path(task_id, id)
    if not os.path.exists(os.path.dirname(path)):
        os.makedirs(os.path.dirname(path))
    cur = os.path.dirname(__file__)
    shutil.copy(f"{cur}/img/{name}", path)

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


def test_ocr() -> None:
    res = client.post("/ocr", json=copy_image("japanese.jpg"))

    assert res.status_code == 200
    data = res.get_json()
    assert data["result"]["image"].pop("id")
    assert len(data["result"]["params"]["texts"]) == 4
    for texts in data["result"]["params"]["texts"]:
        assert texts["image"].pop("id")
    assert data == {
        'result': {
            'image': {
                'height': 418,
                # 'id': '12b5d371-cf18-4581-94a7-3e27a67a7b3c',
                'task_id': 'test',
                'width': 555,
                'x': 0,
                'y': 0
            },
            'params': {
                'texts': [
                    {
                        'image': {
                            'height': 110,
                            # 'id': '62de2404-c79d-4d0a-af20-9ddf77c7b7de',
                            'task_id': 'test',
                            'width': 418,
                            'x': 71,
                            'y': 49
                        },
                        'score': 0.6427963376045227,
                        'text': 'ポ<捨て禁止!'
                    }, {
                        'image': {
                            'height': 86,
                            # 'id': '88d33358-4031-45ce-a827-43f1707d98f8',
                            'task_id': 'test',
                            'width': 366,
                            'x': 95,
                            'y': 149
                        },
                        'score': 0.31056877970695496,
                        'text': 'NOLITTER'
                    }, {
                        'image': {
                            'height': 56,
                            # 'id': '7e8aa6c5-d535-49de-975f-be3180ded78d',
                            'task_id': 'test',
                            'width': 395,
                            'x': 80,
                            'y': 232
                        },
                        'score': 0.9784266948699951,
                        'text': '清潔できれいな港区を'
                    }, {
                        'image': {
                            'height': 44,
                            # 'id': '211e3c44-090d-4be6-baab-39b885abb578',
                            'task_id': 'test',
                            'width': 328,
                            'x': 109,
                            'y': 289
                        },
                        'score': 0.18789316713809967,
                        'text': '港 区 MINATO CITY'
                    }
                ]
            }
        }
    }


def test_card_detection():
    res = client.post("/card_detection", json=copy_image("29.jpg"))
    assert res.status_code == 200
    data = res.get_json()
    print(data)

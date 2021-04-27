import glob
import os
import time
import shutil

ROOT_PATH = os.path.dirname(
    os.path.dirname(
        os.path.dirname(__file__)
    )
)

TASK_PATH = os.path.join(
    ROOT_PATH, "static", "task")

INTERVAL = 60 * 60  # 1時間


def image_gabege_collect() -> None:
    # 画像の一覧をとる
    dirs = glob.glob(os.path.join(TASK_PATH, "*"))

    for d in dirs:
        # 更新時刻をとる
        files = glob.glob(os.path.join(d, "*"))

        if len(files) == 0:
            shutil.rmtree(d)
            continue

        mtime = max([os.stat(f).st_mtime for f in files])

        # 更新時刻が一定以上過去なら消す
        if time.time() - mtime > INTERVAL:
            shutil.rmtree(d)


if __name__ == "__main__":
    image_gabege_collect()

# import cv2
import glob
from PIL import Image
import random
import math
import itertools

backgrounds = list(glob.glob("images/background/*"))
cards = list(glob.glob("images/cards/*"))

for i in range(1000):
    # 背景をランダムで選ぶ
    bgImg = Image.open(random.choice(backgrounds))

    # カードをランダムで選ぶ（複数枚。何枚かもランダム）
    cs = random.sample(cards, random.randint(2, 5))

    (width, height) = bgImg.size
    # 背景にカードを重ね合わせる(どこにはランダム)
    annotations = []
    for c in cs:
        img = Image.open(c)
        (w, h) = img.size
        img = img.resize((w//2, h//2), Image.BICUBIC)
        (w, h) = img.size

        #  -> 回転させる
        r = random.randint(0, 359)
        img = img.rotate(angle=r, resample=Image.BICUBIC, expand=True)
        mask = Image.new("RGB", (w, h), (255, 255, 255)).convert(
            "L").rotate(angle=r, resample=Image.BICUBIC, expand=True)
        mx = random.randint(0, width - w)
        my = random.randint(0, height - h)
        bgImg.paste(img, (mx, my), mask)

        # 各点をrotateさせた後の位置にする
        hw = w // 2
        hh = h // 2
        points = [
            (-hw, -hh),
            (hw, -hh),
            (hw, hh),
            (-hw, hh)
        ]
        theta = r * math.pi / 180
        new_points = []
        for (x, y) in points:
            nx = x * math.cos(theta) + y * -math.sin(theta)
            ny = x * math.sin(theta) + y * math.cos(theta)
            nx += mx
            ny += my
            # TODO 回転後の画像と前の画像の幅、高さの差の半分を引く
            new_points.append((int(nx), int(ny)))

        data = list(itertools.chain.from_iterable(new_points))
        data.insert(0, "card")
        annotations.append(data)
    #  -> 逆に台形補正をかける

    # ファイルに書き出す
    bgImg.save('test.jpg', quality=80)
    # アノテーションデータも書き出す。
    #  -> category,x1,y1...x4,y4
    with open("annotations.txt", "w") as f:
        for a in annotations:
            f.write("\t".join([str(v) for v in a]) + "\n")

    break

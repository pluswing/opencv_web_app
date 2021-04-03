# import cv2
import glob
from PIL import Image
import random

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
        x = random.randint(0, width - w)
        y = random.randint(0, height - h)
        bgImg.paste(img, (x, y))
        annotations.append(
            ["card", x, y, x+w, y, x+w, y+h, x, y+h]
        )
    #  -> 回転させる
    #  -> 逆に台形補正をかける

    # ファイルに書き出す
    bgImg.save('test.jpg', quality=80)
    # アノテーションデータも書き出す。
    #  -> category,x1,y1...x4,y4
    with open("annotations.txt", "w") as f:
        for a in annotations:
            f.write("\t".join([str(v) for v in a]) + "\n")

    break

import cv2
import glob

backgrounds = list(glob.glob("images/background/*"))
cards = list(glob.glob("images/cards/*"))

for i in range(1000):
  # 背景をランダムで選ぶ
  # カードをランダムで選ぶ（複数枚。何枚かもランダム）
  # 背景にカードを重ね合わせる(どこにはランダム)
  #  -> 回転させる
  #  -> 逆に台形補正をかける

  # ファイルに書き出す
  # アノテーションデータも書き出す。
  #  -> category,x1,y1...x4,y4

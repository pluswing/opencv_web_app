import cv2
import glob

for f in glob.glob("images/background/*"):
    img = cv2.imread(f)
    (height, width) = img.shape[:2]
    maxSize = 1024
    ratio = maxSize / max(height, width)
    size = (
        int(width * ratio),
        int(height * ratio)
    )
    resized = cv2.resize(img, size)
    cv2.imwrite(f, resized)

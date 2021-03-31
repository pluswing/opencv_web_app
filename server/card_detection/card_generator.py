import cv2

for i in range(100):
    img = cv2.imread("images/cards/card.jpg")
    font = cv2.FONT_HERSHEY_SIMPLEX
    cv2.putText(img, str(i), (200, 80), font,
                1, (0, 0, 0), 2, cv2.LINE_AA)
    cv2.imwrite(f"images/cards/card{i}.jpg", img)

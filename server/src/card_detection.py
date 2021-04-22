import torch
import torch.nn.functional as F
import cv2
import numpy as np
import os

from models import Darknet
from utils import non_max_suppression

IMAGE_SIZE = 608

ROOT_DIR = os.path.dirname(os.path.dirname(__file__))
CONFIG_PATH = os.path.join(ROOT_DIR, "data", "card_detection")

YOLO_FILE = os.path.join(CONFIG_PATH, "yolov3.cfg")
CHECKPINT_FILE = os.path.join(CONFIG_PATH, "latest.pt")


# resize a rectangular image to a padded square
def resize_square(img, height=416, color=(0, 0, 0)):
    shape = img.shape[:2]  # shape = [height, width]
    ratio = float(height) / max(shape)  # ratio  = old / new
    new_shape = [round(shape[0] * ratio), round(shape[1] * ratio)]
    dw = height - new_shape[1]  # width padding
    dh = height - new_shape[0]  # height padding
    top, bottom = dh // 2, dh - (dh // 2)
    left, right = dw // 2, dw - (dw // 2)
    # resized, no border
    img = cv2.resize(
        img, (new_shape[1], new_shape[0]), interpolation=cv2.INTER_AREA)
    return cv2.copyMakeBorder(img, top, bottom, left, right, cv2.BORDER_CONSTANT, value=color), ratio, dw // 2, dh // 2


def detect(image_path: str):
    torch.cuda.empty_cache()
    model = Darknet(YOLO_FILE, IMAGE_SIZE)
    checkpoint = torch.load(CHECKPINT_FILE, map_location='cpu')
    model.load_state_dict(checkpoint['model'])
    del checkpoint

    cuda = torch.cuda.is_available()
    device = torch.device('cuda:0' if cuda else 'cpu')
    model.to(device).eval()

    # load_images
    img = cv2.imread(image_path)
    img, _, _, _ = resize_square(
        img, height=IMAGE_SIZE, color=(127.5, 127.5, 127.5))
    img = img[:, :, ::-1].transpose(2, 0, 1)
    img = np.ascontiguousarray(img, dtype=np.float32)
    img /= 255.0

    with torch.no_grad():
        chip = torch.from_numpy(img).unsqueeze(0).to(device)
        pred = model(chip)
        pred = pred[pred[:, :, 8] > 0.1]

        detections = []
        if len(pred) > 0:
            detections = non_max_suppression(pred.unsqueeze(0), 0.1, 0.2)

        if len(detections) == 0:
            return []

        img = cv2.imread(image_path)

        # The amount of padding that was added
        pad_x = max(img.shape[0] - img.shape[1], 0) * \
            (IMAGE_SIZE / max(img.shape))
        pad_y = max(img.shape[1] - img.shape[0], 0) * \
            (IMAGE_SIZE / max(img.shape))
        # Image height and width after padding is removed
        unpad_h = IMAGE_SIZE - pad_y
        unpad_w = IMAGE_SIZE - pad_x

        cards = []

        for P1_x, P1_y, P2_x, P2_y, P3_x, P3_y, P4_x, P4_y, conf, cls_conf, cls_pred in detections[0]:
            P1_y = max((((P1_y - pad_y // 2) / unpad_h)
                        * img.shape[0]).round().item(), 0)
            P1_x = max((((P1_x - pad_x // 2) / unpad_w)
                        * img.shape[1]).round().item(), 0)
            P2_y = max((((P2_y - pad_y // 2) / unpad_h)
                        * img.shape[0]).round().item(), 0)
            P2_x = max((((P2_x - pad_x // 2) / unpad_w)
                        * img.shape[1]).round().item(), 0)
            P3_y = max((((P3_y - pad_y // 2) / unpad_h)
                        * img.shape[0]).round().item(), 0)
            P3_x = max((((P3_x - pad_x // 2) / unpad_w)
                        * img.shape[1]).round().item(), 0)
            P4_y = max((((P4_y - pad_y // 2) / unpad_h)
                        * img.shape[0]).round().item(), 0)
            P4_x = max((((P4_x - pad_x // 2) / unpad_w)
                        * img.shape[1]).round().item(), 0)

            cards.append({
                "points": [
                    (P1_x, P1_y),
                    (P2_x, P2_y),
                    (P3_x, P3_y),
                    (P4_x, P4_y)
                ],
                "points_score": conf.item(),
                "class_score": cls_conf.item(),
                "degree": [0, 90, 180, 270][int(cls_pred)],
            })

        return cards

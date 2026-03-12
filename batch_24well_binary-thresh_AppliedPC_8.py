import os
import datetime
import imutils
import time
import cv2
import csv
import glob
import os
import math
import numpy as np
import itertools as it
import multiprocessing
from pathlib import Path

videodir = 'D:/MJPEG/'
os.chdir(videodir)
files = glob.glob("*.avi")


for myvideo in files:
    myvideo = myvideo
    video = videodir+myvideo
    print("video=",video)

    os.system("python videoanalyzer_single_loop_ROI_F_binary-thresh_AppliedPC_8.py -v "+ myvideo)

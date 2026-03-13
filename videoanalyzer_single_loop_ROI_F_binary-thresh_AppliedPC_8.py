#!/usr/bin/python

# import the necessary packages
import argparse
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

# construct the argument parser and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-v", "--video", type=str, help="video name")
ap.add_argument("--threshold", type=int, default=13, help="threshold for image")
ap.add_argument("--threshold_diff", type=int, default=13, help="threshold for diff image (now used for live visualization only)")
args = vars(ap.parse_args())

# params
x_unit = 440 # pixel width for each well
y_unit = 440 # pixel height for each well
x_num = 6 # well number along x
y_num = 4 # well number along y
outdir = 'out/'
fmem = 40 # past frames used to estimate the true size of larva
radius_margin = 20 # margin for radius around larval center of gravity
filterUpdateFrames = 600 # "initialFrame" is updated every XXX frames
threshold_diff = 13

def videoanalyzer(wellID):
    # if outfile exits, skip
    if os.path.exists(outdir+args['video'].replace('.avi','_'+str(wellID)+'.csv')):
        return

    # params
    min_x = combinations[wellID][0]
    max_x = combinations[wellID][0] + x_unit
    min_y = combinations[wellID][1]
    max_y = combinations[wellID][1] + y_unit


    # Read data
    camera = cv2.VideoCapture(args['video'])

    # initialize the previous/ initial frame in the video stream
    previousFrame = None
    initialFrame = None
    mycenter = None
    mycenter_prev = None
    myradius_true = None
    dpixel = None

    # loop over the frames of the video
    myrecord = [[],[]]
    f_num = 0
    while True:
        # print(f_num)
        #########################
        # process grabbed frame
        #########################
        # grab the current frame
        (grabbed, frame) = camera.read()
        # print('camera_OK,wellID=',wellID,'f_num=',f_num)

        # if the frame could not be grabbed, then we have reached the end of the video
        if not grabbed:
            break

        # crop the frame, convert it to grayscale, flip BW, and blur it
        frame = frame[min_y:max_y, min_x:max_x]

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = 255 - gray
        gray = cv2.GaussianBlur(gray, (7, 7), 0)
        #clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        #gray = clahe.apply(gray)
        # print('subtract_OK')

        # if the previous/ initial frame is None, initialize it
        if previousFrame is None:
            previousFrame = gray
            mycenter_prev = mycenter
            continue
        if initialFrame is None:
            initialFrame = gray
            initialFrame_stock = gray
            continue

        #########################
        # get delta pixels around larva
        #########################
        # get frame-frame diff
        diff = cv2.subtract(previousFrame, gray)

        # threshold
        #thresh_df = diff #cv2.threshold(diff, args["threshold_diff"], 255, cv2.THRESH_BINARY)[1]
        thresh_df = cv2.threshold(diff, threshold_diff, 255, cv2.THRESH_TOZERO)[1]

        
        whole = np.sum(thresh_df)
        # record
        myrecord.append([[f_num],[whole]])
        
        # show the frame and record
        cv2.putText(frame, 'frame: '+str(f_num), (10,30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0,255,0), 2)
        cv2.putText(frame, 'well: '+str(wellID), (10,60), cv2.FONT_HERSHEY_SIMPLEX, 1, (0,255,0), 2)
        cv2.imshow("frame", frame)
        #cv2.imshow("thresh", thresh)
#        cv2.imshow("thresh_df", thresh_df)

        f_num += 1
        key = cv2.waitKey(1) & 0xFF

        # register the previousFrame
        previousFrame = gray
        mycenter_prev = mycenter

        # renew "initialframe" every 1h (but use 1h before this time point to prevent larva from temporarily disappearing
        if f_num%filterUpdateFrames==0:
            initialFrame = initialFrame_stock
            initialFrame_stock = gray

        # wait a bit (for better visibility. for debug only)
#        if f_num>150:
#            time.sleep(.5)

        # if the `q` key is pressed, break from the lop
        if key == ord("q"):
            break

    # cleanup the camera and close any open windows
    camera.release()
    cv2.destroyAllWindows()

    # Record the data table
    with open (outdir+args['video'].replace('.avi','_'+str(wellID)+'.csv'),"w") as fp:
        a = csv.writer(fp,delimiter=',')
        a.writerows(myrecord)
    return

##########################
# main
##########################
# prep ROIs
#mydict = {'min_ROI_x_set':[x_unit * i for i in range(x_num)], 'min_ROI_y_set':[y_unit * i for i in range(y_num)]}
mydict = {'min_ROI_x_set':[0,430,870,1310,1750,2180], 'min_ROI_y_set':[0,430,870,1310]}
#mydict = {'min_ROI_x_set':[0,430,870,1310], 'min_ROI_y_set':[0,430,870,1310,1750,2180]}
allnames = sorted(mydict)
combinations = list(it.product(*(mydict[name] for name in allnames)))

# prep outdir
Path(outdir).mkdir(exist_ok=True)

# prep parallel processing
if __name__ == '__main__':
    pool = multiprocessing.Pool(processes=8)
    pool.map(videoanalyzer, range(len(combinations)))

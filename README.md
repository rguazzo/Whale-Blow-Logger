# Whale-Blow-Logger
Created by Regina A. Guazzo
Scripps Institution of Oceanography

This code allows the user to play a video and log whale blows

Logged blows are saved in a csv file with pixel coordinates. ((0,0) is the top left corner of the video frame).  These detections can be further analyzed by the user.
The first two lines are the horizon coordinates.  The first line has the x coordinates and the second line has the y coordinates.
All the other lines have time of detection in the first column, then the x and y coordinates.  Time of detection is in Matlab datenum format (number of days from January 0, 0000).

Download the .m and .fig files to run through Matlab.  Run BlowDetectionGUI.m to begin.  The program will then allow you to open a .wav file and start by selecting the horizon.

To run without Matlab, download the executable file.

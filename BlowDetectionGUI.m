function varargout = BlowDetectionGUI(varargin)
% BLOWDETECTIONGUI MATLAB code for BlowDetectionGUI.fig
%      BLOWDETECTIONGUI, by itself, creates a new BLOWDETECTIONGUI or raises the existing
%      singleton*.
%
%      H = BLOWDETECTIONGUI returns the handle to a new BLOWDETECTIONGUI or the handle to
%      the existing singleton*.
%
%      BLOWDETECTIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BLOWDETECTIONGUI.M with the given input arguments.
%
%      BLOWDETECTIONGUI('Property','Value',...) creates a new BLOWDETECTIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BlowDetectionGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BlowDetectionGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BlowDetectionGUI

% Last Modified by GUIDE v2.5 04-Dec-2017 12:05:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BlowDetectionGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @BlowDetectionGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before BlowDetectionGUI is made visible.
function BlowDetectionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BlowDetectionGUI (see VARARGIN)
set(handles.playbutton,'Enable','off')
set(handles.pausebutton,'Enable','off')
set(handles.deletebutton,'Enable','off')
set(handles.markbutton,'Enable','off')
set(handles.timeslider,'Enable','off')
% Choose default command line output for BlowDetectionGUI
handles.output = hObject;

movegui(handles.figure1,'center')%center on screen

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BlowDetectionGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = BlowDetectionGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% handles.output.horizonx=handles.horizonx;
% handles.output.horizony=handles.horizony;
varargout{1} = handles.output;



% Executes when user presses the Open Button
function openbutton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to openbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[video_filename,video_filepath]=uigetfile({'*.mp4'},'Pick a video file');
if video_filepath==0
    return;
end
input_video_file=[video_filepath,video_filename];
set(handles.filename_text,'String',video_filename);%show file name at top of GUI

%Acquire Video
videoObject=VideoReader(input_video_file);

%Display First Frame
frame_1=read(videoObject,1);
axes(handles.axes1);
imshow(frame_1);
drawnow
axis(handles.axes1,'off');

%Show Start Time
TimeString=[video_filename(11:12),'/',video_filename(14:15),'/',video_filename(6:9),' ',video_filename(17:18),':',video_filename(20:21),':',video_filename(23:24)];
set(handles.EditTime,'String',TimeString)

%Ask User to Change File Name if necessary

OutputFile=OutputNamePopUp(video_filename);%open up pop up to ask user to edit file name
set(handles.FileOut,'String',OutputFile)


%Ask User to select two points on the horizon
set(handles.message,'String','Please select two points on either end of the horizon')
[horizonx,horizony]=ginput(2);
% xlswrite(get(handles.FileOut,'String'),[horizonx,horizony],1)
 fod = fopen(get(handles.FileOut,'String'),'w+');
fprintf(fod,'%f,%f\n', horizonx,horizony);
fclose(fod);

set(handles.message,'String','')

%Enable Play Button and slider
set(handles.playbutton,'Enable','on')
set(handles.timeslider,'Enable','on')
set(handles.timeslider,'Min',0)%set up slider
set(handles.timeslider,'Max',videoObject.Duration)
set(handles.timeslider,'SliderStep',[1/(videoObject.Duration-1), 10/(videoObject.Duration-1)])
set(handles.markbutton,'Enable','on')

%Update handles
handles.videoObject = videoObject;
handles.input_video_file=input_video_file;
handles.TimeString=TimeString;
handles.line=1;

guidata(hObject,handles);



% --- Executes on button press in playbutton.
function playbutton_Callback(hObject, eventdata, handles)
% hObject    handle to playbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume
format='mm/dd/yyyy HH:MM:SS';
starttime=datenum(handles.TimeString,format);

videoObject=VideoReader(handles.input_video_file);

set(handles.pausebutton,'Enable','on')%enable pause
set(handles.playbutton,'Enable','off')%disable play

axes(handles.axes1)
videoObject.CurrentTime=get(handles.timeslider,'value');

while hasFrame(videoObject)
    speedupfactor = str2double(get(handles.EditSpeed,'string')); %as this number decreases, the video speed increases
    skipSec = speedupfactor*1/videoObject.FrameRate-1/videoObject.FrameRate;%1 - framesPerSec/videoObject.FrameRate;

    % skip ahead some number of frames...don't plot them all as each frame
    % takes 26ms to read/plot...we wanna play these videos FAST
    videoObject.CurrentTime = videoObject.CurrentTime + skipSec;%This can cause a problem when it is forced to skip past the end of the video
    
%     fprintf('Time = %.6f, SkipSec = %.6f, framesPerSec = %d\n', videoObject.CurrentTime, skipSec, framesPerSec);
    vidFrame=readFrame(videoObject);
    imshow(vidFrame)
%    drawnow
    pause(1/videoObject.FrameRate-0.026);%if skipsec == 0, video should play at real time, subtracted 0.026 because this is the amount of time to read/plot frame
%     pause(1/(videoObject.FrameRate*str2num(get(handles.EditSpeed,'string'))))
   
   set(handles.timeslider,'value',videoObject.CurrentTime)
   set(handles.EditTime,'String',datestr(starttime+(videoObject.CurrentTime/24/3600),format))
   if videoObject.CurrentTime+skipSec>videoObject.Duration
       set(handles.playbutton,'Enable','on')%enable play
       set(handles.pausebutton,'Enable','off')%disable pause
       break
   end
end



function EditSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to EditSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditSpeed as text
%        str2double(get(hObject,'String')) returns contents of EditSpeed as a double
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function EditSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on slider movement.
function timeslider_Callback(hObject, eventdata, handles)
% hObject    handle to timeslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
format='mm/dd/yyyy HH:MM:SS';
starttime=datenum(handles.TimeString,format);
set(handles.EditTime,'String',datestr(starttime+get(handles.timeslider,'value')/24/3600,format))

videoObject=VideoReader(handles.input_video_file);
videoObject.CurrentTime=get(handles.timeslider,'value');
vidFrame=readFrame(videoObject);
    imshow(vidFrame)
     drawnow
     
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function timeslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function EditTime_Callback(hObject, eventdata, handles)
% hObject    handle to EditTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of EditTime as text
%        str2double(get(hObject,'String')) returns contents of EditTime as a double
format='mm/dd/yyyy HH:MM:SS';
starttime=datenum(handles.TimeString,format);
set(handles.timeslider,'value',(datenum(get(handles.EditTime,'String'),format)-starttime)*24*3600)

videoObject=VideoReader(handles.input_video_file);
videoObject.CurrentTime=get(handles.timeslider,'value');
vidFrame=readFrame(videoObject);
    imshow(vidFrame)
     drawnow
     
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function EditTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pausebutton.
function pausebutton_Callback(hObject, eventdata, handles)
% hObject    handle to pausebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% videoObject=VideoReader(handles.input_video_file);
% videoObject.CurrentTime=get(handles.timeslider,'value');
% vidFrame=readFrame(videoObject);
%     imshow(vidFrame)
%      drawnow
%      
% guidata(hObject,handles);
set(handles.playbutton,'Enable','on')%enable play
set(handles.pausebutton,'Enable','off')%disable pause
uiwait



% --- Executes on button press in markbutton.
function markbutton_Callback(hObject, eventdata, handles)
% hObject    handle to markbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.message,'String','Please select the base of the blow')
[blowx,blowy]=ginput(1);
% xlswrite(get(handles.FileOut,'String'),...
%     {get(handles.EditTime,'String'),blowx,blowy},2,['A',num2str(handles.line)])
fod = fopen(get(handles.FileOut,'String'),'a+');
fprintf(fod,'%.9f,%.9f,%.9f\n', datenum(get(handles.EditTime,'String'),'mm/dd/yyyy HH:MM:SS'), blowx,blowy);
fclose(fod);

set(handles.message,'String','')
set(handles.detectiontime,'String',get(handles.EditTime,'String'))

handles.line=handles.line+1;

set(handles.deletebutton,'Enable','on')%enable the delete button

guidata(hObject,handles);



% --- Executes on button press in deletebutton.
function deletebutton_Callback(hObject, eventdata, handles)
% hObject    handle to deletebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.line=handles.line-1;
M=dlmread(get(handles.FileOut,'String'));%read in the current data
M(end,:)=[];%delete last row
dlmwrite(get(handles.FileOut,'String'),M,'Precision','%.9f')
% xlswrite(get(handles.FileOut,'String'),...
%     {[],[],[]},2,['A',num2str(handles.line)])
% [~,lasttime,~]=xlsread('E:\Visual Data 2015/IR/IR_GUI/testdetections.xlsx',2,['A',num2str(handles.line-1)]);
[rows,~]=size(M);
if rows==2 %no detections, just deleted only detection
   set(handles.detectiontime,'String','No Detections')
else
    lasttime_num=M(end,1);
    lasttime=datestr(lasttime_num,'mm/dd/yyyy HH:MM:SS');
    set(handles.detectiontime,'String',lasttime)
end

guidata(hObject,handles)



% --- Executes during object creation, after setting all properties.
function FileOut_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function varargout = quality_flag(varargin)
% QUALITY_FLAG MATLAB code for quality_flag.fig
%      QUALITY_FLAG, by itself, creates a new QUALITY_FLAG or raises the existing
%      singleton*.
%
%      H = QUALITY_FLAG returns the handle to a new QUALITY_FLAG or the handle to
%      the existing singleton*.
%
%      QUALITY_FLAG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in QUALITY_FLAG.M with the given input arguments.
%
%      QUALITY_FLAG('Property','Value',...) creates a new QUALITY_FLAG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before quality_flag_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to quality_flag_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help quality_flag

% Last Modified by GUIDE v2.5 01-Oct-2015 23:28:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @quality_flag_OpeningFcn, ...
    'gui_OutputFcn',  @quality_flag_OutputFcn, ...
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

% --- Executes just before quality_flag is made visible.
function quality_flag_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to quality_flag (see VARARGIN)

if length(varargin) >= 1
    if class(varargin{1}) == 'timeseries'
        ts = varargin{1};
    else
        display('Must pass in timeseries!')
    end
else
    display('Must pass in timeseries!')
end
    
if length(varargin) >= 2
    handles.title = varargin{2};
else
    handles.title = 'quality_flag: Unnamed time series';
end

handles.ts = ts;
%handles.EKG = EKG;

set(handles.figure1, 'Name', ['quality_flag: ' handles.title]);
handles.fname_text.String = handles.title;

% Default radio button setting is 'Good'
% Assumes Good = 0, Bad = 1
handles.quality_mode = 1;

% Choose default command line output for quality_flag
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

refreshPlot(handles)
%UIWAIT makes quality_flag wait for user response (see UIRESUME)
uiwait(handles.figure1);




function refreshPlot(handles)

axes(handles.TimeSeriesAxes);

ts = handles.ts;

%draw gray rect over threshold area
plot(ts, 'LineStyle', 'none');
set(gca, 'XTick', ts.TimeInfo.Start:30:ts.TimeInfo.End);
grid on

hold on

bad_segs = find_segments(handles.ts.Quality, 1);
bad_time_segs = reshape(ts.Time(bad_segs), [], 2);

nrow = size(bad_time_segs, 1);
for i = 1:nrow
    ylim = get(gca, 'YLim');
    x = bad_time_segs(i,1);
    y = ylim(1);
    w = bad_time_segs(i,2) - bad_time_segs(i,1);
    h = ylim(2) - ylim(1);
    plot_rect = [ x y w h ];
    rectangle('Position', plot_rect , ...
        'FaceColor', [0.95, 0.95, 0.95],...
        'EdgeColor', 'none');
    
end

plot(ts);
hold off





% --- Outputs from this function are returned to the command line.
function varargout = quality_flag_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

% EKG = handles.EKG;
% EKG.RespQuality = handles.ts.Quality;
% EKG.RespQualityFlags = handles.ts.QualityInfo;
% 
% varargout{1} = EKG;

try 
    varargout{1} = handles.ts;
%    varargout{2} = handles.excludeFlag;
catch err
    disp(err.message);
end

delete(hObject)
 


% --- Executes on button press in buttonDone.
function buttonDone_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figure1_CloseRequestFcn(hObject, eventdata, handles)



% --- Executes on button press in buttonMark.
function buttonMark_Callback(hObject, eventdata, handles)
% hObject    handle to buttonMark (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.radioGood,'enable','off');
set(handles.radioBad,'enable','off');
set(handles.buttonMark,'enable','off');
rect = getrect();
set(handles.radioGood,'enable','on');
set(handles.radioBad,'enable','on');
set(handles.buttonMark,'enable','on');

ts = handles.ts;

t_start = rect(1);
t_end = rect(1) + rect(3);
t_range = (ts.Time >= t_start  & ts.Time <= t_end);
q = ts.Quality;
q(t_range) = handles.quality_mode;
ts.Quality = q;

% Update handles structure
handles.ts = ts;
guidata(hObject, handles);
% check_bad_segs = find_segments(handles.ts.Quality, 1)
% check_good_segs = find_segments(handles.ts.Quality, 0)


refreshPlot(handles);


% --- Executes when selected object is changed in FlagButtonGroup.
function FlagButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in FlagButtonGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'radioGood'
        %display('GOOD');
    	handles.quality_mode = 0;    
    case 'radioBad'
        %display('BAD');
       	handles.quality_mode = 1;
end

guidata(hObject, handles);


% --- Executes on mouse press over axes background.
function TimeSeriesAxes_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to TimeSeriesAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

display Click


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure

if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(gcbf);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end


% --- Executes during object creation, after setting all properties.
function fname_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fname_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

%hObject.text = handles.title;


% --- Executes during object deletion, before destroying properties.
function fname_text_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to fname_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

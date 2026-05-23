function varargout = PlotHypercube(varargin)
% PLOTHYPERCUBE MATLAB code for PlotHypercube.fig
%      PLOTHYPERCUBE, by itself, creates a new PLOTHYPERCUBE or raises the existing
%      singleton*.
%
%      H = PLOTHYPERCUBE returns the handle to a new PLOTHYPERCUBE or the handle to
%      the existing singleton*.
%
%      PLOTHYPERCUBE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTHYPERCUBE.M with the given input arguments.
%
%      PLOTHYPERCUBE('Property','Value',...) creates a new PLOTHYPERCUBE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PlotHypercube_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PlotHypercube_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PlotHypercube

% Last Modified by GUIDE v2.5 07-Mar-2022 18:11:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PlotHypercube_OpeningFcn, ...
                   'gui_OutputFcn',  @PlotHypercube_OutputFcn, ...
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


% --- Executes just before PlotHypercube is made visible.
function PlotHypercube_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PlotHypercube (see VARARGIN)

% Choose default command line output for PlotHypercube
global Cube f wl wn Nf maps actualColormap C autoscale aa n_images interval

handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PlotHypercube wait for user response (see UIRESUME)
% uiwait(handles.figure1);
f=varargin{1};
Cube=varargin{2};

C(1)=min(min(min(Cube)));
C(2)=max(max(max(Cube)));

n_images=1; %number of integrated images in the Cube for the plot

aa=1; %slider starting position

min_extreme_band=aa-ceil(n_images./2)+1;
if min_extreme_band<1
    min_extreme_band=1;
end
max_extreme_band=aa+floor(n_images./2);
if max_extreme_band>size(Cube,3)
    max_extreme_band=size(Cube,3);
end

interval=min_extreme_band:max_extreme_band; %starting interval for band intergal

set(handles.MinColor,'String',num2str(C(1)));
set(handles.MaxColor,'String',num2str(C(2)));

set(handles.N_Imag,'String',num2str(n_images));

maps={parula, hsv, hot, gray, bone, copper, pink, white, flag, lines,...
    colorcube, vga, jet, prism, cool, autumn, spring, winter, summer};

actualColormap=cell2mat(maps(2));

Nf=length(f);
Nc=size(Cube,3);

set(handles.sliderFrame,'Min',1);
set(handles.sliderFrame,'Max',Nf);

wl=3e8./(f*1e12)/1e-9; % wavelength [nm]
wn=(f*1e12)./3e8/100; % wavenumber [cm-1]

Cube_plot=Cube(:,:,interval);
imagesc(sum(Cube_plot,3), 'Parent',handles.Immagine);  axis equal; axis off; % era MAP
colorbar('peer',handles.Immagine); colormap(hsv);

autoscale=1-get(handles.ColorAuto,'Value');
if autoscale
    caxis(C);
end;

set(handles.nmValue,'String',[num2str(wl(aa)),' nm']);
set(handles.cmValue,'String',[num2str(wn(aa)),'/cm']);
set(handles.THzValue,'String',[num2str(f(aa)),' THz']);

set(handles.nmValueInterval,'String',[num2str(round(wl(aa)-wl(interval(1)),1,'decimals')),' nm \ ', '+', num2str(round(wl(aa)-wl(interval(end)),1,'decimals')),' nm']);
set(handles.cmValueInterval,'String',[num2str(round(-wn(aa)+wn(interval(1)),0,'decimals')),'/cm \ ', '+', num2str(round(-wn(aa)+wn(interval(end)),0,'decimals')),'/cm']);
set(handles.THzValueInterval,'String',[num2str(round(-f(aa)+f(interval(1)),1,'decimals')),' THz \ ', '+', num2str(round(-f(aa)+f(interval(end)),1,'decimals')),' THz']);




% --- Outputs from this function are returned to the command line.
function varargout = PlotHypercube_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on slider movement.
function sliderFrame_Callback(hObject, eventdata, handles)
% hObject    handle to sliderFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global f wn wl Cube actualColormap C autoscale aa n_images interval

aa=ceil(get(handles.sliderFrame,'Value')); % reads the slider value

min_extreme_band=aa-ceil(n_images./2)+1;
if min_extreme_band<1
    min_extreme_band=1;
end
max_extreme_band=aa+floor(n_images./2);
if max_extreme_band>size(Cube,3)
    max_extreme_band=size(Cube,3);
end

interval=min_extreme_band:max_extreme_band;

Cube_plot=Cube(:,:,interval);
imagesc(sum(Cube_plot,3), 'Parent',handles.Immagine); axis equal; axis off;
colormap(actualColormap); colorbar('peer',handles.Immagine);

if autoscale
    caxis(C);
end;

set(handles.nmValue,'String',[num2str(round(wl(aa))),' nm']);
set(handles.cmValue,'String',[num2str(round(wn(aa))),'/cm']);
set(handles.THzValue,'String',[num2str(round(f(aa))),' THz']);

set(handles.nmValueInterval,'String',[num2str(round(wl(aa)-wl(interval(1)),1,'decimals')),' nm \ ', '+', num2str(round(wl(aa)-wl(interval(end)),1,'decimals')),' nm']);
set(handles.cmValueInterval,'String',[num2str(round(-wn(aa)+wn(interval(1)),0,'decimals')),'/cm \ ', '+', num2str(round(-wn(aa)+wn(interval(end)),0,'decimals')),'/cm']);
set(handles.THzValueInterval,'String',[num2str(round(-f(aa)+f(interval(1)),1,'decimals')),' THz \ ', '+', num2str(round(-f(aa)+f(interval(end)),1,'decimals')),' THz']);



% --- Executes during object creation, after setting all properties.
function sliderFrame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end




% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% set(handles.yBottom,'String',num2str(handles.yBottom_val));
% set(handles.xRight,'String',num2str(handles.xRight_val));



% --- Executes during object creation, after setting all properties.
function Immagine_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Immagine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate Immagine



% --- Executes on selection change in ColormapMenu.
function ColormapMenu_Callback(hObject, eventdata, handles)
% hObject    handle to ColormapMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ColormapMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ColormapMenu

global maps Cube actualColormap C autoscale interval

color=get(handles.ColormapMenu,'Value');
actualColormap=cell2mat(maps(color));

Cube_plot=Cube(:,:,interval);
imagesc(sum(Cube_plot,3), 'Parent',handles.Immagine); axis equal;
colormap(actualColormap);  axis off; colorbar('peer',handles.Immagine);

if autoscale
    caxis(C);
end;

% --- Executes during object creation, after setting all properties.
function ColormapMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ColormapMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ColorAuto.
function ColorAuto_Callback(hObject, eventdata, handles)
% hObject    handle to ColorAuto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ColorAuto
global autoscale C

autoscale=1-get(handles.ColorAuto,'Value');

if autoscale
    set(handles.MinColor,'Enable','On');
    C(1)=str2num(get(handles.MinColor,'String'));

    set(handles.MaxColor,'Enable','On');
    C(2)=str2num(get(handles.MaxColor,'String'));
else
    set(handles.MinColor,'Enable','Off');
    set(handles.MaxColor,'Enable','Off');
end;

caxis(C);


function MinColor_Callback(hObject, eventdata, handles)
% hObject    handle to MinColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinColor as text
%        str2double(get(hObject,'String')) returns contents of MinColor as a double

global C

C(1)=str2num(get(handles.MinColor,'String'));
caxis(C);


% --- Executes during object creation, after setting all properties.
function MinColor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MaxColor_Callback(hObject, eventdata, handles)
% hObject    handle to MaxColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxColor as text
%        str2double(get(hObject,'String')) returns contents of MaxColor as a double

global C

C(2)=str2num(get(handles.MaxColor,'String'));
caxis(C);


% --- Executes during object creation, after setting all properties.
function MaxColor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in openFigure.
function openFigure_Callback(hObject, eventdata, handles)
% hObject    handle to openFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global Cube interval actualColormap

figure;
Cube_plot=Cube(:,:,interval);
imagesc(sum(Cube_plot,3)); axis equal; axis off;
colormap(actualColormap); colorbar;



function N_Imag_Callback(hObject, eventdata, handles)
% hObject    handle to N_Imag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of N_Imag as text
%        str2double(get(hObject,'String')) returns contents of N_Imag as a double

global Cube f wn wl actualColormap autoscale C n_images aa interval

n_images=str2num(get(handles.N_Imag,'String'));

if n_images<1 || (n_images~=floor(n_images)) %if n_images is 0 or negative or not integer
    n_images=1; %put it to 1
    set(handles.N_Imag,'String',num2str(n_images));
end

min_extreme_band=aa-ceil(n_images./2)+1;
if min_extreme_band<1
    min_extreme_band=1;
end
max_extreme_band=aa+floor(n_images./2);
if max_extreme_band>size(Cube,3)
    max_extreme_band=size(Cube,3);
end

interval=min_extreme_band:max_extreme_band;

Cube_plot=Cube(:,:,interval);
imagesc(sum(Cube_plot,3), 'Parent',handles.Immagine); axis equal; axis off;
colormap(actualColormap); colorbar('peer',handles.Immagine);

if autoscale
    caxis(C);
end;

set(handles.nmValueInterval,'String',[num2str(round(wl(aa)-wl(interval(1)),1,'decimals')),' nm \ ', '+', num2str(round(wl(aa)-wl(interval(end)),1,'decimals')),' nm']);
set(handles.cmValueInterval,'String',[num2str(round(-wn(aa)+wn(interval(1)),0,'decimals')),'/cm \ ', '+', num2str(round(-wn(aa)+wn(interval(end)),0,'decimals')),'/cm']);
set(handles.THzValueInterval,'String',[num2str(round(-f(aa)+f(interval(1)),1,'decimals')),' THz \ ', '+', num2str(round(-f(aa)+f(interval(end)),1,'decimals')),' THz']);


% --- Executes during object creation, after setting all properties.
function N_Imag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to N_Imag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

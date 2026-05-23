function varargout = ColorDisplay(varargin)
% COLORDISPLAY M-file for ColorDisplay.fig
%      COLORDISPLAY, by itself, creates a new COLORDISPLAY or raises the existing
%      singleton*.
%
%      H = COLORDISPLAY returns the handle to a new COLORDISPLAY or the handle to
%      the existing singleton*.
%
%      COLORDISPLAY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COLORDISPLAY.M with the given input arguments.
%
%      COLORDISPLAY('Property','Value',...) creates a new COLORDISPLAY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ColorDisplay_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ColorDisplay_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ColorDisplay

% Last Modified by GUIDE v2.5 14-Mar-2026 15:11:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ColorDisplay_OpeningFcn, ...
                   'gui_OutputFcn',  @ColorDisplay_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ColorDisplay is made visible.
function ColorDisplay_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ColorDisplay (see VARARGIN)

% Choose default command line output for ColorDisplay
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ColorDisplay wait for user response (see UIRESUME)
% uiwait(handles.ColorPanel);
global wl_color wl_source_A wl_source_D65 x_color y_color z_color A_source_color D65_source_color;
global NUM_CONTOURLEVELS;

NUM_CONTOURLEVELS=20;

path=which('Spectral_Fit.m');
L=length('Spectral_Fit.m');
path=path(1:end-L);

% temp=dlmread([path 'ColorMatchingFunctions_deg2.txt'],'\t');
% wl_color=temp(:,1);
% x_color=temp(:,2);
% y_color=temp(:,3);
% z_color=temp(:,4);
% clear temp;

temp=dlmread([path 'ColorMatchingFunctions_deg2.txt'],'\t');
wl_color=temp(:,1);
x_color=temp(:,2);
y_color=temp(:,3);
z_color=temp(:,4);
clear temp;
%figure,  plot(wl_color,x_color,'b',wl_color,y_color,'g',wl_color,z_color,'r')

temp=dlmread([path 'A_Source.txt'],'\t');
wl_source_A=temp(:,1);
A_source_color=temp(:,2);
clear temp;
%figure,  plot(wl_source_A,A_source_color,'k')

temp=dlmread([path 'D65_Source.txt'],'\t');
wl_source_D65=temp(:,1);
D65_source_color=temp(:,2);
clear temp;
%figure,  plot(wl_source_D65,D65_source_color,'k')



% --- Outputs from this function are returned to the command line.
function varargout = ColorDisplay_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in Calculate_Color.
function Calculate_Color_Callback(hObject, eventdata, handles)
% hObject    handle to Calculate_Color (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global wl_color wl_source_A wl_source_D65 x_color y_color z_color A_source_color D65_source_color;
global Sd WL data DataTypeOpt;
global AoiOn PosOK;
global XYZ xyL;
global rgbMap labMap;

WL_START=str2double(get(handles.WL_start,'String'));
if WL_START<400
    WL_START=400;
end
WL_END=str2double(get(handles.WL_end,'String'));
if WL_END>720
    WL_END=720;
end



b=sprintf(' Calcultaing color coord... ');
output_textColor(b);

temp=find(WL>=WL_START);
indexLow=temp(1);
clear temp;

temp=find(WL<=WL_END);
indexHigh=temp(end);
clear temp;

for (i=1:(indexHigh-indexLow))
    WL_step(i)=WL(i+1)-WL(i);
end
WL_step(i+1)= WL_step(i);

switch DataTypeOpt
    case 1 %Reflectance
        data_n=data(:,:,indexLow:indexHigh);
        %data_n=data;
    case 2 %Fluorescence
        maxIntensity=str2double(get(handles.MaxIntensityValue,'String'));
        data_n=data(:,:,indexLow:indexHigh)/maxIntensity;
end

x_color_interp=interp1(wl_color,x_color,WL(indexLow:indexHigh));
y_color_interp=interp1(wl_color,y_color,WL(indexLow:indexHigh));
z_color_interp=interp1(wl_color,z_color,WL(indexLow:indexHigh));
switch DataTypeOpt
    case 1 %Reflectance
        Illuminant_value=get(handles. Illuminant_type,'Value');
        switch Illuminant_value
            case 1
                source_color=D65_source_color;
                ref_X =  95.017;
                ref_Y = 100.000;
                ref_Z = 108.813;
                source_color_interp=interp1(wl_source_D65,source_color,WL(indexLow:indexHigh));

            case 2
                source_color=A_source_color;
                ref_X = 109.828;
                ref_Y = 100.000;
                ref_Z = 35.547;
                source_color_interp=interp1(wl_source_A,source_color,WL(indexLow:indexHigh));
        end;
    case 2 %Fluorescence
        source_color_interp=ones(size(WL(indexLow:indexHigh)));
end
kappa=100/sum(y_color_interp.*source_color_interp.*WL_step);
b=sprintf(' Calcultaing XYZ color coord... ');
output_textColor(b);

% ReshapedMask=reshape(ExportMask,dim1*dim2,1);
% PosOK=find(ReshapedMask==1);
% clear ReshapedMask;

data_n=reshape(data_n,Sd(1)*Sd(2),length(WL(indexLow:indexHigh)));

if AoiOn
    dataOK=data_n(PosOK,:);
else
    PosOK=ones(size(data_n,1),1);
    dataOK=data_n(PosOK,:);
end


clear data_n;

x_color_Matrix=repmat(x_color_interp,size(dataOK,1),1);
y_color_Matrix=repmat(y_color_interp,size(dataOK,1),1);
z_color_Matrix=repmat(z_color_interp,size(dataOK,1),1);
source_color_Matrix=repmat(source_color_interp,size(dataOK,1),1);
WL_step_Matrix=repmat(WL_step,size(dataOK,1),1);

clear x_color_interp y_color_interp z_color_interp source_color_interp;

X_OK=kappa*sum(x_color_Matrix.*dataOK.*source_color_Matrix.*WL_step_Matrix,2);
Y_OK=kappa*sum(y_color_Matrix.*dataOK.*source_color_Matrix.*WL_step_Matrix,2);
Z_OK=kappa*sum(z_color_Matrix.*dataOK.*source_color_Matrix.*WL_step_Matrix,2);

clear x_color_Matrix y_color_Matrix z_color_Matrix source_color_Matrix WL_step_Matrix;

X=NaN*ones(Sd(1)*Sd(2),1);
Y=NaN*ones(Sd(1)*Sd(2),1);
Z=NaN*ones(Sd(1)*Sd(2),1);

X(PosOK,:)=X_OK;
Y(PosOK,:)=Y_OK;
Z(PosOK,:)=Z_OK;

clear X_OK Y_OK Z_OK;

X=reshape(X,[Sd(1),Sd(2)]);
Y=reshape(Y,[Sd(1),Sd(2)]);
Z=reshape(Z,[Sd(1),Sd(2)]);

XYZ=zeros(Sd(1),Sd(2),3);
XYZ(:,:,1)=X;
XYZ(:,:,2)=Y;
XYZ(:,:,3)=Z;

b=sprintf(' Calcultaing xyz color coord... ');
output_textColor(b);
x=X./(X+Y+Z);
y=Y./(X+Y+Z);

xyL=zeros(Sd(1),Sd(2),3);
xyL(:,:,1)=x;
xyL(:,:,2)=y;
xyL(:,:,3)=Y;
clear x y;


b=sprintf(' Calcultaing RGB color coord... ');
output_textColor(b);
%XYZ to RGB
var_R_init= X/100*(+2.0413690) + Y/100*(-0.5649464) + Z/100*(-0.3446944);
var_G_init= X/100*(-0.9692660) + Y/100*(+1.8760108) + Z/100*(+0.0415560);
var_B_init= X/100*(+0.0134474) + Y/100*(-0.1183897) + Z/100*(1.01540960);

var_R=zeros(size(var_R_init));
var_G=var_R;
var_B=var_R;

var_R(var_R_init>0.0031308)=1.055*(var_R_init(var_R_init>0.0031308).^(1/2.4))-0.055;
var_R(var_R_init<=0.0031308)=12.92*var_R_init(var_R_init<=0.0031308);

var_G(var_G_init>0.0031308)=1.055*(var_G_init(var_G_init>0.0031308).^(1/2.4))-0.055;
var_G(var_G_init<=0.0031308)=12.92*var_G_init(var_G_init<=0.0031308);

var_B(var_B_init>0.0031308)=1.055*(var_B_init(var_B_init>0.0031308).^(1/2.4))-0.055;
var_B(var_B_init<=0.0031308)=12.92*var_B_init(var_B_init<=0.0031308);


numpixel_r=length(find(or(var_R<0,var_R>1)));
numpixel_g=length(find(or(var_G<0,var_G>1)));
numpixel_b=length(find(or(var_B<0,var_B>1)));
numErroneousPixel=numpixel_r+numpixel_g+numpixel_b;

var_R=min(var_R,ones(size(var_R)));
var_R=max(var_R,zeros(size(var_R)));

var_G=min(var_G,ones(size(var_G)));
var_G=max(var_G,zeros(size(var_G)));

var_B=min(var_B,ones(size(var_B)));
var_B=max(var_B,zeros(size(var_B)));

if numErroneousPixel>(Sd(1)*Sd(2)/100)
    b=sprintf('Warning: number of clipped pixel > 1%% of image size');
    output_textColor(b);
end

rgbMap=zeros(Sd(1),Sd(2),3);
rgbMap(:,:,1)=var_R;
rgbMap(:,:,2)=var_G;
rgbMap(:,:,3)=var_B;
clear var_R_init var_G_init var_B_init var_R var_G var_B;


b=sprintf(' Calcultaing La*b* color coord... ');
output_textColor(b);

%XYZ to CIEL*a*b*
switch DataTypeOpt
    case 1 %Reflectance
        var_X = X / ref_X ;
        var_Y = Y / ref_Y ;
        var_Z = Z / ref_Z ;
    case 2 %Fluorescence
        var_X = X;
        var_Y = Y;
        var_Z = Z;
end
clear X Y Z;

var_X(var_X>0.008856) = var_X(var_X>0.008856).^(1/3);
var_X(var_X<=0.008856) = 7.787*var_X(var_X<=0.008856)+16/116;

var_Y(var_Y>0.008856) = var_Y(var_Y>0.008856).^(1/3);
var_Y(var_Y<=0.008856) = 7.787*var_Y(var_Y<=0.008856)+16/116;

var_Z(var_Z>0.008856) = var_Z(var_Z>0.008856).^(1/3);
var_Z(var_Z<=0.008856) = 7.787*var_Z(var_Z<=0.008856)+16/116;

labMap=zeros(Sd(1),Sd(2),3);
CIE_L = 116*var_Y-16;
CIE_a = 500*(var_X-var_Y);
CIE_b = 200*(var_Y-var_Z);
labMap(:,:,1)=CIE_L;
labMap(:,:,2)=CIE_a;
labMap(:,:,3)=CIE_b;

clear CIE_L CIE_a CIE_b;


b=sprintf(' Calcultaing color coord... done');
output_textColor(b);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in Display.
function Display_Callback(hObject, eventdata, handles)
% hObject    handle to Display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global XYZ xyL;
global rgbMap labMap;
global colorMap;
global handleRGBMap handleCOLORMaps;

Color_value=get(handles. Color_type,'Value');
switch Color_value
    case 1
        colorMap=XYZ;
    case 2
        colorMap=xyL;
    case 3
        colorMap=labMap;
    case 4
        colorMap=rgbMap;               
end; 
handleRGBMap=figure;
imagesc(rgbMap), axis image;

handleCOLORMaps=figure;
for (i=1:3)
    subplot(3,1,i)
    imagesc(colorMap(:,:,i)), colormap(gray), colorbar, axis image;
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in Rescale_ColorMaps.
function Rescale_ColorMaps_Callback(hObject, eventdata, handles)
% hObject    handle to Rescale_ColorMaps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% global XYZ xyL;
% global rgbMap labMap;
global colorMap;

AnalysisMap=colorMap;
axes(handles.axes1);
mappa=AnalysisMap(:,:,1);

rescaleOption=get(handles.rescaleSelection,'Value');
if rescaleOption==0,
    [ClLow,ClHigh]=rescale_figure(mappa);
else
    ClLow=str2double(get(handles.rescaleMin,'String'));
    ClHigh=str2double(get(handles.rescaleMax,'String'));
end;
ClipValues = [ClLow ClHigh];
set(gca,'Clim',ClipValues);
colorbar;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Cl_Low,Cl_High]=rescale_figure(W)
% Rescale the colormap of an image based on a rectangle
if isempty(W),
    return
end
% Get Current Axis
sw=1;
while sw
    [x,y]=ginput(2);
    x=round(x);
    y=round(y);
    if (x>0)&(y>0)&(x<=size(W,2))&(y<=size(W,1))
        sw=0;
    end
end
Max=max(max(W(min(y):max(y),min(x):max(x))));
Min=min(min(W(min(y):max(y),min(x):max(x))));
Cl_High=Max;
Cl_Low=Min;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in Hist_ColorMaps.
function Hist_ColorMaps_Callback(hObject, eventdata, handles)
% hObject    handle to Hist_ColorMaps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global colorMap;
axes(handles.axes1);
choice=get(handles.MapToBeRescaled,'Value');
mappa=colorMap(:,:,1);

[x,y]=ginput(2);
x=round(x);
y=round(y);
Aoi=mappa(min(y):max(y),min(x):max(x));

[average,stdDev]=hist_figure(Aoi);

Buffer=sprintf('Average=%11.2f +/- %8.2f (%6.2f %%)',average,stdDev,stdDev/average*100);
h=text(1,1,Buffer);
set(h,'Units','Normalized');
set(h,'Position',[0.2 0.95]);
output_textColor(Buffer);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [avW,stdW]=hist_figure(W)
% Calculate the image histogram
% Check the figure
if isempty(W),
   return
end
figure;
VECTOR=reshape(W,1,size(W,1)*size(W,2));
% VECTOR=VECTOR(find(not(VECTOR==0)));
% VECTOR=VECTOR(not(isnan(VECTOR)));

% M=min(VECTOR)+(0:255).*((max(VECTOR)-min(VECTOR))/255);
M=min(1000,max(VECTOR)-min(VECTOR));
[n,xout]=hist(VECTOR,M);
bar(xout,n);
avW=mean(VECTOR);
stdW=std(VECTOR);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in Average_ColorMaps.
function Average_ColorMaps_Callback(hObject, eventdata, handles)
% hObject    handle to Average_ColorMaps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Average_ColorMaps
global colorMap;

choice=get(handles.MapToBeRescaled,'Value');
switch choice
    case 1
        axes(handles.axes1);
    case 2
        axes(handles.axes2);
    case 3
        axes(handles.axes3);
end;        

[x,y]=ginput(2);
x=round(x);
y=round(y);
aoi=colorMap(min(y):max(y),min(x):max(x),:);
[average,stdDev]=average_figure(aoi);
Buffer='';
for(i=1:3)
    Buffer=[Buffer;sprintf('Choord %d: Average=%11.2f +/- %8.2f (%6.2f%%)',i,average(i),stdDev(i),stdDev(i)/average(i)*100)];
end
output_textColor(Buffer);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [avW,stdW]=average_figure(aoi)
avW=zeros(3,1);
stdW=avW;
for i=1:3
    W=squeeze(aoi(:,:,i));
    VECTOR=reshape(W,1,size(W,1)*size(W,2));
    avW(i)=nanmean(VECTOR);
    stdW(i)=nanstd(VECTOR);
    clear W VECTOR;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Zoom_ColorMaps_Callback(hObject, eventdata, handles)
% hObject    handle to Zoom_ColorMaps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Zoom_ColorMaps
      
axes(handles.axes1);
ZoomOn = get(hObject, 'Value');
if ZoomOn
    zoom on
else
    zoom off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in PlotAllData.
function PlotAllData_Callback(hObject, eventdata, handles)
% hObject    handle to PlotAllData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global WL data DataTypeOpt Mask indexLow indexHigh;
global normalizationOn;

WL_START=str2double(get(handles.WL_start,'String'));
WL_END=str2double(get(handles.WL_end,'String'));
[dim1,dim2,dim3]=size(data);
clear dim3;

ReshapedMask=reshape(Mask,dim1*dim2,1);
PosOK=find(ReshapedMask==1);
clear ReshapedMask;

temp=find(WL>=WL_START);
indexLow=temp(1);
clear temp;

temp=find(WL<=WL_END);
indexHigh=temp(end);
clear temp;

dataMatrix=reshape(data,dim1*dim2,length(WL(indexLow:indexHigh)));
dataOK=dataMatrix(PosOK,:);

if normalizationOn
    temp=zeros(size(dataOK));
    N=size(dataOK,1);
    for i=1:N
        temp(i,:)=dataOK(i,:)/max(dataOK(i,:));
    end
    dataOK=temp;
end
%sd=size(data);
%dataMatrix=reshape(data,sd(1)*sd(2),sd(3));
%figure, boxplot(dataMatrix);

% figure, boxplot(dataOK);
% set(gca,'XTick',[1 size(dataOK,2)]);
% set(gca,'XTickLabel',[WL(1) WL(end)]);
% xlabel('Wavelength (nm)');
% switch DataTypeOpt
%     case 1 %Reflectance
%         set(gca,'YLim',[0 1]);
%         ylabel('Reflectance factor');
%     case 2 % Fluorescence
%         fixOn=get(handles.rescaleSelection,'Value');
%         if fixOn
%             YMin=str2double(get(handles.rescaleMin,'String'));
%             YMax=str2double(get(handles.rescaleMax,'String'));
%             set(gca,'Ylim',[YMin YMax]);
%         end
%         ylabel('Emission intensity (a.u.)');
% end

figure, errorbar(WL(indexLow:indexHigh),nanmean(dataOK),nanstd(dataOK));
xlabel('Wavelength (nm)');
switch DataTypeOpt
    case 1 %Reflectance
        set(gca,'YLim',[0 1]);
        ylabel('Reflectance factor');
    case 2 % Fluorescence
        fixOn=get(handles.rescaleSelection,'Value');
        if fixOn
            YMin=str2double(get(handles.rescaleMin,'String'));
            YMax=str2double(get(handles.rescaleMax,'String'));
            set(gca,'Ylim',[YMin YMax]);
        end
        ylabel('Emission intensity (a.u.)');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in normalizationOn.
function normalizationOn_Callback(hObject, eventdata, handles)
% hObject    handle to normalizationOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of normalizationOn
global normalizationOn;
normalizationOn=get(hObject,'Value');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in firstDerivativeOn.
function firstDerivativeOn_Callback(hObject, eventdata, handles)
% hObject    handle to firstDerivativeOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of firstDerivativeOn
global firstDerivativeOn;
firstDerivativeOn=get(hObject,'Value');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in PlotData.
function PlotData_Callback(hObject, eventdata, handles)
% hObject    handle to PlotData (see GCBO)
% eventdata  rese5rved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global WL data DataTypeOpt;
global WL_DER data_DER;
global data_ABSORBANCE;

global data_Single data_Single_std data_Single_n data_Single_std_n;
global normalizationOn;
global AbsorbanceOn;
global hRect;
global handleRGBMap handleFigureSimilarityMap handleSegmentedImage hCompositeRGBFig;
global DerivativeOn;
global IMG_Main;



WL_START=str2double(get(handles.WL_start,'String'));
WL_END=str2double(get(handles.WL_end,'String'));

temp=find(WL>=WL_START);
indexLow=temp(1);
clear temp;

temp=find(WL<=WL_END);
indexHigh=temp(end);
clear temp;

colors={'k' 'r' 'g' 'b'};
style={'-k' '-r' '-g' '-b'};
style_DER={'--k' '--r' '--g' '--b'};

selectionNum=str2double(get(handles.SelectionNum,'String'));

data_Single=zeros(selectionNum,length(WL));
data_Single_std=zeros(selectionNum,length(WL));

if AbsorbanceOn
    data_Absorbance_Single=zeros(selectionNum,length(WL));
    data_Absorbance_Single_std=zeros(selectionNum,length(WL));
end

if DerivativeOn
    data_firstDerivative_Single=zeros(selectionNum,length(WL_DER));
end

if DataTypeOpt==3 %EEM
    global Xaxis Yaxis;
    figure, imagesc(Xaxis,Yaxis,IMG_Main); axis xy; axis image, colormap(jet), colorbar;
    xlabel('Emission wavelength /nm'), ylabel('Excitation wavelength /nm'),colormap(jet);
    h=gca;
else
    choice=get(handles.FigOptForPlotSelection,'Value');
    switch choice
        case 1
            h=handles.axes1;
        case 2
            figure(handleRGBMap);
            h=gca;
        case 3
            figure(handleFigureSimilarityMap);
            h=gca;
        case 4
            figure(handleSegmentedImage);
            h=gca;
        case 5
            figure(hCompositeRGBFig);
            h=gca;
    end
end
axes(h);
for i=1:selectionNum
    datacursormode on;
    [AOI, x, y] = roipoly();
    line(x,y,'Color',colors{i});
    AOI_1D=reshape(AOI,size(AOI,1)*size(AOI,2),1);
    data_2D=reshape(data,size(data,1)*size(data,2),size(data,3));
    temp_2D=data_2D(AOI_1D,:);

    if AbsorbanceOn
        data_ABSORBANCE_2D=reshape(data_ABSORBANCE,size(data,1)*size(data,2),size(data,3));
        temp_ABSORBANCE_2D=data_ABSORBANCE_2D(AOI_1D,:);
    end
    if DerivativeOn
        data_DER_2D=reshape(data_DER,size(data,1)*size(data,2),size(data_DER,3));
        temp_DER_2D=data_DER_2D(AOI_1D,:);
    end
    datacursormode off;
    data_Single(i,:)=mean(temp_2D,1,'omitnan');
    data_Single_std(i,:)=std(temp_2D,1,'omitnan');
    
    if AbsorbanceOn
        data_Absorbance_Single(i,:)=mean(temp_ABSORBANCE_2D,1,'omitnan');
        data_Absorbance_Single_std(i,:)=std(temp_ABSORBANCE_2D,1,'omitnan');
            end
    if DerivativeOn
        data_firstDerivative_Single(i,:)=mean(temp_DER_2D,1,'omitnan');
    end
end

WL_subset=WL(indexLow:indexHigh);
WL_temp = [WL_subset, fliplr(WL_subset)];

data_Single=data_Single(:,indexLow:indexHigh);
data_Single_std=data_Single_std(:,indexLow:indexHigh);
data_Single_H= data_Single + data_Single_std;
data_Single_L = data_Single - data_Single_std;
inBetween = [data_Single_H, fliplr(data_Single_L)];

if AbsorbanceOn
    data_Absorbance_Single=data_Absorbance_Single(:,indexLow:indexHigh);
    data_Absorbance_Single_std=data_Absorbance_Single_std(:,indexLow:indexHigh);
    data_Absorbance_Single_H = data_Absorbance_Single + data_Absorbance_Single_std;
    data_Absorbance_Single_L = data_Absorbance_Single - data_Absorbance_Single_std;
    inBetween_Absorbance= [data_Absorbance_Single_H, fliplr(data_Absorbance_Single_L)];

end
if normalizationOn
    data_Single_n=zeros(selectionNum,length(WL_subset));
    data_Single_std_n=zeros(selectionNum,length(WL_subset));
    for i=1:selectionNum
        data_Single_n(i,:)=data_Single(i,:)./max(data_Single(i,:));
        data_Single_std_n(i,:)=data_Single_std(i,:)./max(data_Single(i,:));
    end
    data_Single_H_n= data_Single_n + data_Single_std_n;
    data_Single_L_n = data_Single_n - data_Single_std_n;
    inBetween_n = [data_Single_H_n, fliplr(data_Single_L_n)];

end

if DerivativeOn
    temp=find(WL_DER>=WL_START);
    indexLow=temp(1);
    clear temp;

    temp=find(WL_DER<=WL_END);
    indexHigh=temp(end);
    clear temp;

    WL_DER_subset=WL_DER(indexLow:indexHigh);
    data_firstDerivative_Single=data_firstDerivative_Single(:,indexLow:indexHigh);
end


errorbarOn=get(handles.errorbarOn,'Value');

if AbsorbanceOn
    figure
    if errorbarOn
        for i=1:selectionNum
            yyaxis left;
            plot(WL_subset,data_Single(i,:),style{i},'LineWidth',2), hold on;
            fill(WL_temp, inBetween(i,:), colors{i},'FaceAlpha',.3,'EdgeColor','none');

            hold on;
            yyaxis right;
            plot(WL_subset,data_Absorbance_Single(i,:),style_DER{i},'LineWidth',2), hold on;
            fill(WL_temp, inBetween_Absorbance(i,:), colors{i},'FaceAlpha',.3,'EdgeColor','none');
        end
    else
        for i=1:selectionNum
            yyaxis left;
            plot(WL_subset,data_Single(i,:),style{i},'LineWidth',2);
            hold on;
            yyaxis right;
            plot(WL_subset,data_Absorbance_Single(i,:),style_DER{i},'LineWidth',2), hold on;            
        end
    end
    yyaxis right;
    ylabel('K/S')    
    xlabel('Wavelength (nm)');
    set(gca,'XLim',[WL_subset(1) WL_subset(end)]);    
end

figure;
if normalizationOn
    subplot(2,1,1);
end

if errorbarOn
    for i=1:selectionNum
        yyaxis left;
        plot(WL_subset,data_Single(i,:),style{i},'LineWidth',2), hold on;
        fill(WL_temp, inBetween(i,:), colors{i},'FaceAlpha',.3,'EdgeColor','none');
        hold on;
        if DerivativeOn            
            yyaxis right;
            plot(WL_DER_subset(1:end),data_firstDerivative_Single(i,:),style_DER{i},'LineWidth',2), hold on;
            ylabel('Derivative as a function of wavelength')
        end
    end
    if normalizationOn
        subplot(2,1,2);
        for i=1:selectionNum
            plot(WL_subset,data_Single_n(i,:),style{i},'LineWidth',2), hold on;
            fill(WL_temp, inBetween_n(i,:), colors{i},'FaceAlpha',.3,'EdgeColor','none');
            hold on;
        end
    end
else    
    for i=1:selectionNum
        yyaxis left;
        plot(WL_subset,data_Single(i,:),style{i},'LineWidth',2);
        hold on;
        if DerivativeOn
            yyaxis right;
            plot(WL_DER_subset(1:end),data_firstDerivative_Single(i,:),style_DER{i},'LineWidth',2), hold on;
        end
    end
    if normalizationOn
        subplot(2,1,2);
        for i=1:selectionNum
            plot(WL_subset,data_Single_n(i,:),style{i},'LineWidth',2);
            hold on;
        end
    end
end

if normalizationOn
    subplot(2,1,1);
end
grid on;
xlabel('Wavelength (nm)');
set(gca,'XLim',[WL_subset(1) WL_subset(end)]);
yyaxis left;
switch DataTypeOpt
    case 1 %Reflectance
        %         set(gca,'YLim',[0 1]);
        ylabel('Reflectance');
    case 2 % Fluorescence
        fixOn=get(handles.rescaleSelection,'Value');
        if fixOn
            YMin=str2double(get(handles.rescaleMin,'String'));
            YMax=str2double(get(handles.rescaleMax,'String'));
            set(gca,'Ylim',[YMin YMax]);
        end
        ylabel('Emission intensity (a.u.)');
end

if normalizationOn
    subplot(2,1,2);
    grid on;
    xlabel('Wavelength (nm)');
    set(gca,'XLim',[WL_subset(1) WL_subset(end)]);
    yyaxis left;
    set(gca,'YLim',[0 1]);
    ylabel('Normalized Emission intensity');
end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in ExportPlotData.
function ExportPlotData_Callback(hObject, eventdata, handles)
% hObject    handle to ExportPlotData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global WL_interp data_Single data_Single_std data_Single_n data_Single_std_n;
global normalizationOn;

[outputDataFilename, outputDataPathname, flag] = uiputfile('*.txt', 'save PLOT data');
if flag==0
else   
    if normalizationOn
        DataToExport=[WL_interp' data_Single_n' data_Single_std_n'];
    else
        DataToExport=[WL_interp' data_Single' data_Single_std'];
    end
    dlmwrite([outputDataPathname outputDataFilename],DataToExport,'\t');
end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output_textColor(buffer)

handle=findobj(gcbf,'Tag','ColorText');
set(handle,'String',buffer); 
drawnow;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in Print_Map.
function Print_Map_Callback(hObject, eventdata, handles)
% hObject    handle to Print_Map (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[PrintFilename, PrintPathname, flag]= uiputfile('*.jpg', 'print JPG figure');

if flag==0
    return;
end

mapSelected=get(handles.listboxPrintMap,'Value');
switch mapSelected
    case 1
        h=handles.axes1;       
        immagine=get(get(h,'Children'),'CData');
        Limiti=get(h,'CLim');
        PrintFigureHn=figure; imagesc(immagine), axis image;
        set(gca,'Clim',Limiti);
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
        colormap(gray), title('Color choord 1 (a.u.)','Units','Normalized','FontSize',12,'FontWeight','Bold');
        MxLabel=sprintf(' Max\n%.0f',Limiti(2));
        MnLabel=sprintf(' Min\n%.0f',Limiti(1));
        text(+1.02,0.8,MxLabel,'Units','Normalized','FontSize',12,'FontWeight','Bold');
        text(+1.02,0.2,MnLabel,'Units','Normalized','FontSize',12,'FontWeight','Bold');

    case 2
        h=handles.axes2;
        immagine=get(get(h,'Children'),'CData');
        Limiti=get(h,'CLim');
        PrintFigureHn=figure;
        imagesc(immagine), axis image;
        set(gca,'Clim',Limiti);
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
        colormap(gray), title('Color choord 2 (a.u.)','Units','Normalized','FontSize',12,'FontWeight','Bold');
        MxLabel=sprintf(' Max\n%.0f',Limiti(2));
        MnLabel=sprintf(' Min\n%.0f',Limiti(1));
        text(+1.02,0.8,MxLabel,'Units','Normalized','FontSize',12,'FontWeight','Bold');
        text(+1.02,0.2,MnLabel,'Units','Normalized','FontSize',12,'FontWeight','Bold');

    case 3
        h=handles.axes3;
        immagine=get(get(h,'Children'),'CData');
         Limiti=get(h,'CLim');
        PrintFigureHn=figure;
        imagesc(immagine), axis image;
        set(gca,'Clim',Limiti);
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
        colormap(gray), title('Color choord 3 (a.u.)','Units','Normalized','FontSize',12,'FontWeight','Bold');
        MxLabel=sprintf(' Max\n%.0f',Limiti(2));
        MnLabel=sprintf(' Min\n%.0f',Limiti(1));
        text(+1.02,0.8,MxLabel,'Units','Normalized','FontSize',12,'FontWeight','Bold');
        text(+1.02,0.2,MnLabel,'Units','Normalized','FontSize',12,'FontWeight','Bold');

    case 4
        h=handles.axesRGB;
        immagine=get(get(h,'Children'),'CData');
        PrintFigureHn=figure;
        imagesc(immagine), axis image;
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
        title('RGB color map','Units','Normalized','FontSize',12,'FontWeight','Bold');

    case 5        
        h=handles.axes1;
        immagine=get(get(h,'Children'),'CData');
        Limiti=get(h,'CLim');
        PrintFigureHn=figure('Units','Normalized','Position',[0.3 0.05 0.4 0.85]);
        subplot('Position',[0.20 0.67 0.6 0.28]);
        subimage(mat2gray(immagine,Limiti)), title('Color choord 1 (a.u.)','Units','Normalized','FontSize',8,'FontWeight','Bold'), axis image;
        set(gca,'Clim',Limiti);
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
        MxLabel=sprintf(' Max\n%.0f',Limiti(2));
        MnLabel=sprintf(' Min\n%.0f',Limiti(1));
        text(+1.05,0.8,MxLabel,'Units','Normalized','FontSize',8,'FontWeight','Bold')
        text(+1.05,0.2,MnLabel,'Units','Normalized','FontSize',8,'FontWeight','Bold')

        h=handles.axes2;
        immagine=get(get(h,'Children'),'CData');
        Limiti=get(h,'CLim');  
        figure(PrintFigureHn);
        subplot('Position',[0.20 0.35 0.6 0.28]);
        subimage(mat2gray(immagine,Limiti)), title('Color choord 2 (a.u.)','Units','Normalized','FontSize',8,'FontWeight','Bold'),  axis image;
        set(gca,'Clim',Limiti);
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
        MxLabel=sprintf(' Max\n%.0f',Limiti(2));
        MnLabel=sprintf(' Min\n%.0f',Limiti(1));
        text(+1.05,0.8,MxLabel,'Units','Normalized','FontSize',8,'FontWeight','Bold')
        text(+1.05,0.2,MnLabel,'Units','Normalized','FontSize',8,'FontWeight','Bold')

        h=handles.axes3;
        immagine=get(get(h,'Children'),'CData');
        Limiti=get(h,'CLim');  
        figure(PrintFigureHn);
        subplot('Position',[0.20 0.03 0.6 0.28]);
        subimage(mat2gray(immagine,Limiti)), title('Color choord 3 (a.u.)','Units','Normalized','FontSize',8,'FontWeight','Bold'), axis image;
        set(gca,'Clim',Limiti);
        set(gca,'XTickLabel',[]);
        set(gca,'YTickLabel',[]);
        MxLabel=sprintf(' Max\n%.0f',Limiti(2));
        MnLabel=sprintf(' Min\n%.0f',Limiti(1));
        text(+1.05,0.8,MxLabel,'Units','Normalized','FontSize',8,'FontWeight','Bold')
        text(+1.05,0.2,MnLabel,'Units','Normalized','FontSize',8,'FontWeight','Bold')

end

NamePrint=[PrintPathname PrintFilename];

print(PrintFigureHn,'-djpeg100',NamePrint);
saveas(PrintFigureHn,NamePrint(1:end-4),'fig')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in PCA.
function listboxPrintMap_Callback(hObject, eventdata, handles)
% hObject    handle to PCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in CalcDeltaE.
function CalcDeltaE_Callback(hObject, eventdata, handles)
% hObject    handle to CalcDeltaE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global labMap;

axes(handles.axesRGB);

[x,y]=ginput(2);
x=round(x);
y=round(y);
aoi=labMap(min(y):max(y),min(x):max(x),:);
[average,stdDev]=average_figure(aoi);
L=average(1);
a=average(2);
b=average(3);

Illuminant_type=get(handles.Illuminant_type,'Value');
SpComparison=get(handles.SpectralonComparisonOpt,'Value');
switch SpComparison
    case 1 %RED
        if Illuminant_type==1 %D65
%             L_ref=47.28;
%             a_ref=56.08;
%             b_ref=28.11;
            L_ref=47.297;
            a_ref=56.041;
            b_ref=28.153;
        elseif Illuminant_type==2 %A
            L_ref=54.61;
            a_ref=60.72;
            b_ref=40.73;
        end
    case 2 %GREEN
        if Illuminant_type==1 %D65
            L_ref=62.81;
            a_ref=-33.17;
            b_ref=16.28;
        elseif Illuminant_type==2 %A
            L_ref=60.51;
            a_ref=-27.34;
            b_ref=9.00;
        end
    case 3 %BLUE
        if Illuminant_type==1 %D65
            L_ref=56.00;
            a_ref=4.12;
            b_ref=-45.65;
        elseif Illuminant_type==2 %A
            L_ref=52.21;
            a_ref=-7.31;
            b_ref=-51.21;
        end
    case 4 %YELLOW
        if Illuminant_type==1 %D65
            L_ref=88.83;
            a_ref=2.36;
            b_ref=78.89;
        elseif Illuminant_type==2 %A
            L_ref=92.14;
            a_ref=11.23;
            b_ref=81.13;
        end
end

DeltaE_opt=get(handles.DeltaE_opt,'Value');
switch DeltaE_opt
    case 1 %CIE 1976
      DeltaE=((L_ref-L)^2+(a_ref-a)^2+(b_ref-b)^2)^0.5; 
      DeltaL=L-L_ref
      Deltaa=a-a_ref
      Deltab=b-b_ref
%         DeltaE=((a_ref-a)^2+(b_ref-b)^2)^0.5;  
    case 2 %CIE 1994
        c=(a^2+b^2)^0.5;
        c_ref=(a_ref^2+b_ref^2)^0.5;
        
        K1=0.045 %for graphic_art; k_1=0.048 for textiles; 
        K2=0.015 %for graphic_art; k_2=0.016 for textiles;
        KC=1;
        KH=1;
        KL=1; %default; KL=2 for textiles;
        SL=1;
        SC=1+K1*c;
        SH=1+K2*c;                
       
        Delta_c=c-c_ref;
        Delta_a=a_ref-a;
        Delta_b=b_ref-b;
        Delta_L=L_ref-L;                      
        Delta_H=(Delta_a^2+Delta_b^2-Delta_c^2)^0.5;

        DeltaE=((Delta_L/KL/SL)^2+(Delta_c/KC/SC)^2+(Delta_H/KH/SH)^2);
    case 3 %CIE 1976 DeltaE_ab
        DeltaE=((a_ref-a)^2+(b_ref-b)^2)^0.5;
end
set(handles.DisplayDeltaE,'String',num2str(DeltaE));

% --- Executes on button press in ExportFig.
function ExportFig_Callback(hObject, eventdata, handles)
% hObject    handle to ExportFig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global  colorMap rgbMap;

[outputDataFilename, outputDataPathname, flag] = uiputfile('*.mat', 'save FLUO maps');
if flag==0
else   
    colorMap_1_RIFLE=colorMap(:,:,1);
    colorMap_2_RIFLE=colorMap(:,:,2);
    colorMap_3_RIFLE=colorMap(:,:,3);
    rgbMap_RIFLE=rgbMap;   
    save([outputDataPathname outputDataFilename], 'colorMap_1_RIFLE','colorMap_1_RIFLE','colorMap_1_RIFLE','rgbMap_RIFLE');
end   
    
% --------------------------------------------------------------------
function ExportRGB_Callback(hObject, eventdata, handles)
% hObject    handle to ExportRGB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global rgbMap;

rgbMap_RIFLE=rgbMap;

[outputDataFilename, outputDataPathname, flag] = uiputfile('*.mat', 'save FLUO RGB map');
if flag==0
else
    save([outputDataPathname outputDataFilename], 'rgbMap_RIFLE');
end


% --------------------------------------------------------------------
function ExportColorMaps_Callback(hObject, eventdata, handles)
% hObject    handle to ExportColorMaps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global colorMap;

colorMap_1_RIFLE=colorMap(:,:,1);
colorMap_2_RIFLE=colorMap(:,:,2);
colorMap_3_RIFLE=colorMap(:,:,3);

[outputDataFilename, outputDataPathname, flag] = uiputfile('*.mat', 'save COLOR maps');
if flag==0
else
    save([outputDataPathname outputDataFilename], 'colorMap_1_RIFLE','colorMap_2_RIFLE','colorMap_3_RIFLE');
end

% --------------------------------------------------------------------


% --- Executes on button press in LoadDataButton.
function LoadDataButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global WL data Sd N ThresholdMask MaskAOI Mask AoiOn ThrOn AbsorbanceOn PreProcessDONE DerivativeOn; 
global DataTypeOpt;


[filename, pathname, output]=uigetfile('*.mat','Load hyperspectral dataset');

if output==0
    return;
end


if DataTypeOpt==3 %EEM
    global Xaxis Yaxis;
    data=struct2array (load([pathname filename],"data"));
    WL=struct2array(load([pathname filename],"WL"));
    Xaxis=struct2array(load([pathname filename],"Xaxis"));
    Yaxis=struct2array(load([pathname filename],"Yaxis"));
else
    data=struct2array (load([pathname filename],'-regexp','data'));
    WL=struct2array(load([pathname filename],'-regexp','WL'));
end
data=double(data);

if size(WL,1)>size(WL,2)
    WL=WL';
end
Rot90OPT=get(handles.Rot90OPT,'Value');
if Rot90OPT
    data=rot90(data,-1);
end
Buffer=sprintf('Loading data... done');
output_textColor(Buffer);

axes(handles.axes1),cla;

N=length(WL);
set(handles.WLvalue,'String',num2str(WL(1)));
set(handles.WL_start,'String',num2str(round(WL(1))));
set(handles.WL_end,'String',num2str(round(WL(end))));
step=1/N;
set(handles.SliderViewImage,'Value',1, 'SliderStep', [step step], 'Max', N, 'Min',1);
Sd=size(data);


AoiOn=0;
set(handles.ApplyAOI,'Value',AoiOn);

ThrOn=0;
set(handles.THROn,'Value',ThrOn);

PreProcessDONE=0;
set(handles.PerformSpectralPreproccesing,'Value',PreProcessDONE);

AbsorbanceOn=0;
set(handles.CalcAbsorbance,'Value',AbsorbanceOn);

DerivativeOn=0;
set(handles.PerformDataDerivative,'Value',DerivativeOn);

ThresholdMask=ones(Sd(1),Sd(2));
MaskAOI=ones(Sd(1),Sd(2));
Mask=(MaskAOI)&ThresholdMask;


% --------------------------------------------------------------------
% --- Executes on slider movement.
function SliderViewImage_Callback(hObject, eventdata, handles)
% hObject    handle to SliderViewImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global WL data DataTypeOpt; 
global index DisplayX;
global WL_DER data_DER;
global data_ABSORBANCE;
global DataToDisplayOpt;
global NUM_CONTOURLEVELS;


if DataTypeOpt==3 %EEM
    global Xaxis Yaxis;
end

switch DataToDisplayOpt
case 1
        wl=WL;
    case 2
        wl=WL;        
    case 3
        wl=WL_DER;
    case 4
        wl=WL;
end

N=length(wl);
index=get(hObject,'Value');
index=round(index);
if index<1
    index=1;
elseif index==N
    index=N;
end
DisplayX=wl(index);
get(handles.WLvalue,'String');
set(handles.WLvalue,'String',num2str(DisplayX));

switch DataToDisplayOpt
    case 1
        IMG_Main=data(:,:,index);
    case 2
        IMG_Main=data_ABSORBANCE(:,:,index);
    case 3
        IMG_Main=data_DER(:,:,index);
    case 4
        IMG_Main=log10(data(:,:,index));
end

axes(handles.axes1);

if DataTypeOpt==3 %EEM
    contourf(Xaxis,Yaxis,IMG_Main,NUM_CONTOURLEVELS); axis xy;
    % shading interp;
    xlabel('Emission wavelength /nm'), ylabel('Excitation wavelength /nm'),colormap(jet);
else
    imagesc(IMG_Main);
    colormap(gray);
    axis off;
end

fixOn=get(handles.rescaleSelection,'Value');
if fixOn
    CMin=str2double(get(handles.rescaleMin,'String'));
    CMax=str2double(get(handles.rescaleMax,'String'));
    set(gca,'Clim',[CMin CMax]);
elseif and(DataTypeOpt==1,DataToDisplayOpt==1) %Reflectance
    set(gca,'Clim',[0 1])    
end

colorbar, axis image;

% --------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function SliderViewImage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SliderViewImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
% --------------------------------------------------------------------
% --- Executes on button press in ViewIMGbutton.
function ViewIMGbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ViewIMGbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global WL data;
global index DisplayX DataTypeOpt IMG_Main;
global WL_DER data_DER;
global data_ABSORBANCE;
global DataToDisplayOpt;
global NUM_CONTOURLEVELS;

if DataTypeOpt==3 %EEM
    global Xaxis Yaxis;
end

switch DataToDisplayOpt
    case 1
        index=findIndex(DisplayX,WL);
        set(handles.WLvalue,'String',num2str(WL(index)));
        set(handles.SliderViewImage,'Value',index);
        IMG_Main=data(:,:,index);
    case 2
        index=findIndex(DisplayX,WL);
        set(handles.WLvalue,'String',num2str(WL(index)));
        set(handles.SliderViewImage,'Value',index);
        IMG_Main=data_ABSORBANCE(:,:,index);
    case 3
        index=findIndex(DisplayX,WL_DER);
        set(handles.WLvalue,'String',num2str(WL_DER(index)));
        set(handles.SliderViewImage,'Value',index);
        IMG_Main=data_DER(:,:,index);
    case 4
        index=findIndex(DisplayX,WL);
        set(handles.WLvalue,'String',num2str(WL(index)));
        set(handles.SliderViewImage,'Value',index);
        IMG_Main=log10(data(:,:,index));
end

axes(handles.axes1);

if DataTypeOpt==3 %EEM
   contourf(Xaxis,Yaxis,IMG_Main,NUM_CONTOURLEVELS); axis xy; 
   xlabel('Emission wavelength /nm'), ylabel('Excitation wavelength /nm'),colormap(jet);
else
    imagesc(IMG_Main);
    axis off;
    colormap(gray);
end

fixOn=get(handles.rescaleSelection,'Value');
if fixOn
    CMin=str2double(get(handles.rescaleMin,'String'));
    CMax=str2double(get(handles.rescaleMax,'String'));
    set(gca,'Clim',[CMin CMax]);
elseif and(DataTypeOpt==1,DataToDisplayOpt==1) %Reflectance
    set(gca,'Clim',[0 1]) 
end

colorbar, axis image
%axis off;

% --------------------------------------------------------------------
function [i]=findIndex(value,vector)
temp1=find(vector <= value);
temp2=find(vector > value);
if ~isempty(temp1),
    if ~isempty(temp2),
        if ((value-vector(temp1(end))) < (vector(temp2(1))-value))
            i=temp1(end);
        else
            i=temp2(1);
        end;
    else
        i=temp1(end);
    end;
else
    i=temp2(1);
end;

% --------------------------------------------------------------------
function WLvalue_Callback(hObject, eventdata, handles)
% hObject    handle to WLvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WLvalue as text
%        str2double(get(hObject,'String')) returns contents of WLvalue as a double
global DisplayX;
DisplayX=str2double(get(hObject,'String'));
% --------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function WLvalue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WLvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global DisplayX;
set(hObject,'String','400');
DisplayX=str2num(get(hObject,'String'));
% --------------------------------------------------------------------

% --- Executes on selection change in DataTypeOpt.
function DataTypeOpt_Callback(hObject, eventdata, handles)
% hObject    handle to DataTypeOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns DataTypeOpt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DataTypeOpt
global DataTypeOpt;
DataTypeOpt=get(hObject,'Value');
% --------------------------------------------------------------------

% --- Executes during object creation, after setting all properties.
function DataTypeOpt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DataTypeOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global DataTypeOpt;
set(hObject,'Value',1);
DataTypeOpt=get(hObject,'Value');

% --------------------------------------------------------------------
function MinThrValue_Callback(hObject, eventdata, handles)
% hObject    handle to MinThrValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinThrValue as text
%        str2double(get(hObject,'String')) returns contents of MinThrValue as a double
global MinThrValue;
MinThrValue=str2double(get(hObject,'String'));
% --------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function MinThrValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinThrValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global MinThrValue;
set(hObject,'String',0);
MinThrValue=str2double(get(hObject,'String'));
% --------------------------------------------------------------------


function MaxThrValue_Callback(hObject, eventdata, handles)
% hObject    handle to MaxThrValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxThrValue as text
%        str2double(get(hObject,'String')) returns contents of MaxThrValue as a double
global MaxThrValue;
MaxThrValue=str2double(get(hObject,'String'));

% --------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function MaxThrValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxThrValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global MaxThrValue;
set(hObject,'String',1);
MaxThrValue=str2double(get(hObject,'String'));
% --------------------------------------------------------------------

% --- Executes on button press in THROn.
function THROn_Callback(hObject, eventdata, handles)
% hObject    handle to THROn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of THROn
global MaxThrValue MinThrValue THROpt;
global IMG_Main IMG_SUM;
global ThrOn Mask ThresholdMask MaskAOI;

Sd=size(IMG_Main);
ThresholdMask=true(Sd(1),Sd(2));

ThrOn=get(hObject,'Value');

if ThrOn
    THRopt=get(handles.listbox_THRopt,'Value');
    switch THRopt
        case 1
            IMG_ToBeThresholded=IMG_SUM;
        case 2
            IMG_ToBeThresholded=IMG_Main;
    end
    switch THROpt
        case 1
            ThresholdMask=(ThresholdMask)&(IMG_ToBeThresholded>=MinThrValue);
        case 2
            ThresholdMask=(ThresholdMask)&(IMG_ToBeThresholded<=MaxThrValue);
        case 3
            ThresholdMask=(ThresholdMask)&(IMG_ToBeThresholded>=MinThrValue)&(IMG_ToBeThresholded<=MaxThrValue);
    end
else
    ThresholdMask=ones(Sd(1),Sd(2));
end

Mask=(MaskAOI)&ThresholdMask;
figure, imagesc(Mask), colormap(gray), axis image;

% --------------------------------------------------------------------



% --- Executes on button press in SelectAOI.
function SelectAOI_Callback(hObject, eventdata, handles)
% hObject    handle to SelectAOI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Sd IMG_Main DataTypeOpt;
global MaskAOI;

figure
if DataTypeOpt==3 %EEM
    global Xaxis Yaxis;
    imagesc(Xaxis,Yaxis,IMG_Main); axis xy, shading interp;
    xlabel('Emission wavelength /nm'), ylabel('Excitation wavelength /nm'),colormap(jet);
else
    imagesc(IMG_Main),colormap(gray);
end

fixOn=get(handles.rescaleSelection,'Value');
if fixOn
    CMin=str2double(get(handles.rescaleMin,'String'));
    CMax=str2double(get(handles.rescaleMax,'String'));
    set(gca,'Clim',[CMin CMax]);
elseif DataTypeOpt==1 %Reflectance
    set(gca,'Clim',[0 1])
end
 colorbar, axis image;

MaskAOI=false(Sd(1),Sd(2));
again = true;
while again
    [ThisAOI, x, y] = roipoly();
    MaskAOI = MaskAOI | ThisAOI;
    promptMessage = sprintf('Draw another AOI or Quit?');
    titleBarCaption = 'Continue?';
    button = questdlg(promptMessage, titleBarCaption, 'Draw', 'Quit', 'Draw');
    if strcmpi(button, 'Quit')
        again = false;
    end
end

line(x,y,'Color','r');
% indexAOI=find(MaskAOI==1);
% --------------------------------------------------------------------
% --- Executes on button press in AOIOn.
function AOIOn_Callback(hObject, eventdata, handles)
% hObject    handle to AOIOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AOIOn
global AoiOn MaskAOI ThresholdMask Mask Sd data OriginalData PosOK PosNaN;
global data_DER OriginalData_DER;

AoiOn=get(hObject,'Value');

if not(AoiOn)
    MaskAOI=ones(Sd(1),Sd(2));
end
Mask=(MaskAOI)&ThresholdMask;
figure, imagesc(Mask), colormap(gray), axis image;

if (AoiOn)
    OriginalData=data;
    PosNaN=find(Mask==0);
    PosOK=find(Mask==1);
    data_reshaped2D=reshape(data,Sd(1)*Sd(2),Sd(3));
    data_reshaped2D(PosNaN,:)=NaN;
    data=reshape(data_reshaped2D,Sd(1),Sd(2),Sd(3));
  
    OriginalData_DER=data_DER;
    data_DER_reshaped2D=reshape(data_DER,Sd(1)*Sd(2),size(OriginalData_DER,3));
    data_DER_reshaped2D(PosNaN,:)=NaN;
    data_DER=reshape(data_DER_reshaped2D,Sd(1),Sd(2),size(OriginalData_DER,3));
    
else
    MaskAOI=ones(Sd(1),Sd(2));
    data=OriginalData;
    data_DER=OriginalData_DER;
end


% --------------------------------------------------------------------
% --- Executes on button press in PerformSpectralComparison.
function PerformSpectralComparison_Callback(hObject, eventdata, handles)
% hObject    handle to PerformSpectralComparison (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SpectralComparisonOpt ThrValue;
global WL data Sd DataTypeOpt;
global WL_DER data_DER;
global data_ABSORBANCE;
% global PosOK PosNaN;
global SimilarityMap NumWL iLow_plot iHigh_plot;
global Mask;
global handleFigureSimilarityMap handleRGBMap handleSegmentedImage hCompositeRGBFig;
global DataToDisplayOpt;
global WL_toBeUsed data_toBeUsed;

% Select refefence reflectance spectrum
minWL=str2double(get(handles.WL_start,'String'));
maxWL=str2double(get(handles.WL_end,'String'));

switch DataToDisplayOpt
    case 1
        WL_toBeUsed=WL;
        data_toBeUsed=data;
    case 2
        WL_toBeUsed=WL;    
        data_toBeUsed=data_ABSORBANCE;
    case 3
        WL_toBeUsed=WL_DER;        
        data_toBeUsed=data_DER;
end



temp=find(WL_toBeUsed > maxWL);
if isempty(temp)
    iHigh_plot=length(WL_toBeUsed);
else
    iHigh_plot=temp(1);
end
clear temp;

temp=find(WL_toBeUsed<=minWL);
if isempty(temp)
    iLow_plot=1;
else
    iLow_plot=temp(end);
end
clear temp;

choice=get(handles.FigOptForPlotSelection,'Value');
switch choice
    case 1
        h=handles.axes1;
    case 2
        figure(handleRGBMap);
        h=gca;
    case 3
        figure(handleFigureSimilarityMap);
        h=gca;
    case 4
        figure(handleSegmentedImage);
        h=gca;
    case 5
        figure(hCompositeRGBFig);
        h=gca;
end


RefSpectrumOpt=get(handles.RefSpectrumOpt,'Value');
switch RefSpectrumOpt
    case 1
        %         aoiSize=str2double(get(handles.aoiSize,'String'));
        %         aoiHalfSize=aoiSize;
        %
        %
        Buffer = sprintf('Select reference spectrum');
        output_textColor(Buffer);
        axes(h);
        datacursormode on;
        %         [x y] = ginput(1);
        [AOI, x, y] = roipoly();
        line(x,y,'Color','k');
        datacursormode off;
        
        %       temp=data_toBeUsed(round(y-aoiHalfSize):round(y+aoiHalfSize),round(x-aoiHalfSize):round(x+aoiHalfSize),iLow_plot:iHigh_plot);
        AOI_1D=reshape(AOI,size(AOI,1)*size(AOI,2),1);
        data_toBeUsed_2D=reshape(data_toBeUsed,size(data_toBeUsed,1)*size(data_toBeUsed,2),size(data_toBeUsed,3));
        temp_2D=data_toBeUsed_2D(AOI_1D,:);
        referenceSpectrum=(mean(temp_2D,1,"omitnan"))';
        referenceSpectrum_std=(std(temp_2D,1,"omitnan"))';
%         if aoiSize==1
%             referenceSpectrum=squeeze(temp);
%             referenceSpectrum_std=zeros(size(temp));
%         else
%             referenceSpectrum=squeeze(mean(reshape(temp,[1 size(temp,1)*size(temp,2) size(temp,3)])));
%             referenceSpectrum_std=squeeze(std(reshape(temp,[1 size(temp,1)*size(temp,2) size(temp,3)])));
%         end
    case 2
        [filename, pathname, output]=uigetfile('*.mat','Load reference spectrum');
        if output==0
            return;
        end
        
        referenceSpectrum_imported=struct2array(load([pathname filename],'-regexp','meanspectrum'));
        referenceSpectrum_std_imported=struct2array(load([pathname filename],'-regexp','stdspectrum'));
        wl_imported=struct2array(load([pathname filename],'-regexp','WL'));
        referenceSpectrum=(interp1(wl_imported,referenceSpectrum_imported,WL_toBeUsed(iLow_plot:iHigh_plot)))';
        referenceSpectrum_std=(interp1(wl_imported,referenceSpectrum_std_imported,WL_toBeUsed(iLow_plot:iHigh_plot)))';
        Buffer=sprintf('Data imported from file %s',[pathname filename]);
        output_textColor(Buffer);
end
        

figure;
errorbarOn=get(handles.errorbarOn,'Value');
if errorbarOn
    errorbar(WL_toBeUsed(iLow_plot:iHigh_plot),referenceSpectrum(iLow_plot:iHigh_plot),referenceSpectrum_std(iLow_plot:iHigh_plot),'color','k','LineWidth',1);
else
    plot(WL_toBeUsed(iLow_plot:iHigh_plot),referenceSpectrum(iLow_plot:iHigh_plot),'color','k','LineWidth',1);
end
grid on;
xlabel('Wavelength (nm)');
set(gca,'XLim',[WL_toBeUsed(1) WL_toBeUsed(end)]);

fixOn=get(handles.rescaleSelection,'Value');
if fixOn
    YMin=str2double(get(handles.rescaleMin,'String'));
    YMax=str2double(get(handles.rescaleMax,'String'));
    set(gca,'Ylim',[YMin YMax]);
end

switch DataTypeOpt
    case 1 %Reflectance
        ylabel('Reflectance factor');
    case 2 % Fluorescence
        ylabel('Emission intensity (a.u.)');
end

NumPixel=Sd(1)*Sd(2);
NumWL=iHigh_plot-iLow_plot+1;

data_2D = reshape(data_toBeUsed(:,:,iLow_plot:iHigh_plot),Sd(1)*Sd(2),NumWL);
Mask_1D=reshape(Mask,Sd(1)*Sd(2),1);
data2D_OK = data_2D(Mask_1D(:),:);

SpectralComparisonOpt=get(handles.SpectralComparisonOpt,'Value');
switch SpectralComparisonOpt
    case 1 %SAM
        % normalize reference spectrum
        referenceSpectrum_n=referenceSpectrum(iLow_plot:iHigh_plot)./norm(referenceSpectrum(iLow_plot:iHigh_plot));
        
        % normalize the reflectance dataset        
        data2D_n=zeros(size(data2D_OK));
        
        Buffer = sprintf('Normalizing data...');
        output_textColor(Buffer);
        for i=1:size(data2D_OK,1)
            data2D_n(i,:)=data2D_OK(i,:)./norm(data2D_OK(i,:));
        end
        clear data2D_OK;
        Buffer = sprintf('Normalizing data... done');
        output_textColor(Buffer);
        
        Buffer = sprintf('Performing SAM comparison...');
        output_textColor(Buffer);        
        SAM=acos(data2D_n*referenceSpectrum_n)*180/pi;
        SimilarityMap_1D=ones(Sd(1)*Sd(2),1)*NaN;
        SimilarityMap_1D(Mask_1D(:))=SAM;
        SimilarityMap=reshape(SimilarityMap_1D,Sd(1),Sd(2));
        clear SimilarityMap_1D;
        
        Buffer = sprintf('Performing SAM comparison... done');
        output_textColor(Buffer);

    case 2 %SID
        % normalize reference spectrum
        referenceSpectrum_n=referenceSpectrum(iLow_plot:iHigh_plot)./norm(referenceSpectrum(iLow_plot:iHigh_plot));

        % normalize the reflectance dataset
        temp1=reshape(data(:,:,iLow_plot:iHigh_plot),NumPixel,NumWL);
        data_n=zeros(NumPixel,NumWL);
        
        Buffer = sprintf('Normalizing data...');
        output_textColor(Buffer);
        for i=1:NumPixel
            data_n(i,:)=temp1(i,:)./sum(temp1(i,:));
        end
        clear temp1;
        Buffer = sprintf('Normalizing data... done');
        output_textColor(Buffer);

        Buffer = sprintf('Performing SID comparison...');
        output_textColor(Buffer);
        SID=zeros(NumPixel,1);
        for i=1:NumPixel
            SID(i)=sum(data_n(i,:).*log(data_n(i,:)./referenceSpectrum_n'))+ sum(referenceSpectrum_n'.*log(referenceSpectrum_n'./data_n(i,:)));
        end
        SimilarityMap=reshape(SID,Sd(1),Sd(2));
        clear SID;
        Buffer = sprintf('Performing SID comparison... done');
        output_textColor(Buffer);
    case 3 %SAMSID
        % normalize reference spectrum
        referenceSpectrum_n=referenceSpectrum(iLow_plot:iHigh_plot)./norm(referenceSpectrum(iLow_plot:iHigh_plot));

        % normalize the reflectance dataset
        temp1=reshape(data(:,:,iLow_plot:iHigh_plot),NumPixel,NumWL);
        data_n=zeros(NumPixel,NumWL);

        Buffer = sprintf('Normalizing data...');
        output_textColor(Buffer);
        for i=1:NumPixel
            data_n(i,:)=temp1(i,:)./sum(temp1(i,:));
        end
        clear temp1;
        Buffer = sprintf('Normalizing data... done');
        output_textColor(Buffer);

        Buffer = sprintf('Performing SIDSAM comparison...');
        output_textColor(Buffer);
        SID=zeros(NumPixel,1);
        for i=1:NumPixel
            SID(i)=sum(data_n(i,:).*log(data_n(i,:)./referenceSpectrum_n'))+ sum(referenceSpectrum_n'.*log(referenceSpectrum_n'./data_n(i,:)));            
        end
        SAM=acos(data_n*referenceSpectrum_n);
        SIDSAM=SID.*tan(SAM);
        SimilarityMap=reshape(SIDSAM,Sd(1),Sd(2));
        clear SID SAM SIDSAM;
        Buffer = sprintf('Performing SIDSAM comparison... done');
        output_textColor(Buffer);
    case 4 %Euclidean distance
%         data_reshaped=reshape(data(:,:,iLow_plot:iHigh_plot),NumPixel,NumWL);
        Buffer = sprintf('Performing Euclidean distance...');
        output_textColor(Buffer);
        %         EU_DISTANCE=pdist2(data_reshaped,referenceSpectrum','euclidean');
        %         EU_DISTANCE(PosNaN)=NaN;
        %         SimilarityMap=reshape(EU_DISTANCE,Sd(1),Sd(2));
        EU_DISTANCE=pdist2(data2D_OK,referenceSpectrum(iLow_plot:iHigh_plot)','euclidean');
        SimilarityMap_1D=ones(Sd(1)*Sd(2),1)*NaN;        
        SimilarityMap_1D(Mask_1D(:))=EU_DISTANCE;
        SimilarityMap=reshape(SimilarityMap_1D,Sd(1),Sd(2));
        clear EU_DISTANCE data2D_OK;
        Buffer = sprintf('Performing Euclidean distance... done');
        output_textColor(Buffer);
    case 5 %Euclidean distance * (1-cos(teta))
        %         data_reshaped=reshape(data(:,:,iLow_plot:iHigh_plot),NumPixel,NumWL);
        Buffer = sprintf('Performing similarity measuremente...');
        output_textColor(Buffer);
        %         EU_DISTANCE=pdist2(data_reshaped,referenceSpectrum','euclidean');
        %         TETA_DISTANCE=pdist2(data_reshaped,referenceSpectrum','cosine');
        EU_DISTANCE=pdist2(data2D_OK,referenceSpectrum(iLow_plot:iHigh_plot)','euclidean');
        TETA_DISTANCE=pdist2(data2D_OK,referenceSpectrum(iLow_plot:iHigh_plot)','cosine');
        DISTANCE=EU_DISTANCE.*TETA_DISTANCE;
        %          DISTANCE(PosNaN)=NaN;
        % SimilarityMap=reshape(DISTANCE,Sd(1),Sd(2));
        SimilarityMap_1D=ones(Sd(1)*Sd(2),1)*NaN;        
        SimilarityMap_1D(Mask_1D(:))=DISTANCE;
        SimilarityMap=reshape(SimilarityMap_1D,Sd(1),Sd(2));
        
        clear EU_DISTANCE TETA_DISTANCE DISTANCE data2D_OK;
        Buffer = sprintf('Performing similarity measuremente... done');
        output_textColor(Buffer);
end

% display similarity map
% axes(handles.axes1),cla;
handleFigureSimilarityMap=figure;
SimilarityMap=SimilarityMap.*Mask;
imagesc(SimilarityMap); axis image; 
set(gca,'Clim',[0 ThrValue]);
grayCMAP=colormap(gray); colormap(flipud(grayCMAP));
colorbar;

figure, hAxis=gca();
histogram(hAxis,SimilarityMap(Mask==1));
title('Distribution of spectral distances');
xlabel('Spectral Distance');



% --- Executes on selection change in SpectralComparisonOpt.
function SpectralComparisonOpt_Callback(hObject, eventdata, handles)
% hObject    handle to SpectralComparisonOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns SpectralComparisonOpt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SpectralComparisonOpt
global SpectralComparisonOpt;
SpectralComparisonOpt=get(hObject,'Value');


% --- Executes during object creation, after setting all properties.
function SpectralComparisonOpt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectralComparisonOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global SpectralComparisonOpt;
set(hObject,'Value',1);
SpectralComparisonOpt=get(hObject,'Value');


% --- Executes on selection change in RefSpectrumOpt.
function RefSpectrumOpt_Callback(hObject, eventdata, handles)
% hObject    handle to RefSpectrumOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns RefSpectrumOpt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from RefSpectrumOpt


% --- Executes during object creation, after setting all properties.
function RefSpectrumOpt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RefSpectrumOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PrintSimilarityMap.
function PrintSimilarityMap_Callback(hObject, eventdata, handles)
% hObject    handle to PrintSimilarityMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ThrValue;
global SimilarityMap;
[PrintFilename, PrintPathname, flag]= uiputfile('*.jpg', 'print JPG figure');

if flag==0
    return;
end

figure;
imagesc(SimilarityMap); axis image; 
set(gca,'Clim',[0 ThrValue]);
set(gca,'XTickLabel',[]);
set(gca,'YTickLabel',[]);
grayCMAP=colormap(gray); colormap(flipud(grayCMAP)), colorbar;
title('Similarity map [degree]','Units','Normalized','FontSize',12,'FontWeight','Bold');
NamePrint=[PrintPathname PrintFilename];
print(gcf,'-djpeg100',NamePrint);
% NameMATFile=[NamePrint(1:end-3) 'mat'];
% save(NameMATFile,'SimilarityMap');


% --- Executes on button press in RescaleSimilarityMap.
function RescaleSimilarityMap_Callback(hObject, eventdata, handles)
% hObject    handle to RescaleSimilarityMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% global ThrValue;
global handleFigureSimilarityMap SimilarityMap;
global WL_toBeUsed data_toBeUsed;

ThrValue=str2double(get(handles.ThrValue,'String'));

figure(handleFigureSimilarityMap);
set(gca,'Clim',[0 ThrValue]);

grayCMAP=colormap(gray); colormap(flipud(grayCMAP)), colorbar;

% ImageSimilarityMap=get(gca,'Children');
% SimilarityMap=get(ImageSimilarityMap,'Cdata');

SimilarityMap_1D=reshape(SimilarityMap,1,size(SimilarityMap,1)*size(SimilarityMap,2));
index=find(SimilarityMap_1D<ThrValue);
% SimilarityMap_1D(index)=NaN;
% SimilarityMap_THR=reshape(SimilarityMap_1D,size(SimilarityMap,1),size(SimilarityMap,2));
% figure, imagesc(SimilarityMap_THR), colormap(gray), axis image

SimilarityMap_MASK_1D=NaN(1,size(SimilarityMap,1)*size(SimilarityMap,2));
SimilarityMap_MASK_1D(index)=1;
SimilarityMap_MASK=reshape(SimilarityMap_MASK_1D,size(SimilarityMap,1),size(SimilarityMap,2));
figure, imagesc(SimilarityMap_MASK), colormap(gray), axis image;

data_2D=reshape(data_toBeUsed,size(data_toBeUsed,1)*size(data_toBeUsed,2),size(data_toBeUsed,3));
temp_2D=data_2D(index,:);
data_plot_mean=(mean(temp_2D,1,"omitnan"));
data_plot_std=(std(temp_2D,1,"omitnan"));

data_plot_H = data_plot_mean + data_plot_std;
data_plot_L = data_plot_mean - data_plot_std;
WL_temp = [WL_toBeUsed, fliplr(WL_toBeUsed)];
inBetween = [data_plot_H, fliplr(data_plot_L)];
figure;
plot(WL_toBeUsed,data_plot_mean,'-k','LineWidth',2), hold on;
fill(WL_temp, inBetween, 'k','FaceAlpha',.3,'EdgeColor','none');
grid on;
xlabel('Wavelength (nm)');
set(gca,'XLim',[WL_toBeUsed(1) WL_toBeUsed(end)]);
ylabel('Reflectance');





function ThrValue_Callback(hObject, eventdata, handles)
% hObject    handle to ThrValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ThrValue as text
%        str2double(get(hObject,'String')) returns contents of ThrValue as a double
global ThrValue;
ThrValue=str2double(get(hObject,'String'));



% --- Executes during object creation, after setting all properties.
function ThrValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ThrValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global ThrValue;
set(hObject,'String',num2str(10));
ThrValue=str2double(get(hObject,'String'));






% --- Executes on selection change in listbox12.
function listbox12_Callback(hObject, eventdata, handles)
% hObject    handle to listbox12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox12 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox12


% --- Executes during object creation, after setting all properties.
function listbox12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton28.
function pushbutton28_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit20_Callback(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit20 as text
%        str2double(get(hObject,'String')) returns contents of edit20 as a double


% --- Executes during object creation, after setting all properties.
function edit20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit21_Callback(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit21 as text
%        str2double(get(hObject,'String')) returns contents of edit21 as a double


% --- Executes during object creation, after setting all properties.
function edit21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox7.
function checkbox7_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox7


% --- Executes on button press in pushbutton29.
function pushbutton29_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton29 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in togglebutton5.
function togglebutton5_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton5


% --- Executes on button press in pushbutton30.
function pushbutton30_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton31.
function pushbutton31_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton31 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit22_Callback(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit22 as text
%        str2double(get(hObject,'String')) returns contents of edit22 as a double


% --- Executes during object creation, after setting all properties.
function edit22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox8.
function checkbox8_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox8



function edit23_Callback(hObject, eventdata, handles)
% hObject    handle to edit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit23 as text
%        str2double(get(hObject,'String')) returns contents of edit23 as a double


% --- Executes during object creation, after setting all properties.
function edit23_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in SizeSelectionOpt.
function SizeSelectionOpt_Callback(hObject, eventdata, handles)
% hObject    handle to SizeSelectionOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns SizeSelectionOpt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SizeSelectionOpt


% --- Executes during object creation, after setting all properties.
function SizeSelectionOpt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SizeSelectionOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in ClusterData.
function ClusterData_Callback(hObject, eventdata, handles)
% hObject    handle to ClusterData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global WL data data_ABSORBANCE;
global WL_DER data_DER;
global DataTypeOpt DataToDisplayOpt;
global ClusterOpt NumClusters;
global IDX_image degree_image;
global WLToCluster ClustersSpectra ClustersSpectra_std;
global Mask Sd;
global CalcClusterNumberDONE;
global IDX_cell C_cell;


switch DataToDisplayOpt
    case 1
        WL_toBeUsed=WL;
        data_toBeUsed=data;
    case 2
        WL_toBeUsed=WL;    
        data_toBeUsed=data_ABSORBANCE;
    case 3
        WL_toBeUsed=WL_DER;        
        data_toBeUsed=data_DER;
end

if CalcClusterNumberDONE
    degree_NotNan=zeros(size(dataToCluster_NotNan,1),NumClusters);
            for i=1:NumClusters
                degree_NotNan(:,i)=(IDX_NotNan==i);
            end
else
    minWL=str2double(get(handles.WL_start,'String'));
    maxWL=str2double(get(handles.WL_end,'String'));
    
    temp=find(WL_toBeUsed > maxWL);
    if isempty(temp)
        iHigh_plot=length(WL_toBeUsed);
    else
        iHigh_plot=temp(1);
    end
    clear temp;
    
    temp=find(WL_toBeUsed<minWL);
    if isempty(temp)
        iLow_plot=1;
    else
        iLow_plot=temp(end);
    end
    clear temp;
    
    dataToCluster=data_toBeUsed(:,:,iLow_plot:iHigh_plot);
    WLToCluster=WL_toBeUsed(iLow_plot:iHigh_plot);
    Sd_dataToCluster=size(dataToCluster);
    dataToCluster_2D=reshape(dataToCluster,Sd_dataToCluster(1)*Sd_dataToCluster(2),Sd_dataToCluster(3));
    
    
    % PosNaN=isnan(dataToCluster(:,1));
    % PosNotNaN=not(PosNaN);
    %     PosNaN=find(ExportMask==0);
    %     PosNotNaN=find(ExportMask==1);
    %     dataToCluster_NotNan=dataToCluster(PosNotNaN,:);
    Mask_1D=reshape(Mask,Sd(1)*Sd(2),1);
    dataToCluster_NotNan = dataToCluster_2D(Mask_1D(:),:);
    switch DataTypeOpt
        case 2 % Fluo
            %         MaxIntensity=max(dataToCluster_NotNan,[],2);
            %         MaxIntensityMatrix=repmat(MaxIntensity,1,size(dataToCluster_NotNan,2));
            %         dataToCluster_NotNan=dataToCluster_NotNan./MaxIntensityMatrix;
            Intensity=sum(dataToCluster_NotNan,2);
            IntensityMatrix=repmat(Intensity,1,size(dataToCluster_NotNan,2));
            dataToCluster_NotNan=dataToCluster_NotNan./IntensityMatrix;
    end
    
    Buffer = sprintf('Clustering data... ');
    output_textColor(Buffer);
    switch ClusterOpt
        case 1 % K-means
            IDX_NotNan = kmeans(dataToCluster_NotNan,NumClusters,'Distance','cosine');
            degree_NotNan=zeros(size(dataToCluster_NotNan,1),NumClusters);
            for i=1:NumClusters
                degree_NotNan(:,i)=(IDX_NotNan==i);
            end
        case 2 % Fuzzy Logic
            [C, degree_NotNan, objFun]=fcm(dataToCluster_NotNan,NumClusters);
            degree_NotNan=degree_NotNan';
            [temp IDX_NotNan] = max(degree_NotNan,[],2); clear temp;
    end
    
    degree=ones(Sd_dataToCluster(1)*Sd_dataToCluster(2),NumClusters)*NaN;
    degree(Mask_1D,:)=degree_NotNan;
    %     degree(PosNaN,:)=NaN;
    %     degree(PosNotNaN,:)=degree_NotNan;
    
    IDX=ones(Sd_dataToCluster(1)*Sd_dataToCluster(2),1)*NaN;
    IDX(Mask_1D)=IDX_NotNan;
    
    %     IDX(PosNaN)=NaN;
    %     IDX(PosNotNaN)=IDX_NotNan;
    
    dataToCluster=reshape(dataToCluster_2D,Sd_dataToCluster(1),Sd_dataToCluster(2),Sd_dataToCluster(3));
        
    degree_image=zeros(Sd_dataToCluster(1,1),Sd_dataToCluster(1,2),NumClusters);
    for i=1:NumClusters
        degree_image(:,:,i)=reshape(degree(:,i),Sd_dataToCluster(1),Sd_dataToCluster(2));
        degree_image(:,:,i)=squeeze(degree_image(:,:,i)).*Mask;
    end
    IDX_image=reshape(IDX,Sd_dataToCluster(1),Sd_dataToCluster(2));
    IDX_image=IDX_image.*Mask;
    
    ClustersSpectra=zeros(NumClusters,Sd_dataToCluster(3));
    ClustersSpectra_std=zeros(NumClusters,Sd_dataToCluster(3));
    
    for i=1:NumClusters
        vettore_m=zeros(1,Sd_dataToCluster(3));
        vettore_s=zeros(1,Sd_dataToCluster(3));
        for j=1:Sd_dataToCluster(3)
            temp=squeeze(dataToCluster(:,:,j));
            vettore_m(j)=nanmean(temp(IDX_image==i));
            vettore_s(j)=nanstd(temp(IDX_image==i));
        end
        ClustersSpectra(i,:)=vettore_m;
        ClustersSpectra_std(i,:)=vettore_s;
    end
end

Buffer = sprintf('Clustering data... done');
output_textColor(Buffer);


% --- Executes on button press in DisplaySegmentedImage.
function DisplaySegmentedImage_Callback(hObject, eventdata, handles)
% hObject    handle to DisplaySegmentedImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IDX_image NumClusters;
global WLToCluster ClustersSpectra ClustersSpectra_std;
global DataTypeOpt;
global degree_image;
global handleSegmentedImage;


handleSegmentedImage=figure;
title('Segmented image');
imagesc(IDX_image), axis('image');
colormap(jet)
set(gca,'Clim',[0 NumClusters]);
map=colormap; numColors=size(map,1);
stepColors=round(numColors/(NumClusters));
colorbar;

NUMCOLS=floor(NumClusters/3);
if mod(NumClusters,3)>0
   NUMCOLS=NUMCOLS+1,
end
figure,    
for i=1:NumClusters
    subplot(3,NUMCOLS,i)
    imagesc(squeeze(degree_image(:,:,i))), colorbar, colormap(gray), axis('image');
end

normalizationOn=get(handles.normalizationOn,'Value');
if normalizationOn
    for i=1:NumClusters
        ClustersSpectra_n(i,:)=ClustersSpectra(i,:)./max(ClustersSpectra(i,:));
        ClustersSpectra_std_n(i,:)=ClustersSpectra_std(i,:)./max(ClustersSpectra(i,:));
    end
end
figure
if normalizationOn
    subplot(2,1,1)
end
errorbarOn=get(handles.errorbarOn,'Value');
for i=1:NumClusters
    indexColor(i)=min(stepColors*(i),numColors);
    if errorbarOn
        errorbar(WLToCluster, ClustersSpectra(i,:),ClustersSpectra_std(i,:),'LineWidth',2,'color',map(indexColor(i),:));
    else
        plot(WLToCluster, ClustersSpectra(i,:),'LineWidth',2,'color',map(indexColor(i),:));
    end
    hold on
end
hold off;
legend toggle;
legend('Location','NorthEastOutside')
set(gca,'Xlim',[WLToCluster(1) WLToCluster(end)]);
xlabel('Wavelength (nm)');

switch DataTypeOpt
    case 1 %Reflectance
%         set(gca,'YLim',[0 1]);
        ylabel('Reflectance factor');
    case 2 % Fluorescence
        ylabel('Emission intensity (a.u.)');
end
fixOn=get(handles.rescaleSelection,'Value');
if fixOn
    YMin=str2double(get(handles.rescaleMin,'String'));
    YMax=str2double(get(handles.rescaleMax,'String'));
    set(gca,'Ylim',[YMin YMax]);
end

if normalizationOn
    subplot(2,1,2)
    for i=1:NumClusters
        if errorbarOn
            errorbar(WLToCluster, ClustersSpectra_n(i,:),ClustersSpectra_std_n(i,:),'LineWidth',2,'color',map(indexColor(i),:));
        else
            plot(WLToCluster, ClustersSpectra_n(i,:),'LineWidth',2,'color',map(indexColor(i),:));
        end
        hold on
    end
    hold off;
    legend toggle;
    legend('Location','NorthEastOutside')
    set(gca,'Xlim',[WLToCluster(1) WLToCluster(end)]);
    xlabel('Wavelength (nm)');

    set(gca,'YLim',[0 1]);
    ylabel('Normalized emission intensity');
end

% --- Executes on selection change in ClusterMethod.
function ClusterMethod_Callback(hObject, eventdata, handles)
% hObject    handle to ClusterMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns ClusterMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ClusterMethod
global ClusterOpt;
ClusterOpt=get(hObject,'Value');

% --- Executes during object creation, after setting all properties.
function ClusterMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ClusterMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global ClusterOpt;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'Value',1);
ClusterOpt=get(hObject,'Value');

function ClustersNum_Callback(hObject, eventdata, handles)
% hObject    handle to ClustersNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ClustersNum as text
%        str2double(get(hObject,'String')) returns contents of ClustersNum as a double
global NumClusters;
NumClusters=str2double(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function ClustersNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ClustersNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global NumClusters;

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String','5');
NumClusters=str2double(get(hObject,'String'));

function ClusterMapToDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to ClusterMapToDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ClusterMapToDisplay as text
%        str2double(get(hObject,'String')) returns contents of ClusterMapToDisplay as a double
global ClusterMapToDisplay;
ClusterMapToDisplay=str2double(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function ClusterMapToDisplay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ClusterMapToDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
global ClusterMapToDisplay;
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String','1');
ClusterMapToDisplay=str2double(get(hObject,'String'));



% --- Executes on button press in DisplayClusterMap.
function DisplayClusterMap_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayClusterMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global ClusterMapToDisplay NumClusters;
global degree_image; 


if ClusterMapToDisplay>NumClusters
    Buffer = sprintf('Error !');
    output_textColor(Buffer);
else
    figure
    imagesc(squeeze(degree_image(:,:,ClusterMapToDisplay))), colorbar, colormap(gray), axis('image');
end

function MaxIntensityValue_Callback(hObject, eventdata, handles)
% hObject    handle to MaxIntensityValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxIntensityValue as text
%        str2double(get(hObject,'String')) returns contents of MaxIntensityValue as a double


% --- Executes during object creation, after setting all properties.
function MaxIntensityValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxIntensityValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in PrintSegmentedImage.
function PrintSegmentedImage_Callback(hObject, eventdata, handles)
% hObject    handle to PrintSegmentedImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IDX_image NumClusters;
global WLToCluster ClustersSpectra ClustersSpectra_std;
global DataTypeOpt;

[PrintFilename, PrintPathname, flag]= uiputfile('*.jpg', 'print JPG figure');
if flag==0
    return;
end

normalizationOn=get(handles.normalizationOn,'Value');
figure;
if normalizationOn
    subplot(3,1,1)
else
    subplot(2,1,1);
end
imagesc(IDX_image), colorbar, colormap(jet), axis('image');
title('Segmented image');
set(gca,'Clim',[0 NumClusters]);
map=colormap; numColors=size(map,1);
stepColors=round(numColors/(NumClusters));

if normalizationOn
    for i=1:NumClusters
        ClustersSpectra_n(i,:)=ClustersSpectra(i,:)./max(ClustersSpectra(i,:));
        ClustersSpectra_std_n(i,:)=ClustersSpectra_std(i,:)./max(ClustersSpectra(i,:));
    end
end

errorbarOn=get(handles.errorbarOn,'Value');
if normalizationOn
    subplot(3,1,2)
else
    subplot(2,1,2)
end
for i=1:NumClusters
    indexColor(i)=min(stepColors*(i),numColors);
    if errorbarOn
        errorbar(WLToCluster, ClustersSpectra(i,:),ClustersSpectra_std(i,:),'LineWidth',2,'color',map(indexColor(i),:));
    else
        plot(WLToCluster, ClustersSpectra(i,:),'LineWidth',2,'color',map(indexColor(i),:));
    end
    hold on
end
hold off;
legend toggle;
legend('Location','NorthEastOutside');
set(gca,'Xlim',[WLToCluster(1) WLToCluster(end)]);
xlabel('Wavelength (nm)');

switch DataTypeOpt
    case 1 %Reflectance
        set(gca,'YLim',[0 1]);
        ylabel('Reflectance factor');
    case 2 % Fluorescence
        fixOn=get(handles.rescaleSelection,'Value');
        if fixOn
            YMin=str2double(get(handles.rescaleMin,'String'));
            YMax=str2double(get(handles.rescaleMax,'String'));
            set(gca,'Ylim',[YMin YMax]);
        end
        ylabel('Emission intensity (a.u.)');
end


if normalizationOn
    subplot(3,1,3)
    for i=1:NumClusters
        if errorbarOn
            errorbar(WLToCluster, ClustersSpectra_n(i,:),ClustersSpectra_std_n(i,:),'LineWidth',2,'color',map(indexColor(i),:));
        else
            plot(WLToCluster, ClustersSpectra_n(i,:),'LineWidth',2,'color',map(indexColor(i),:));
        end
        hold on
    end
    hold off;
    legend toggle;
    legend('Location','NorthEastOutside');
    set(gca,'Xlim',[WLToCluster(1) WLToCluster(end)]);
    xlabel('Wavelength (nm)');

    set(gca,'YLim',[0 1]);
    ylabel('Normalized emission intensity');
end

NamePrint=[PrintPathname PrintFilename];
print(gcf,'-djpeg100',NamePrint);
saveas(gcf,NamePrint(1:end-4),'fig');




% --- Executes on button press in PrintClusterMap.
function PrintClusterMap_Callback(hObject, eventdata, handles)
% hObject    handle to PrintClusterMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ClusterMapToDisplay NumClusters;
global degree_image; 

if ClusterMapToDisplay>NumClusters
    Buffer = sprintf('Error !');
    output_textColor(Buffer);
else
    [PrintFilename, PrintPathname, flag]= uiputfile('*.jpg', 'print JPG figure');
    if flag==0
        return;
    end
    figure;
    imagesc(squeeze(degree_image(:,:,ClusterMapToDisplay))), colorbar, colormap(gray), axis('image');
    title('Cluster map');
    NamePrint=[PrintPathname PrintFilename];
    print(gcf,'-djpeg100',NamePrint);
    saveas(gcf,NamePrint(1:end-4),'fig');
end







function SizeFiltWindow_Callback(hObject, eventdata, handles)
% hObject    handle to SizeFiltWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SizeFiltWindow as text
%        str2double(get(hObject,'String')) returns contents of SizeFiltWindow as a double


% --- Executes during object creation, after setting all properties.
function SizeFiltWindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SizeFiltWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CalcClusterNumber.
function CalcClusterNumber_Callback(hObject, eventdata, handles)
% hObject    handle to CalcClusterNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global WL data Mask;
global DataTypeOpt NumClusters;
global dataToCluster_NotNan;
global CalcClusterNumberDONE;
global IDX_cell C_cell;

CalcClusterNumberDONE=0;
minWL=str2double(get(handles.WL_start,'String'));
maxWL=str2double(get(handles.WL_end,'String'));
temp=find(WL > maxWL);
if isempty(temp)
    iHigh_plot=length(WL);
else
    iHigh_plot=temp(1);
end
clear temp;

temp=find(WL<minWL);
if isempty(temp)
    iLow_plot=1;
else
    iLow_plot=temp(end);
end
clear temp;
dataToCluster=data(:,:,iLow_plot:iHigh_plot);
WLToCluster=WL(iLow_plot:iHigh_plot);

Sd_dataToCluster=size(dataToCluster);
dataToCluster=reshape(dataToCluster,Sd_dataToCluster(1)*Sd_dataToCluster(2),Sd_dataToCluster(3));
PosNaN=find(Mask==0);
PosNotNaN=find(Mask==1);
dataToCluster_NotNan=dataToCluster(PosNotNaN,:);
switch DataTypeOpt
    case 2 % Fluo
        Intensity=sum(dataToCluster_NotNan,2);
        IntensityMatrix=repmat(Intensity,1,size(dataToCluster_NotNan,2));
        dataToCluster_NotNan=dataToCluster_NotNan./IntensityMatrix;
end


for N =1:NumClusters
    Buffer = sprintf('Starting to cluster using %d clusters... ',N);
    output_textColor(Buffer);
    
    [IDX_NotNan{N}, C_cell{N}] = kmeans(dataToCluster_NotNan,N,'distance','cosine');
    IDX_cell{N}=zeros(Sd_dataToCluster(1)*Sd_dataToCluster(2),1);
    IDX_cell{N}(PosNaN)=NaN;
    IDX_cell{N}(PosNotNaN)=IDX_NotNan{N};
    Buffer=sprintf('Clustering data...done');
    
end
Buffer=sprintf('Starting to cluster using %d clusters... done ',N);
output_textColor(Buffer);
Calc_dBXu_index(IDX_cell,C_cell,dataToCluster, NumClusters,Sd_dataToCluster);

% CalcClusterNumberDONE=1;
clear IDX_NotNan;
% clear IDX IDX_NotNan C;

%save('clusteredData.mat','IDX','C','IMG2');

% --- Executes on button press in dBXu.
function Calc_dBXu_index(IDX,C,data,nMax,dim)
% hObject    handle to dBXu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
locs1=0;
locs2=0;

count=zeros(1,nMax);
J=zeros(1,nMax);
dataInCluster=cell(nMax,dim(3));
dataInCluster{1}=zeros(1,dim(3));
k=0;
P=0;
D=0;
Rh=zeros(nMax,1);
%load('clusteredData.mat');

for h=1:nMax % iterazione del clustering
    for jj=1:h; % ciclo sui cluster esistenti nel partizionamento h
        ind{jj}=find(IDX{h}==jj);
        count(jj)=count(jj)+1;
        dataInCluster{jj}=cat(count(jj),data(ind{jj},:)); % per VG crop: IMG2_new
        % AB: IMG_INPUT_NoOut (2:norm)
        % spectralon: data_RIFLE
        % rosa: data_RIFLE2
        data2{h,jj}=dataInCluster{jj}; %data{numero hp clustering, num cluster}
        for jk=1:size(data2{h,jj},1)
            J(jj)=J(jj)+sum((data2{h,jj}(jk,:)-C{h}(jj,:)).^2);
        end
        
        for ij=1:h
            R(ij,jj)=(J(ij)/sqrt(count(ij))+(J(jj)/sqrt(count(jj))))*(nanmean(C{h}(jj,:)-C{h}(ij,:)));
            d{h}(jj,ij)=sqrt(count(jj)*count(ij)/(count(ij)+count(jj)))*abs(nanmean(C{h}(jj,:)-C{h}(ij,:)));
        end
        Rh(jj)=max(R(:,jj));
        dh{jj}=sort(d{h}(jj,:));
        
    end
    JJ(h)=sum(J);
    DB(h)=(1/(h-1))*sum(Rh);
end
for n=1:nMax
    M(n)=dh{n}(3);
end
for kk=1:nMax-1
    E(kk)=(M(kk)-M(kk+1))/(sqrt(JJ(kk))-sqrt(JJ(kk+1)));
end
%save('debug.mat','E','M','R','d','J','dataInCluster');
[pks1,locs1]= findpeaks(E);

DB2=-DB;
[pks2,locs2]= findpeaks(DB2);

figure;
subplot(2,1,1);
plot(1:1:nMax,DB,'.-b');
xlabel('N clusters');
ylabel('Davies-Bouldin');
title('to be MINIMIZED')
subplot(2,1,2);
plot(1:1:nMax-1,E,'.-r');
xlabel('N clusters');
ylabel('Xu');
title('to be MAXIMIZED')
%delete('debug.mat','clusteredData.mat');



% --- Executes on button press in Rot90OPT.
function Rot90OPT_Callback(hObject, eventdata, handles)
% hObject    handle to Rot90OPT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Rot90OPT


% --- Executes on selection change in FigOptForPlotSelection.
function FigOptForPlotSelection_Callback(hObject, eventdata, handles)
% hObject    handle to FigOptForPlotSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FigOptForPlotSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FigOptForPlotSelection


% --- Executes during object creation, after setting all properties.
function FigOptForPlotSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FigOptForPlotSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PrintIMG.
function PrintIMG_Callback(hObject, eventdata, handles)
% hObject    handle to PrintIMG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IMG_Main;
global DataTypeOpt;
global NUM_CONTOURLEVELS;


if DataTypeOpt==3 %EEM
    global Xaxis Yaxis;
end

axes(handles.axes1);
CLim=get(gca,'Clim');


PrintFigureHn=figure;
if DataTypeOpt==3 %EEM
    contourf(Xaxis,Yaxis,IMG_Main,NUM_CONTOURLEVELS); axis xy;
    % shading interp;
    xlabel('Emission wavelength /nm'), ylabel('Excitation wavelength /nm'),colormap(jet);
else
    imagesc(IMG_Main), axis image, axis off, colormap(gray), set(gca,'CLim',CLim);
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
end

[PrintFilename, PrintPathname, flag]= uiputfile('*.png', 'print JPG figure');

if flag==0
    return;
end

NamePrint=[PrintPathname PrintFilename];
print(PrintFigureHn,'-djpeg100',NamePrint);
saveas(PrintFigureHn,NamePrint(1:end-4),'fig')


function WLstop_R_Callback(hObject, eventdata, handles)
% hObject    handle to WLstop_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WLstop_R as text
%        str2double(get(hObject,'String')) returns contents of WLstop_R as a double


% --- Executes during object creation, after setting all properties.
function WLstop_R_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WLstop_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function WLstart_R_Callback(hObject, eventdata, handles)
% hObject    handle to WLstart_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WLstart_R as text
%        str2double(get(hObject,'String')) returns contents of WLstart_R as a double


% --- Executes during object creation, after setting all properties.
function WLstart_R_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WLstart_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CreateRGBComposite.
function CreateRGBComposite_Callback(hObject, eventdata, handles)
% hObject    handle to CreateRGBComposite (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global WL data hCompositeRGBFig;
global WL_DER data_DER;
global data_ABSORBANCE;
global DataToDisplayOpt DataTypeOpt;
global FixRGBComposite_opt MinValue_R MaxValue_R MinValue_G MaxValue_G MinValue_B MaxValue_B;


CompositeRGB=zeros(size(data,1),size(data,2),3);


switch DataToDisplayOpt
    case 1
        WL_toBeUsed=WL;
        data_toBeUsed=data;
    case 2
        WL_toBeUsed=WL;
        data_toBeUsed=data_ABSORBANCE;
    case 3
        WL_toBeUsed=WL_DER;
        data_toBeUsed=data_DER;
end


WLstart_R=str2double(get(handles.WLstart_R,'String'));
WLstop_R=str2double(get(handles.WLstop_R,'String'));

temp=find(WL_toBeUsed>=WLstart_R);
indexLow=temp(1);
clear temp;

temp=find(WL_toBeUsed<=WLstop_R);
indexHigh=temp(end);
clear temp;

if and(DataToDisplayOpt==1,DataTypeOpt==1)
    %Reflectance data
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
else
    %PL data or derivative data
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
    if FixRGBComposite_opt
        maxValue=MaxValue_R;
        minValue=MinValue_R;
    else
        maxValue=max(max(tempMatrix));
        minValue=min(min(tempMatrix));
    end
    tempMatrix=(tempMatrix-minValue)/(maxValue-minValue);
end

CompositeRGB(:,:,1)=tempMatrix;
clear indexLow indexHigh tempMatrix;



WLstart_G=str2double(get(handles.WLstart_G,'String'));
WLstop_G=str2double(get(handles.WLstop_G,'String'));

temp=find(WL_toBeUsed>=WLstart_G);
indexLow=temp(1);
clear temp;

temp=find(WL_toBeUsed<=WLstop_G);
indexHigh=temp(end);
clear temp;

if and(DataToDisplayOpt==1,DataTypeOpt==1)
    %Reflectance data
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
else
    %PL data or derivative data
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
    if FixRGBComposite_opt
        maxValue=MaxValue_G;
        minValue=MinValue_G;
    else
        maxValue=max(max(tempMatrix));
        minValue=min(min(tempMatrix));
    end
    tempMatrix=(tempMatrix-minValue)/(maxValue-minValue);
end

CompositeRGB(:,:,2)=tempMatrix;
clear indexLow indexHigh tempMatrix;


WLstart_B=str2double(get(handles.WLstart_B,'String'));
WLstop_B=str2double(get(handles.WLstop_B,'String'));

temp=find(WL_toBeUsed>=WLstart_B);
indexLow=temp(1);
clear temp;

temp=find(WL_toBeUsed<=WLstop_B);
indexHigh=temp(end);
clear temp;

if and(DataToDisplayOpt==1,DataTypeOpt==1)
    %Reflectance data
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
else
    %PL data or derivative data
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
    if FixRGBComposite_opt
        maxValue=MaxValue_B;
        minValue=MinValue_B;
    else
        maxValue=max(max(tempMatrix));
        minValue=min(min(tempMatrix));
    end
    tempMatrix=(tempMatrix-minValue)/(maxValue-minValue);
end

CompositeRGB(:,:,3)=tempMatrix;
clear indexLow indexHigh tempMatrix;

hCompositeRGBFig=figure;
image(CompositeRGB), axis image

function WLstop_G_Callback(hObject, eventdata, handles)
% hObject    handle to WLstop_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WLstop_G as text
%        str2double(get(hObject,'String')) returns contents of WLstop_G as a double


% --- Executes during object creation, after setting all properties.
function WLstop_G_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WLstop_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function WLstart_G_Callback(hObject, eventdata, handles)
% hObject    handle to WLstart_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WLstart_G as text
%        str2double(get(hObject,'String')) returns contents of WLstart_G as a double


% --- Executes during object creation, after setting all properties.
function WLstart_G_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WLstart_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function WLstop_B_Callback(hObject, eventdata, handles)
% hObject    handle to WLstop_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WLstop_B as text
%        str2double(get(hObject,'String')) returns contents of WLstop_B as a double


% --- Executes during object creation, after setting all properties.
function WLstop_B_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WLstop_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function WLstart_B_Callback(hObject, eventdata, handles)
% hObject    handle to WLstart_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WLstart_B as text
%        str2double(get(hObject,'String')) returns contents of WLstart_B as a double


% --- Executes during object creation, after setting all properties.
function WLstart_B_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WLstart_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ClusterSimilarityMap.
function ClusterSimilarityMap_Callback(hObject, eventdata, handles)
% hObject    handle to ClusterSimilarityMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SimilarityMap;
global handleSegmentedImage;
global IDX_image;
global degree_image;

NumClusters=str2double(get(handles.SimilarityClustersNum,'String'));

prompt = sprintf('Enter %d space-separated numbers:',NumClusters+1);
dlgtitle = 'Input Threshold values';
answer = inputdlg(prompt,dlgtitle);
ThrValues = str2num(answer{1});
IDX_image=zeros(size(SimilarityMap));
degree_image=zeros(size(SimilarityMap,1),size(SimilarityMap,2),NumClusters);
for i=1:NumClusters
    
    IDX_image(and((SimilarityMap>ThrValues(i)),(SimilarityMap<=ThrValues(i+1))))=i;
    temp=zeros(size(SimilarityMap));

    temp(IDX_image==i)=1;
    degree_image(:,:,i)=temp;
end

handleSegmentedImage=figure;
title('Segmented image');
imagesc(IDX_image), axis('image');
colormap(jet)
set(gca,'Clim',[0 NumClusters]);
map=colormap; numColors=size(map,1);
% stepColors=round(numColors/(NumClusters));
colorbar;

NUMCOLS=floor(NumClusters/3);
if mod(NumClusters,3)>0
   NUMCOLS=NUMCOLS+1;
end
figure,    
for i=1:NumClusters
    subplot(3,NUMCOLS,i)
    imagesc(squeeze(degree_image(:,:,i))), colorbar, colormap(gray), axis('image');
end


function SimilarityClustersNum_Callback(hObject, eventdata, handles)
% hObject    handle to SimilarityClustersNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SimilarityClustersNum as text
%        str2double(get(hObject,'String')) returns contents of SimilarityClustersNum as a double


% --- Executes during object creation, after setting all properties.
function SimilarityClustersNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SimilarityClustersNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in DataToDisplayOpt.
function DataToDisplayOpt_Callback(hObject, eventdata, handles)
% hObject    handle to DataToDisplayOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns DataToDisplayOpt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DataToDisplayOpt
global DataToDisplayOpt;
DataToDisplayOpt=get(hObject,'Value');

% --- Executes during object creation, after setting all properties.
function DataToDisplayOpt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DataToDisplayOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global DataToDisplayOpt;
set(hObject,'Value',1);
DataToDisplayOpt=get(hObject,'Value');


% --- Executes on button press in PerformSpectralPreproccesing.
function PerformSpectralPreproccesing_Callback(hObject, eventdata, handles)
% hObject    handle to PerformSpectralPreproccesing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global WL data Mask Sd;
global WL_original data_original;
global PreProcessOn;

PreProcessOn=get(hObject,'Value');
if PreProcessOn
    Buffer=sprintf('Preproccessing data... ');
    output_textColor(Buffer);
    
    % Adaptation of the exportmask
    data_1D = reshape(data,Sd(1)*Sd(2),Sd(3));
    Mask_1D=reshape(Mask,Sd(1)*Sd(2),1);
    data_1D_Masked = data_1D(Mask_1D(:),:);
    
    WL_original=WL;
    data_original=data;
    prompt = {'Window (odd number):',...
        'polynomial degree:'};
    name = 'Input Smoothing (Sav-Gol) parameters';
    numlines = 1;
    defaultanswer = {'15','2'};
    prepro=inputdlg(prompt,name,numlines,defaultanswer);
    
    if isempty(prepro)
        set(hObject,'Value',0);
        PreProcessOn=get(hObject,'Value');
        return;
    end
    
    win = str2double(prepro{1});
    window = [-1*floor(win/2) floor(win/2)];
    polynom = str2double(prepro{2});
    data_1D_Masked_SMOOTHED = filpoly(data_1D_Masked,(1:size(data_1D_Masked,2)),window,polynom,0);
    WL = WL_original;
    
    data_1D=ones(Sd(1)*Sd(2),length(WL))*NaN;
    data_1D(Mask_1D(:),:)=data_1D_Masked_SMOOTHED;
    data=reshape(data_1D,Sd(1),Sd(2),length(WL));
    
    Buffer=sprintf('Preproccessing data... done');
    output_textColor(Buffer);
else
    WL=WL_original;
    data=data_original;
    Buffer=sprintf('Back to raw data');
    output_textColor(Buffer);
end
% --- Executes on selection change in SpectralPreprocessingOpt.
function SpectralPreprocessingOpt_Callback(hObject, eventdata, handles)
% hObject    handle to SpectralPreprocessingOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SpectralPreprocessingOpt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SpectralPreprocessingOpt
global SpectralPreprocessingOpt;
SpectralPreprocessingOpt=get(hObject,'Value');


% --- Executes during object creation, after setting all properties.
function SpectralPreprocessingOpt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpectralPreprocessingOpt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global SpectralPreprocessingOpt;
set(hObject,'Value',1);
SpectralPreprocessingOpt=get(hObject,'Value');




% --- Executes on button press in ApplyAOI.
function ApplyAOI_Callback(hObject, eventdata, handles)
% hObject    handle to ApplyAOI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ApplyAOI
global AoiOn MaskAOI ThresholdMask Mask Sd data OriginalData PosOK PosNaN;
% global data_DER OriginalData_DER;

AoiOn=get(hObject,'Value');

if (AoiOn)
    Mask=(ThresholdMask)&(MaskAOI);
    PosNaN=find(Mask==0);
    PosOK=find(Mask==1);
    figure, imagesc(Mask), colormap(gray), axis image;
    
    OriginalData=data;
    data_reshaped2D=reshape(data,Sd(1)*Sd(2),Sd(3));
    data_reshaped2D(PosNaN,:)=NaN;
    data=reshape(data_reshaped2D,Sd(1),Sd(2),Sd(3));
  
%     OriginalData_DER=data_DER;
%     data_DER_reshaped2D=reshape(data_DER,Sd(1)*Sd(2),size(OriginalData_DER,3));
%     data_DER_reshaped2D(PosNaN,:)=NaN;
%     data_DER=reshape(data_DER_reshaped2D,Sd(1),Sd(2),size(OriginalData_DER,3));

else
    
    Mask=ones(Sd(1),Sd(2));
    figure, imagesc(Mask), colormap(gray), axis image;
    PosNaN=find(Mask==0);
    PosOK=find(Mask==1);
    data=OriginalData;
    %     data_DER=OriginalData_DER;
end


% --- Executes on button press in CalcAbsorbance.
function CalcAbsorbance_Callback(hObject, eventdata, handles)
% hObject    handle to CalcAbsorbance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CalcAbsorbance
global data;
global data_ABSORBANCE;
global AbsorbanceOn;

AbsorbanceOn=get(hObject,'Value');
if AbsorbanceOn
    % data_ABSORBANCE=log(1./abs(data));
    data_ABSORBANCE=((1-data).^2)./(2*data);
    Buffer=sprintf('Absorbance data available');
    output_textColor(Buffer);
else
    clear global data_ABSORBANCE;
end


% --- Executes on button press in PerformDataDerivative.
function PerformDataDerivative_Callback(hObject, eventdata, handles)
% hObject    handle to PerformDataDerivative (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PerformDataDerivative
global WL data Mask Sd;
global WL_DER data_DER;
global DerivativeOn;

DerivativeOn=get(hObject,'Value');
if DerivativeOn
    
    Buffer=sprintf('Calculating derivative of data... ');
    output_textColor(Buffer);
    
    % Adaptation of the exportmask
    data_1D = reshape(data,Sd(1)*Sd(2),Sd(3));
    Mask_1D=reshape(Mask,Sd(1)*Sd(2),1);
    data_1D_Masked = data_1D(Mask_1D(:),:);

    % WL_step_in_nm=5;
    % WL_i=WL(1):WL_step_in_nm:WL(end);
    % data_1D_Masked_i=zeros(size(data_1D_Masked,1),length(WL_i));
    % data_1D_Masked_i=(interp1(WL,data_1D_Masked',WL_i))';
    % WL_original=WL_i;
    WL_original=WL;
    prompt = {'Window (odd number):',...
        'polynomial degree:',...
        'Derivative degree:'};
    name = 'Input Derivatives (Sav-Gol) parameters';
    numlines = 1;
    defaultanswer = {'15','2','1'};
    prepro = inputdlg(prompt,name,numlines,defaultanswer);
    
    if isempty(prepro)
        set(hObject,'Value',0);
        DerivativeOn=get(hObject,'Value');
        return;
    end
    win = str2double(prepro{1});
    window = [-1*floor(win/2) floor(win/2)];
    polynom = str2double(prepro{2});
    deriv = str2double(prepro{3});
    if size(WL_original,1) ~= 1;
        WL_original = WL_original';
    end
    data_1D_Masked_DER = filpoly(data_1D_Masked,WL_original,window,polynom,deriv);
    WL_DER = WL_original;

    % data_1D_Masked_DER = filpoly(data_1D_Masked_i,WL_i,window,polynom,deriv);
    % WL_DER = WL_i;
    data_1D_Masked_DER = data_1D_Masked_DER(:,floor(win/2)+1:size(data_1D_Masked_DER,2)-floor(win/2));
    WL_DER = WL_DER(floor(win/2)+1:length(WL_DER)-floor(win/2));
    
    data_1D_DER=ones(Sd(1)*Sd(2),length(WL_DER))*NaN;
    data_1D_DER(Mask_1D(:),:)=data_1D_Masked_DER;
    data_DER=reshape(data_1D_DER,Sd(1),Sd(2),length(WL_DER));
    
    Buffer=sprintf('Calculating derivative of data... done');
    output_textColor(Buffer);
    
else
    clear global WL_DER;
    clear global data_DER;
end

% --- Executes during object creation, after setting all properties.
function PerformDataDerivative_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PerformDataDerivative (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in DisplayImageInSpectralROI_R.
function DisplayImageInSpectralROI_R_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayImageInSpectralROI_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global WL data hImageInSpectralROI_R;
global WL_DER data_DER;
global data_ABSORBANCE;
global DataToDisplayOpt DataTypeOpt;
global FixRGBComposite_opt MinValue_R MaxValue_R;

MinValue=MinValue_R;
MaxValue=MaxValue_R;

ImageInSpectralROI=zeros(size(data,1),size(data,2));


switch DataToDisplayOpt
    case 1
        WL_toBeUsed=WL;
        data_toBeUsed=data;
        stretchData=0;
    case 2
        WL_toBeUsed=WL;
        data_toBeUsed=data_ABSORBANCE;
        stretchData=0;
    case 3
        WL_toBeUsed=WL_DER;
        data_toBeUsed=data_DER;
        stretchData=1;
end

WLstart=str2double(get(handles.WLstart_R,'String'));
WLstop=str2double(get(handles.WLstop_R,'String'));

temp=find(WL_toBeUsed>=WLstart);
indexLow=temp(1);
clear temp;

temp=find(WL_toBeUsed<=WLstop);
indexHigh=temp(end);
clear temp;
if and(DataToDisplayOpt==1,DataTypeOpt==1) 
    %Reflectance dat
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
else 
    %PL data or derivative dataq
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');  
end

ImageInSpectralROI=tempMatrix;
clear indexLow indexHigh tempMatrix;

hImageInSpectralROI_R=figure;
imagesc(ImageInSpectralROI), axis image, colormap(gray), title('RED spectral ROI')
if FixRGBComposite_opt==1
    set(gca,'CLim',[MinValue MaxValue])
else
    if and(DataToDisplayOpt==1,DataTypeOpt==1)
        set(gca,'CLim',[0 1])
    end
end


% --- Executes on button press in SaveDataset.
function SaveDataset_Callback(hObject, eventdata, handles)
% hObject    handle to SaveDataset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global DataToDisplayOpt
global WL data data_ABSORBANCE WL_DER data_DER;

switch DataToDisplayOpt
    case 1
        WL_toBeUsed=WL;
        data_toBeUsed=data;
    case 2
        WL_toBeUsed=WL;
        data_toBeUsed=data_ABSORBANCE;
    case 3
        WL_toBeUsed=WL_DER;
        data_toBeUsed=data_DER;
end
Buffer=sprintf('Saving data... ');
output_textColor(Buffer);
saveData(WL_toBeUsed,data_toBeUsed);
Buffer=sprintf('Saving data... done');
output_textColor(Buffer);

function saveData(WL, data)
[file,path] = uiputfile('*.mat');
filename=[path,file];
save(filename,'WL','data');



% --- Executes on selection change in THR_opt.
function THR_opt_Callback(hObject, eventdata, handles)
% hObject    handle to THR_opt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns THR_opt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from THR_opt
global THROpt;
THROpt=get(hObject,'Value');


% --- Executes during object creation, after setting all properties.
function THR_opt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to THR_opt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

global THROpt;
set(hObject,'Value',1);
THROpt=get(hObject,'Value');




function MaxValue_R_Callback(hObject, eventdata, handles)
% hObject    handle to MaxValue_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxValue_R as text
%        str2double(get(hObject,'String')) returns contents of MaxValue_R as a double
global MaxValue_R;
MaxValue_R=str2double(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function MaxValue_R_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxValue_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global MaxValue_R;
set(hObject,'String','1');
MaxValue_R=str2double(get(hObject,'String'));



function MaxValue_G_Callback(hObject, eventdata, handles)
% hObject    handle to MaxValue_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxValue_G as text
%        str2double(get(hObject,'String')) returns contents of MaxValue_G as a double
global MaxValue_G;
MaxValue_G=str2double(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function MaxValue_G_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxValue_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global MaxValue_G;
set(hObject,'String',1);
MaxValue_G=str2double(get(hObject,'String'));



function MaxValue_B_Callback(hObject, eventdata, handles)
% hObject    handle to MaxValue_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxValue_B as text
%        str2double(get(hObject,'String')) returns contents of MaxValue_B as a double
global MaxValue_B;
MaxValue_B=str2double(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function MaxValue_B_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxValue_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
MinThrValue=str2double(get(hObject,'String'));
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global MaxValue_B;
set(hObject,'String',1);
MaxValue_B=str2double(get(hObject,'String'));


% --- Executes on button press in DisplayImageInSpectralROI_G.
function DisplayImageInSpectralROI_G_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayImageInSpectralROI_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global WL data hImageInSpectralROI_G;
global WL_DER data_DER;
global data_ABSORBANCE;
global DataToDisplayOpt DataTypeOpt;
global FixRGBComposite_opt MinValue_G MaxValue_G;

minValue=MinValue_G;
maxValue=MaxValue_G;

ImageInSpectralROI=zeros(size(data,1),size(data,2));

switch DataToDisplayOpt
    case 1
        WL_toBeUsed=WL;
        data_toBeUsed=data;
        stretchData=0;
    case 2
        WL_toBeUsed=WL;
        data_toBeUsed=data_ABSORBANCE;
        stretchData=0;
    case 3
        WL_toBeUsed=WL_DER;
        data_toBeUsed=data_DER;
        stretchData=1;
end

WLstart=str2double(get(handles.WLstart_G,'String'));
WLstop=str2double(get(handles.WLstop_G,'String'));

temp=find(WL_toBeUsed>=WLstart);
indexLow=temp(1);
clear temp;

temp=find(WL_toBeUsed<=WLstop);
indexHigh=temp(end);
clear temp;
if and(DataToDisplayOpt==1,DataTypeOpt==1) 
    %Reflectance dat
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
else 
    %PL data or derivative dataq
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');  
end

ImageInSpectralROI=tempMatrix;
clear indexLow indexHigh tempMatrix;

hImageInSpectralROI_G=figure;
imagesc(ImageInSpectralROI), axis image, colormap(gray), title('GREEN spectral ROI')

if FixRGBComposite_opt==1
    set(gca,'CLim',[minValue maxValue])
else
    if and(DataToDisplayOpt==1,DataTypeOpt==1)
        set(gca,'CLim',[0 1])
    end
end


% --- Executes on button press in DisplayImageInSpectralROI_B.
function DisplayImageInSpectralROI_B_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayImageInSpectralROI_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global WL data hImageInSpectralROI_B;
global WL_DER data_DER;
global data_ABSORBANCE;
global DataToDisplayOpt DataTypeOpt;
global FixRGBComposite_opt MinValue_B MaxValue_B;

minValue=MinValue_B;
maxValue=MaxValue_B;

ImageInSpectralROI=zeros(size(data,1),size(data,2));

switch DataToDisplayOpt
    case 1
        WL_toBeUsed=WL;
        data_toBeUsed=data;
        stretchData=0;
    case 2
        WL_toBeUsed=WL;
        data_toBeUsed=data_ABSORBANCE;
        stretchData=0;
    case 3
        WL_toBeUsed=WL_DER;
        data_toBeUsed=data_DER;
        stretchData=1;
end

WLstart=str2double(get(handles.WLstart_B,'String'));
WLstop=str2double(get(handles.WLstop_B,'String'));

temp=find(WL_toBeUsed>=WLstart);
indexLow=temp(1);
clear temp;

temp=find(WL_toBeUsed<=WLstop);
indexHigh=temp(end);
clear temp;
if and(DataToDisplayOpt==1,DataTypeOpt==1) 
    %Reflectance dat
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');
else 
    %PL data or derivative dataq
    tempMatrix=mean(data_toBeUsed(:,:,indexLow:indexHigh),3,'omitnan');  
end

ImageInSpectralROI=tempMatrix;
clear indexLow indexHigh tempMatrix;

hImageInSpectralROI_B=figure;
imagesc(ImageInSpectralROI), axis image, colormap(gray), title('BLUE spectral ROI')

if FixRGBComposite_opt==1
    set(gca,'CLim',[minValue maxValue])
else
    if and(DataToDisplayOpt==1,DataTypeOpt==1)
        set(gca,'CLim',[0 1])
    end
end



function MinValue_R_Callback(hObject, eventdata, handles)
% hObject    handle to MinValue_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinValue_R as text
%        str2double(get(hObject,'String')) returns contents of MinValue_R as a double
global MinValue_R;
MinValue_R=str2num(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function MinValue_R_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinValue_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global MinValue_R;
set(hObject,'String','0');
MinValue_R=str2double(get(hObject,'String'));



function MinValue_G_Callback(hObject, eventdata, handles)
% hObject    handle to MinValue_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinValue_G as text
%        str2double(get(hObject,'String')) returns contents of MinValue_G as a double
global MinValue_G;
MinValue_G=str2num(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function MinValue_G_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinValue_G (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global MinValue_G;
set(hObject,'String','0');
MinValue_G=str2double(get(hObject,'String'));



function MinValue_B_Callback(hObject, eventdata, handles)
% hObject    handle to MinValue_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinValue_B as text
%        str2double(get(hObject,'String')) returns contents of MinValue_B as a double
global MinValue_B;
MinValue_B=str2num(get(hObject,'String'));


% --- Executes during object creation, after setting all properties.
function MinValue_B_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinValue_B (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global MinValue_B;
set(hObject,'String','0');
MinValue_B=str2double(get(hObject,'String'));


% --- Executes on button press in FixRGBComposite_Bands.
function FixRGBComposite_Bands_Callback(hObject, eventdata, handles)
% hObject    handle to FixRGBComposite_Bands (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FixRGBComposite_Bands
global FixRGBComposite_opt;
FixRGBComposite_opt=get(hObject,'Value');


% --- Executes on selection change in listbox_THRopt.
function listbox_THRopt_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_THRopt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_THRopt contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_THRopt


% --- Executes during object creation, after setting all properties.
function listbox_THRopt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_THRopt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ViewSUMIMGbutton.
function ViewSUMIMGbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ViewSUMIMGbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global WL data;
global index DisplayX DataTypeOpt IMG_SUM;
global WL_DER data_DER;
global data_ABSORBANCE;
global DataToDisplayOpt;
global handleFigureSUM;


WL_START=str2double(get(handles.WL_start,'String'));
WL_END=str2double(get(handles.WL_end,'String'));

switch DataToDisplayOpt
    case 1
        WL_toBeUsed=WL;
    case 2
        WL_toBeUsed=WL;
    case 3
        WL_toBeUsed=WL_DER;
end

temp=find(WL_toBeUsed>=WL_START);
indexLow=temp(1);
clear temp;

temp=find(WL_toBeUsed<=WL_END);
indexHigh=temp(end);
clear temp;

switch DataToDisplayOpt
    case 1
        IMG_SUM=sum(data(:,:,indexLow:indexHigh),3);
    case 2
        IMG_SUM=sum(data_ABSORBANCE(:,:,indexLow:indexHigh),3);
    case 3
        IMG_SUM=sum(data_DER(:,:,indexLow:indexHigh),3);
end
% 
% if exist("handleFigureSUM","var")
%     figure(handleFigureSUM);
% else
%     handleFigureSUM=figure;
% 
axes(handles.axes1);
imagesc(IMG_SUM);
fixOn=get(handles.rescaleSelection,'Value');
if fixOn
    CMin=str2double(get(handles.rescaleMin,'String'));
    CMax=str2double(get(handles.rescaleMax,'String'));
    set(gca,'Clim',[CMin CMax]);
elseif and(DataTypeOpt==1,DataToDisplayOpt==1) %Reflectance
    set(gca,'Clim',[0 1]) 
end
colormap(gray), colorbar, axis image, axis off;
title('Integral of all images in the selected spectral band');



% --- Executes on button press in PrintSUM_IMG.
function PrintSUM_IMG_Callback(hObject, eventdata, handles)
% hObject    handle to PrintSUM_IMG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global IMG_SUM;

axes(handles.axes1);
CLim=get(gca,'Clim');


PrintFigureHn=figure;
imagesc(IMG_SUM), axis image, axis off, colormap(gray), set(gca,'CLim',CLim);
set(gca,'XTick',[]);
set(gca,'YTick',[]);
[PrintFilename, PrintPathname, flag]= uiputfile('*.png', 'print JPG figure');

if flag==0
    return;
end

NamePrint=[PrintPathname PrintFilename];
print(PrintFigureHn,'-djpeg100',NamePrint);
saveas(PrintFigureHn,NamePrint(1:end-4),'fig')



% --- Executes on button press in PlotEEMSpectra.
function PlotEEMSpectra_Callback(hObject, eventdata, handles)
% hObject    handle to PlotEEMSpectra (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Xaxis Yaxis data WL;
global normalizationOn;



SpectrumType=get(handles.ExOrEmSpectrum,'Value');
minExWLtoPlot=str2double(get(handles.minExWLtoPlot,'String'));
maxExWLtoPlot=str2double(get(handles.maxExWLtoPlot,'String'));
i_minExWLtoPlot=findIndex(minExWLtoPlot,Yaxis);
i_maxExWLtoPlot=findIndex(maxExWLtoPlot,Yaxis);

minEmWLtoPlot=str2double(get(handles.minEmWLtoPlot,'String'));
maxEmWLtoPlot=str2double(get(handles.maxEmWLtoPlot,'String'));
i_minEmWLtoPlot=findIndex(minEmWLtoPlot,Xaxis);
i_maxEmWLtoPlot=findIndex(maxEmWLtoPlot,Xaxis);

dataSubset=data(i_minExWLtoPlot:i_maxExWLtoPlot,i_minEmWLtoPlot:i_maxEmWLtoPlot,:);

switch SpectrumType
    case 1 % emission spectrum (horizontal profile)
        Spectra=squeeze(mean(dataSubset,1));
    case 2 % excitation spectrum (vertical profile)
        Spectra=squeeze(mean(dataSubset,2));
end


if normalizationOn
    SpectraMax=repmat(max(Spectra,[],1),[size(Spectra,1) 1]);
    Spectra_n=Spectra./SpectraMax;
    SpectraToBePlotted=Spectra_n;
    labelYaxis='Normalized emission intensity \a.u.';
else
    SpectraToBePlotted=Spectra;
    labelYaxis='Emission intensity \a.u.';
end

LegendCellArray=num2cell(WL');

for i=1:length(WL)
    LegendCellArray{i}=strcat(num2str(LegendCellArray{i}),' kJ/cm2');
end

figure
switch SpectrumType
    case 1 % emission spectrum (horizontal profile)
        plot(Xaxis(i_minEmWLtoPlot:i_maxEmWLtoPlot),SpectraToBePlotted);
        title('EmissionSpectra versus irradiation dose');
        xlabel('Emission wavelength \nm');
    case 2 % excitation spectrum (vertical profile)
        plot(Yaxis(i_minExWLtoPlot:i_maxExWLtoPlot),SpectraToBePlotted);
        title('ExcitationSpectra versus irradiation dose')
        xlabel('Excitation wavelength \nm');
end

newcolors = [1 0 0; 0 1 0; 0 0 1; 1 1 0; 0 1 1; 1 0 1;
    0.5 0 0; 0 0.5 0; 0 0 0.5; .5 .5 0; 0 .5 .5; .5 0 .5;
    .75 0 0; 0 .75 0; 0 0 .75; .75 .75 0; 0 .75 .75; .75 0 .75
    .25 0 0; 0 .25 0; 0 0 .25; .25 .25 0; 0 .25 .25; .25 0 .25];

newcolorsToBeUsed=newcolors(1:size(WL,2),:);
colororder(gcf,newcolorsToBeUsed);
ylabel(labelYaxis)
legend(LegendCellArray,'Location','northeastoutside');


% --- Executes on selection change in ExOrEmSpectrum.
function ExOrEmSpectrum_Callback(hObject, eventdata, handles)
% hObject    handle to ExOrEmSpectrum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ExOrEmSpectrum contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ExOrEmSpectrum


% --- Executes during object creation, after setting all properties.
function ExOrEmSpectrum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExOrEmSpectrum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minExWLtoPlot_Callback(hObject, eventdata, handles)
% hObject    handle to minExWLtoPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minExWLtoPlot as text
%        str2double(get(hObject,'String')) returns contents of minExWLtoPlot as a double


% --- Executes during object creation, after setting all properties.
function minExWLtoPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minExWLtoPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxExWLtoPlot_Callback(hObject, eventdata, handles)
% hObject    handle to maxExWLtoPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxExWLtoPlot as text
%        str2double(get(hObject,'String')) returns contents of maxExWLtoPlot as a double


% --- Executes during object creation, after setting all properties.
function maxExWLtoPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxExWLtoPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minEmWLtoPlot_Callback(hObject, eventdata, handles)
% hObject    handle to minEmWLtoPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minEmWLtoPlot as text
%        str2double(get(hObject,'String')) returns contents of minEmWLtoPlot as a double


% --- Executes during object creation, after setting all properties.
function minEmWLtoPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minEmWLtoPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxEmWLtoPlot_Callback(hObject, eventdata, handles)
% hObject    handle to maxEmWLtoPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxEmWLtoPlot as text
%        str2double(get(hObject,'String')) returns contents of maxEmWLtoPlot as a double


% --- Executes during object creation, after setting all properties.
function maxEmWLtoPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxEmWLtoPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CorrectSpectralDataset.
function CorrectSpectralDataset_Callback(hObject, eventdata, handles)
% hObject    handle to CorrectSpectralDataset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CorrectSpectralDataset
global data data_original;


CorrectionOn=get(hObject,'Value');
if CorrectionOn
    data_original=data;
    CorrFactor=str2double(get(handles.CorrectionFactor,'String'));
    data=data./CorrFactor;
else
    data=data_original;
end

function CorrectionFactor_Callback(hObject, eventdata, handles)
% hObject    handle to CorrectionFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CorrectionFactor as text
%        str2double(get(hObject,'String')) returns contents of CorrectionFactor as a double


% --- Executes during object creation, after setting all properties.
function CorrectionFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CorrectionFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function ExportMask_Callback(hObject, eventdata, handles)
% hObject    handle to ExportMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Mask;

[outputDataFilename, outputDataPathname, flag] = uiputfile('*.mat', 'Save AOI and/or THR mask');
if flag==0
else
    save([outputDataPathname outputDataFilename], 'Mask');
end

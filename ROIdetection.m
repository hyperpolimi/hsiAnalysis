%% Cross-correlation to find template in image

% Load original Hypercube
[filename_original, pathname_original] = uigetfile({'*.mat';'*.h5*'}, 'Load original whole frame file');
if strcmp(filename_original(end-2:end),'.h5')
    H5toMatlabHypercube(filename_original, pathname_original); %creates a .mat in the same folder
    filename_original= strcat(filename_original(1:end-3), '_hyp.mat');
end
filename_tot_original = [pathname_original, filename_original];
load(filename_tot_original);
image = mean(HyperMatrix, 3); 
%%
% Load roi
[filename_roi, pathname_roi] = uigetfile({'*.mat';'*.h5*'}, 'Load cut file');
filename_tot_roi = [pathname_roi, filename_roi]; 

if strcmp(filename_roi(end-2:end),'.h5') %if loaded file is .h5
    [Hyperspectrum_cube,f,saturationMap,file_totCal,fr_real,Intens] = H5HypercubeRead(filename_tot_roi);
    if isempty(fr_real)
        clear fr_real
    end
    if isempty(file_totCal)
        clear file_totCal
    end
    NoSaturationMap=saturationMap;
    clear saturationMap

    if isempty(Intens)
        Intens=sum(abs(Hyperspectrum_cube),3);
    end
else
    load(filename_tot_roi); 
end


if size(Hyperspectrum_cube,3)==2.*length(f) %if the spectral hypecube is complex the real and imag are stacked one over the other
    Hyperspectrum_cube_real=Hyperspectrum_cube(:,:,1:size(Hyperspectrum_cube,3)./2);
    Hyperspectrum_cube_imag=Hyperspectrum_cube(:,:,size(Hyperspectrum_cube,3)./2+1:end);
    clear Hyperspectrum_cube
    Hyperspectrum_cube=zeros(size(Hyperspectrum_cube_real));
    Hyperspectrum_cube=Hyperspectrum_cube_real+1i.*Hyperspectrum_cube_imag;
    clear Hyperspectrum_cube_real Hyperspectrum_cube_imag
end

roi = mean(abs(Hyperspectrum_cube), 3); 

%%
% Compute correlation
c = normxcorr2(roi,image);
[ypeak,xpeak] = find(c==max(c(:)));

% Account for the padding that normxcorr2 adds to define upper-left
% coordinate [xmin, ymin]
ymin = ypeak-size(roi,1);
xmin = xpeak-size(roi,2);

% Define x axis and y axis extremes
x_axis = [xmin, xmin+size(roi,2)-1];
y_axis = [ymin, ymin+size(roi,1)-1]; 

% % Display the matched area
figure();
imagesc(image); 
drawrectangle(gca,'Position',[xmin,ymin,size(roi,2),size(roi,1)], ...
    'FaceAlpha',0);
axis image; 
figure(); 
imagesc(roi); axis image; 



%%
settings = struct(); 
settings.pol = 1; 
settings.t_limits = [20, 180]; 
settings.spec_num = 300; 
settings.wave_limits = [400 1000]; 
settings.file_tot_cal = 'C:\Users\marti\OneDrive - Politecnico di Milano\MAGISTRALE\Thesis\MatLab\Calibration\Macro camera\Calibration_250730.mat'; 
settings.file_tot_del ='No delay correction';
settings.apod = 1; 
settings.x_limits = x_axis;  
settings.y_limits = y_axis; 
save(strcat(filename_tot_original, '_Settings.mat'), "settings",'-mat'); 


function [Hyperspectrum_cube,f,saturationMap,file_totCal,fr_real,Intens] = MJ2HypercubeRead

%function to load the mj2 (Motion JPEG 2000 lossless video) Spectral Hypercubes in Matlab
%
%Hyperspectrum_cube: spectral hypercube dataset (absolute or complex)
%f: pseudofrequency axis
%saturationMap: map of saturated pixels (0:saturated, 1:not saturated
%file_totCal: frequency calibration, if it is present
%fr_real: real calibrated frequencies axis, if it is present
%Intens: 2D matrix hypercube integral over frequencies

dir0=('C:\Users\HARDi\Desktop\Tesi\Codice immagini');

[file_name,path_name] = uigetfile('*.mj2', 'Load spectral Hypercube',dir0);
filename=[path_name '\' file_name];

obj=VideoReader(filename);

load([filename(1:end-4) '_VALUES.mat']); %here there're minimum, maximum, f, saturationMap and fr_real and file_totCal if exist

if ~exist('file_totCal')
    file_totCal=[];
end

if ~exist('fr_real')
    fr_real=[];
end

if ~exist('Intens')
    Intens=[];
end

if ~exist('minimum')
    minimum=[];
end

if ~exist('maximum')
    maximum=[];
end

h=waitbar(1/2,'hypercube conversion from video to .mat...');

tic;
images=obj.read; %video uint16 images stack
Hyperspectrum_cube=double(squeeze(images(:,:,1,:)))./(2.^16-1).*maximum+minimum;
tempo=toc;
waitbar(1,h);
close(h);

clear images

fprintf('\nTime elapsed for the conversion: %.1f seconds\n',tempo);

if size(Hyperspectrum_cube,3)==2.*length(f) %if the spectral hypecube is complex the real and imag are stacked one over the other
    Hyperspectrum_cube_real=Hyperspectrum_cube(:,:,1:size(Hyperspectrum_cube,3)./2);
    Hyperspectrum_cube_imag=Hyperspectrum_cube(:,:,size(Hyperspectrum_cube,3)./2+1:end);
    clear Hyperspectrum_cube
    Hyperspectrum_cube=zeros(size(Hyperspectrum_cube_real));
    Hyperspectrum_cube=Hyperspectrum_cube_real+1i.*Hyperspectrum_cube_imag;
    clear Hyperspectrum_cube_real Hyperspectrum_cube_imag
end

end
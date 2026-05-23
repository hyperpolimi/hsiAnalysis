function [Hyperspectrum_cube,f,saturationMap,file_totCal,fr_real,Intens] = H5HypercubeRead(varargin)

%function to load the H5 (hyerarchical files) Spectral Hypercubes in Matlab
%
%Hyperspectrum_cube: spectral hypercube dataset (absolute or complex)
%f: pseudofrequency axis
%saturationMap: map of saturated pixels (0:saturated, 1:not saturated
%file_totCal: frequency calibration, if it is present
%fr_real: real calibrated frequencies axis, if it is present
%Intens: 2D matrix hypercube integral over frequencies

if nargin < 1

    [file_name,path_name] = uigetfile('*.h5', 'Load spectral Hypercube');
    filename=[path_name '\' file_name];

    filename_print=strrep(filename,'\','/');
    fprintf(['\nHypercube ' filename_print ' loaded\n']);

else
    filename = varargin{1}; 
end

info=h5info(filename); %struct with info of Datasets in H5 file

if isempty(cell2mat({info.Datasets}))
    file_totCal=[];
else
    H5_datasets_list=cell2mat({info.Datasets.Name}); %string listing all datasets in the H5 file

    if contains(H5_datasets_list,'file_totCal')
        file_totCal=cell2mat(h5read(filename,'/file_totCal')); %if calibration string exists load it
    else
        file_totCal=[];
    end
end

info_datasets=h5info(filename,'/SpectralHypercube'); %struct with info of Datasets in SpectralHypercube dataset in H5 file
H5_variables_list=cell2mat({info_datasets.Datasets.Name}); %string listing all datasets (variables) names inside the SpectralHypercube dataset in the H5 file

Hyperspectrum_cube=h5read(filename,'/SpectralHypercube/Hyperspectrum_cube');
f=h5read(filename,'/SpectralHypercube/f');
saturationMap=h5read(filename,'/SpectralHypercube/saturationMap');

if contains(H5_variables_list,'fr_real')
    fr_real=h5read(filename,'/SpectralHypercube/fr_real'); %if calibrated frequencies axis exists load it
else
    fr_real=[];
end

if contains(H5_variables_list,'Intens')
    Intens=h5read(filename,'/SpectralHypercube/Intens'); %if Intens matrix preview exists
else
    Intens=[];
end

if contains(H5_variables_list,'minimum')
    minimum=h5read(filename,'/SpectralHypercube/minimum'); %if minimum (to reconvert uint16 dataset) exists load it
else
    minimum=[];
end

if contains(H5_variables_list,'maximum')
    maximum=h5read(filename,'/SpectralHypercube/maximum'); %if maximum (to reconvert uint16 dataset) exists load it
else
    maximum=[];
end

if isa(Hyperspectrum_cube,'uint16')
    Hyperspectrum_cube=double(Hyperspectrum_cube)./(2.^16-1).*maximum+minimum; %double reconversion procedure from uint16
    fprintf('\n The loaded hypercube was saved in uint16 type\n\n'); %message to explicit the hypercube format
elseif isa(Hyperspectrum_cube,'single')
    Hyperspectrum_cube=double(Hyperspectrum_cube); %reconversion to double
    fprintf('\n The loaded hypercube was saved in single type\n\n'); %message to explicit the hypercube format
else
    fprintf('\n The loaded hypercube was saved in double type\n\n'); %message to explicit the hypercube format
end

if size(Hyperspectrum_cube,3)==2.*length(f) %if the spectral hypecube is complex the real and imag are stacked one over the other
    Hyperspectrum_cube_real=Hyperspectrum_cube(:,:,1:size(Hyperspectrum_cube,3)./2);
    Hyperspectrum_cube_imag=Hyperspectrum_cube(:,:,size(Hyperspectrum_cube,3)./2+1:end);
    clear Hyperspectrum_cube
    Hyperspectrum_cube=zeros(size(Hyperspectrum_cube_real));
    Hyperspectrum_cube=Hyperspectrum_cube_real+1i.*Hyperspectrum_cube_imag;
    clear Hyperspectrum_cube_real Hyperspectrum_cube_imag
end


end
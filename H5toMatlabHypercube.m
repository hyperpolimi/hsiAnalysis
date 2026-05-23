%This program converts the .h5 file into a .mat file that can be feeded to
%HypespectralAnalysis_Time.m. The .mat temporal hypercube will be saved in
%the same folder of the .h5 file. The .mat temporal hypercube is a struct
%file with HyperMatrix (the temporal hypercube) and t (the delay axis)

%This program can be run directly without input arguments or called from another program 
% (with inputs filename_Hyper, pathname_Hyper)

function H5toMatlabHypercube(varargin)

if nargin==0 %run directly the program
    %load hypercube
    [filename_Hyper, pathname_Hyper] = uigetfile('*.h5', 'Load Hypercube');
    path(path,pathname_Hyper);

else %pass filename_Hyper and pathname_Hyper
    filename_Hyper=varargin{1};
    pathname_Hyper=varargin{2};
    path(path,pathname_Hyper);

end


[HyperMatrix,el_size,step]=H5ReadStackHyper(filename_Hyper);
%% original version Benedetto 
% el_size = [dx,dy,dz]
% step = [start_pos,step,step_num]
%%start_pos in mm
%%step in um
% t=step(1).*1e3:step(2):step(1).*1e3+step(2).*(step(3)-1); %t is in um
%%Uncomment for saving in .mat
%h=waitbar(0.5,'Saving hypercube in .mat file');
%save(file_tot,'t','HyperMatrix');
%close(h);
%clear all;

%new version Martina 
t=step'; 

HyperMatrix=double(HyperMatrix); %HyperMatrix is converted from uint16 to double
HyperMatrix=permute(HyperMatrix,[2 1 3]); %change X and Y as they are in the measurement setup

filename=[filename_Hyper(1:end-3) '_hyp.mat'];
file_tot=[pathname_Hyper,filename];


% Checks the size of the matrix, before saving
HyProp = whos('HyperMatrix') ;
Gigabytes = HyProp.bytes/2^30;

if Gigabytes<1.8
    save(file_tot,'t','HyperMatrix');
else
    save(file_tot,'t','HyperMatrix','-v7.3'); 
end

end
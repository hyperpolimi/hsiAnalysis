%% Temporal hypercube generator for hyperspectral microscope Leica.

%% Preparation of raw data for temporal hypercube generation
% Starting from the files generated from LABVIEW acquisition software:
% 1. create a .txt file with the delay axis from .xls file
% 2. create a folder Infos where both .txt and .xls files are moved
% 3. create two new folders, old and results, in Infos
% 4. rename bins for a proper analysis

% Martina 10/03/2026

dir0=uigetdir('Select directory for raw data folder');

if isfolder(fullfile(dir0, 'Infos'))
    fprintf('\n Infos folder already exists in the chosen directory. Check your data!')
    return
end

xlsFile = dir(fullfile(dir0, '*.xls')); %xls file

if (xlsFile(2).name(end-12:end) == 'settings_.xls')
    xlsTime = xlsFile(1); 
    xlsSett = xlsFile(2);
elseif (xlsFile(1).name(end-12:end) == 'settings_.xls')
    xlsTime = xlsFile(2); 
    xlsSett = xlsFile(1);
else 
    disp('Check the name of your files!')
end

delays = load(fullfile(xlsTime.folder, xlsTime.name));
txtTime = fullfile(dir0, "Delays.txt");
save(txtTime,'delays','-ASCII');


newFolder=fullfile(dir0, 'Infos');
mkdir(newFolder)
newFolderIn = fullfile(newFolder, 'Old');
mkdir(newFolderIn)
newFolderIn2 = fullfile(newFolder, 'Results');
mkdir(newFolderIn2)


% Moving files in Infos
movefile(txtTime, newFolder);
movefile(fullfile(dir0, xlsTime.name), newFolderIn);
movefile(fullfile(dir0, xlsSett.name), newFolderIn);


% Rename bins (same as RenameBin)
el=dir(dir0);
fine=size(el,1)-2; % number of files in folder

ii=1;
while (el(ii).isdir)
    ii=ii+1;
end

lun=length(el(ii).name); % Length of the shortest file

pnt=0;

h=waitbar(0,'Loading all files');

for ii=1:size(el,1)

    if not(el(ii).isdir)

        pnt=pnt+1;

        if length(el(ii).name)==lun

            oldname=[dir0,'/',el(ii).name];
            newname=[dir0,'/',el(ii).name(1:end-5),'000',el(ii).name(end-4:end)];
            % newname=[dir2,'/',el(ii).name(1:end-1),'00',el(ii).name(end:end)]; % ONLY for files with NO extension
            movefile (oldname,newname); % (1)

        elseif length(el(ii).name)==lun+1

            oldname=[dir0,'/',el(ii).name];
            newname=[dir0,'/',el(ii).name(1:end-6),'00',el(ii).name(end-5:end)];
            % newname=[dir2,'/',el(ii).name(1:end-2),'0',el(ii).name(end-1:end)]; % ONLY for files with NO extension
            movefile (oldname,newname); % (1)

        elseif length(el(ii).name)==lun+2

            oldname=[dir0,'/',el(ii).name];
            newname=[dir0,'/',el(ii).name(1:end-7),'0',el(ii).name(end-6:end)];
            % newname=[dir2,'/',el(ii).name(1:end-2),'0',el(ii).name(end-1:end)]; % ONLY for files with NO extension
            movefile (oldname,newname); % (1)

        end

        waitbar(pnt/fine,h);

    end

end

close(h);

%% Generation of temporal hypercube
form=Dinput('\n File format (0: TIFF - 1: binary Milan - 2: binary BH)',1);

el=dir(dir0);
fine=size(el,1)-2; % number of files in folder

ii=1;
while (el(ii).isdir)
    ii=ii+1;
end

stringa=[' *** Analysis of file ',el(ii).name,' ***'];
fprintf('\n\n%s',stringa);

switch  form
    case 0
        A=double((fullfile(dir0, el(ii).name)))/256;
    case 1
        fprintf('\n\n Sensor size:');
        fprintf(  '\n   1. 1004 x 1002 \n   2. 1024 x 1280 \n   3. 1280 x 1024 \n   4. Other');
        Sensor=Dinput('\n\n Select sensor size:',1);

        switch Sensor
            case 1
                Sx=1004;
                Sy=1002;
            case 2
                Sx=1024;
                Sy=1280;
            case 3
                Sy=1024;
                Sx=1280;
            case 4
                Sx=Dinput('\n X dimension:',1004);
                Sy=Dinput('\n Y dimension:',1002);
        end

        fileID = fopen(fullfile(dir0, el(ii).name));
        A = fread(fileID,[Sx Sy],'uint32');
        fclose(fileID);
    case 2
        A=load(fullfile(dir0, el(ii).name));
end


% Grey colormap
M=linspace(0,1,512)';
MAP=[M M M];


A=A(:,:,1); % Takes the first useful file.
figure(); imagesc(A); colormap(MAP);
ax = gca;
ax.FontSize = 12;
ax.LineWidth = 1.5;
ax.Title.String = 'Preview: First frame'
[a,b]=size(A);
pnt = 0;

proceed = Dinput('\n\n Are you sure to proceed?', 1);
if ~proceed
    disp('Temporal hypercube will not be created. Use HyperspectralAnalysis_Time');
    return;
end

h=waitbar(0,'Loading all files');

switch  form
    case 0
        for ii=1:size(el,1)

            if not(el(ii).isdir)

                pnt=pnt+1;

                A=double(imread(fullfile(dir0, el(ii).name)))/256;
                HyperMatrix(:,:,pnt) = sepblockfun(A(1:a,1:b),[1,1],'mean');

                waitbar(pnt/fine,h);

            end

        end
    case 1

        for ii=1:size(el,1)

            if not(el(ii).isdir)

                pnt=pnt+1;

                fileID = fopen(fullfile(dir0, el(ii).name));
                A = fread(fileID,[Sx Sy],'uint32');
                fclose(fileID);
                HyperMatrix(:,:,pnt) = sepblockfun(A(1:a,1:b),[1,1],'mean');

                waitbar(pnt/fine,h);

            end

        end

    case 2

        for ii=1:size(el,1)

            if not(el(ii).isdir)

                pnt=pnt+1;

                A=load(fullfile(dir0, el(ii).name));
                HyperMatrix(:,:,pnt) = sepblockfun(A(1:a,1:b),[1,1],'mean');

                waitbar(pnt/fine,h);

            end

        end
end

fprintf(['\n  -- Number of images: ',num2str(pnt),' --']);
close(h);


% Load time axis
t = delays;

t=t(1:pnt); % as many delays as frames
if iscolumn(t), t=t'; end

t=t.*10^(3); %um


%% SPATIAL SHIFT TEMPORAL HYPERCUBE CORRECTION **Benedetto** 27/05/2022
%Code added for spatial shift correction along y-axis of the image
%Updated with gradual correction on 29/06/2022
fprintf('\n\n    Spatial y-axis shift correction (necessary for YVO4 interferometer):');
fprintf(  '\n    1. standard YVO4+LucaR camera correction \n    2. custom correction \n    3. registration\n    4.no correction\n');
SpatialShiftCorrection=Dinput('\n\n    Select choice:',1);

switch SpatialShiftCorrection
    case 3
        z = size(HyperMatrix, 3); 
        HyperMatrix_original = HyperMatrix; 
        HyperMatrix = [];
        %reference image fixed at the beginning 
        fixed_image=HyperMatrix_original(:,:,1);
        
        for i=1:z
        uncorrected_image=HyperMatrix_original(:,:,i);%compute necessary transform (translation and rotation)
        transform=imregcorr(uncorrected_image, fixed_image);
        
        Rfixed=imref2d(size(fixed_image));
        HyperMatrix(:,:,i)=imwarp(uncorrected_image, transform, OutputView=Rfixed);
        %all corrected images should have the same dimension as the initial one , thus I can create a new corrected
        %hypercube that is going to have strange features at the edges: I'm going to cut it manually during analysis.
        end
        spatialShiftCorrection='Spatial shift correction: registration'; %string to save with Temporal Hypercube


    case 4
        spatialShiftCorrection='No spatial shift correction applied'; %string to save with Temporal Hypercube

    otherwise %cases 1 and 2
        if SpatialShiftCorrection==1
            wedge_excursion=17999; %YVO4 wedge excursion [um] in the 220527\USAF_0 measurement with LucaR camera
            spatial_shift=17; %spatial shift [pixels] for the wedge excursion above
            pixel_ratio=1002./Sy; %image pixel ratio with respect to the LucaR 8um pixel
            %(1002/Sy): binning in detection (pixel dimension compared to the LucaR pixel)

        else
            wedge_excursion=Dinput('\n\n    Wedge excursion [um]:',9600);
            spatial_shift=Dinput('\n\n    Related image spatial shift [pixels] (without detection binning):',5);
            %pixel_dimension=Dinput('\n\n    Camera pixel dimension [um]:',8);
            binning=Dinput('\n\n    Camera binning applied in detection:',1);
            pixel_ratio=binning;
            %pixel_ratio=pixel_dimension./8.*binning.*Bin; %image pixel ratio with respect to the LucaR 8um pixel
            %clear pixel_dimension binning
        end

        shift_rate=spatial_shift./wedge_excursion./pixel_ratio; %pixels shift velocity [pixels/um]
        shift_num=floor((max(t)-min(t)).*shift_rate); %number of cumulative 1-pixel shift to apply during the delay scan

        transl=0; %pixels translation
        R_pxl_w=0; %right (adjacent) pixel weight for gradual shift correction
        L_pxl_w=1; %left (current) pixel weigth for gradual shift correction

        h_shiftCorrection=waitbar(0,'Temporal hypercube spatial shift correction...');

        %gradual shift correction of temporal hypercube frames
        for index=2:length(t) %the first frame is not shifted (index start from 2)

            if R_pxl_w>=1 %once the left (adjacent) pixel weight is greater than one it means that you need to apply a translation 1 pixel on the image
                R_pxl_w=R_pxl_w-1;
                L_pxl_w=1-R_pxl_w;
                transl=transl+1; %update transl by adding 1 (you need a translation of 1 pixel more)
            end

            R_pxl_w=R_pxl_w+shift_rate.*(t(index)-t(index-1)); %the right (adjacent) pixel weight is calculated considering sub-pixel image shift due to the wedge step t(index)-t(index-1) with respect to the pixel size
            L_pxl_w=1-R_pxl_w;

            %correction of the frame n° index by a weighted average of the
            %frame (matrix of current pixels) with its copy shifted by 1
            %pixel on the y direction (matrix of adjacent pixels)
            HyperMatrix(:,1:end-shift_num-1,index)=R_pxl_w.*HyperMatrix(:,2+transl:end-shift_num+transl,index)+L_pxl_w.*HyperMatrix(:,1+transl:end-shift_num-1+transl,index);

            waitbar((index-1)./(length(t)-1),h_shiftCorrection);

        end

        HyperMatrix=HyperMatrix(:,1:end-shift_num-1,:); %pixels in the border are discarded
        b=size(HyperMatrix,2); %new y dimension of the matrix
        close(h_shiftCorrection);
        spatialShiftCorrection=['Spatial shift correction on Y axis applied, shift rate = shift/wedge excursion =' num2str(shift_rate) ' [pixels/um]']; %string to save with Temporal Hypercube
        clear h_shiftCorrection time_interval shift_rate shift_num


end

Averages0=mean(HyperMatrix,3);

%% Saving

% Saving image and step
[filename_Hyper, pathname_Hyper] = uiputfile('*.mat', 'Save Hypercube as',dir0);
file_tot=[pathname_Hyper,filename_Hyper];

stringa=['  -- Saving Hypercube in ',file_tot,' --'];
fprintf('\n%s',stringa);

% Checks the size of the matrix, before saving
HyProp = whos('HyperMatrix') ;
Gigabytes = HyProp.bytes/2^30;

if Gigabytes<1.8
    save(file_tot,'t','HyperMatrix','Averages0','spatialShiftCorrection'); % raw data, averages not removed yet
else
    save(file_tot,'t','HyperMatrix','Averages0','spatialShiftCorrection','-v7.3'); % raw data, averages not removed yet
end


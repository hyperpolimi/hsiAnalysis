function save_hypercube(Hyperspectrum_cube,f,saturationMap,fr_real,file_totCal,Intens,dir0,filename)

% First version: Benedetto 3/07/2023
% Second version: Martina 26/09/2025

%function to save the spectral hypercube in H5 or .mat (format double, single or
%uint16) or in Lossless Motion JPEG 2000 video file
%
%save_hypercube_NEW(Hyperspectrum_cube,f,saturationMap,fr_real,file_totCal,Intens)
%Hyperspectrum_cube: spectral hypercube dataset (absolute or complex)
%f: pseudofrequency axis
%saturationMap: map of saturated pixels (0:saturated, 1:not saturated
%file_totCal: frequency calibration, if it is present
%fr_real: real calibrated frequencies axis, if it is present
%Intens: 2D matrix hypercube integral over frequencies
%
%save_hypercube_NEW(Hyperspectrum_cube,f,saturationMap,fr_real,file_totCal,Intens,dir0)
%dir0: directory to start the uiputfile window for saving
%
%save_hypercube_NEW(Hyperspectrum_cube,f,saturationMap,fr_real,file_totCal,Intens,dir0,filename)
%filename: path+filename to save (if not indicated the uiputfile window is
%open for the user)


if ~exist('dir0')
    [dir0,~,~] = fileparts(mfilename('fullpath')); %directory of the script
end



if exist('filename')
    save_format=round(Dinput('\n\n    Save format [1:.h5 double (64 bit) - 2:.h5 single (32 bit) - 3:.h5 uint16 (16 bit) \n- 4:.mat double (64 bit) - 5:.mat single (32 bit) - 6:.mat uint16 (16 bit) \n- 7:lossless video]? ',2));
    file_tot=filename;
else
    [filename_Hypercube, pathname_Hypercube] = uiputfile({'*.mat';'*.h5';'*.mj2'}, 'Save Hypercube',dir0);
    file_tot=[pathname_Hypercube,filename_Hypercube];

    if strcmp(file_tot(end-3:end),'.mj2') %if format selected is .mj2
        save_format=7;
    elseif strcmp(file_tot(end-3:end),'.mat')
        dataType=menu('File type', 'double (64 bit)','single (32 bit)','uint16 (16 bit)');
        save_format=dataType+3; %save_format=4 .mat double %save_format=5 .mat single %save_format=6 .mat uint16
        clear dataType
    else %if format selected is .h5
        save_format=menu('File type', 'double (64 bit)','single (32 bit)','uint16 (16 bit)'); %save_format=1 .h5 double %save_format=2 .h5 single %save_format=3 .h5 uint16
    end
end

if isempty(fr_real)
    clear fr_real;
end

if isempty(file_totCal)
    clear file_totCal;
end

a=size(Hyperspectrum_cube,1);
b=size(Hyperspectrum_cube,2);

h=waitbar(0.5,'Saving Hypercube, please wait...');
tic;

switch save_format

    case 1 
        Hyperspectrum_cube=double(Hyperspectrum_cube);
        fprintf('\n    Save hypercube in .h5, double format \n');
        if ~isreal(Hyperspectrum_cube)
                    Hyperspectrum_cube_real=real(Hyperspectrum_cube);
                    Hyperspectrum_cube_imag=imag(Hyperspectrum_cube);
                    clear Hyperspectrum_cube
                    %create a single images stack Hyperspectrum_cube with imag dataset images
                    %after real dataset images
                    Hyperspectrum_cube=zeros(a,b,size(Hyperspectrum_cube_real,3).*2);
                    Hyperspectrum_cube(:,:,1:size(Hyperspectrum_cube_real,3))=Hyperspectrum_cube_real;
                    Hyperspectrum_cube(:,:,size(Hyperspectrum_cube_real,3)+1:end)=Hyperspectrum_cube_imag;
                    clear Hyperspectrum_cube_real Hyperspectrum_cube_imag
        end

    case 2
        Hyperspectrum_cube=single(Hyperspectrum_cube);
        fprintf('\n    Save hypercube in .h5, single format \n');
        if ~isreal(Hyperspectrum_cube)
            Hyperspectrum_cube_real=real(Hyperspectrum_cube);
            Hyperspectrum_cube_imag=imag(Hyperspectrum_cube);
            clear Hyperspectrum_cube
            %create a single images stack Hyperspectrum_cube with imag dataset images
            %after real dataset images
            Hyperspectrum_cube=single(zeros(a,b,size(Hyperspectrum_cube_real,3).*2));
            Hyperspectrum_cube(:,:,1:size(Hyperspectrum_cube_real,3))=Hyperspectrum_cube_real;
            Hyperspectrum_cube(:,:,size(Hyperspectrum_cube_real,3)+1:end)=Hyperspectrum_cube_imag;
            clear Hyperspectrum_cube_real Hyperspectrum_cube_imag
        end

    case {3, 6, 7}

        if save_format == 3
            fprintf('\n    Save hypercube in .h5, uint16 format \n');
        elseif save_format == 6
            fprintf('\n    Save hypercube in .mat, uint16 format \n');
        else
            fprintf('\n    Save hypercube in Motion JPEG 2000 Lossless format \n');
        end

        if isreal(Hyperspectrum_cube)

            minimum=min(min(min(real(Hyperspectrum_cube))));
            Hyperspectrum_cube=Hyperspectrum_cube-minimum; %subtract minumum --> start data from 0
            maximum=max(max(max(real(Hyperspectrum_cube))));
            Hyperspectrum_cube=Hyperspectrum_cube./maximum; %divide by maximum --> end data to 1
            Hyperspectrum_cube=uint16((2.^16-1) * mat2gray(Hyperspectrum_cube,[0 1])); %convert in levels from 0 to 2^16-1

        else

            minimum=min([min(min(min(real(Hyperspectrum_cube)))) min(min(min(imag(Hyperspectrum_cube))))]);
            Hyperspectrum_cube=Hyperspectrum_cube-(1+1i).*minimum; %subtract minumum --> start real and imag data from 0
            maximum=max([max(max(max(real(Hyperspectrum_cube)))) max(max(max(imag(Hyperspectrum_cube))))]);
            Hyperspectrum_cube_0_real=real(Hyperspectrum_cube)./maximum; %divide real data by maximum --> end real data to 1
            Hyperspectrum_cube_1_real=uint16((2.^16-1) * mat2gray(Hyperspectrum_cube_0_real,[0 1])); %convert in levels from 0 to 2^16-1
            Hyperspectrum_cube_0_imag=imag(Hyperspectrum_cube)./maximum; %divide imag data by maximum --> end imag data to 1
            Hyperspectrum_cube_1_imag=uint16((2.^16-1) * mat2gray(Hyperspectrum_cube_0_imag,[0 1])); %convert in levels from 0 to 2^16-1
            clear Hyperspectrum_0_cube_real Hyperspectrum_cube_0_imag

            clear Hyperspectrum_cube
            %create a single images stack Hyperspectrum_cube with imag dataset images
            %after real dataset images
            Hyperspectrum_cube=uint16(zeros(a,b,size(Hyperspectrum_cube_1_real,3).*2));
            Hyperspectrum_cube(:,:,1:size(Hyperspectrum_cube_1_real,3))=Hyperspectrum_cube_1_real;
            Hyperspectrum_cube(:,:,size(Hyperspectrum_cube_1_real,3)+1:end)=Hyperspectrum_cube_1_imag;
            clear Hyperspectrum_1_cube_real Hyperspectrum_cube_1_imag

        end

    case 4 %.mat double
        fprintf('\n    Save hypercube in .mat, double format \n');
        Hyperspectrum_cube=double(Hyperspectrum_cube);

    case 5 %.mat single
        fprintf('\n    Save hypercube in .mat, single format \n');
        Hyperspectrum_cube=single(Hyperspectrum_cube);
end



%data saving

if save_format==1 || save_format==2 || save_format==3 %.h5 (double or single or uint16)

    if strcmp(file_tot(end-2:end),'.h5') %if format selected is .h5
        file_spectra=[file_tot(1:end-3),'_SpectralHypercube.h5']; %end-3 to exclude '.h5' in the string
    else %if ending part is .mat (this could happen: e.g. in HyperspectralAnalysis_Time where file_tot is referred to the .mat of Temporal Hypercube)
        file_spectra=[file_tot(1:end-4),'_SpectralHypercube.h5']; %end-4 to exclude '.mat' in the string
    end

    %datatype of Hyperspectrum_cube inside H5 file
    if save_format==1
        datatype='double';
    elseif save_format==2
        datatype='single';
    else
        datatype='uint16';
    end

    %delete the previous file if you want to overwrite it
    %necessary to avoid error (normal h5 creation in Matlab does not allow to overwrite files)
    if exist(file_spectra,'file')
        delete(file_spectra)
    end

    %create variables (datasets) inside the dataset SpectralHypercube
    %inside the H5 file
    h5create(file_spectra,'/SpectralHypercube/Hyperspectrum_cube',[a b size(Hyperspectrum_cube,3)],'Datatype',datatype);
    h5create(file_spectra,'/SpectralHypercube/f',[1 length(f)]);
    h5create(file_spectra,'/SpectralHypercube/saturationMap',[a b]);

    %write variables in H5 file
    h5write(file_spectra,'/SpectralHypercube/Hyperspectrum_cube',Hyperspectrum_cube);
    h5write(file_spectra,'/SpectralHypercube/f',f);
    h5write(file_spectra,'/SpectralHypercube/saturationMap',saturationMap);

    %write other variables in H5 file only if they exist
    if exist('file_totCal')
        write_Str_In_H5(file_spectra,'file_totCal',file_totCal); %save the calibration string in a dataset inside H5 file
    end

    if exist('fr_real')
        h5create(file_spectra,'/SpectralHypercube/fr_real',[1 length(fr_real)]);
        h5write(file_spectra,'/SpectralHypercube/fr_real',fr_real);
    end

    if exist('Intens') && ~isempty(Intens)
        h5create(file_spectra,'/SpectralHypercube/Intens',[a,b]);
        h5write(file_spectra,'/SpectralHypercube/Intens',Intens);
    end

    if exist('minimum')
        h5create(file_spectra,'/SpectralHypercube/minimum',[1]);
        h5write(file_spectra,'/SpectralHypercube/minimum',minimum);
    end

    if exist('maximum')
        h5create(file_spectra,'/SpectralHypercube/maximum',[1]);
        h5write(file_spectra,'/SpectralHypercube/maximum',maximum);
    end

elseif save_format==4 || save_format==5 || save_format==6 %.mat (double or single or uint16)

    file_spectra=[file_tot(1:end-4),'_SpectralHypercube.mat']; %end-4 to exclude '.mat' in the string

    % Checks the size of the matrix, before saving
    HyProp = whos('Hyperspectrum_cube') ;
    Gigabytes = HyProp.bytes/2^30;

    if exist('fr_real')

        if exist('minimum') && exist('maximum')
            if Gigabytes<1.8
                save(file_spectra,'f','fr_real','Hyperspectrum_cube','saturationMap','file_totCal','minimum','maximum'); %**Benedetto** saturationMap 25/10/2020
            else
                save(file_spectra,'f','fr_real','Hyperspectrum_cube','saturationMap','file_totCal','minimum','maximum','-v7.3'); %**Benedetto** saturationMap 25/10/2020
            end;
        else
            if Gigabytes<1.8
                save(file_spectra,'f','fr_real','Hyperspectrum_cube','saturationMap','file_totCal'); %**Benedetto** saturationMap 25/10/2020
            else
                save(file_spectra,'f','fr_real','Hyperspectrum_cube','saturationMap','file_totCal','-v7.3'); %**Benedetto** saturationMap 25/10/2020
            end;
        end

        % save(file_spectra,'f','fr_real','Hyperspectrum_cube','saturationMap','file_totCal','-v7.3'); %**Benedetto** saturationMap 25/10/2020
    else

        if exist('minimum') && exist('maximum')
            if Gigabytes<1.8
                save(file_spectra,'tt','f','Hyperspectrum_cube','saturationMap','minimum','maximum'); %**Benedetto** saturationMap 25/10/2020
            else
                save(file_spectra,'tt','f','Hyperspectrum_cube','saturationMap','minimum','maximum','-v7.3'); %**Benedetto** saturationMap 25/10/2020
            end;
        else
            if Gigabytes<1.8
                save(file_spectra,'tt','f','Hyperspectrum_cube','saturationMap'); %**Benedetto** saturationMap 25/10/2020
            else
                save(file_spectra,'tt','f','Hyperspectrum_cube','saturationMap','-v7.3'); %**Benedetto** saturationMap 25/10/2020
            end;
        end
    end

else %lossless video (Motion JPEG 2000 Lossless) format
    file_spectra=[file_tot(1:end-4),'_SpectralHypercube'];
    writerObj = VideoWriter(file_spectra,'Archival'); %'Archival' is Motion JPEG 2000 Lossless; other formats 'MPEG-4' 'Motion JPEG 2000' 'Motion JPEG AVI'

    % Set frame rate (this is a parameter of the video)
    writerObj.FrameRate = 30;

    % Open video writer object and write frames sequentially
    open(writerObj);

    for index = 1:size(Hyperspectrum_cube,3)

        % Write frame now
        immagine=squeeze(Hyperspectrum_cube(:,:,index));
        writeVideo(writerObj, immagine);

    end

    % Close the video writer object
    close(writerObj);

    %save other parameters in .mat file
    if exist('fr_real') && exist('Intens')
        save([file_spectra '_VALUES.mat'],'f','fr_real','saturationMap','file_totCal','Intens','minimum','maximum');
    elseif exist('fr_real') && ~exist('Intens')
        save([file_spectra '_VALUES.mat'],'f','fr_real','saturationMap','file_totCal','minimum','maximum');
    elseif ~exist('fr_real') && exist('Intens')
        save([file_spectra '_VALUES.mat'],'f','saturationMap','Intens','minimum','maximum');
    else
        save([file_spectra '_VALUES.mat'],'f','saturationMap','minimum','maximum');
    end
end

tempo_salvataggio=toc;
waitbar(1,h);
close(h);

fprintf('\nTime elapsed for saving: %.1f seconds\n',tempo_salvataggio);

stringa=[' *** Hypercube saved in ',file_spectra,' ***'];
fprintf('\n\n%s \n\n',stringa);


end




function write_Str_In_H5(filename,dataset_name,wdata)

%write 'wdata' string in dataset 'dataset_name' inside H5 file 'filename'

DIM0 = size(wdata,1);
SDIM = size(wdata,2)+1;
dims   = DIM0;
%Open file using Read/Write option
file_id = H5F.open(filename,'H5F_ACC_RDWR','H5P_DEFAULT');
% Preceeding line replaces the H5F create statement in the example:
%file = H5F.create (filename, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
%Create file and memory datatypes
filetype = H5T.copy ('H5T_C_S1');
H5T.set_size (filetype, SDIM-1);
memtype = H5T.copy ('H5T_C_S1');
H5T.set_size (memtype, SDIM-1);
% Create dataspace.  Setting maximum size to [] sets the maximum
% size to be the current size.
%
space_id = H5S.create_simple (1,fliplr( dims), []);
% Create the dataset and write the string data to it.
%
dataset_id = H5D.create (file_id, dataset_name, filetype, space_id, 'H5P_DEFAULT');
% Transpose the data to match the layout in the H5 file to match C
% generated H5 file.
H5D.write (dataset_id, memtype, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', wdata);
%Close and release resources
H5D.close(dataset_id);
H5S.close(space_id);
H5T.close(filetype);
H5T.close(memtype);
H5F.close(file_id);
end

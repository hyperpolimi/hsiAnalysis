function HyperspectralAnalysis_Spectrum

% Original version: Cristian Manzoni 06.11.2019
% First update: Benedetto Ardini 23.06.2023
% Second update: Martina Riva 01.2025
% Third update: Filippo Coviello 09.2025


[filepath,~,~] = fileparts(mfilename('fullpath'));

addpath(genpath('RGBspectra')); % Filippo: Adding RGBSpectra ("RGBSpectra")
RGB_t_file = fullfile(filepath, 'RGB_Transmission.mat');


c=299792458; %speed of light [m/s]
saturation=1;
black=0;
gamma=1;
num_spectrum=0;

norm_R=1;
norm_G=1;
norm_B=1;
% parpool;

mm=hsv(8); % hsv Map of colours - 8 colours


[filename_Hyper, pathname_Hyper] = uigetfile('*.mat;*.h5;*.mj2', 'Load spectral Hypercube'); %**Benedetto 18/11/2022 *.h5;*.mj2 added
file_tot=[pathname_Hyper,filename_Hyper];

dir2=pathname_Hyper;

h=waitbar(0.5,'Loading Hypercube, please wait...');

stringa=[' *** Analysis of file ',file_tot,' ***'];
fprintf('\n\n%s\n',stringa);

if strcmp(filename_Hyper(end-2:end),'.h5') %if loaded file is .h5
    [Hyperspectrum_cube,f,saturationMap,file_totCal,fr_real,Intens] = H5HypercubeRead(file_tot);
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

elseif strcmp(filename_Hyper(end-3:end),'.mj2') %if loaded file is .mj2

    [Hyperspectrum_cube,f,saturationMap,file_totCal,fr_real,Intens] = MJ2HypercubeRead(file_tot);
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

else %if loaded file is .mat

    input_data=load(file_tot);

    f=input_data.f;

    Hyperspectrum_cube=input_data.Hyperspectrum_cube;

    if isfield(input_data,'fr_real')
        fr_real=input_data.fr_real;
    end

    if isfield(input_data,'file_totCal')
        file_totCal=input_data.file_totCal;
    end

    %**Benedetto** saturationMap 25/10/2020
    if isfield(input_data,'saturationMap')==1 %if saturationMap has been saved together with Hyperspectrum_cube
        NoSaturationMap=input_data.saturationMap;
    else
        NoSaturationMap=ones(size(Hyperspectrum_cube,1),size(Hyperspectrum_cube,2));
    end

    Hyperspectrum_cube(isnan(Hyperspectrum_cube))=0;

    if isa(Hyperspectrum_cube,'uint16')
        maximum=input_data.maximum;
        minimum=input_data.minimum;
        Hyperspectrum_cube=double(Hyperspectrum_cube)./(2.^16-1).*maximum+minimum; %double reconversion procedure from uint16
        fprintf('\n\n The loaded hypercube was saved in uint16 type\n\n'); %message to explicit the hypercube format
    elseif isa(Hyperspectrum_cube,'single')
        Hyperspectrum_cube=double(Hyperspectrum_cube); %reconversion to double
        fprintf('\n\n The loaded hypercube was saved in single type\n\n'); %message to explicit the hypercube format
    else
        fprintf('\n\n The loaded hypercube was saved in double type\n\n'); %message to explicit the hypercube format
    end

    if size(Hyperspectrum_cube,3)==2.*length(f) %if the spectral hypecube is complex the real and imag are stacked one over the other
        Hyperspectrum_cube_real=Hyperspectrum_cube(:,:,1:size(Hyperspectrum_cube,3)./2);
        Hyperspectrum_cube_imag=Hyperspectrum_cube(:,:,size(Hyperspectrum_cube,3)./2+1:end);
        clear Hyperspectrum_cube
        Hyperspectrum_cube=zeros(size(Hyperspectrum_cube_real));
        Hyperspectrum_cube=Hyperspectrum_cube_real+1i.*Hyperspectrum_cube_imag;
        clear Hyperspectrum_cube_real Hyperspectrum_cube_imag
    end

    if isfield(input_data,'Intens')==1 %if Intens has been saved together with Hyperspectrum_cube **Benedetto** 12/07/2021
        Intens=input_data.Intens;
    else
        Intens=sum(abs(Hyperspectrum_cube),3); %**Benedetto** abs 09/10/2020
    end

end

close(h);

%absolute value vs. complex value **Benedetto** 06/11/2020
absoluteVal=menu('Spectral Hypercube Values Format', 'absolute values (if no uniform phase, e.g. camera)]','complex values (if uniform phase, e.g. microscope)');
%if there's no uniform Zero Path Delay Configuration the spectral Hypercube
%cannot be treated as a complex set of data because, at a given frequency,
%the phase changes according to the spacial coordinate


if absoluteVal==1
    fprintf('\n\n   Absolute value of the Hypercube will be considered.');
    Hyperspectrum_cube=abs(Hyperspectrum_cube);
else
    fprintf('\n\n   The Hypercube will be considered as complex.');
end

derivative_flag=0; %at the beginning the Spectral Hypercube has been not derived **Benedetto** 16/07/2021


[a,b]=size(Hyperspectrum_cube(:,:,1));
cc=length(f); % number of spectral points

fprintf(['\n\n   Size: ',num2str(b),' x ',num2str(a),' pixels']);

load_cal=1;

%--CARICAMENTO DI RGB_Transmission-- %Filippo: Pulled it outside to reduce duplication.
% -> For calculation of RAW(*) RGB spectra
if load_cal || ~exist('fr_real')

    RGB_t=load(RGB_t_file);

    R=RGB_t.R/5.8559e+03; % 5.8559e+03 is the normalization of the spectrum
    G=RGB_t.G/4.6082e+03; % 4.6082e+03 is the normalization of the spectrum
    B=RGB_t.B/4.7163e+03; % 4.7163e+03 is the normalization of the spectrum
    wl=RGB_t.wl;
end


if exist('fr_real')==0

    load_cal=round(Dinput('\n\n    Load frequency calibration [0: no - 1: yes]? ',0));

    if load_cal

        [filename_Cal, pathname_Cal] = uigetfile('*.mat', 'Load Calibration');
        file_totCal=[pathname_Cal,filename_Cal];

        stringa=['  Calibration: ',file_totCal];
        fprintf('\n%s\n',stringa);

        Calibration=load(file_totCal); % Contains  fr_real0 and f_0
        f_0=Calibration.f_0;
        fr_real0=Calibration.fr_real0;

        fr_real=interp1(f_0,fr_real0,f);
        lambda_nm=c./(fr_real*1e12)/1e-9;

        fprintf(['\n   Frequency: ',num2str(fr_real(1)),'-',num2str(fr_real(end)),' THz (', num2str(cc),' spectral points)']);
        fprintf(['\n   Wavelength: ',num2str(lambda_nm(end)),'-',num2str(lambda_nm(1)),' nm\n\n']);


        R=RGB_t.R/5.8559e+03; % 5.8559e+03 is the normalization of the spectrum
        G=RGB_t.G/4.6082e+03; % 4.6082e+03 is the normalization of the spectrum
        B=RGB_t.B/4.7163e+03; % 4.7163e+03 is the normalization of the spectrum
        wl=RGB_t.wl;

        % RGB in frequency axis
        R_THz=interp1(wl, R,lambda_nm).*lambda_nm.^2/c; R_THz(isnan(R_THz))=0;
        G_THz=interp1(wl, G,lambda_nm).*lambda_nm.^2/c; G_THz(isnan(G_THz))=0;
        B_THz=interp1(wl, B,lambda_nm).*lambda_nm.^2/c; B_THz(isnan(B_THz))=0;

        Label_x='Wavelength [nm]';

        ImmagineRGB=zeros(a,b,3);

    else

        fprintf(['\n   pseudoFrequency: ',num2str(f(1)),'-',num2str(f(end)),' THz (', num2str(cc),' spectral points)']);
        Label_x='Pseudowavelength';
        fr_real=f;

        ImmagineRGB=zeros(a,b);



    end;

else
    lambda_nm=c./(fr_real*1e12)/1e-9;

    fprintf(['\n   Frequency: ',num2str(fr_real(1)),'-',num2str(fr_real(end)),' THz (', num2str(cc),' spectral points)']);
    fprintf(['\n   Wavelength: ',num2str(lambda_nm(end)),'-',num2str(lambda_nm(1)),' nm\n\n']);


    R=RGB_t.R/5.8559e+03; % 5.8559e+03 is the normalization of the spectrum
    G=RGB_t.G/4.6082e+03; % 4.6082e+03 is the normalization of the spectrum
    B=RGB_t.B/4.7163e+03; % 4.7163e+03 is the normalization of the spectrum

    wl=RGB_t.wl;

    R_THz=interp1(wl, R,lambda_nm).*lambda_nm.^2/c; R_THz(isnan(R_THz))=0;
    G_THz=interp1(wl, G,lambda_nm).*lambda_nm.^2/c; G_THz(isnan(G_THz))=0;
    B_THz=interp1(wl, B,lambda_nm).*lambda_nm.^2/c; B_THz(isnan(B_THz))=0;


    %%%%%%%% FOR CALIBRATED RGB
    %%%% COLOR MATCHING FUNCTIONS for REAL RGB
    [lambdaC, xC, yC, zC] = colorMatchFcn('1964_full');
    % lambda in nm

    % other matching functions:

    %      CIE_1931   CIE 1931 2-degree, XYZ
    %      1931_FULL  CIE 1931 2-degree, XYZ  (at 1nm resolution)
    %      CIE_1964   CIE 1964 10-degree, XYZ
    %      1964_FULL  CIE 1964 10-degree, XYZ (at 1nm resolution)
    %      Judd       CIE 1931 2-degree, XYZ modified by Judd (1951)
    %      Judd_Vos   CIE 1931 2-degree, XYZ modified by Judd (1951) and Vos (1978)
    %      Stiles_2   Stiles and Burch 2-degree, RGB (1955)
    %      Stiles_10  Stiles and Burch 10-degree, RGB (1959)
    %%%%

    % interpolation of color matching functionsto to the wavelength axis of the
    % measurement
    lamC=c./(fr_real*1e12)/1e-9;
    dlamC=diff(lamC);
    dlamC(end+1)=dlamC(end);
    dlamC=-dlamC; % no need to change sign of differential for numerical integration

    % the differential dlam should be in the integral for the calculation of X, Y, Z.
    % However, to speed up the processing, it is placed here already.

    x_lam=interp1(lambdaC,xC,lamC).*dlamC; x_lam(isnan(x_lam))=0;
    y_lam=interp1(lambdaC,yC,lamC).*dlamC; y_lam(isnan(y_lam))=0;
    z_lam=interp1(lambdaC,zC,lamC).*dlamC; z_lam(isnan(z_lam))=0;
    % Now x,y,z functions are sampled over the measured wavelength

    %%%%%%%%%% iLLUMINANT
    [lambda_i, ENERGY] = illuminant('D65');

    % other illuminants:

    %      A    The standard tungsten filament lamp (2856K)
    %      D65  Medium daylight with UV component (6500K)
    %      EE   Theoretical equal-energy illuminant

    Energy_i=interp1(lambda_i,ENERGY,lamC); Energy_i(isnan(Energy_i))=0;
    % Now Energy_i is sampled over the measured wavelength


    Label_x='Wavelength [nm]';

end;

ImmagineRGB(:,:,1)=Intens;
ImmagineRGB(:,:,2)=Intens;
ImmagineRGB(:,:,3)=Intens;

main=figure('Units', 'normalized', 'Position',[0.25 0.05 0.75 0.85]); %250822

h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
hold all; axis off;

h3=subplot(2,2,2,'visible','off','Colororder',mm);

axh3=gca;
axh3.YAxisLocation = 'right';
axh3.XLabel.String=Label_x;
axh3.YLabel.String='Intensity [arb.un.]';
axh3.Title.String='Spectra for selected regions'; % title('Spectra NOT corrected with Jacobian');
hold all; axis tight;

h4=subplot(2,2,4,'visible','off','Colororder',mm);
% title('Spectra NOT corrected with Jacobian');
% title('Spectra normalised to the peak'); %250822
title('Spectra normalised to the area'); %251021
axh4=gca;
axh4.YAxisLocation = 'right';
hold all; axis tight;
% axh4.Title.String='Spectra normalised to the peak';
axh4.Title.String='Spectra normalised to the area'; %251021
axh4.XLabel.String=Label_x;
axh4.YLabel.String='Intensity [norm.]';

max_image=max(max(max(ImmagineRGB)));
subplot(h1);
image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
axis equal;
set(gca,'YDir','reverse')

scelta_menu = menu('Choose analysis',...
    'Remove BKG from ROI','Intensity levels','Gamma correction','Rotate',...
    'Generate False-RGB map','RGB white balance','Spectrum on area',...
    'Save spectral GIF',...
    'Spectral Angle Mapping','Clean Graphs','Reflectivity map',...
    'Transmission map ','Normalize on Lambertian','Crop/Smoothing',...
    'Map Spectral Peaks','Plot Hypercube','Hypercube derivative',...
    'Save Spectra','Save current image','Save current Hypercube','Calibrated RGB',...
    'EXIT' );


Spectrum_subAve=[];
BKG_Ave=zeros(a,b);
RGB_flag=0; %**Benedetto**

while ne(scelta_menu,22)

    %**BENEDETTO** 29/11/2021
    if exist('h_PH') %if PlotHypercube has been opened for one time at least
        if ~isvalid(h_PH) %if PlotHypercube window is NOT open (h_PH exists but not valid)
            set(h1,'HandleVisibility','on'); %reset the visibility of image plot on
            set(h3,'HandleVisibility','on'); %reset the visibility of graphs on
            set(h4,'HandleVisibility','on'); %reset the visibility of normalized graphs on
        end
    end

    switch scelta_menu
        case 1  % Stretch RGB colormap
            RGB_flag=1; %the user has generated at least one time the RGB map **Benedetto**

            % From Spectral_filter
            menuRGB=menu('Choose RGB format', 'Spectral range', 'Single wavelenghts');

            switch menuRGB
                case 1 %Spectral range

                    prompt={'Lower wavelength (nm)','Higher wavelength (nm)','Binning'}; %**Benedetto** 09/10/2020 aggiunta del binning
                    name='Select spectral band and binning';
                    numlines=1;
                    defaultanswer={num2str(390),num2str(690),num2str(1)};

                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';

                    answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                    lm(1)=str2double(cell2mat(answer(1)));
                    lm(2)=str2double(cell2mat(answer(2)));
                    bin=str2double(cell2mat(answer(3))); %**Benedetto** 09/10/2020 aggiunta del binning

                    wl1=(lm(2)-lm(1))/(690-390)*(wl-390)+lm(1);

                    % Generazione del nuovo spettro RGB (stretchato in modo da coprire
                    % tutto lo spetro del campione
                    R_THz1=interp1(wl1, R,lambda_nm).*lambda_nm.^2/c; R_THz1(isnan(R_THz1))=0;
                    G_THz1=interp1(wl1, G,lambda_nm).*lambda_nm.^2/c; G_THz1(isnan(G_THz1))=0;
                    B_THz1=interp1(wl1, B,lambda_nm).*lambda_nm.^2/c; B_THz1(isnan(B_THz1))=0;

                    R_THz1=R_THz1/sum(R_THz1); % Normalization, to get 1 in case of constant spectrum=1
                    G_THz1=G_THz1/sum(G_THz1);
                    B_THz1=B_THz1/sum(B_THz1);

                case 2 %single wavelengths- Martina 250822
                    prompt={'Red channel','Green channel','Blue channel', 'Binning'};
                    name='Select R,G,B channel and binning';
                    numlines=1;
                    defaultanswer={num2str(630),num2str(530),num2str(470), num2str(1)};


                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';


                    answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                    lm(1)=str2double(cell2mat(answer(1)));
                    lm(2)=str2double(cell2mat(answer(2)));
                    lm(3)=str2double(cell2mat(answer(3)));
                    bin=str2double(cell2mat(answer(4)));

                    [~, idxR] = min(abs(lambda_nm - lm(1)));  % Find the index of the minimum difference
                    waveR = lambda_nm(idxR);
                    [~, idxG] = min(abs(lambda_nm - lm(2)));  % Find the index of the minimum difference
                    waveG = lambda_nm(idxG);
                    [~, idxB] = min(abs(lambda_nm - lm(3)));  % Find the index of the minimum difference
                    waveB = lambda_nm(idxB);
                    %if wavelengths are outside the range, extreme wavelengths are chosen with this algorithm

            end


            h=waitbar(0,'Generating binned matrix');

            % Nuova parte Cristian
            % Genrates convolution matrix
            bin_matrix=ones(bin);

            % generates normalization cube
            Norm_matrix=ones(a,b);

            waitbar(0.3,h);
            Norm_matrix=imfilter(Norm_matrix,bin_matrix);
            Norm_matrix=repmat(Norm_matrix,[1 1 cc]);

            waitbar(0.6,h);
            % Generation of binned Hypercube, No weight
            Hyperspectrum_cube_bin=imfilter(Hyperspectrum_cube,bin_matrix)./Norm_matrix; % a new matrix, where all points are averages of surrounding points

            h=waitbar(0,h,'Generating RGB image');

            switch menuRGB
                case 1
                    for yy=1:a
                        waitbar(yy/a,h);

                        for xx=1:b

                            Spectrum=squeeze(abs(Hyperspectrum_cube_bin(yy,xx,:)));

                            ImmagineRGB(yy,xx,1)=R_THz1*Spectrum; % R
                            ImmagineRGB(yy,xx,2)=G_THz1*Spectrum; % G
                            ImmagineRGB(yy,xx,3)=B_THz1*Spectrum; % B

                        end;
                    end;
                case 2 %Martina 250822

                    imageR=mat2gray(abs(Hyperspectrum_cube_bin(:,:,idxR)));
                    imageG=mat2gray(abs(Hyperspectrum_cube_bin(:,:,idxG)));
                    imageB=mat2gray(abs(Hyperspectrum_cube_bin(:,:,idxB)));
                    ImmagineRGB(:,:,3)=imageB; ImmagineRGB(:,:,2)=imageG; ImmagineRGB(:,:,1)=imageR;

            end

            close (h);

            max_image=max(max(max(ImmagineRGB)));

            figure(main);
            cla(h1);

            h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
            hold all; axis off;

            % subplot(h1);
            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
            axis equal;
            set(gca,'YDir','reverse')

            set(h4,'visible','on');
            switch menuRGB

                case 1
                    plot(h4,c./(fr_real*1e12)/1e-9,R_THz1/max(R_THz1),'r--',...
                        c./(fr_real*1e12)/1e-9,G_THz1/max(G_THz1),'g--',...
                        c./(fr_real*1e12)/1e-9,B_THz1/max(B_THz1),'b--',...
                        'linewidth',1);
                    subplot(h4);
                    legend('R','G','B');

                case 2
                    subplot(h4)
                    xline(waveR, 'r--', 'R', 'LineWidth',1.5);
                    xline(waveG, 'g--', 'G', 'LineWidth',1.5);
                    xline(waveB, 'b--', 'B', 'LineWidth',1.5);
            end
            hold all;


        case 2 % Select_spectra: Selects spectrum from ROI
            aspectRatio=2000;
            width=1;
            height=1;

            while aspectRatio~=0

                num_spectrum=num_spectrum+1;
                [~,~,Spectrum_subAve(:,num_spectrum),Spectrum_subStd(:,num_spectrum),cont, aspectRatio, width, height]=Select_spectra_ROI(aspectRatio, width, height); %**Benedetto** (aggiunta di cont)

                set(h3,'visible','on');
                %%%  plot(h3,c./(fr_real*1e12)/1e-9,Spectrum_subAveWL,'linewidth',3);

                %             plot(h3,c./(fr_real*1e12)/1e-9,Spectrum_subAve(:,num_spectrum),...
                %                 'linewidth',3,'Color',mm(mod(num_spectrum-1,8)+1,:));

                %             %%%%%%%%%%%
                %
                shaded_error(h3,c./(fr_real*1e12)/1e-9,...
                    Spectrum_subAve(:,num_spectrum)',Spectrum_subStd(:,num_spectrum)',mm,num_spectrum);
                %
                %             %%%%%%%%%%%%%
                hold all;
                % plot(h3,c./(fr_real*1e12)/1e-9,Spectrum_subAveWL-Spectrum_subStdWL,'k--',...
                %  c./(fr_real*1e12)/1e-9,Spectrum_subAveWL+Spectrum_subStdWL,'k--','linewidth',1);

                %             plot(h3,c./(fr_real*1e12)/1e-9,Spectrum_subAve(:,num_spectrum)-Spectrum_subStd(:,num_spectrum),'k--',...
                %                 c./(fr_real*1e12)/1e-9,Spectrum_subAve(:,num_spectrum)+Spectrum_subStd(:,num_spectrum),'k--','linewidth',1);
                % title('Spectra NOT corrected with Jacobian');
                %title('Spectra for selected regions'); %250822
                axh3.Title.String='Spectra for selected regions'; % title('Spectra NOT corrected with Jacobian');


                set(h4,'visible','on');
                % % plot(h4,c./(fr_real*1e12)/1e-9,Spectrum_subAveWL./max(Spectrum_subAveWL),'linewidth',3);
                % plot(h4,c./(fr_real*1e12)/1e-9,Spectrum_subAve(:,num_spectrum)./max(Spectrum_subAve(:,num_spectrum)),...
                %     'linewidth',3,'Color',mm(mod(num_spectrum-1,8)+1,:));
                % hold all;
                % %title('Spectra NOT corrected with Jacobian');
                % %title('Spectra normalised to the peak'); %250822
                % axh4.Title.String='Spectra normalised to the peak'; % title('Spectra NOT corrected with Jacobian');
                %
                % %                     plot(h4,c./(fr_real*1e12)/1e-9,(Spectrum_subAve-Spectrum_subStd)./max(Spectrum_subAve),'k--',...
                % %                         c./(fr_real*1e12)/1e-9,(Spectrum_subAve+Spectrum_subStd)./max(Spectrum_subAve),'k--','linewidth',1);

                % Spectra normalised to the area %Martina 251021
                plot(h4,c./(fr_real*1e12)/1e-9,Spectrum_subAve(:,num_spectrum)./trapz(Spectrum_subAve(:,num_spectrum)),...
                    'linewidth',3,'Color',mm(mod(num_spectrum-1,8)+1,:));
                hold all;
                axh4.Title.String='Spectra normalised to the area'; % title('Spectra NOT corrected with Jacobian');

                fprintf(['\n   Selected: ',num2str(cont),' pixels\n']);
            end

        case 3
            %**Benedetto** 24/06/2021 also possibility to load an external spectrum
            %as white reference for Reflectivity Map generation and
            %possibility to specify the reflectivity value of spectralon
            spectrum_ref_Source=menu('Choose reference spectrum', 'Spectrum from ROI', 'Load external spectrum (e.g. if there''s no spectralon in the current image)');

            switch spectrum_ref_Source
                case 1
                    uiwait(msgbox('Select ROI for reference spectrum','Reflectivity map','warn'));
                    Select_ROI; %calculate the Spectrum_subAve, the white normilizer in CalculateR
                case 2
                    uiwait(msgbox('The external spectrum has to be a .txt file with the first column representing the frequency and the second column representing the intensity; other columns will be neglected. The frequency range of the external spectrum must be contained inside the frequency range of the current hypercube spectra',...
                        'External spectrum file format','warn'));
                    [filename_spectrum_ref, pathname_spectrum_ref] = uigetfile('*.txt', 'Load saved spectra');
                    file_tot_spectrum_ref=[pathname_spectrum_ref,filename_spectrum_ref];

                    try %txt with only numeric values
                        input_data_spectrum_ref=load(file_tot_spectrum_ref);
                    catch %files with headers imported as structures; "data" field with numeric values
                        dataStruct = importdata(file_tot_spectrum_ref);
                        input_data_spectrum_ref = dataStruct.data;
                    end
                    Spectrum_Ref=input_data_spectrum_ref(:,2);
                    fr_real_Ref=input_data_spectrum_ref(:,1);

                    %If the first and the last elements of the frequencies
                    %axes are different for a very small part the program
                    %will consider them equal in order to avoid NaN after
                    %the interpolation of Spectrum_Ref
                    if abs(fr_real_Ref(1)-fr_real(1))<1e-12
                        fr_real_Ref(1)=fr_real(1);
                    end
                    if abs(fr_real_Ref(end)-fr_real(end))<1e-12
                        fr_real_Ref(end)=fr_real(end);
                    end

                    Spectrum_Ref=interp1(fr_real_Ref,Spectrum_Ref,fr_real);

                    if any(isnan(Spectrum_Ref(:)))==1
                        fprintf('\nERROR! \nThe external spectrum must be defined in a frequency range that complies with the frequency range of the current hypercube!\n');
                        return; %the program is closed
                    end

                    Spectrum_Ref=Spectrum_Ref';

                    prompt={'Adjust integration factor between current measurement and spectralon measurement'};
                    name='Specify spectralon spectrum multiplication factor';
                    numlines=1;
                    defaultanswer={num2str(1)};

                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';

                    answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                    Spectralon_factor=str2double(cell2mat(answer(1))); %spectralon spectrum multiplication factor


                    Spectrum_subAve=Spectrum_Ref.*Spectralon_factor; %Spectrum_subAve as white normalizer in CalculaterR

                    clear input_data_spectrum_ref Spectrum_Ref;
            end

            spectralon_menu=menu('Spectralon reflectivity','Input single reflectivity value','Load spectralon reflectivity spectrum');

            switch spectralon_menu

                case 1 %Input single reflectivity value
                    prompt={'Spectralon reflectivity value (from 0 [black] to 1 [white])'};
                    name='Specify value of Spectralon reflectivity';
                    numlines=1;
                    defaultanswer={num2str(1)};

                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';

                    answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                    Reflectivity_value=str2double(cell2mat(answer(1))); %spectralon reflectivity value


                    Spectrum_subAve=Spectrum_subAve./Reflectivity_value;

                case 2 %Load external spectrum
                    uiwait(msgbox('The external spectrum has to be a .txt file with the first column representing the frequency and the second column representing the intensity; other columns will be neglected.',...
                        'External spectrum file format','warn'));
                    [filename_spectrum_ref, pathname_spectrum_ref] = uigetfile('*.txt', 'Load saved spectra');
                    file_tot_spectrum_ref=[pathname_spectrum_ref,filename_spectrum_ref];

                    try %only numeric values
                        input_data_spectrum_ref=load(file_tot_spectrum_ref);
                    catch % files with headers
                        dataStruct = importdata(file_tot_spectrum_ref);
                        input_data_spectrum_ref = dataStruct.data;
                    end
                    Spectrum_Ref=input_data_spectrum_ref(:,2);
                    fr_real_Ref=input_data_spectrum_ref(:,1);
                    Spectrum_Ref=interp1(fr_real_Ref,Spectrum_Ref,fr_real);
                    Spectrum_Ref=Spectrum_Ref';

                    prompt={'Adjust integration factor between the external spectrum and the current measurement'};
                    name='Specify spectralon spectrum multiplication factor';
                    numlines=1;

                    if exist('Spectralon_factor')
                        defaultanswer={num2str(Spectralon_factor)}; %it is likely that the external spectrum has been measured with same int. time as the spectralon one
                    else
                        defaultanswer={num2str(1)};
                    end

                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';

                    answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                    Ext_Spect_factor=str2double(cell2mat(answer(1))); %external spectrum multiplication factor

                    Spectrum_subAve=Spectrum_subAve./(Spectrum_Ref.*Ext_Spect_factor);
                    clear input_data_spectrum_ref Spectrum_Ref fr_real_Ref;
            end

            CalculateR;

        case 4
            uiwait(msgbox('Select ROI for reference spectrum','Transmission map','warn'));
            Select_ROI;
            CalculateT;

        case 5  % rotate

            figure(main);
            % cla(h1);
            subplot(h1);

            %**Benedetto** 26/09/2020
            scelta_rotazione=menu('Choose rotation', ...
                '90deg clock','90deg counterclock','180deg','custom (select angle)','custom (draw line)');
            switch scelta_rotazione
                case 1 %90deg clock
                    angle=90; %90deg clockwise

                case 2 %90deg counterclock
                    angle=-90; %90deg counterclockwise

                case 3 %180deg
                    angle=180;

                case 4 %custom (select angle)
                    prompt={'Select rotation angle (+: clock, -: counterclock)'};
                    name='Select rotation angle';
                    numlines=1;
                    defaultanswer={num2str(0)};

                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';

                    answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                    angle=str2double(cell2mat(answer));

                case 5 %custom (draw line)
                    uiwait(msgbox('Draw reference direction line, then DOUBLE CLICK',...
                        'Hypercube Rotation','warn'));

                    V=axis;

                    h_line = imline;
                    %             fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
                    %             setPositionConstraintFcn(h_line,fcn);

                    position = wait(h_line);

                    ButtonName = questdlg('Align to:', ...
                        'Rotation', ...
                        'Vertical  ', 'Horizontal', 'Vertical  ');

                    ratio=( position(2,2)-position(1,2) )/( position(2,1)-position(1,1) );

                    if ButtonName=='Horizontal'
                        angle=atan(ratio)*180/pi;
                    else
                        angle=-atan(1/ratio)*180/pi;
                    end

            end
            %**Benedetto** 26/09/2020

            B = imrotate(Intens,angle,'bilinear');

            Hyperspectrum_cubeOriginal=Hyperspectrum_cube;

            [a,b]=size(B); % New size
            Hyperspectrum_cube=zeros(a,b,cc);

            h=waitbar(0,'Rotating hypercube');

            for hr=1:cc % Rotation of all spectra
                waitbar(hr/cc,h);
                Hyperspectrum_cube(:,:,hr) = imrotate(Hyperspectrum_cubeOriginal(:,:,hr),angle,'bilinear');
            end;

            close(h);

            %**Benedetto**
            if ne(RGB_flag,0) %if the user has used at least one time the RGB map generation tool, after the rotation I need to re-generate the same RGB map choice

                ImmagineRGB_old=ImmagineRGB;
                ImmagineRGB=[];

                h=waitbar(0,'Rotating RGB image');
                for hr=1:3 % Rotation of RGB
                    waitbar(hr/3,h);
                    ImmagineRGB(:,:,hr) = imrotate(ImmagineRGB_old(:,:,hr),angle,'bilinear');
                end;

                close(h);


            else

                Intens=sum(Hyperspectrum_cube,3);
                ImmagineRGB=zeros(a,b,3);
                ImmagineRGB(:,:,1)=Intens;
                ImmagineRGB(:,:,2)=Intens;
                ImmagineRGB(:,:,3)=Intens;

            end;
            %**Benedetto**

            max_image=max(max(max(ImmagineRGB)));
            subplot(h1);
            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
            axis equal;
            set(gca,'YDir','reverse')

        case 6
            Generate_GIF;

        case 7 % Selects BKG spectrum from ROI
            Select_ROI_BKG;

            h=waitbar(0,'Removing Background');
            for yy=1:a
                waitbar(yy/a,h);
                for xx=1:b
                    Hyperspectrum_cube(yy,xx,:)=squeeze(Hyperspectrum_cube(yy,xx,:))-BKG_Ave; % Can be real or complex, works both ways
                    Spectrum=squeeze(Hyperspectrum_cube(yy,xx,:));
                    %
                    %                     ImmagineRGB(yy,xx,1)=R_THz*Spectrum; % R
                    %                     ImmagineRGB(yy,xx,2)=G_THz*Spectrum; % G
                    %                     ImmagineRGB(yy,xx,3)=B_THz*Spectrum; % B
                    %
                end;
            end;

            close (h);

            Intens=sum(abs(Hyperspectrum_cube),3); %**Benedetto** abs 09/10/2020

            ImmagineRGB(:,:,1)=Intens;
            ImmagineRGB(:,:,2)=Intens;
            ImmagineRGB(:,:,3)=Intens;

            max_image=max(max(max(ImmagineRGB)));
            subplot(h1);
            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
            axis equal;
            set(gca,'YDir','reverse')

            %             [filename_Spectra, pathname_Spectra] = uiputfile('*.mat', 'Save new Hypercube as',dir2);
            %             file_totBKG=[pathname_Spectra,filename_Spectra];
            %
            %             h=waitbar(0.5,'Saving new Hypercube, please wait...');
            %
            %             fprintf(['\n  -- Saving new spectral image in ',file_totBKG,' --\n']);
            %             save(file_totBKG,'f','fr_real','Hyperspectrum_cube'); % R/T Spectra
            %
            %             close(h);

        case 8 % Save spectra

            % Saves the spectra of selected areas

            % Saving selected spectra
            [filename_Spectra, pathname_Spectra] = uiputfile('*.txt', 'Save Spectra as',dir2);
            file_tot=[pathname_Spectra,filename_Spectra];

            spectra_export=[fr_real' Spectrum_subAve Spectrum_subStd];

            stringa=['  -- Saving Selected Spectra in ',file_tot,' --'];
            fprintf('\n%s\n',stringa);
            fprintf(['\n  Data format:\n\n    frequency[THz] (1 col)  Intensity[a.u.] Intensity_std[a.u.]\n\n']);

            % Text file with header for columns % Martina 10.2025
            % save(file_tot,'spectra_export','-ASCII'); % Selected Spectra
            header = [{'Frequency [THz]'}, repmat({'Spectrum_Ave [a.u.]'}, 1, size(Spectrum_subAve, 2)), repmat({'Spectrum_Std [a.u.]'}, 1, size(Spectrum_subStd, 2))];
            writecell(header, file_tot, 'Delimiter', '\t');
            writematrix(spectra_export, file_tot, 'Delimiter', '\t', 'WriteMode', 'append');

            saveas(main,[file_tot(1:end-3),'jpg'],'jpeg');

        case 9 % Gamma correction

            prompt={'Gamma value'};
            name='Select gamma value';
            numlines=1;
            defaultanswer={'1'};

            options.Resize='on';
            options.WindowStyle='normal';
            options.Interpreter='tex';

            answer=inputdlg(prompt,name,numlines,defaultanswer,options);
            gamma=str2num(cell2mat(answer));
            max_image=max(max(max(ImmagineRGB)));

            cla(h1);

            h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
            hold all; axis off;

            % subplot(h1);

            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma);
            title(['Gamma = ',num2str(gamma)]);
            axis equal;
            set(gca,'YDir','reverse')


        case 10 % Spectral angle Mapping

            %**Benedetto** also possibility to load an external spectrum
            %as reference  06/11/2020
            spectrum_ref_Source=menu('Choose reference spectrum', 'Spectrum from ROI', 'Load external spectrum');

            switch spectrum_ref_Source
                case 1
                    uiwait(msgbox('Select ROI for reference spectrum','Spectral Angle Mapping','warn'));

                    [~,~,Spectrum_Ref,~,cont]=Select_spectra_ROI_simple; %**Benedetto** (aggiunta di cont)
                case 2
                    uiwait(msgbox('The external spectrum has to be a .txt file with the first column representing the frequency and the second column representing the intensity; other columns will be neglected.',...
                        'External spectrum file format','warn'));
                    [filename_spectrum_ref, pathname_spectrum_ref] = uigetfile('*.txt', 'Load saved spectra');
                    file_tot_spectrum_ref=[pathname_spectrum_ref,filename_spectrum_ref];

                    try %files with only numeric values
                        input_data_spectrum_ref = load(file_tot_spectrum_ref);
                    catch %files with headers imported as structures; "data" field with numeric values
                        dataStruct = importdata(file_tot_spectrum_ref);
                        input_data_spectrum_ref = dataStruct.data;
                    end
                    Spectrum_Ref=input_data_spectrum_ref(:,2);
                    fr_real_Ref=input_data_spectrum_ref(:,1);
                    Spectrum_Ref=interp1(fr_real_Ref,Spectrum_Ref,fr_real); Spectrum_Ref(isnan(Spectrum_Ref)) = 0;
                    Spectrum_Ref=Spectrum_Ref';

                    clear input_data_spectrum_ref;

                    Raman_option=menu('Specify external spectrum type', 'Raman', 'Other');
                    if Raman_option==1
                        uiwait(msgbox('If the loaded extenal spectrum is a Raman spectrum it has to be shifted in frequency depending on the difference of its pump laser with respect to the current measurement pump laser.',...
                            'Warning for Raman measurements','warn'));
                        prompt={'External spectrum pump laser wavelength [nm]','Current measurement spectrum pump laser wavelength [nm]'};
                        name='Select pump laser wavelengths';
                        numlines=1;
                        defaultanswer={num2str(780),num2str(780)};
                        options.Resize='on';
                        options.WindowStyle='normal';
                        options.Interpreter='tex';

                        answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                        pump_laser_1=str2double(cell2mat(answer(1)));
                        pump_laser_2=str2double(cell2mat(answer(2)));
                        %shift of the external spectrum
                        fr_real_Ref=fr_real_Ref+c.*(pump_laser_1-pump_laser_2)./(pump_laser_1.*pump_laser_2).*1e9./1e12;
                    end
            end

            prompt={'Lower wavelength (nm)','Higher wavelength (nm)'};
            name='Select spectral band for SAM';
            numlines=1;
            switch spectrum_ref_Source
                case 1
                    defaultanswer={num2str(c/(max(fr_real)*1e12)/1e-9),num2str(c/(min(fr_real)*1e12)/1e-9)};
                case 2 %if I have loaded an external spectrum the extremes of the band must be included in both current and external spectra
                    defaultanswer={num2str(c/(min(max(fr_real_Ref),max(fr_real))*1e12)/1e-9),num2str(c/(max(min(fr_real_Ref),min(fr_real))*1e12)/1e-9)};
            end
            options.Resize='on';
            options.WindowStyle='normal';
            options.Interpreter='tex';

            answer=inputdlg(prompt,name,numlines,defaultanswer,options);
            lmSAM(1)=str2double(cell2mat(answer(1)));
            lmSAM(2)=str2double(cell2mat(answer(2)));

            f_range(1)=c./(lmSAM(1)*1e-9)/1e12;
            f_range(2)=c./(lmSAM(2)*1e-9)/1e12;
            f_range=sort(f_range);

            Index=fr_real>f_range(1) & fr_real<f_range(2);

            theta=zeros(a,b);

            h=waitbar(0,'Generating Spectral Angle Mapping');
            for yy=1:a
                waitbar(yy/a,h);
                for xx=1:b
                    Spectrum=abs(squeeze(Hyperspectrum_cube(yy,xx,Index))); %**Benedetto** abs 09/10/2020
                    theta(yy,xx)=acos( (Spectrum_Ref(Index)'*Spectrum) / sqrt(sum(Spectrum_Ref(Index).^2)*sum(Spectrum.^2)) )*180/pi;

                end
            end

            close (h);

            figure;
            imagesc(theta);
            col=colormap(gray(256)); col=flipud(col); colormap(col); colorbar;
            title('Spectral Angle Mapping (deg)  -  To change angle limits: Edit -> Colormap...');
            axis equal; axis off;

        case 11

            figure(main);
            cla(h1);

            h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
            hold all; axis off;

            % subplot(h1);
            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
            axis equal;
            set(gca,'YDir','reverse')

            cla(h3);
            h3=subplot(2,2,2,'visible','off','Colororder',mm);
            % title('Spectra NOT corrected with Jacobian');
            axh3.XLabel.String=Label_x;
            axh3.YLabel.String='Intensity [arb.un.]';
            axh3.Title.String='Spectra for selected regions'; % title('Spectra NOT corrected with Jacobian'); %250822
            hold all; axis tight;


            cla(h4);
            h4=subplot(2,2,4,'visible','off','Colororder',mm);
            % title('Spectra NOT corrected with Jacobian');
            hold all; axis tight;
            axh4.XLabel.String=Label_x;
            axh4.YLabel.String='Intensity [arb.un.]';
            % axh4.Title.String='Spectra normalised to the peak'; % title('Spectra NOT corrected with Jacobian');
            axh4.Title.String='Spectra normalised to the area'; %251021

            num_spectrum=0;
            Spectrum_subAve=[];
            Spectrum_subStd=[];

        case 12 % Intensity levels

            ImmagineRGB(isnan(ImmagineRGB))=0;

            max_image=max(max(max(ImmagineRGB)));

            [COUNTSr,Xr]=imhist(ImmagineRGB(:,:,1)./max_image,2^11);
            [COUNTSg,Xg]=imhist(ImmagineRGB(:,:,2)./max_image,2^11);
            [COUNTSb,Xb]=imhist(ImmagineRGB(:,:,3)./max_image,2^11);
            histo=figure;
            plot(Xr(1:end-1),COUNTSr(1:end-1),'r',...
                Xg(1:end-1),COUNTSg(1:end-1),'g',...
                Xb(1:end-1),COUNTSb(1:end-1),'b','linewidth',3); axis tight; %era semilogy
            grid on;

            title('Intensity Hystogram');
            legend('R','G','B');

            uiwait(msgbox('ZOOM x-axis to adjust levels, then ENTER',...
                'Adjust intensity levels','warn'));

            zoom xon;
            pause;
            zoom off;

            V=axis;
            close(histo);

            black=V(1); if black<0, black=0; end;
            saturation=V(2);

            cla(h1);

            h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
            hold all; axis off;

            % subplot(h1);

            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma);
            axis equal;
            set(gca,'YDir','reverse')

        case 13 % Normalize on Lambertian

            uiwait(msgbox('The surface must have the same number of pixels and of spectral points',...
                'Load Lambertian surface','warn'));

            [filename_HyperLambert, pathname_HyperLambert] = uigetfile('*.mat;*.h5;*.mj2', 'Load spectral Hypercube of Lambertian'); %**Benedetto *.h5;*.mj2 added
            file_totLambert=[pathname_HyperLambert,filename_HyperLambert];

            dir2=pathname_Hyper;

            stringa=[' *** Analysis of file ',file_totLambert,' ***'];
            fprintf('\n\n%s\n',stringa);

            h=waitbar(0.5,'Loading Lambertian, please wait...');

            %%%%%%%%

            if strcmp(filename_HyperLambert(end-2:end),'.h5') %if loaded file is .h5

                [Hyperspectrum_cubeLambert,fLambert] = H5HypercubeRead(file_totLambert);

            elseif strcmp(filename_HyperLambert(end-3:end),'.mj2') %if loaded file is .mj2

                [Hyperspectrum_cubeLambert,fLambert] = MJ2HypercubeRead(file_totLambert);

            else %if loaded file is .mat

                input_data=load(file_totLambert);

                fLambert=input_data.f;
                Hyperspectrum_cubeLambert=input_data.Hyperspectrum_cube;

                if isa(Hyperspectrum_cubeLambert,'uint16')
                    maximumLambert=input_data.maximum;
                    minimumLambert=input_data.minimum;
                    Hyperspectrum_cubeLambert=double(Hyperspectrum_cubeLambert)./(2.^16-1).*maximumLambert+minimumLambert; %double reconversion procedure from uint16
                    fprintf('\n\n The loaded hypercube was saved in uint16 type\n\n'); %message to explicit the hypercube format
                elseif isa(Hyperspectrum_cubeLambert,'single')
                    Hyperspectrum_cubeLambert=double(Hyperspectrum_cubeLambert); %reconversion to double
                    fprintf('\n\n The loaded hypercube was saved in single type\n\n'); %message to explicit the hypercube format
                else
                    fprintf('\n\n The loaded hypercube was saved in double type\n\n'); %message to explicit the hypercube format
                end

                if size(Hyperspectrum_cubeLambert,3)==2.*length(f) %if the spectral hypecube is complex the real and imag are stacked one over the other
                    Hyperspectrum_cubeLambert_real=Hyperspectrum_cubeLambert(:,:,1:size(Hyperspectrum_cubeLambert,3)./2);
                    Hyperspectrum_cubeLambert_imag=Hyperspectrum_cubeLambert(:,:,size(Hyperspectrum_cubeLambert,3)./2+1:end);
                    clear Hyperspectrum_cubeLambert
                    Hyperspectrum_cubeLambert=zeros(size(Hyperspectrum_cubeLambert_real));
                    Hyperspectrum_cubeLambert=Hyperspectrum_cubeLambert_real+1i.*Hyperspectrum_cubeLambert_imag;
                    clear Hyperspectrum_cubeLambert_real Hyperspectrum_cubeLambert_imag
                end

            end

            %%%%%%%%

            close(h);

            %%% Cristian, 26.5.2021
            if absoluteVal==1
                fprintf('\n\n   Absolute value of the Lambertian Hypercube will be considered.');
                Hyperspectrum_cubeLambert=abs(Hyperspectrum_cubeLambert);
            else
                fprintf('\n\n   The Lambertian Hypercube will be considered as complex.');
            end
            maxLambert=max(max(max(Hyperspectrum_cubeLambert)));
            Hyperspectrum_cubeLambert(Hyperspectrum_cubeLambert==0)=maxLambert/10000;

            %%%%%%

            clear input_data;

            prompt={'Smoothing Lambert spectra (10x10 Gaussian filter''s st.dev.)','Multiplication factor'}; %Multiplication factor is different from 1 if the gain and/or the time frame parameters of the Lambertian are different from the measure %**Benedetto** 19/10/2020
            name='Select smoothing level (0 = no smoothing) and factor'; %**Benedetto** 19/10/2020
            numlines=1;
            defaultanswer={'0','1'}; %**Benedetto** 19/10/2020

            options.Resize='on';
            options.WindowStyle='normal';
            options.Interpreter='tex';

            answer=inputdlg(prompt,name,numlines,defaultanswer,options);
            filt=str2num(cell2mat(answer(1))); %**Benedetto** 19/10/2020
            factor=str2num(cell2mat(answer(2))); %**Benedetto** 19/10/2020

            if filt>0
                H = fspecial('gaussian',10,filt/2);

                sp_points=size(Hyperspectrum_cubeLambert,3);

                h=waitbar(0,'Smoothing Lambertian, please wait...');

                for sp=1:sp_points

                    waitbar(sp/sp_points,h);
                    Hyperspectrum_cubeLambert(:,:,sp)=imfilter(Hyperspectrum_cubeLambert(:,:,sp),H,'replicate'); % Gaussian filter for smoothing
                end;

                close(h);

            end;

            %%%%%%%%%%%

            [aLambert,bLambert]=size(Hyperspectrum_cubeLambert(:,:,1));
            ccLambert=length(fLambert); % number of spectral points

            fprintf(['\n\n   Size: ',num2str(a),' x ',num2str(b),' pixels']);

            if ne(aLambert,a)||ne(bLambert,b)

                settings_file_name = strcat(filename_Hyper(1:end-21),"Settings.mat");
                settings_file = load(fullfile(pathname_Hyper,settings_file_name));

                x_limits = settings_file.settings.x_limits;
                y_limits = settings_file.settings.y_limits;
                Hyperspectrum_cubeLambert = Hyperspectrum_cubeLambert(y_limits(1):y_limits(2)+1, x_limits(1):x_limits(2)+1, :);

                [aLambert,bLambert]=size(Hyperspectrum_cubeLambert(:,:,1));

                fprintf(['\n\n   New Size of Lambertian Hypercube: ',num2str(aLambert),' x ',num2str(bLambert),' pixels']);
            end;

           
            if ne(ccLambert,cc)

                uiwait(msgbox('Numebr of spectral points is different. Aborting',...
                    'Load Lambertian surface','warn'));
            elseif ne(aLambert,a)||ne(bLambert,b)

                uiwait(msgbox('Image size is different. Aborting',...
                    'Load Lambertian surface','warn'));

            else

                Hyperspectrum_cube=Hyperspectrum_cube./(abs(Hyperspectrum_cubeLambert).*factor); %**Benedetto** 19/10/2020 **Benedetto** abs 23/10/2020
                clear Hyperspectrum_cubeLambert;

                Intens=sum(Hyperspectrum_cube,3);

                ImmagineRGB(:,:,1)=Intens;
                ImmagineRGB(:,:,2)=Intens;
                ImmagineRGB(:,:,3)=Intens;

                max_image=max(max(max(ImmagineRGB)));

                cla(h1);

                h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
                hold all; axis off;

                % subplot(h1);

                %image(abs(ImmagineRGB./max_image)); % era imagesc
                image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
                axis equal;
                set(gca,'YDir','reverse')

            end;

        case 14 % Crop/Smoothing

            scelta_CROP_SMOOTHING=menu('Choose action on Hypercube','Crop','Smoothing');

            switch scelta_CROP_SMOOTHING
                case 1 %CROP
                    scelta_crop=menu('Choose crop domain','Spectral','Spatial');

                    switch scelta_crop
                        case 1 %spectral
                            prompt={'Lower wavelength (nm)','Higher wavelength (nm)'};
                            name='Select spectral limits';
                            numlines=1;
                            defaultanswer={num2str(c/(max(fr_real)*1e12)/1e-9),num2str(c/(min(fr_real)*1e12)/1e-9)};
                            options.Resize='on';
                            options.WindowStyle='normal';
                            options.Interpreter='tex';

                            answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                            lmCrop(1)=str2double(cell2mat(answer(1)));
                            lmCrop(2)=str2double(cell2mat(answer(2)));

                            f_Crop(1)=c./(lmCrop(1)*1e-9)/1e12;
                            f_Crop(2)=c./(lmCrop(2)*1e-9)/1e12;
                            f_Crop=sort(f_Crop);

                            Index_Crop=fr_real>f_Crop(1) & fr_real<f_Crop(2);

                            Hyperspectrum_cube=Hyperspectrum_cube(:,:,Index_Crop);
                            fr_real=fr_real(Index_Crop);
                            f=f(Index_Crop);

                            cc=length(f); % number of spectral points

                            uiwait(msgbox('To properly analize the cropped hypercube: save it, close the program and then reopen it','warn'));

                        case 2 %spatial
                            [x_max,y_max,n]=size(Hyperspectrum_cube);
                            uiwait(msgbox('ZOOM crop area, then ENTER','Crop','warn'));

                            figure(main);

                            subplot(h1);
                            axis normal;
                            zoom on;
                            pause;
                            zoom off;

                            V=round(axis);

                            rmin=max([1 round(V(3))]); rmax=min([x_max round(V(4))-1]); % First and last row
                            cmin=max([1 round(V(1))]); cmax=min([y_max round(V(2))-1]); % First and last column

                            Hyperspectrum_cube=Hyperspectrum_cube(rmin:rmax,cmin:cmax,:);
                            Intens=sum(abs(Hyperspectrum_cube),3); %I need to recalculate the Intens map (if then I wan to save the cropped hypercube)
                            ImmagineRGB=ImmagineRGB(rmin:rmax,cmin:cmax,:);
                            [a,b]=size(Hyperspectrum_cube);

                            max_image=max(max(max(ImmagineRGB)));

                            figure(main);
                            cla(h1);

                            h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
                            hold all; axis off;

                            % subplot(h1);
                            %image(abs(ImmagineRGB./max_image)); % Era imagesc
                            saturation=1;
                            gamma=1;

                            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
                            axis equal;
                            set(gca,'YDir','reverse')
                    end

                case 2 %SMOOTHING

                    prompt={'Spatial smoothing of Hypercube (5x5-pixels-Gaussian filter''s st.dev., e.g. 10 = 5 pxls st.dev. smoothing, 0 = no smoothing)'};
                    name='Select number of pixels for smoothing (5x5-pixels-Gaussian filter''s st.dev., e.g. 10 = 5 pxls st.dev. smoothing, 0 = no smoothing)';
                    numlines=1;
                    defaultanswer={'0'};

                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';

                    answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                    n_pixel_smoothing=str2num(cell2mat(answer(1)));

                    if n_pixel_smoothing>0
                        %H = fspecial('average',n_pixel_smoothing)
                        %'average' è un filtro rettangolare
                        %era H = fspecial('gaussian',10,filt/2);
                        %filt/2 era la st.dev. della gaussiana (filt
                        %inserito dall'utente)
                        H = fspecial('gaussian',5,n_pixel_smoothing./2);

                        %il filtro non deve necessariamente essere
                        %rettangolare, può essere anche Gaussiano o altro
                        %(sono tutti buoni filtri)

                        sp_points=size(Hyperspectrum_cube,3);

                        h=waitbar(0,'Smoothing Hypercube, please wait...');

                        for sp=1:sp_points

                            waitbar(sp/sp_points,h);
                            Hyperspectrum_cube(:,:,sp)=imfilter(Hyperspectrum_cube(:,:,sp),H,'replicate'); % imfilter smoothing (it works properly even with complex hypercubes)
                        end

                        close(h);
                    end

                    Intens=sum(abs(Hyperspectrum_cube),3); %I need to recalculate the Intens map (if then I wan to save the cropped hypercube)

                    ImmagineRGB(:,:,1)=Intens;
                    ImmagineRGB(:,:,2)=Intens;
                    ImmagineRGB(:,:,3)=Intens;

                    max_image=max(max(max(ImmagineRGB)));

                    figure(main);
                    cla(h1);

                    h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
                    hold all; axis off;

                    % subplot(h1);
                    %image(abs(ImmagineRGB./max_image)); % Era imagesc
                    saturation=1;
                    gamma=1;

                    image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
                    axis equal;
                    set(gca,'YDir','reverse')
            end


        case 15 % RGB white balance

            black=0; saturation=1; gamma=1; %the image plot parameters are re-setted to the initial ones **Benedetto** 16/11/2020

            %**Benedetto** 24/06/2021 Code modification: possibility to perform the white
            %balance with values set by the user and specification of the
            %spectralon reflectivity value
            uiwait(msgbox('The parameters (black, saturation and gamma) have been set to the initial values.','RGB white balance','warn'));

            RGBwhiteBalance_Source=menu('RGB white balance source', 'Select ROI from image','Set the RGB white values');

            switch RGBwhiteBalance_Source
                case 1
                    uiwait(msgbox('Select now a ROI for RGB white balance.','RGB white balance','warn'));
                    Select_ROI_RGB;
                    uiwait(msgbox(sprintf('The selected RGB values for the normalization are: \n\nnorm_R=%2.3g\nnorm_G=%2.3g\nnorm_B=%2.3g\n',norm_R,norm_G,norm_B),'warn'));
                case 2
                    prompt={'norm\_R','norm\_G','norm\_B'};
                    name='Set values for the image normalization in white balance';
                    numlines=1;
                    defaultanswer={num2str(1),num2str(1),num2str(1)};

                    options.Resize='on';
                    options.WindowStyle='normal';
                    options.Interpreter='tex';

                    answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                    norm_R=str2double(cell2mat(answer(1)));
                    norm_G=str2double(cell2mat(answer(2)));
                    norm_B=str2double(cell2mat(answer(3)));

            end


            prompt={'Set pure white value','Specify Spectralon reflectivity value (from 0 [black] to 1 [white])'};
            name='Select value to attribute to pure white';
            numlines=1;
            defaultanswer={num2str(0.8),num2str(1)};

            options.Resize='on';
            options.WindowStyle='normal';
            options.Interpreter='tex';

            answer=inputdlg(prompt,name,numlines,defaultanswer,options);
            whiteValue=str2double(cell2mat(answer(1))); %white level as defined by the user
            Reflectivity_value=str2double(cell2mat(answer(2))); %spectralon reflectivity value

            norm_R=norm_R./Reflectivity_value;
            norm_G=norm_G./Reflectivity_value;
            norm_B=norm_B./Reflectivity_value;

            ImmagineRGB_R=ImmagineRGB(:,:,1)/norm_R.*whiteValue; % R
            ImmagineRGB_G=ImmagineRGB(:,:,2)/norm_G.*whiteValue; % G
            ImmagineRGB_B=ImmagineRGB(:,:,3)/norm_B.*whiteValue; % B

            noSaturation_R=ones(size(ImmagineRGB_R));
            noSaturation_G=ones(size(ImmagineRGB_G));
            noSaturation_B=ones(size(ImmagineRGB_B));

            noSaturation_R(ImmagineRGB_R>1)=0; %R
            noSaturation_G(ImmagineRGB_G>1)=0; %G
            noSaturation_B(ImmagineRGB_B>1)=0; %B
            %noSaturation matrix (for each R, G and B) has 0 in correspondent saturated
            %values position in ImmagineRGB
            %the product noSaturation_R.*noSaturation_G.*noSaturation_B has 0 in all
            %positions in which at least one R, G or B is saturated

            noSaturation_product=noSaturation_R.*noSaturation_G.*noSaturation_B;

            ImmagineRGB_R(noSaturation_product==0)=1; %R
            ImmagineRGB_G(noSaturation_product==0)=1; %G
            ImmagineRGB_B(noSaturation_product==0)=1; %B
            %all pixels [R,G,B] with R>1 || G>1 || B>1 have been put to [1,1,1]

            ImmagineRGB(:,:,1)=ImmagineRGB_R;
            ImmagineRGB(:,:,2)=ImmagineRGB_G;
            ImmagineRGB(:,:,3)=ImmagineRGB_B;

            max_image=max(max(max(ImmagineRGB))); %**Benedetto** 16/11/2020

            cla(h1);

            h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
            hold all; axis off;

            % subplot(h1);

            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma);
            axis equal;
            set(gca,'YDir','reverse')

            %SaturatedPixelsImage map is created in grey levels (integral
            %R+G+B is put in each one of R, G and B)
            SaturatedPixelsImage_R=(ImmagineRGB_R+ImmagineRGB_G+ImmagineRGB_B)./max(max(ImmagineRGB_R+ImmagineRGB_G+ImmagineRGB_B)); %R
            SaturatedPixelsImage_G=SaturatedPixelsImage_R; %G
            SaturatedPixelsImage_B=SaturatedPixelsImage_R; %B
            %saturated pixels are set in red
            SaturatedPixelsImage_R(noSaturation_product==0)=1; %R
            SaturatedPixelsImage_G(noSaturation_product==0)=0; %G
            SaturatedPixelsImage_B(noSaturation_product==0)=0; %B

            SaturatedPixelsImage(:,:,1)=SaturatedPixelsImage_R;
            SaturatedPixelsImage(:,:,2)=SaturatedPixelsImage_G;
            SaturatedPixelsImage(:,:,3)=SaturatedPixelsImage_B;

            hSaturatedPixels=figure;
            image(SaturatedPixelsImage);
            axis equal;
            title('Saturated pixels map. Press ENTER to continue.');
            pause;
            close(hSaturatedPixels);
            clear ImmagineRGB_R ImmagineRGB_G ImmagineRGB_B;
            clear noSaturation_R noSaturation_G noSaturation_B;
            clear noSaturation_product SaturatedPixelsImage_R SaturatedPixelsImage_G SaturatedPixelsImage_B

        case 16 % Map Spectral Peaks Finding Peaks - from SAM

            MaxSpectrum=max(max(max(abs(Hyperspectrum_cube)))); %**Benedetto** abs 09/10/2020
            prompt={'Lower wavelength (nm)','Higher wavelength (nm)',...
                'Threshold','Spectral interpolation (1: no interpolation)'};
            name='Select spectral band for Peak Maping';
            numlines=1;
            defaultanswer={num2str(c/(max(fr_real)*1e12)/1e-9),...
                num2str(c/(min(fr_real)*1e12)/1e-9),...
                num2str(MaxSpectrum/10),num2str(10)};

            options.Resize='on';
            options.WindowStyle='normal';
            options.Interpreter='tex';

            answer=inputdlg(prompt,name,numlines,defaultanswer,options);
            lmPeak(1)=str2double(cell2mat(answer(1)));
            lmPeak(2)=str2double(cell2mat(answer(2)));
            Threshold=str2double(cell2mat(answer(3)));
            Resolution=round(str2double(cell2mat(answer(4)))); % For interpolation
            if Resolution<1, Resolution=1; end;


            f_rangeP(1)=c./(lmPeak(1)*1e-9)/1e12;
            f_rangeP(2)=c./(lmPeak(2)*1e-9)/1e12;
            f_rangeP=sort(f_rangeP);

            Index=fr_real>f_rangeP(1) & fr_real<f_rangeP(2);
            f1=fr_real(Index);

            PeakWl=zeros(a,b); % Maps spectral frequency
            IntWl=zeros(a,b); % maps spectral intensity

            h=waitbar(0,'Finding Peaks');
            for yy=1:a
                waitbar(yy/a,h);
                for xx=1:b
                    Spectrum=abs(squeeze(Hyperspectrum_cube(yy,xx,Index))); %**Benedetto** abs 09/10/2020

                    %%%% No interpolation

                    % [IntWl(yy,xx),PeakWl(yy,xx)]=max(Spectrum);
                    % PeakWl(yy,xx)=c./(f1(PeakWl(yy,xx))*1e12)/1e-9; % in nm

                    %%%% With interpolation

                    [IntWl(yy,xx),PeakWl_provv]=max(Spectrum);

                    min1=max([PeakWl_provv-5, 1]);
                    max1=min([PeakWl_provv+4, length(f1)]);

                    f2=linspace(f1(min1),f1(max1),(max1-min1+1)*Resolution); % (max1-min1+1)*Resolution Ã¨ il numero di punti dell'interpolante
                    Spectrum_dense=interp1(f1(min1:max1),...
                        Spectrum(min1:max1),f2,'spline');

                    [IntWl(yy,xx),PeakWl(yy,xx)]=max(Spectrum_dense);

                    PeakWl(yy,xx)=c./(f2(PeakWl(yy,xx))*1e12)/1e-9; % in nm

                    %%%%

                end;
            end;

            close (h);

            PeakWl(IntWl<Threshold)=NaN;

            figure;
            imagesc(PeakWl); colormap(jet(256)); colorbar;
            title('Spectral Peak Mapping (nm)  -  To change Wavelength limits: Edit -> Colormap...');
            axis equal; axis off;

            figure;
            imagesc(IntWl); colormap(gray(256)); colorbar;
            title('Intensity of main peak  -  To change Wavelength limits: Edit -> Colormap...');
            axis equal; axis off;


        case 17 %Plot Hypercube **Benedetto** 16/07/2021

            set(h1,'HandleVisibility','off'); %to avoid PlotHypercube to spoil the image **BENEDETTO** 29/11/2021
            set(h3,'HandleVisibility','off'); %to avoid PlotHypercube to spoil the graphs **BENEDETTO** 29/11/2021
            set(h4,'HandleVisibility','off'); %to avoid PlotHypercube to spoil the graphs **BENEDETTO** 29/11/2021

            if derivative_flag==0 %no derivative **Benedetto** 16/07/2021
                h_PH=PlotHypercube(fr_real,abs(Hyperspectrum_cube));

            elseif derivative_flag==1 %first derivative **Benedetto** 16/07/2021
                h_PH=PlotHypercube(fr_real(1:end-1),Hypercube_derivative); %the diff has one less element

            else %second derivative **Benedetto** 16/07/2021
                h_PH=PlotHypercube(fr_real(1:end-2),Hypercube_derivative); %the diff2 has two less elements


            end

        case 18 %Hypercube derivative **Benedetto 16/07/2021

            prompt={'Derivative: 1 or 2 (0 for no derivative)'};
            name='Select derivative order';
            numlines=1;
            defaultanswer={num2str(derivative_flag)};

            options.Resize='on';
            options.WindowStyle='normal';
            options.Interpreter='tex';

            answer=inputdlg(prompt,name,numlines,defaultanswer,options);

            derivative_flag=str2double(cell2mat(answer)); %this is the flag that manages the different cases in the Plot Hypercube and in the Spectrum on area buttons

            if derivative_flag==0
                uiwait(msgbox('No derivative of the Spectral Hypercube will be visualize','warn'));
            elseif derivative_flag==1
                uiwait(msgbox('Spectrum on area and Plot Hypercube buttons will visualize the first derivative.','warn'));
                Hypercube_derivative=diff(abs(Hyperspectrum_cube),1,3);
                Intens_der=sum(abs(Hypercube_derivative),3);

            else
                Hypercube_derivative=diff(abs(Hyperspectrum_cube),2,3);
                Intens_der=sum(abs(Hypercube_derivative),3);
                uiwait(msgbox('Spectrum on area and Plot Hypercube buttons will visualize the second derivative.','warn'));
            end


        case 19 % Saving image

            [filename_Image, pathname_Image] = uiputfile({'*.jpg','jpeg-file (*.jpg)'; ...
                '*.tif','uncompressed TIFF-image (*.tiff)'}, 'Save Current Image',dir2);
            file_Image=[pathname_Image,filename_Image];

            imwrite((abs(ImmagineRGB./max_image-black)/saturation).^gamma,file_Image);

        case 20 % Saving Hypercube

            % %             [filename_Spectra, pathname_Spectra] = uiputfile('*.mat', 'Save Current Hypercube',dir2);
            % %             file_tot=[pathname_Spectra,filename_Spectra];


            %**Benedetto 23/06/2023


            if exist('file_totCal')
                %Saving derivative directly- Martina 16/03/2025
                if derivative_flag~0 %first or second derivative
                    save_hypercube(Hypercube_derivative,f(1:end-1),NoSaturationMap,fr_real(1:end-1), file_totCal, Intens_der, dir2);
                else
                    save_hypercube(Hyperspectrum_cube,f,NoSaturationMap,fr_real,file_totCal,Intens,dir2);
                end
            else
                %Saving derivative directly- Martina 16/03/2025
                if derivative_flag~0 %first or second derivative
                    save_hypercube(Hypercube_derivative,f(1:end-1),NoSaturationMap,[], [], Intens_der, dir2);
                else
                    save_hypercube(Hyperspectrum_cube,f,NoSaturationMap,[],[],Intens,dir2);
                end
            end

            % %             stringa=['  -- Saving current Hypercube in ',file_tot,' --'];
            % %             fprintf('\n%s\n',stringa);
            % %
            % %             % Checks the size of the matrix, before saving
            % %             HyProp = whos('Hyperspectrum_cube') ;
            % %             Gigabytes = HyProp.bytes/2^30;
            % %
            % %             saturationMap=NoSaturationMap; %In the Hypercube file I want the variable called 'saturationMap'
            % %
            % %             if Gigabytes<1.8
            % %                 save(file_tot,'f','fr_real','saturationMap','Intens','Hyperspectrum_cube');
            % %             else
            % %                 save(file_tot,'f','fr_real','saturationMap','Intens','Hyperspectrum_cube','-v7.3');
            % %             end;

        case 21 % Calibrated RGB
            % Calculates the true RGB in the VISIBLE SPECTRAL RANGE
            % Two cases are considered:
            %    1. spectra with absolute REFLECTIVITY
            %    2. EMISSIVE (=fluorescent/non-with-weighted) spectra

            Tipo_dato=menu('This dataset is:',...
                'Absolute Reflectivity','Emission/Fluo/uncalibrated reflectivity');

            % Check here: http://www.brucelindbloom.com/ for reference on
            % color transformation

            switch Tipo_dato

                case 1

                    % P=Spectrum*I
                    I=Energy_i;

                case 2

                    % Wavelength spectrum for x,y,z calculation
                    % P=Spectrum*fr_real^2

                    I=fr_real.^2; % or equivalently, 1/lambda.^2

            end;

            % Normalization coefficient

            kappa=sum(y_lam.*I);

            h=waitbar(0,'Generating RGB image');

            for yy=1:a
                waitbar(yy/a,h);

                for xx=1:b

                    Spectrum=squeeze(abs(Hyperspectrum_cube(yy,xx,:))).*I';

                    % calculation of XYZ coordinates

                    XC=x_lam*Spectrum /kappa;
                    YC=y_lam*Spectrum /kappa;
                    ZC=z_lam*Spectrum /kappa;

                    % from XYZ to RGB (Adobe RGB (1998), white of D65)
                    M=[2.0413690 -0.5649464 -0.3446944;
                        -0.9692660  1.8760108  0.0415560;
                        0.0134474 -0.1183897  1.0154096];

                    %                             var_R_init= X/100*(+2.0413690) + Y/100*(-0.5649464) + Z/100*(-0.3446944);
                    %                             var_G_init= X/100*(-0.9692660) + Y/100*(+1.8760108) + Z/100*(+0.0415560);
                    %                             var_B_init= X/100*(+0.0134474) + Y/100*(-0.1183897) + Z/100*(1.01540960);

                    v = M*[XC YC ZC]';
                    V=zeros(3,1);

                    %%% sRGB nonlinear Companding
                    %                             V(v>0.0031308)=1.055*(v(v>0.0031308).^(1/2.4))-0.055;
                    %                             V(v<=0.0031308)=12.92*v(v<=0.0031308);

                    %%% Nocompanding
                    V=v;

                    ImmagineRGB(yy,xx,1)=V(1); % R
                    ImmagineRGB(yy,xx,2)=V(2); % G
                    ImmagineRGB(yy,xx,3)=V(3); % B

                end;

            end;
            close (h);

            max_image=max(max(max(ImmagineRGB)));

            figure(main);
            cla(h1);

            h1=subplot('position',[0.05 0.05 0.5 1],'Colororder',mm);
            hold all; axis off;

            % subplot(h1);
            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
            axis equal;
            set(gca,'YDir','reverse')


        case 50  % OLD UNUSED
            Spectral_filter;

            lambda_nm=c./(fr_real*1e12)/1e-9;

            fprintf(['\n   Frequency: ',num2str(fr_real(1)),'-',num2str(fr_real(end)),' THz (', num2str(cc),' spectral points)']);
            fprintf(['\n   Wavelength: ',num2str(lambda_nm(end)),'-',num2str(lambda_nm(1)),' nm\n\n']);

            % RGB in frequency axis
            R_THz=interp1(wl, R,lambda_nm).*lambda_nm.^2/c; R_THz(isnan(R_THz))=0;
            G_THz=interp1(wl, G,lambda_nm).*lambda_nm.^2/c; G_THz(isnan(G_THz))=0;
            B_THz=interp1(wl, B,lambda_nm).*lambda_nm.^2/c; B_THz(isnan(B_THz))=0;

            % RGB;

            Intens=sum(Hyperspectrum_cube,3);

            ImmagineRGB(:,:,1)=Intens;
            ImmagineRGB(:,:,2)=Intens;
            ImmagineRGB(:,:,3)=Intens;

            max_image=max(max(max(ImmagineRGB)));
            subplot(h1);
            image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
            axis equal;
            set(gca,'YDir','reverse')

    end;

    scelta_menu = menu('Choose analysis',...
        'Generate False-RGB map','Spectrum on area','Reflectivity map',...
        'Transmission map ','Rotate','Save spectral GIF',...
        'Remove BKG from ROI','Save Spectra','Gamma correction',...
        'Spectral Angle Mapping','Clean Graphs','Intensity levels',...
        'Normalize on Lambertian','Crop/Smoothing','RGB white balance',...
        'Map Spectral Peaks','Plot Hypercube','Hypercube derivative',...
        'Save current image','Save current Hypercube','Calibrated RGB',...
        'EXIT' );

end;

% end


    function RGB % Generates an RGB image from colormap

        h=waitbar(0,'Generating RGB image');
        for y1=1:a
            waitbar(y1/a,h);
            for x1=1:b
                Spectrum=abs(squeeze(Hyperspectrum_cube(y1,x1,:))); %**Benedetto** abs 09/10/2020

                ImmagineRGB(y1,x1,1)=R_THz*Spectrum; % R
                ImmagineRGB(y1,x1,2)=G_THz*Spectrum; % G
                ImmagineRGB(y1,x1,3)=B_THz*Spectrum; % B

            end;
        end;

        close (h);

        max_image=max(max(max(ImmagineRGB)));
        subplot(h1);
        image((abs(ImmagineRGB./max_image-black)/saturation).^gamma); % era image(abs(ImmagineRGB./max_image)); **Benedetto** 18/11/2020
        axis equal;
        set(gca,'YDir','reverse')

    end


    function Select_spectra

        set(h3,'visible','off'); hold off; hold all
        set(h4,'visible','off'); hold off; hold all

        subplot(h1);
        [x,y,button]=ginput(1);
        colore=0;
        cont=0;

        while button==1

            x=round(x);
            y=round(y);
            cont=cont+1;
            x_sel(cont)=x;
            y_sel(cont)=y;

            Spectrum=abs(squeeze(Hyperspectrum_cube(y,x,:))); %**Benedetto** abs 09/10/2020

            Spectrum_sel(:,cont)=Spectrum;

            % Correction frequency -> wavelength: SpettroC1*fr_real.^2/c
            SpectrumWL=Spectrum.*fr_real(ones(1,size(Spectrum,2)),:).'.^2/c;

            plot(h1,x,y,'o','linewidth',2);

            set(h3,'visible','on');
            plot(h3,c./(fr_real*1e12)/1e-9,SpectrumWL,'linewidth',2);

            set(h4,'visible','on');
            plot(h4,c./(fr_real*1e12)/1e-9,SpectrumWL/max(SpectrumWL),'linewidth',2);

            subplot(h1);
            [x,y,button]=ginput(1);

        end;

        % Saving selected spectra
        [filename_Spectra, pathname_Spectra] = uiputfile('*.mat', 'Save Spectra as',dir2);
        file_tot=[pathname_Spectra,filename_Spectra];

        stringa=['  -- Saving Selected Spectra in ',file_tot,' --'];
        fprintf('\n%s\n',stringa);

        save(file_tot,'x_sel','y_sel','fr_real','Spectrum_sel'); % Selected Spectra

    end


    function Spectral_filter
        % Filtered=zeros(size(Hyperspectrum_cube(:,:,1)));

        prompt={'Lower wavelength (nm)','Higher wavelength (nm) - 4 digits'};
        name='Select spectral band';
        numlines=1;
        defaultanswer={num2str(c/(max(fr_real)*1e12)/1e-9),num2str(c/(min(fr_real)*1e12)/1e-9)};

        options.Resize='on';
        options.WindowStyle='normal';
        options.Interpreter='tex';

        answer=inputdlg(prompt,name,numlines,defaultanswer,options);
        f_range(1)=c./(str2num(cell2mat(answer(1)))*1e-9)/1e12;
        f_range(2)=c./(str2num(cell2mat(answer(2)))*1e-9)/1e12;
        f_range=sort(f_range);

        Index=fr_real>f_range(1) & fr_real<f_range(2);

        f=f(Index); % Non serve
        fr_real=fr_real(Index);
        Hyperspectrum_cube=Hyperspectrum_cube(:,:,Index);

        [filename_Spectra, pathname_Spectra] = uiputfile('*.mat', 'Save filtered image as',dir2);
        file_tot=[pathname_Spectra,filename_Spectra];

        h=waitbar(0.5,'Saving filtered hypercube, please wait...');

        stringa=['  -- Saving filtered image in ',file_tot,' --'];
        fprintf('\n%s\n',stringa);

        % Checks the size of the matrix, before saving
        HyProp = whos('Hyperspectrum_cube') ;
        Gigabytes = HyProp.bytes/2^30;

        if Gigabytes<1.8
            save(file_tot,'f','fr_real','Hyperspectrum_cube');
        else
            save(file_tot,'f','fr_real','Hyperspectrum_cube','-v7.3');
        end;

        % save(file_tot,'f_range','f','fr_real','Hyperspectrum_cube'); %

        close(h);

    end

    function [Spectrum_subAveWL,Spectrum_subStdWL,...
            Spectrum_subAve,Spectrum_subStd,cont]=Select_spectra_ROI_simple % Selects a ROI and calculates the average spectrum of that ROI  %**Benedetto** (aggiunta di cont)

        subplot(h1);
        [ThisAOI, xr, yr] = roipoly();
        hold all;
        line(xr,yr,'Linewidth',2,'Color',mm(mod(num_spectrum-1,8)+1,:)); % ,'Color','r'); % display the outer border of the mask as a polygon
        cont=0;

        for y1=1:a

            for x1=1:b

                if ThisAOI(y1,x1)==1 && NoSaturationMap(y1,x1)==1 %**Benedetto** saturationMap 25/10/2020
                    cont=cont+1;
                    Spectrum=squeeze(Hyperspectrum_cube(y1,x1,:));
                    Spectrum_sub(:,cont)=Spectrum;

                end

            end

        end

        if derivative_flag==0 %no derivative **Benedetto** 16/07/2021
            Spectrum_subAve=abs(mean(Spectrum_sub,2)); %**Benedetto** abs 09/10/2020
            Spectrum_subStd=sqrt(var(abs(Spectrum_sub'))'); %**Benedetto** abs 09/10/2020
        elseif derivative_flag==1 %first derivative **Benedetto** 16/07/2021
            mean_Spectrum_sub=abs(mean(Spectrum_sub,2));
            Spectrum_subAve_diff=diff(mean_Spectrum_sub,1);
            Spectrum_subAve=zeros(size(mean_Spectrum_sub)); %Spectrum_subAve must have the same dimension as mean_Spectrum_sub
            Spectrum_subAve(1:end-1)=Spectrum_subAve_diff;
            Spectrum_subAve(end)=Spectrum_subAve_diff(end); %the last element is equal to the second-last
            clear mean_Spectrum_sub Spectrum_subAve_diff;

            Std_Spectrum_sub=sqrt(var(abs(Spectrum_sub'))');
            Spectrum_subStd_diff=diff(Std_Spectrum_sub,1);
            Spectrum_subStd=zeros(size(Std_Spectrum_sub)); %Spectrum_subStd must have the same dimension as mean_Spectrum_sub
            Spectrum_subStd(1:end-1)=Spectrum_subStd_diff;
            Spectrum_subStd(end)=Spectrum_subStd_diff(end); %the last element is equal to the second-last
            clear Std_Spectrum_sub Spectrum_subStd_diff;
        else %second derivative **Benedetto** 16/07/2021
            mean_Spectrum_sub=abs(mean(Spectrum_sub,2));
            Spectrum_subAve_diff=diff(mean_Spectrum_sub,2);
            Spectrum_subAve=zeros(size(mean_Spectrum_sub)); %Spectrum_subAve must have the same dimension as mean_Spectrum_sub
            Spectrum_subAve(1:end-2)=Spectrum_subAve_diff;
            Spectrum_subAve(end-1)=Spectrum_subAve_diff(end);
            Spectrum_subAve(end)=Spectrum_subAve_diff(end); %the last two elements are equal to the third-last
            clear mean_Spectrum_sub Spectrum_subAve_diff;

            Std_Spectrum_sub=sqrt(var(abs(Spectrum_sub'))');
            Spectrum_subStd_diff=diff(Std_Spectrum_sub,2);
            Spectrum_subStd=zeros(size(Std_Spectrum_sub)); %Spectrum_subStd must have the same dimension as mean_Spectrum_sub
            Spectrum_subStd(1:end-2)=Spectrum_subStd_diff;
            Spectrum_subStd(end-1)=Spectrum_subStd_diff(end);
            Spectrum_subStd(end)=Spectrum_subStd_diff(end); %the last two elements are equal to the third-last
            clear Std_Spectrum_sub Spectrum_subStd_diff;
        end


        % Correction frequency -> wavelength: SpettroC1*fr_real.^2/c
        SpectrumWL=Spectrum_sub.*fr_real(ones(1,size(Spectrum_sub,2)),:).'.^2/c;

        Spectrum_subAveWL=abs(mean(SpectrumWL,2)); %**Benedetto** abs 09/10/2020
        Spectrum_subStdWL=sqrt(var(abs(SpectrumWL'))'); %**Benedetto** abs 09/10/2020

    end



    function [Spectrum_subAveWL,Spectrum_subStdWL,...
            Spectrum_subAve,Spectrum_subStd,cont, aspectRatio, width, height]=Select_spectra_ROI(aspectRatio, width, height) % Selects a ROI and calculates the average spectrum of that ROI  %**Benedetto** (aggiunta di cont)

        subplot(h1);
        if aspectRatio>1500 %arbitrary number
            %ROItype=Dinput('\n\n   Select ROI type: (0 = generic, 1 = rectangular): ',0);
            prompt={'ROI type: generic (0); rectangular (1).'};
            name='Select ROI type';
            numlines=1;
            defaultanswer={num2str(0)};

            options.Resize='on';
            options.WindowStyle='normal';
            options.Interpreter='tex';

            answer=inputdlg(prompt,name,numlines,defaultanswer,options);
            ROItype=str2double(cell2mat(answer)); %this is the flag that manages the different cases

        else
            ROItype=2;
        end

        switch ROItype
            case 0
                [mask, xr, yr] = roipoly();
                hold all;
                line(xr,yr,'Linewidth',2,'Color',mm(mod(num_spectrum-1,8)+1,:)); % ,'Color','r'); % display the outer border of the mask as a polygon
                aspectRatio=0;
            case 1
                roi=drawrectangle();
                % extract top-left corner position, width and height
                rectPosition=roi.Position;
                % Extract x, y, width, height
                %x = rectPosition(1);
                %y = rectPosition(2);
                width = rectPosition(3);
                height = rectPosition(4);

                % Calculate the aspect ratio
                aspectRatio = width / height;
                %display(aspectRatio)
                %Keep the aspect ratio and select the new coordinates: clicking in a point
                %without drawing any rectangle I can derive the coordinates of the top-left
                %corner while I use the previous aspect ratio
                mask=createMask(roi,a,b);
                %mask3d=repmat(mask, [1,1, length(fr_real)]);

            case 2
                [x, y] = ginput(1);
                roi=drawrectangle('Position', [x, y, width, height]);
                mask=createMask(roi, a,b);
        end
        cont=0;

        for y1=1:a

            for x1=1:b

                if mask(y1,x1)==1 && NoSaturationMap(y1,x1)==1 %**Benedetto** saturationMap 25/10/2020
                    cont=cont+1;
                    Spectrum=squeeze(Hyperspectrum_cube(y1,x1,:));
                    Spectrum_sub(:,cont)=Spectrum;

                end

            end

        end

        if derivative_flag==0 %no derivative **Benedetto** 16/07/2021
            Spectrum_subAve=abs(mean(Spectrum_sub,2)); %**Benedetto** abs 09/10/2020
            Spectrum_subStd=sqrt(var(abs(Spectrum_sub'))'); %**Benedetto** abs 09/10/2020
        elseif derivative_flag==1 %first derivative **Benedetto** 16/07/2021
            mean_Spectrum_sub=abs(mean(Spectrum_sub,2));
            Spectrum_subAve_diff=diff(mean_Spectrum_sub,1);
            Spectrum_subAve=zeros(size(mean_Spectrum_sub)); %Spectrum_subAve must have the same dimension as mean_Spectrum_sub
            Spectrum_subAve(1:end-1)=Spectrum_subAve_diff;
            Spectrum_subAve(end)=Spectrum_subAve_diff(end); %the last element is equal to the second-last
            clear mean_Spectrum_sub Spectrum_subAve_diff;

            Std_Spectrum_sub=sqrt(var(abs(Spectrum_sub'))');
            Spectrum_subStd_diff=diff(Std_Spectrum_sub,1);
            Spectrum_subStd=zeros(size(Std_Spectrum_sub)); %Spectrum_subStd must have the same dimension as mean_Spectrum_sub
            Spectrum_subStd(1:end-1)=Spectrum_subStd_diff;
            Spectrum_subStd(end)=Spectrum_subStd_diff(end); %the last element is equal to the second-last
            clear Std_Spectrum_sub Spectrum_subStd_diff;
        else %second derivative **Benedetto** 16/07/2021
            mean_Spectrum_sub=abs(mean(Spectrum_sub,2));
            Spectrum_subAve_diff=diff(mean_Spectrum_sub,2);
            Spectrum_subAve=zeros(size(mean_Spectrum_sub)); %Spectrum_subAve must have the same dimension as mean_Spectrum_sub
            Spectrum_subAve(1:end-2)=Spectrum_subAve_diff;
            Spectrum_subAve(end-1)=Spectrum_subAve_diff(end);
            Spectrum_subAve(end)=Spectrum_subAve_diff(end); %the last two elements are equal to the third-last
            clear mean_Spectrum_sub Spectrum_subAve_diff;

            Std_Spectrum_sub=sqrt(var(abs(Spectrum_sub'))');
            Spectrum_subStd_diff=diff(Std_Spectrum_sub,2);
            Spectrum_subStd=zeros(size(Std_Spectrum_sub)); %Spectrum_subStd must have the same dimension as mean_Spectrum_sub
            Spectrum_subStd(1:end-2)=Spectrum_subStd_diff;
            Spectrum_subStd(end-1)=Spectrum_subStd_diff(end);
            Spectrum_subStd(end)=Spectrum_subStd_diff(end); %the last two elements are equal to the third-last
            clear Std_Spectrum_sub Spectrum_subStd_diff;
        end


        % Correction frequency -> wavelength: SpettroC1*fr_real.^2/c
        SpectrumWL=Spectrum_sub.*fr_real(ones(1,size(Spectrum_sub,2)),:).'.^2/c;

        Spectrum_subAveWL=abs(mean(SpectrumWL,2)); %**Benedetto** abs 09/10/2020
        Spectrum_subStdWL=sqrt(var(abs(SpectrumWL'))'); %**Benedetto** abs 09/10/2020

        if ROItype
            newROI=Dinput('\n\n   Select new ROI with same aspect ratio: (0 = no, 1 = yes): ',1);
            if newROI==0
                aspectRatio=0;
            end
        end
    end


    function Select_ROI

        subplot(h1);
        [ThisAOI, xr, yr] = roipoly();
        hold all;
        line(xr,yr); %,'Color','r'); % display the outer border of the mask as a red polygon
        cont=0;

        for y1=1:a

            for x1=1:b

                if ThisAOI(y1,x1)==1 && NoSaturationMap(y1,x1)==1 %**Benedetto** saturationMap 25/10/2020
                    cont=cont+1;
                    Spectrum=squeeze(Hyperspectrum_cube(y1,x1,:));
                    Spectrum_sub(:,cont)=Spectrum;

                end;

            end;

        end;

        Spectrum_subAve=abs(mean(Spectrum_sub,2)); %**Benedetto** abs 09/10/2020
        Spectrum_subStd=sqrt(var(abs(Spectrum_sub'))'); %**Benedetto** abs 09/10/2020

    end


    function Select_ROI_RGB % Calculates average RGB in the selected area

        subplot(h1);
        [ThisAOI, xr, yr] = roipoly();
        hold all;
        line(xr,yr); %,'Color','r'); % display the outer border of the mask as a red polygon
        cont=0;

        for y1=1:a

            for x1=1:b

                if ThisAOI(y1,x1)==1 && NoSaturationMap(y1,x1)==1 %**Benedetto** saturationMap 25/10/2020
                    cont=cont+1;

                    %RGB(cont,:)=(abs(ImmagineRGB(y1,x1,:)./max_image-black)/saturation).^gamma;
                    RGB(cont,:)=ImmagineRGB(y1,x1,:); %**Benedetto** 16/11/2020

                end;

            end;

        end;

        norm_R=mean(RGB(:,1));
        norm_G=mean(RGB(:,2));
        norm_B=mean(RGB(:,3));

    end



    function CalculateR

        Re=zeros(size(Hyperspectrum_cube));

        h=waitbar(0,'Calculating R');

        for y1=1:a
            waitbar(y1/a,h);

            for x1=1:b

                Spectrum=abs(squeeze(Hyperspectrum_cube(y1,x1,:))); %**Benedetto** abs 09/10/2020
                Re(y1,x1,:)=(Spectrum)./Spectrum_subAve;

            end;

        end;
        close(h);

        % Saving selected spectra
        Hyperspectrum_cube_Old=Hyperspectrum_cube;

        % %         [filename_Spectra, pathname_Spectra] = uiputfile('*.mat', 'Save R Hypercube as',dir2);
        % %         file_tot=[pathname_Spectra,filename_Spectra];

        %         stringa=['  -- Saving R Hypercube in ',file_tot,' --'];
        %         fprintf('\n%s\n',stringa);
        stringa=['  -- Saving T Hypercube',' --']; %the path is chosen inside save_hypercube
        fprintf('\n%s\n',stringa);

        Hyperspectrum_cube=Re;

        %**Benedetto 23/06/2023
        if exist('file_totCal')
            save_hypercube(Hyperspectrum_cube,f,NoSaturationMap,fr_real,file_totCal,Intens,dir2);
        else
            save_hypercube(Hyperspectrum_cube,f,NoSaturationMap,[],[],Intens,dir2);
        end

        % %         % Checks the size of the matrix, before saving
        % %         HyProp = whos('Hyperspectrum_cube') ;
        % %         Gigabytes = HyProp.bytes/2^30;
        % %
        % %         if Gigabytes<1.8
        % %             save(file_tot,'f','fr_real','Hyperspectrum_cube');
        % %         else
        % %             save(file_tot,'f','fr_real','Hyperspectrum_cube','-v7.3');
        % %         end;
        % %
        % %         % save(file_tot,'f','fr_real','Hyperspectrum_cube'); % R Spectra

        Hyperspectrum_cube=Hyperspectrum_cube_Old;

        clear Hyperspectrum_cube_Old

    end



    function CalculateT

        T=zeros(size(Hyperspectrum_cube));

        h=waitbar(0,'Calculating T');

        for y1=1:a

            waitbar(y1/a,h);

            for x1=1:b

                Spectrum=abs(squeeze(Hyperspectrum_cube(y1,x1,:))); %**Benedetto** abs 09/10/2020
                T(y1,x1,:)=(Spectrum-Spectrum_subAve)./Spectrum_subAve;

            end;

        end;

        % Saving selected spectra
        Hyperspectrum_cube_Old=Hyperspectrum_cube;

        % %         [filename_Spectra, pathname_Spectra] = uiputfile('*.mat', 'Save T Hypercube as',dir2);
        % %         file_tot=[pathname_Spectra,filename_Spectra];

        %         stringa=['  -- Saving T Hypercube in ',file_tot,' --'];
        %         fprintf('\n%s\n',stringa);
        stringa=['  -- Saving T Hypercube',' --']; %the path is chosen inside save_hypercube
        fprintf('\n%s\n',stringa);

        Hyperspectrum_cube=T;

        %**Benedetto 23/06/2023
        if exist('file_totCal')
            save_hypercube(Hyperspectrum_cube,f,NoSaturationMap,fr_real,file_totCal,Intens,dir2);
        else
            save_hypercube(Hyperspectrum_cube,f,NoSaturationMap,[],[],Intens,dir2);
        end

        % %         % Checks the size of the matrix, before saving
        % %         HyProp = whos('Hyperspectrum_cube') ;
        % %         Gigabytes = HyProp.bytes/2^30;
        % %
        % %         if Gigabytes<1.8
        % %             save(file_tot,'f','fr_real','Hyperspectrum_cube');
        % %         else
        % %             save(file_tot,'f','fr_real','Hyperspectrum_cube','-v7.3');
        % %         end;

        % save(file_tot,'f','fr_real','Hyperspectrum_cube'); % T Spectra

        Hyperspectrum_cube=Hyperspectrum_cube_Old;
        clear Hyperspectrum_cube_Old

    end



    function Select_ROI_BKG % Select ROI for BKG subtraction

        subplot(h1);
        [ThisAOI, ~, ~] = roipoly();
        hold all;
        % line(xr,yr); %,'Color','r'); % display the outer border of the mask as a red polygon
        cont=0;

        for y1=1:a

            for x1=1:b

                if ThisAOI(y1,x1)==1
                    cont=cont+1;
                    Spectrum=squeeze(Hyperspectrum_cube(y1,x1,:));
                    Spectrum_sub(:,cont)=Spectrum;

                end;

            end;

        end;

        BKG_Ave=(mean(Spectrum_sub,2)); %**Benedetto** ERA abs 09/10/2020
        BKG_Std=sqrt(var(abs(Spectrum_sub)'))'; %**Benedetto** abs 09/10/2020

        % Correction frequency -> wavelength: SpettroC1*fr_real.^2/c
        % SpectrumWL=Spectrum_sub.*fr_real(ones(1,size(Spectrum_sub,2)),:).'.^2/c;

        % BKG_AveWL=mean(SpectrumWL,2);
        % BKG_StdWL=sqrt(var(SpectrumWL'))';

        set(h3,'visible','on');
        % plot(h3,c./(fr_real*1e12)/1e-9,BKG_AveWL,'linewidth',3);
        plot(h3,c./(fr_real*1e12)/1e-9,abs(BKG_Ave),'linewidth',3); %**Benedetto** abs 09/10/2020
        hold all;
        %         plot(h3,c./(fr_real*1e12)/1e-9,BKG_AveWL-BKG_StdWL,'k--',...
        %             c./(fr_real*1e12)/1e-9,BKG_AveWL+BKG_StdWL,'k--','linewidth',1);
        plot(h3,c./(fr_real*1e12)/1e-9,abs(BKG_Ave)-BKG_Std,'k--',...
            c./(fr_real*1e12)/1e-9,abs(BKG_Ave)+BKG_Std,'k--','linewidth',1); %**Benedetto** abs 09/10/2020  era abs(BKG_Ave-BKG_Std)

        set(h4,'visible','on');
        % plot(h4,c./(fr_real*1e12)/1e-9,BKG_AveWL./max(BKG_AveWL),'linewidth',3);
        plot(h4,c./(fr_real*1e12)/1e-9,abs(BKG_Ave)./max(abs(BKG_Ave)),'linewidth',3);
        hold all;
        %         plot(h4,c./(fr_real*1e12)/1e-9,(BKG_AveWL-BKG_StdWL)./max(BKG_AveWL),'k--',...
        %             c./(fr_real*1e12)/1e-9,(BKG_AveWL+BKG_StdWL)./max(BKG_AveWL),'k--','linewidth',1);
        plot(h4,c./(fr_real*1e12)/1e-9,(abs(BKG_Ave)-BKG_Std)./max(abs(BKG_Ave)),'k--',...
            c./(fr_real*1e12)/1e-9,(abs(BKG_Ave)+BKG_Std)./max(abs(BKG_Ave)),'k--','linewidth',1); %**Benedetto** abs 09/10/2020

        fprintf(['\n   Selected for Bkg: ',num2str(cont),' pixels\n']);

    end


    function shaded_error(hfig,x,y,err,mm,num_spectrum)
        % plots a line and the shaded standard deviation; mm is the matrix
        % including the colors used for plotting.

        plot(hfig,x,y,'linewidth',3,'Color',mm(mod(num_spectrum-1,8)+1,:));

        xconf = [x x(end:-1:1)] ;
        yconf = [y+err y(end:-1:1)-err(end:-1:1)];

        subplot(hfig);
        p = fill(xconf,yconf,mm(mod(num_spectrum-1,8)+1,:));
        set(p,'FaceColor',mm(mod(num_spectrum-1,8)+1,:),'facealpha',.2,'Edgealpha',0);

        %         h = fill(x,y,color);  % Original code
        %         % Choose a number between 0 (invisible) and 1 (opaque) for facealpha.
        %         set(h,'facealpha',.1);
        %         set(h,'Edgealpha',0)

    end


    function Generate_GIF

        lmPeak(1)=round(Dinput('\n    Lower wavelength: ',min(lambda_nm)));
        lmPeak(2)=round(Dinput('\n    Higher wavelength: ',max(lambda_nm)));

        f_rangeP(1)=c./(lmPeak(1)*1e-9)/1e12;
        f_rangeP(2)=c./(lmPeak(2)*1e-9)/1e12;
        f_rangeP=sort(f_rangeP);

        Index=find(fr_real>f_rangeP(1) & fr_real<f_rangeP(2));
        cc1=min(Index);
        cc2=max(Index);

        bands=round(Dinput('\n    Total number of bands: ',cc2-cc1+1));

        gammaGIF=Dinput('\n    Gamma value: ',gamma);
        bar=round(Dinput('\n    Spectral Bar in picture? [1: yes - 0: no]: ',1));

        % reflectivity=Dinput('\n    This is a: 1 - Reflectivity map; 2 - Other',2);

        sel_band=linspace(cc2,cc1,bands); sel_band=round(sel_band);

        % Saving GIF image
        [filename_GIF, pathname_GIF] = uiputfile('*.gif', 'Save GIF as',dir2);
        filename=[pathname_GIF,filename_GIF];

        scrsz = get(groot,'ScreenSize');
        hh=figure('Position',[1 scrsz(4) scrsz(3) scrsz(4)]);

        % colormap(jet(512));
        colormap(gray(512));


        %%%%%%%%%%%%%%%

        AllSpectra=reshape(abs(Hyperspectrum_cube(:,:,cc1:cc2)),[],1); %**Benedetto** abs 09/10/2020
        maxCube=max(AllSpectra);

        [COUNTS,X]=hist(AllSpectra,2^11);
        histo=figure;
        % semilogy(X*maxCube,COUNTS); axis tight;
        plot(X,COUNTS); axis tight; % era semilogy
        grid on;

        title('Spectral Intensity Hystogram');

        uiwait(msgbox('ZOOM x-axis to adjust levels, then ENTER',...
            'Adjust intensity levels','warn'));

        zoom xon;
        pause;
        zoom off;

        V=axis;
        close(histo);

        maxCube=V(2);

        %%%%%%%%%%%%%%%%%%%%
        hGIF=subplot('position',[0.05 0.05 0.9 0.9]);

        for n = 1:bands

            aaaa=abs( Hyperspectrum_cube(:,:,sel_band(n))./maxCube); % *3);

            subplot(hGIF);
            image((aaaa.^gammaGIF)*256); axis off; axis equal; colorbar;

            if bar, rectangle('FaceColor',[1 0 0 ],'EdgeColor','none','Position',[0 0 b*n/bands a/30 ]); end;

            if load_cal
                testo=['\lambda = ',num2str(round(lambda_nm(sel_band(n)))),' nm'];
                %testo=[num2str(round(lambda_nm(sel_band(n)))),'nm']; %era così **Benedetto 24/06/2023
            else
                testo=[num2str(round(sel_band(n))),' pseudo'];
            end;

            text(b/2, -15,testo,'HorizontalAlignment', 'center','FontSize',20);

            drawnow

            frame = getframe(hh);
            im = frame2im(frame);
            [imind,cm] = rgb2ind(im,256);
            if n == 1;
                imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
            else
                imwrite(imind,cm,filename,'gif','WriteMode','append');
            end
        end

    end





end

function [Hyperspectrum_cube,f,saturationMap,file_totCal,fr_real,Intens] = H5HypercubeRead(filename) %**Benedetto 21/11/2022

%function to load the H5 (hyerarchical files) Spectral Hypercubes in Matlab
%
%filename: path and file name
%
%Hyperspectrum_cube: spectral hypercube dataset (absolute or complex)
%f: pseudofrequency axis
%saturationMap: map of saturated pixels (0:saturated, 1:not saturated
%file_totCal: frequency calibration, if it is present
%fr_real: real calibrated frequencies axis, if it is present
%Intens: 2D matrix hypercube integral over frequencies

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
    fprintf('\n\n The loaded hypercube was saved in uint16 type\n\n'); %message to explicit the hypercube format
elseif isa(Hyperspectrum_cube,'single')
    Hyperspectrum_cube=double(Hyperspectrum_cube); %reconversion to double
    fprintf('\n\n The loaded hypercube was saved in single type\n\n'); %message to explicit the hypercube format
else
    fprintf('\n\n The loaded hypercube was saved in double type\n\n'); %message to explicit the hypercube format
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

function [Hyperspectrum_cube,f,saturationMap,file_totCal,fr_real,Intens] = MJ2HypercubeRead(filename) %**Benedetto 21/11/2022

%function to load the mj2 (Motion JPEG 2000 lossless video) Spectral Hypercubes in Matlab
%
%filename: path and file name
%
%Hyperspectrum_cube: spectral hypercube dataset (absolute or complex)
%f: pseudofrequency axis
%saturationMap: map of saturated pixels (0:saturated, 1:not saturated
%file_totCal: frequency calibration, if it is present
%fr_real: real calibrated frequencies axis, if it is present
%Intens: 2D matrix hypercube integral over frequencies

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

hh=waitbar(1/2,'hypercube conversion from video to .mat...');

tic;
images=obj.read; %video uint16 images stack
Hyperspectrum_cube=double(squeeze(images(:,:,1,:)))./(2.^16-1).*maximum+minimum;
tempo=toc;
waitbar(1,hh);
close(hh);

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
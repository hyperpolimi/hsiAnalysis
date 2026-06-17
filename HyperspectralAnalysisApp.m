classdef HyperspectralAnalysisApp < matlab.apps.AppBase
    % HyperspectralAnalysisApp
    %
    % App Designer-style (programmatic) app for analysis of spectral
    % hypercubes, based on HyperspectralAnalysis_Spectrum.m
    %
    % PHASE 1 (core features):
    %   - Load hypercube (.mat / .h5 / .mj2), with frequency calibration
    %   - Display image with black/saturation/gamma levels
    %   - Rotate (90/-90/180/custom)
    %   - Generate false-RGB map (spectral range or single wavelengths,
    %     with spatial binning)
    %   - RGB white balance
    %   - Spectrum from ROI (polygon/rectangle), with shaded std. dev.
    %   - Spectrum at clicked pixel
    %   - Remove background from ROI
    %   - Clean graphs
    %   - Save spectra / current image / current hypercube
    %
    % REQUIREMENTS (must be on the MATLAB path / next to this file):
    %   - RGB_Transmission.mat   (R, G, B, wl variables)
    %   - RGBspectra/            (folder, as in the original script)
    %   - save_hypercube.m       (external function, used by "Save Hypercube")
    %
    % Internally, spectral data is stored vs. frequency (f, fr_real, THz)
    % exactly as in the original script. All plots/axes use wavelength
    % (lambda_nm = c./(fr_real*1e12)/1e-9), in nm.
    %
    % Phase 2 (planned): Spectral Angle Mapping, Reflectivity/Transmission
    % maps, Lambertian normalization, crop/spectral smoothing, peak
    % mapping, hypercube derivative + PlotHypercube, GIF export,
    % calibrated (CIE) RGB.

    % ---------------------------------------------------------------
    % UI components
    % ---------------------------------------------------------------
    properties (Access = public)
        UIFigure
        MainGrid
        ImageAxes
        SpectrumAxes
        NormSpectrumAxes
        ControlTabGroup
        StatusLabel

        % File tab
        FileTab
        LoadButton
        FileNameLabel
        SizeLabel
        CalibLabel

        % Display tab
        DisplayTab
        BlackEditField
        SaturationEditField
        GammaEditField
        ApplyLevelsButton
        AutoLevelsButton
        RotateButton
        CleanGraphsButton
        CustomAxesButton

        % RGB tab
        RGBTab
        GenerateRGBButton
        WhiteBalanceButton
        CalibratedRGBButton

        % Spectra tab
        SpectraTab
        AddROISpectrumButton
        PixelClickButton
        RemoveBKGButton

        % Maps tab
        MapsTab
        SAMButton
        ReflectivityButton
        TransmissionButton
        LambertianButton
        PeakMappingButton

        % Analysis tab
        AnalysisTab
        SVDButton
        KMeansButton

        % Process tab
        ProcessTab
        CropSmoothingButton
        DerivativeButton
        PlotHypercubeButton
        MaskButton

        % Export tab
        ExportTab
        SaveSpectraButton
        SaveImageButton
        SaveHypercubeButton
        SaveGIFButton
    end

    % ---------------------------------------------------------------
    % Data
    % ---------------------------------------------------------------
    properties (Access = private)
        c = 299792458; % speed of light [m/s]

        Hyperspectrum_cube
        f
        fr_real
        lambda_nm
        Intens
        NoSaturationMap
        ImmagineRGB
        maxImage = 1

        a = 0 % rows (y)
        b = 0 % cols (x)
        cc = 0 % number of spectral points

        absoluteVal = 1 % 1 = abs, 2 = complex

        blackLevel = 0
        saturationLevel = 1
        gammaVal = 1

        R, G, B, wl
        R_THz, G_THz, B_THz

        load_cal = false
        file_totCal = []
        spectralAxisType = 'index' % 'fr_real_THz', 'f_invum', or 'index'

        pathname_Hyper = ''
        filename_Hyper = ''
        dir2 = ''

        mm % color order, hsv(8)

        num_spectrum = 0
        Spectrum_subAve = []
        Spectrum_subStd = []

        norm_R = 1
        norm_G = 1
        norm_B = 1

        RGB_flag = 0
        LabelX = 'Wavelength [nm]'

        derivative_flag = 0
        Hypercube_derivative = []
        Intens_der = []

        currentLambda
        currentFrReal

        x_lam, y_lam, z_lam, Energy_i
        calibratedRGBAvailable = false

        ClickModeOn = false
        ImageHandle

        useCustomAxes = false
        customXVec = []
        customYVec = []
        customXLabel = 'X position'
        customYLabel = 'Y position'

        RoiHandles = {}
        PixelMarkerHandles = matlab.graphics.chart.primitive.Line.empty
        SpectrumPlotHandles = gobjects(1,0)
        NormSpectrumPlotHandles = gobjects(1,0)
    end

    % ---------------------------------------------------------------
    % Construction
    % ---------------------------------------------------------------
    methods (Access = public)
        function app = HyperspectralAnalysisApp
            createComponents(app);
            registerApp(app, app.UIFigure);
            startupFcn(app);
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end

    % ---------------------------------------------------------------
    % Startup
    % ---------------------------------------------------------------
    methods (Access = private)
        function startupFcn(app)
            app.mm = hsv(8);
            app.StatusLabel.Text = 'Load a spectral hypercube to begin.';
            cla(app.ImageAxes);
            title(app.ImageAxes,'Hypercube view');
            app.ImageAxes.XTick = [];
            app.ImageAxes.YTick = [];
        end
    end

    % ---------------------------------------------------------------
    % Component creation
    % ---------------------------------------------------------------
    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Visible','off');
            app.UIFigure.Position = [50 50 1450 850];
            app.UIFigure.Name = 'Hyperspectral Analysis';

            app.MainGrid = uigridlayout(app.UIFigure,[2 2]);
            app.MainGrid.ColumnWidth = {'1x',380};
            app.MainGrid.RowHeight = {'1x',26};

            % ----- Plot area -----
            plotGrid = uigridlayout(app.MainGrid,[2 2]);
            plotGrid.Layout.Row = 1;
            plotGrid.Layout.Column = 1;
            plotGrid.RowHeight = {'1x','1x'};
            plotGrid.ColumnWidth = {'1.2x','1x'};

            app.ImageAxes = uiaxes(plotGrid);
            app.ImageAxes.Layout.Row = [1 2];
            app.ImageAxes.Layout.Column = 1;
            title(app.ImageAxes,'Hypercube view');
            app.ImageAxes.XTick = [];
            app.ImageAxes.YTick = [];
            hold(app.ImageAxes,'on');

            app.SpectrumAxes = uiaxes(plotGrid);
            app.SpectrumAxes.Layout.Row = 1;
            app.SpectrumAxes.Layout.Column = 2;
            title(app.SpectrumAxes,'Spectra for selected regions');
            xlabel(app.SpectrumAxes,'Wavelength [nm]');
            ylabel(app.SpectrumAxes,'Intensity [arb.un.]');
            hold(app.SpectrumAxes,'on');
            grid(app.SpectrumAxes,'on');

            app.NormSpectrumAxes = uiaxes(plotGrid);
            app.NormSpectrumAxes.Layout.Row = 2;
            app.NormSpectrumAxes.Layout.Column = 2;
            title(app.NormSpectrumAxes,'Spectra normalised to the area');
            xlabel(app.NormSpectrumAxes,'Wavelength [nm]');
            ylabel(app.NormSpectrumAxes,'Intensity [norm.]');
            hold(app.NormSpectrumAxes,'on');
            grid(app.NormSpectrumAxes,'on');

            % ----- Control panel -----
            app.ControlTabGroup = uitabgroup(app.MainGrid);
            app.ControlTabGroup.Layout.Row = 1;
            app.ControlTabGroup.Layout.Column = 2;

            app.createFileTab();
            app.createDisplayTab();
            app.createRGBTab();
            app.createSpectraTab();
            app.createMapsTab();
            app.createAnalysisTab();
            app.createProcessTab();
            app.createExportTab();

            % ----- Status bar -----
            app.StatusLabel = uilabel(app.MainGrid);
            app.StatusLabel.Layout.Row = 2;
            app.StatusLabel.Layout.Column = [1 2];
            app.StatusLabel.Text = '';
            app.StatusLabel.FontColor = [0.35 0.35 0.35];

            app.UIFigure.Visible = 'on';
        end

        function createFileTab(app)
            app.FileTab = uitab(app.ControlTabGroup,'Title','File');
            g = uigridlayout(app.FileTab,[4 1]);
            g.RowHeight = {40,24,24,'1x'};

            app.LoadButton = uibutton(g,'push','Text','Load Hypercube (.mat / .h5 / .mj2)');
            app.LoadButton.Layout.Row = 1; app.LoadButton.Layout.Column = 1;
            app.LoadButton.ButtonPushedFcn = @(~,~) app.LoadButtonPushed();

            app.FileNameLabel = uilabel(g,'Text','No file loaded.');
            app.FileNameLabel.Layout.Row = 2; app.FileNameLabel.Layout.Column = 1;

            app.SizeLabel = uilabel(g,'Text','');
            app.SizeLabel.Layout.Row = 3; app.SizeLabel.Layout.Column = 1;

            app.CalibLabel = uilabel(g,'Text','');
            app.CalibLabel.Layout.Row = 4; app.CalibLabel.Layout.Column = 1;
            app.CalibLabel.VerticalAlignment = 'top';
        end

        function createDisplayTab(app)
            app.DisplayTab = uitab(app.ControlTabGroup,'Title','Display');
            g = uigridlayout(app.DisplayTab,[8 2]);
            g.RowHeight = {28,28,28,36,36,12,36,36};
            g.ColumnWidth = {'1x','1x'};

            l1 = uilabel(g,'Text','Black level');
            l1.Layout.Row = 1; l1.Layout.Column = 1;
            app.BlackEditField = uieditfield(g,'numeric','Value',0,'Limits',[0 Inf]);
            app.BlackEditField.Layout.Row = 1; app.BlackEditField.Layout.Column = 2;

            l2 = uilabel(g,'Text','Saturation level');
            l2.Layout.Row = 2; l2.Layout.Column = 1;
            app.SaturationEditField = uieditfield(g,'numeric','Value',1,'Limits',[0 Inf]);
            app.SaturationEditField.Layout.Row = 2; app.SaturationEditField.Layout.Column = 2;

            l3 = uilabel(g,'Text','Gamma');
            l3.Layout.Row = 3; l3.Layout.Column = 1;
            app.GammaEditField = uieditfield(g,'numeric','Value',1,'Limits',[0 Inf]);
            app.GammaEditField.Layout.Row = 3; app.GammaEditField.Layout.Column = 2;

            app.ApplyLevelsButton = uibutton(g,'push','Text','Apply levels / gamma');
            app.ApplyLevelsButton.Layout.Row = 4; app.ApplyLevelsButton.Layout.Column = [1 2];
            app.ApplyLevelsButton.ButtonPushedFcn = @(~,~) app.ApplyLevelsButtonPushed();

            app.AutoLevelsButton = uibutton(g,'push','Text','Auto levels (0.5-99.5 pct)');
            app.AutoLevelsButton.Layout.Row = 5; app.AutoLevelsButton.Layout.Column = [1 2];
            app.AutoLevelsButton.ButtonPushedFcn = @(~,~) app.AutoLevelsButtonPushed();

            app.RotateButton = uibutton(g,'push','Text','Rotate hypercube');
            app.RotateButton.Layout.Row = 7; app.RotateButton.Layout.Column = [1 2];
            app.RotateButton.ButtonPushedFcn = @(~,~) app.RotateButtonPushed();

            app.CustomAxesButton = uibutton(g,'push','Text','Custom X/Y axes...');
            app.CustomAxesButton.Layout.Row = 8; app.CustomAxesButton.Layout.Column = [1 2];
            app.CustomAxesButton.ButtonPushedFcn = @(~,~) app.CustomAxesButtonPushed();
        end

        function createRGBTab(app)
            app.RGBTab = uitab(app.ControlTabGroup,'Title','RGB');
            g = uigridlayout(app.RGBTab,[4 1]);
            g.RowHeight = {36,36,36,'1x'};

            app.GenerateRGBButton = uibutton(g,'push','Text','Generate false-RGB map');
            app.GenerateRGBButton.Layout.Row = 1; app.GenerateRGBButton.Layout.Column = 1;
            app.GenerateRGBButton.ButtonPushedFcn = @(~,~) app.GenerateRGBButtonPushed();

            app.WhiteBalanceButton = uibutton(g,'push','Text','RGB white balance');
            app.WhiteBalanceButton.Layout.Row = 2; app.WhiteBalanceButton.Layout.Column = 1;
            app.WhiteBalanceButton.ButtonPushedFcn = @(~,~) app.WhiteBalanceButtonPushed();

            app.CalibratedRGBButton = uibutton(g,'push','Text','Calibrated RGB (CIE)');
            app.CalibratedRGBButton.Layout.Row = 3; app.CalibratedRGBButton.Layout.Column = 1;
            app.CalibratedRGBButton.ButtonPushedFcn = @(~,~) app.CalibratedRGBButtonPushed();
        end

        function createSpectraTab(app)
            app.SpectraTab = uitab(app.ControlTabGroup,'Title','Spectra');
            g = uigridlayout(app.SpectraTab,[5 1]);
            g.RowHeight = {36,36,36,36,'1x'};

            app.AddROISpectrumButton = uibutton(g,'push','Text','Spectrum from ROI');
            app.AddROISpectrumButton.Layout.Row = 1; app.AddROISpectrumButton.Layout.Column = 1;
            app.AddROISpectrumButton.ButtonPushedFcn = @(~,~) app.AddROISpectrumButtonPushed();

            app.PixelClickButton = uibutton(g,'push','Text','Pixel spectrum (click on image)');
            app.PixelClickButton.Layout.Row = 2; app.PixelClickButton.Layout.Column = 1;
            app.PixelClickButton.ButtonPushedFcn = @(~,~) app.PixelClickButtonPushed();

            app.RemoveBKGButton = uibutton(g,'push','Text','Remove background from ROI');
            app.RemoveBKGButton.Layout.Row = 3; app.RemoveBKGButton.Layout.Column = 1;
            app.RemoveBKGButton.ButtonPushedFcn = @(~,~) app.RemoveBKGButtonPushed();

            app.CleanGraphsButton = uibutton(g,'push','Text','Clean graphs');
            app.CleanGraphsButton.Layout.Row = 4; app.CleanGraphsButton.Layout.Column = 1;
            app.CleanGraphsButton.ButtonPushedFcn = @(~,~) app.CleanGraphsButtonPushed();
        end

        function createMapsTab(app)
            app.MapsTab = uitab(app.ControlTabGroup,'Title','Maps');
            g = uigridlayout(app.MapsTab,[6 1]);
            g.RowHeight = {36,36,36,36,36,'1x'};

            app.SAMButton = uibutton(g,'push','Text','Spectral Angle Mapping');
            app.SAMButton.Layout.Row = 1; app.SAMButton.Layout.Column = 1;
            app.SAMButton.ButtonPushedFcn = @(~,~) app.SAMButtonPushed();

            app.ReflectivityButton = uibutton(g,'push','Text','Reflectivity map');
            app.ReflectivityButton.Layout.Row = 2; app.ReflectivityButton.Layout.Column = 1;
            app.ReflectivityButton.ButtonPushedFcn = @(~,~) app.ReflectivityButtonPushed();

            app.TransmissionButton = uibutton(g,'push','Text','Transmission map');
            app.TransmissionButton.Layout.Row = 3; app.TransmissionButton.Layout.Column = 1;
            app.TransmissionButton.ButtonPushedFcn = @(~,~) app.TransmissionButtonPushed();

            app.LambertianButton = uibutton(g,'push','Text','Normalize on Lambertian');
            app.LambertianButton.Layout.Row = 4; app.LambertianButton.Layout.Column = 1;
            app.LambertianButton.ButtonPushedFcn = @(~,~) app.LambertianButtonPushed();

            app.PeakMappingButton = uibutton(g,'push','Text','Map spectral peaks');
            app.PeakMappingButton.Layout.Row = 5; app.PeakMappingButton.Layout.Column = 1;
            app.PeakMappingButton.ButtonPushedFcn = @(~,~) app.PeakMappingButtonPushed();
        end

        function createAnalysisTab(app)
            app.AnalysisTab = uitab(app.ControlTabGroup,'Title','Analysis');
            g = uigridlayout(app.AnalysisTab,[3 1]);
            g.RowHeight = {36,36,'1x'};

            app.SVDButton = uibutton(g,'push','Text','SVD denoising');
            app.SVDButton.Layout.Row = 1; app.SVDButton.Layout.Column = 1;
            app.SVDButton.ButtonPushedFcn = @(~,~) app.SVDButtonPushed();

            app.KMeansButton = uibutton(g,'push','Text','K-means clustering');
            app.KMeansButton.Layout.Row = 2; app.KMeansButton.Layout.Column = 1;
            app.KMeansButton.ButtonPushedFcn = @(~,~) app.KMeansButtonPushed();
        end

        function createProcessTab(app)
            app.ProcessTab = uitab(app.ControlTabGroup,'Title','Process');
            g = uigridlayout(app.ProcessTab,[5 1]);
            g.RowHeight = {36,36,36,36,'1x'};

            app.CropSmoothingButton = uibutton(g,'push','Text','Crop / Smoothing');
            app.CropSmoothingButton.Layout.Row = 1; app.CropSmoothingButton.Layout.Column = 1;
            app.CropSmoothingButton.ButtonPushedFcn = @(~,~) app.CropSmoothingButtonPushed();

            app.DerivativeButton = uibutton(g,'push','Text','Hypercube derivative');
            app.DerivativeButton.Layout.Row = 2; app.DerivativeButton.Layout.Column = 1;
            app.DerivativeButton.ButtonPushedFcn = @(~,~) app.DerivativeButtonPushed();

            app.PlotHypercubeButton = uibutton(g,'push','Text','Plot Hypercube (external viewer)');
            app.PlotHypercubeButton.Layout.Row = 3; app.PlotHypercubeButton.Layout.Column = 1;
            app.PlotHypercubeButton.ButtonPushedFcn = @(~,~) app.PlotHypercubeButtonPushed();

            app.MaskButton = uibutton(g,'push','Text','Mask (threshold)');
            app.MaskButton.Layout.Row = 4; app.MaskButton.Layout.Column = 1;
            app.MaskButton.ButtonPushedFcn = @(~,~) app.MaskButtonPushed();
        end

        function createExportTab(app)
            app.ExportTab = uitab(app.ControlTabGroup,'Title','Export');
            g = uigridlayout(app.ExportTab,[5 1]);
            g.RowHeight = {36,36,36,36,'1x'};

            app.SaveSpectraButton = uibutton(g,'push','Text','Save spectra (.txt)');
            app.SaveSpectraButton.Layout.Row = 1; app.SaveSpectraButton.Layout.Column = 1;
            app.SaveSpectraButton.ButtonPushedFcn = @(~,~) app.SaveSpectraButtonPushed();

            app.SaveImageButton = uibutton(g,'push','Text','Save current image');
            app.SaveImageButton.Layout.Row = 2; app.SaveImageButton.Layout.Column = 1;
            app.SaveImageButton.ButtonPushedFcn = @(~,~) app.SaveImageButtonPushed();

            app.SaveHypercubeButton = uibutton(g,'push','Text','Save current hypercube');
            app.SaveHypercubeButton.Layout.Row = 3; app.SaveHypercubeButton.Layout.Column = 1;
            app.SaveHypercubeButton.ButtonPushedFcn = @(~,~) app.SaveHypercubeButtonPushed();

            app.SaveGIFButton = uibutton(g,'push','Text','Save spectral GIF');
            app.SaveGIFButton.Layout.Row = 4; app.SaveGIFButton.Layout.Column = 1;
            app.SaveGIFButton.ButtonPushedFcn = @(~,~) app.SaveGIFButtonPushed();
        end
    end

    % ---------------------------------------------------------------
    % Callbacks
    % ---------------------------------------------------------------
    methods (Access = private)

        % ----------------------------------------------------------
        % File / loading
        % ----------------------------------------------------------
        function LoadButtonPushed(app, ~)
            [filename, pathname] = uigetfile({'*.mat;*.h5;*.mj2','Hypercube files (*.mat,*.h5,*.mj2)'}, ...
                'Load spectral Hypercube');
            if isequal(filename,0)
                return
            end

            app.filename_Hyper = filename;
            app.pathname_Hyper = pathname;
            app.dir2 = pathname;
            file_tot = fullfile(pathname,filename);

            d = uiprogressdlg(app.UIFigure,'Title','Loading', ...
                'Message','Loading hypercube, please wait...','Indeterminate','on');

            try
                [~,~,ext] = fileparts(filename);
                switch lower(ext)
                    case '.h5'
                        [cube,f,satMap,file_totCal,fr_real,Intens] = app.H5HypercubeRead(file_tot);
                    case '.mj2'
                        [cube,f,satMap,file_totCal,fr_real,Intens] = app.MJ2HypercubeRead(file_tot);
                    otherwise
                        [cube,f,satMap,file_totCal,fr_real,Intens] = app.MATHypercubeRead(file_tot);
                end
            catch ME
                close(d);
                uialert(app.UIFigure, ME.message, 'Error loading hypercube');
                return
            end

            close(d);

            app.f = f(:)';
            app.fr_real = fr_real;
            app.file_totCal = file_totCal;

            if isempty(satMap)
                app.NoSaturationMap = ones(size(cube,1),size(cube,2));
            else
                app.NoSaturationMap = satMap;
            end

            % Absolute vs complex values
            choice = uiconfirm(app.UIFigure, ...
                ['Is this hypercube best treated as ABSOLUTE values (e.g. camera, ' ...
                 'no uniform zero-path-delay) or COMPLEX values (e.g. microscope, ' ...
                 'uniform zero-path-delay)?'], ...
                'Spectral Hypercube Values Format', ...
                'Options',{'Absolute values','Complex values'}, ...
                'DefaultOption',1,'CancelOption',1);

            if strcmp(choice,'Complex values')
                app.absoluteVal = 2;
            else
                app.absoluteVal = 1;
                cube = abs(cube);
            end

            app.Hyperspectrum_cube = cube;

            if isempty(Intens)
                Intens = sum(abs(cube),3);
            end
            app.Intens = Intens;

            [app.a, app.b] = size(cube(:,:,1));
            app.cc = numel(app.f);

            % Frequency calibration + RGB transmission curves
            app.setupCalibrationAndRGB();

            % Reset display state
            app.blackLevel = 0; app.saturationLevel = 1; app.gammaVal = 1;
            app.BlackEditField.Value = 0;
            app.SaturationEditField.Value = 1;
            app.GammaEditField.Value = 1;
            app.RGB_flag = 0;

            app.ClickModeOn = false;
            app.PixelClickButton.Text = 'Pixel spectrum (click on image)';
            app.UIFigure.Pointer = 'arrow';

            app.useCustomAxes = false;
            app.customXVec = [];
            app.customYVec = [];

            app.ImmagineRGB = repmat(app.Intens,[1 1 3]);

            app.derivative_flag = 0;

            delete(app.ImageHandle);
            app.ImageHandle = [];

            app.updateImageDisplay();
            app.clearSpectrumPlots();

            app.FileNameLabel.Text = sprintf('File: %s', filename);
            app.SizeLabel.Text = sprintf('Size: %d x %d px, %d spectral pts', app.b, app.a, app.cc);
            switch app.spectralAxisType
                case 'fr_real_THz'
                    app.CalibLabel.Text = sprintf('fr_real (THz): %.1f - %.1f nm', ...
                        min(app.lambda_nm), max(app.lambda_nm));
                case 'f_invum'
                    app.CalibLabel.Text = sprintf('f (µm⁻¹): %.4g - %.4g µm⁻¹', ...
                        min(app.lambda_nm), max(app.lambda_nm));
                otherwise
                    app.CalibLabel.Text = 'No spectral axis found: using index.';
            end
            title(app.ImageAxes, filename, 'Interpreter','none');
            app.StatusLabel.Text = 'Hypercube loaded.';
        end

        % ----------------------------------------------------------
        % Display: levels / gamma / rotation / clean
        % ----------------------------------------------------------
        function ApplyLevelsButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end
            blk = app.BlackEditField.Value;
            sat = app.SaturationEditField.Value;
            gam = app.GammaEditField.Value;

            if sat <= blk
                uialert(app.UIFigure,'Saturation level must be greater than black level.','Invalid levels');
                return
            end
            if gam <= 0
                uialert(app.UIFigure,'Gamma must be positive.','Invalid gamma');
                return
            end

            app.blackLevel = blk;
            app.saturationLevel = sat;
            app.gammaVal = gam;
            app.updateImageDisplay();
            app.StatusLabel.Text = sprintf('Levels applied: black=%.4g, saturation=%.4g, gamma=%.4g.',blk,sat,gam);
        end

        function AutoLevelsButtonPushed(app, ~)
            if isempty(app.ImmagineRGB)
                return
            end
            mx = max(app.ImmagineRGB(:));
            if mx == 0
                mx = 1;
            end
            vals = abs(app.ImmagineRGB(:))/mx;

            lo = app.localPercentile(vals, 0.5);
            hi = app.localPercentile(vals, 99.5);
            if hi <= lo
                hi = lo + eps;
            end

            app.blackLevel = max(lo,0);
            app.saturationLevel = hi;
            app.gammaVal = 1;
            app.BlackEditField.Value = app.blackLevel;
            app.SaturationEditField.Value = app.saturationLevel;
            app.GammaEditField.Value = app.gammaVal;
            app.updateImageDisplay();
            app.StatusLabel.Text = 'Auto levels applied.';
        end

        function RotateButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end
            choice = uiconfirm(app.UIFigure,'Choose rotation:','Rotate hypercube', ...
                'Options',{'90 deg CW','90 deg CCW','180 deg','Custom angle'}, ...
                'DefaultOption',1);

            switch choice
                case '90 deg CW'
                    angle = 90;
                case '90 deg CCW'
                    angle = -90;
                case '180 deg'
                    angle = 180;
                case 'Custom angle'
                    answer = inputdlg({'Rotation angle (deg). Positive = clockwise.'}, ...
                        'Rotation angle',1,{'0'});
                    if isempty(answer)
                        return
                    end
                    angle = str2double(answer{1});
                    if isnan(angle)
                        return
                    end
                otherwise
                    % Dialog closed without a selection
                    return
            end

            d = uiprogressdlg(app.UIFigure,'Title','Rotating', ...
                'Message','Rotating hypercube, please wait...','Indeterminate','on');

            cube = app.Hyperspectrum_cube;
            newIntens = imrotate(app.Intens, angle, 'bilinear');
            [newA,newB] = size(newIntens);

            if isreal(cube)
                newCube = zeros(newA,newB,app.cc);
            else
                newCube = complex(zeros(newA,newB,app.cc));
            end
            for k = 1:app.cc
                newCube(:,:,k) = imrotate(cube(:,:,k), angle, 'bilinear');
            end
            app.Hyperspectrum_cube = newCube;
            app.a = newA; app.b = newB;

            newSatMap = imrotate(app.NoSaturationMap, angle, 'nearest');
            if isequal(size(newSatMap),[newA newB])
                app.NoSaturationMap = round(newSatMap);
            else
                app.NoSaturationMap = ones(newA,newB);
            end

            if app.RGB_flag
                oldRGB = app.ImmagineRGB;
                newRGB = zeros(newA,newB,3);
                for ch = 1:3
                    newRGB(:,:,ch) = imrotate(oldRGB(:,:,ch), angle, 'bilinear');
                end
                app.ImmagineRGB = newRGB;
                app.Intens = sum(abs(app.Hyperspectrum_cube),3);
            else
                app.Intens = sum(abs(app.Hyperspectrum_cube),3);
                app.ImmagineRGB = repmat(app.Intens,[1 1 3]);
            end

            close(d);

            delete(app.ImageHandle);
            app.ImageHandle = [];

            app.useCustomAxes = false;
            app.customXVec = [];
            app.customYVec = [];

            app.updateImageDisplay();
            app.clearSpectrumPlots();
            app.SizeLabel.Text = sprintf('Size: %d x %d px, %d spectral pts', app.b, app.a, app.cc);
            app.StatusLabel.Text = sprintf('Hypercube rotated by %g deg.', angle);
        end

        function CleanGraphsButtonPushed(app, ~)
            app.clearSpectrumPlots();
            app.StatusLabel.Text = 'Graphs cleared.';
        end

        function CustomAxesButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            choice = uiconfirm(app.UIFigure,'Set custom X/Y image axes:','Custom axes', ...
                'Options',{'Load X and Y vectors','Reset to pixel indices','Cancel'}, ...
                'DefaultOption',1,'CancelOption',3);

            switch choice
                case 'Reset to pixel indices'
                    app.useCustomAxes = false;
                    app.customXVec = [];
                    app.customYVec = [];
                    app.applyAxesCoordinates();
                    app.StatusLabel.Text = 'Image axes reset to pixel indices.';

                case 'Load X and Y vectors'
                    uialert(app.UIFigure, sprintf(['Load a vector for the X axis (image columns, ' ...
                        'length = %d pixels). It can be a .mat file (a single variable, or you will ' ...
                        'be asked which one to use) or a .txt file, and it can be a row or a column ' ...
                        'vector.'], app.b), 'X axis vector','Icon','info');
                    xVec = app.loadAxisVector('Load X axis vector');
                    if isempty(xVec)
                        return
                    end
                    if numel(xVec) ~= app.b
                        uialert(app.UIFigure, sprintf(['The X vector has %d elements, but the image ' ...
                            'has %d columns.'], numel(xVec), app.b), 'Size mismatch');
                        return
                    end

                    uialert(app.UIFigure, sprintf(['Load a vector for the Y axis (image rows, ' ...
                        'length = %d pixels).'], app.a), 'Y axis vector','Icon','info');
                    yVec = app.loadAxisVector('Load Y axis vector');
                    if isempty(yVec)
                        return
                    end
                    if numel(yVec) ~= app.a
                        uialert(app.UIFigure, sprintf(['The Y vector has %d elements, but the image ' ...
                            'has %d rows.'], numel(yVec), app.a), 'Size mismatch');
                        return
                    end

                    answer = inputdlg({'X axis label','Y axis label'}, 'Axis labels',1, ...
                        {app.customXLabel, app.customYLabel});
                    if ~isempty(answer)
                        app.customXLabel = answer{1};
                        app.customYLabel = answer{2};
                    end

                    app.customXVec = xVec;
                    app.customYVec = yVec;
                    app.useCustomAxes = true;

                    app.applyAxesCoordinates();
                    app.StatusLabel.Text = 'Custom X/Y axes applied.';

                otherwise
                    return
            end
        end

        function vec = loadAxisVector(app, dlgTitle)
            % Loads a 1-D axis vector from a .mat or .txt file. Accepts
            % either a row or a column vector and returns it as a row
            % vector. For .mat files with multiple variables, or for
            % files containing a matrix, the user is asked which
            % variable/column to use.
            vec = [];

            [fname,pname] = uigetfile({'*.mat;*.txt','Vector files (*.mat, *.txt)'}, dlgTitle);
            if isequal(fname,0)
                return
            end
            fileTot = fullfile(pname,fname);
            [~,~,ext] = fileparts(fname);

            try
                switch lower(ext)
                    case '.mat'
                        S = load(fileTot);
                        fns = fieldnames(S);
                        if isempty(fns)
                            uialert(app.UIFigure,'The .mat file does not contain any variables.','Error');
                            return
                        elseif numel(fns) == 1
                            data = S.(fns{1});
                        else
                            [selIdx,ok] = listdlg('PromptString','Select the variable containing the axis vector:', ...
                                'SelectionMode','single','ListString',fns,'ListSize',[300 150], ...
                                'Name',dlgTitle);
                            if ~ok
                                return
                            end
                            data = S.(fns{selIdx});
                        end
                    otherwise
                        data = readmatrix(fileTot);
                end
            catch ME
                uialert(app.UIFigure, ME.message, 'Error loading axis vector');
                return
            end

            data = double(squeeze(data));

            if ~isvector(data)
                if ismatrix(data) && min(size(data)) > 1
                    answer = inputdlg({sprintf(['The file contains a %dx%d matrix. Which column ' ...
                        'should be used as the axis vector?'], size(data,1), size(data,2))}, ...
                        'Select column',1,{'1'});
                    if isempty(answer)
                        return
                    end
                    colIdx = round(str2double(answer{1}));
                    if isnan(colIdx) || colIdx < 1 || colIdx > size(data,2)
                        uialert(app.UIFigure,'Invalid column index.','Error');
                        return
                    end
                    data = data(:,colIdx);
                else
                    uialert(app.UIFigure,'The selected file does not contain a vector.','Error');
                    return
                end
            end

            % Works regardless of whether the file contained a row or a
            % column vector.
            vec = data(:)';
        end

        % ----------------------------------------------------------
        % RGB generation / white balance
        % ----------------------------------------------------------
        function GenerateRGBButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            mode = uiconfirm(app.UIFigure,'Choose RGB generation mode:','False-RGB map', ...
                'Options',{'Spectral range','Single wavelengths','Cancel'}, ...
                'DefaultOption',1,'CancelOption',3);
            if strcmp(mode,'Cancel')
                return
            end

            cube = app.Hyperspectrum_cube;

            switch mode
                case 'Spectral range'
                    prompt = {'Lower wavelength (nm)','Higher wavelength (nm)','Binning (pixels, 1 = none)'};
                    defaults = {'390','690','1'};
                    answer = inputdlg(prompt,'Select spectral band and binning',1,defaults);
                    if isempty(answer)
                        return
                    end
                    lm1 = str2double(answer{1});
                    lm2 = str2double(answer{2});
                    binSize = str2double(answer{3});
                    if any(isnan([lm1 lm2 binSize]))
                        uialert(app.UIFigure,'Invalid numeric input.','Error'); return
                    end

                    % Stretch the RGB filter curves to cover the requested band
                    wl1 = (lm2-lm1)/(690-390)*(app.wl-390) + lm1;

                    R1 = interp1(wl1, app.R, app.lambda_nm) .* app.lambda_nm.^2 / app.c; R1(isnan(R1)) = 0;
                    G1 = interp1(wl1, app.G, app.lambda_nm) .* app.lambda_nm.^2 / app.c; G1(isnan(G1)) = 0;
                    B1 = interp1(wl1, app.B, app.lambda_nm) .* app.lambda_nm.^2 / app.c; B1(isnan(B1)) = 0;

                    R1 = R1 / sum(R1);
                    G1 = G1 / sum(G1);
                    B1 = B1 / sum(B1);

                    cubeBin = app.spatialBin(cube, binSize);
                    specMat = abs(reshape(cubeBin, app.a*app.b, app.cc));

                    ImR = reshape(specMat * R1(:), app.a, app.b);
                    ImG = reshape(specMat * G1(:), app.a, app.b);
                    ImB = reshape(specMat * B1(:), app.a, app.b);

                    app.ImmagineRGB = cat(3,ImR,ImG,ImB);

                    hRGB = plot(app.NormSpectrumAxes, app.lambda_nm, R1/max(R1),'r--', ...
                        app.lambda_nm, G1/max(G1),'g--', ...
                        app.lambda_nm, B1/max(B1),'b--','LineWidth',1);
                    for kRGB = 1:numel(hRGB)
                        app.NormSpectrumPlotHandles(end+1) = hRGB(kRGB);
                    end

                case 'Single wavelengths'
                    prompt = {'Red channel (nm)','Green channel (nm)','Blue channel (nm)','Binning (pixels, 1 = none)'};
                    defaults = {'630','530','470','1'};
                    answer = inputdlg(prompt,'Select R, G, B channels and binning',1,defaults);
                    if isempty(answer)
                        return
                    end
                    lmR = str2double(answer{1});
                    lmG = str2double(answer{2});
                    lmB = str2double(answer{3});
                    binSize = str2double(answer{4});
                    if any(isnan([lmR lmG lmB binSize]))
                        uialert(app.UIFigure,'Invalid numeric input.','Error'); return
                    end

                    [~,idxR] = min(abs(app.lambda_nm - lmR));
                    [~,idxG] = min(abs(app.lambda_nm - lmG));
                    [~,idxB] = min(abs(app.lambda_nm - lmB));

                    cubeBin = app.spatialBin(cube, binSize);

                    imageR = mat2gray(abs(cubeBin(:,:,idxR)));
                    imageG = mat2gray(abs(cubeBin(:,:,idxG)));
                    imageB = mat2gray(abs(cubeBin(:,:,idxB)));
                    app.ImmagineRGB = cat(3,imageR,imageG,imageB);

                    hR = xline(app.NormSpectrumAxes, app.lambda_nm(idxR),'r--','R','LineWidth',1.5);
                    hG = xline(app.NormSpectrumAxes, app.lambda_nm(idxG),'g--','G','LineWidth',1.5);
                    hB = xline(app.NormSpectrumAxes, app.lambda_nm(idxB),'b--','B','LineWidth',1.5);
                    app.NormSpectrumPlotHandles(end+1) = hR;
                    app.NormSpectrumPlotHandles(end+1) = hG;
                    app.NormSpectrumPlotHandles(end+1) = hB;
            end

            app.RGB_flag = 1;
            app.blackLevel = 0; app.saturationLevel = 1; app.gammaVal = 1;
            app.BlackEditField.Value = 0;
            app.SaturationEditField.Value = 1;
            app.GammaEditField.Value = 1;

            app.updateImageDisplay();
            app.StatusLabel.Text = 'False-RGB map generated.';
        end

        function WhiteBalanceButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            uialert(app.UIFigure, ...
                'Black, saturation and gamma will be reset to their default values.', ...
                'RGB white balance','Icon','warning');

            app.blackLevel = 0; app.saturationLevel = 1; app.gammaVal = 1;
            app.BlackEditField.Value = 0;
            app.SaturationEditField.Value = 1;
            app.GammaEditField.Value = 1;

            src = uiconfirm(app.UIFigure,'Choose white balance source:','RGB white balance', ...
                'Options',{'Select ROI','Set RGB values manually','Cancel'}, ...
                'DefaultOption',1,'CancelOption',3);
            if strcmp(src,'Cancel')
                return
            end

            if strcmp(src,'Select ROI')
                try
                    roi = drawpolygon(app.ImageAxes);
                catch
                    return
                end
                if ~isvalid(roi) || isempty(roi.Position)
                    return
                end
                mask = createMask(roi, app.a, app.b);
                delete(roi);

                RGBvals = reshape(app.ImmagineRGB, app.a*app.b, 3);
                sel = mask(:) & (app.NoSaturationMap(:) == 1);
                if ~any(sel)
                    uialert(app.UIFigure,'No valid (unsaturated) pixels in ROI.','Empty ROI');
                    return
                end
                RGBsel = RGBvals(sel,:);
                app.norm_R = mean(RGBsel(:,1));
                app.norm_G = mean(RGBsel(:,2));
                app.norm_B = mean(RGBsel(:,3));

                uialert(app.UIFigure, sprintf(['Selected RGB normalization values:\n' ...
                    'norm_R = %.4g\nnorm_G = %.4g\nnorm_B = %.4g'], ...
                    app.norm_R, app.norm_G, app.norm_B), 'White balance','Icon','info');
            else
                answer = inputdlg({'norm_R','norm_G','norm_B'}, ...
                    'Set values for image normalization in white balance',1,{'1','1','1'});
                if isempty(answer)
                    return
                end
                app.norm_R = str2double(answer{1});
                app.norm_G = str2double(answer{2});
                app.norm_B = str2double(answer{3});
            end

            answer = inputdlg({'Set pure white value','Spectralon reflectivity value (0 [black] to 1 [white])'}, ...
                'White balance settings',1,{'0.8','1'});
            if isempty(answer)
                return
            end
            whiteValue = str2double(answer{1});
            reflVal = str2double(answer{2});
            if any(isnan([whiteValue reflVal])) || reflVal == 0
                uialert(app.UIFigure,'Invalid numeric input.','Error'); return
            end

            nR = app.norm_R/reflVal;
            nG = app.norm_G/reflVal;
            nB = app.norm_B/reflVal;

            Rc = app.ImmagineRGB(:,:,1)/nR*whiteValue;
            Gc = app.ImmagineRGB(:,:,2)/nG*whiteValue;
            Bc = app.ImmagineRGB(:,:,3)/nB*whiteValue;

            noSat = (Rc <= 1) & (Gc <= 1) & (Bc <= 1);

            RcSat = Rc; GcSat = Gc; BcSat = Bc;
            RcSat(~noSat) = 1; GcSat(~noSat) = 1; BcSat(~noSat) = 1;

            app.ImmagineRGB = cat(3,RcSat,GcSat,BcSat);
            app.updateImageDisplay();

            % Saturated-pixels preview, shown in a separate figure
            grey = RcSat + GcSat + BcSat;
            mxg = max(grey(:));
            if mxg == 0
                mxg = 1;
            end
            grey = grey/mxg;

            satR = grey; satG = grey; satB = grey;
            satR(~noSat) = 1;
            satG(~noSat) = 0;
            satB(~noSat) = 0;
            satImg = cat(3,satR,satG,satB);

            f = figure('Name','Saturated pixels map','NumberTitle','off');
            ax = axes('Parent',f);
            imshow(satImg,'Parent',ax);
            axis(ax,'equal'); axis(ax,'off');
            title(ax,'Saturated pixels map (red = saturated)');

            app.StatusLabel.Text = 'White balance applied.';
        end

        % ----------------------------------------------------------
        % Spectra
        % ----------------------------------------------------------
        function AddROISpectrumButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            choice = uiconfirm(app.UIFigure,'Select ROI shape:','ROI type', ...
                'Options',{'Polygon','Rectangle','Cancel'}, ...
                'DefaultOption',1,'CancelOption',3);
            if strcmp(choice,'Cancel')
                return
            end

            try
                if strcmp(choice,'Polygon')
                    roi = drawpolygon(app.ImageAxes);
                else
                    roi = drawrectangle(app.ImageAxes);
                end
            catch
                return
            end
            if ~isvalid(roi) || isempty(roi.Position)
                return
            end

            mask = createMask(roi, app.a, app.b);

            sel = mask(:) & (app.NoSaturationMap(:) == 1);
            nPix = nnz(sel);
            if nPix == 0
                uialert(app.UIFigure,'No valid (unsaturated) pixels in ROI.','Empty ROI');
                delete(roi);
                return
            end

            [dataCube, ~] = app.activeSpectralData();
            ccCur = size(dataCube,3);
            specMat = reshape(dataCube, app.a*app.b, ccCur);
            specSel = specMat(sel,:); % nPix x ccCur, may be complex

            specAve = abs(mean(specSel,1))';
            specStd = sqrt(var(abs(specSel),0,1))';

            app.addSpectrumToPlots(specAve, specStd);

            roi.Color = app.mm(mod(app.num_spectrum-1,8)+1,:);
            roi.InteractionsAllowed = 'none';
            roi.FaceAlpha = 0;
            app.RoiHandles{end+1} = roi;

            app.StatusLabel.Text = sprintf('ROI spectrum #%d added (%d pixels).', app.num_spectrum, nPix);
        end

        function PixelClickButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end
            app.ClickModeOn = ~app.ClickModeOn;
            if app.ClickModeOn
                app.PixelClickButton.Text = 'Pixel click mode: ON (click image to stop)';
                app.UIFigure.Pointer = 'crosshair';
                app.StatusLabel.Text = 'Click on the image to plot the spectrum at that pixel.';
            else
                app.PixelClickButton.Text = 'Pixel spectrum (click on image)';
                app.UIFigure.Pointer = 'arrow';
                app.StatusLabel.Text = 'Pixel click mode off.';
            end
        end

        function imageClicked(app, evt)
            if ~app.ClickModeOn || isempty(app.Hyperspectrum_cube)
                return
            end

            pt = evt.IntersectionPoint;
            xPix = round(pt(1));
            yPix = round(pt(2));
            if xPix < 1 || xPix > app.b || yPix < 1 || yPix > app.a
                return
            end

            [dataCube, ~] = app.activeSpectralData();
            spec = abs(squeeze(dataCube(yPix,xPix,:)));

            specStd = zeros(size(spec));
            app.addSpectrumToPlots(spec, specStd);

            col = app.mm(mod(app.num_spectrum-1,8)+1,:);
            markerHandle = plot(app.ImageAxes, xPix, yPix, 'o','MarkerEdgeColor',col,'MarkerSize',8,'LineWidth',2);
            app.PixelMarkerHandles(end+1) = markerHandle;

            app.StatusLabel.Text = sprintf('Pixel spectrum #%d added at (x=%d, y=%d).', app.num_spectrum, xPix, yPix);
        end

        function RemoveBKGButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            uialert(app.UIFigure,'Draw a ROI over the background area.','Remove background','Icon','info');

            try
                roi = drawpolygon(app.ImageAxes);
            catch
                return
            end
            if ~isvalid(roi) || isempty(roi.Position)
                return
            end

            mask = createMask(roi, app.a, app.b);
            delete(roi);

            sel = mask(:);
            if ~any(sel)
                uialert(app.UIFigure,'Empty ROI.','Error');
                return
            end

            specMat = reshape(app.Hyperspectrum_cube, app.a*app.b, app.cc);
            bkgSpec = mean(specMat(sel,:),1); % 1 x cc, may be complex
            bkgStd = sqrt(var(abs(specMat(sel,:)),0,1))';

            d = uiprogressdlg(app.UIFigure,'Title','Processing', ...
                'Message','Removing background...','Indeterminate','on');

            app.Hyperspectrum_cube = app.Hyperspectrum_cube - reshape(bkgSpec,[1 1 app.cc]);
            app.Intens = sum(abs(app.Hyperspectrum_cube),3);

            if ~app.RGB_flag
                app.ImmagineRGB = repmat(app.Intens,[1 1 3]);
            end

            if app.derivative_flag ~= 0
                app.recomputeDerivative();
            end

            close(d);
            app.updateImageDisplay();

            bkgAve = abs(bkgSpec(:));
            h1 = plot(app.SpectrumAxes, app.lambda_nm, bkgAve,'k--','LineWidth',1.5);
            h2 = plot(app.SpectrumAxes, app.lambda_nm, bkgAve+bkgStd,'k:','LineWidth',1);
            h3 = plot(app.SpectrumAxes, app.lambda_nm, bkgAve-bkgStd,'k:','LineWidth',1);
            app.SpectrumPlotHandles(end+1) = h1;
            app.SpectrumPlotHandles(end+1) = h2;
            app.SpectrumPlotHandles(end+1) = h3;

            mx = max(bkgAve);
            if mx > 0
                h4 = plot(app.NormSpectrumAxes, app.lambda_nm, bkgAve./mx,'k--','LineWidth',1.5);
                app.NormSpectrumPlotHandles(end+1) = h4;
            end

            app.StatusLabel.Text = 'Background removed (dashed black = background spectrum).';
        end

        % ----------------------------------------------------------
        % Export
        % ----------------------------------------------------------
        function SaveSpectraButtonPushed(app, ~)
            if app.num_spectrum == 0
                uialert(app.UIFigure,'No spectra to save yet. Add at least one ROI or pixel spectrum first.', ...
                    'Nothing to save');
                return
            end

            [fname,pname] = uiputfile('*.txt','Save Spectra as', app.dir2);
            if isequal(fname,0)
                return
            end
            file_tot = fullfile(pname,fname);

            header = [{'Frequency_THz'}, ...
                arrayfun(@(k) sprintf('Spectrum_Ave_%d',k), 1:app.num_spectrum,'UniformOutput',false), ...
                arrayfun(@(k) sprintf('Spectrum_Std_%d',k), 1:app.num_spectrum,'UniformOutput',false)];

            data = [app.fr_real(:), app.Spectrum_subAve, app.Spectrum_subStd];

            writecell(header, file_tot, 'Delimiter','\t');
            writematrix(data, file_tot, 'Delimiter','\t', 'WriteMode','append');

            try
                [~,baseName] = fileparts(file_tot);
                app.exportSpectrumFigures(fullfile(pname,[baseName '.jpg']));
            catch
                % Figure export is a convenience extra; not critical if it fails
            end

            app.StatusLabel.Text = sprintf('Spectra saved to %s', file_tot);
        end

        function SaveImageButtonPushed(app, ~)
            if isempty(app.ImmagineRGB)
                uialert(app.UIFigure,'No image to save.','Nothing to save');
                return
            end

            [fname,pname] = uiputfile({'*.jpg','JPEG image (*.jpg)'; '*.tif','TIFF image (*.tif)'}, ...
                'Save Current Image', app.dir2);
            if isequal(fname,0)
                return
            end

            dispImg = app.computeDisplayImage();
            imwrite(dispImg, fullfile(pname,fname));
            app.StatusLabel.Text = sprintf('Image saved to %s', fullfile(pname,fname));
        end

        function SaveHypercubeButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                uialert(app.UIFigure,'No hypercube loaded.','Nothing to save');
                return
            end

            if app.derivative_flag ~= 0
                cubeToSave = app.Hypercube_derivative;
                fToSave = app.f(1:end-app.derivative_flag);
                frToSave = app.fr_real(1:end-app.derivative_flag);
                intensToSave = app.Intens_der;
            else
                cubeToSave = app.Hyperspectrum_cube;
                fToSave = app.f;
                frToSave = app.fr_real;
                intensToSave = app.Intens;
            end

            try
                if app.load_cal
                    save_hypercube(cubeToSave, fToSave, app.NoSaturationMap, ...
                        frToSave, app.file_totCal, intensToSave, app.dir2);
                else
                    save_hypercube(cubeToSave, fToSave, app.NoSaturationMap, ...
                        [], [], intensToSave, app.dir2);
                end
                app.StatusLabel.Text = 'Hypercube saved.';
            catch ME
                uialert(app.UIFigure, ME.message, 'Error saving hypercube');
            end
        end

        % ----------------------------------------------------------
        % Maps: Spectral Angle Mapping, Reflectivity, Transmission,
        % Lambertian normalization, Peak mapping
        % ----------------------------------------------------------
        function SAMButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            choice = uiconfirm(app.UIFigure,'Choose reference spectrum source:','Spectral Angle Mapping', ...
                'Options',{'Spectrum from ROI','Load external spectrum','Cancel'}, ...
                'DefaultOption',1,'CancelOption',3);
            if strcmp(choice,'Cancel')
                return
            end

            fr = app.fr_real(:)';

            switch choice
                case 'Spectrum from ROI'
                    uialert(app.UIFigure,'Draw a ROI for the reference spectrum.','Spectral Angle Mapping','Icon','info');
                    try
                        roi = drawpolygon(app.ImageAxes);
                    catch
                        return
                    end
                    if ~isvalid(roi) || isempty(roi.Position)
                        return
                    end
                    mask = createMask(roi, app.a, app.b);
                    delete(roi);
                    sel = mask(:) & (app.NoSaturationMap(:) == 1);
                    if ~any(sel)
                        uialert(app.UIFigure,'No valid pixels in ROI.','Empty ROI');
                        return
                    end
                    specMat = reshape(abs(app.Hyperspectrum_cube), app.a*app.b, app.cc);
                    specRef = mean(specMat(sel,:),1)'; % cc x 1

                case 'Load external spectrum'
                    uiwait(msgbox(['The external spectrum has to be a .txt file with the first column ' ...
                        'representing the frequency [THz] and the second column representing the ' ...
                        'intensity; other columns will be neglected.'], ...
                        'External spectrum file format','warn'));
                    [fname,pname] = uigetfile('*.txt','Load reference spectrum');
                    if isequal(fname,0)
                        return
                    end
                    try
                        inputData = load(fullfile(pname,fname));
                    catch
                        dataStruct = importdata(fullfile(pname,fname));
                        inputData = dataStruct.data;
                    end
                    specRefRaw = inputData(:,2);
                    frRef = inputData(:,1);

                    ramanChoice = uiconfirm(app.UIFigure,'Is the external spectrum a Raman spectrum?', ...
                        'External spectrum type','Options',{'Raman','Other'},'DefaultOption',2);
                    if strcmp(ramanChoice,'Raman')
                        uiwait(msgbox(['If the external spectrum is a Raman spectrum it must be shifted in ' ...
                            'frequency to account for the difference between its pump-laser wavelength and ' ...
                            'the current measurement''s pump-laser wavelength.'], ...
                            'Raman shift','warn'));
                        answer = inputdlg({'External spectrum pump laser wavelength [nm]', ...
                            'Current measurement pump laser wavelength [nm]'}, ...
                            'Pump laser wavelengths',1,{'780','780'});
                        if ~isempty(answer)
                            pump1 = str2double(answer{1});
                            pump2 = str2double(answer{2});
                            if ~any(isnan([pump1 pump2]))
                                frRef = frRef + app.c.*(pump1-pump2)./(pump1.*pump2).*1e9./1e12;
                            end
                        end
                    end

                    specRef = interp1(frRef, specRefRaw, fr);
                    specRef(isnan(specRef)) = 0;
                    specRef = specRef(:);
            end

            defLo = num2str(min(app.lambda_nm));
            defHi = num2str(max(app.lambda_nm));
            answer = inputdlg({'Lower wavelength (nm)','Higher wavelength (nm)'}, ...
                'Select spectral band for SAM',1,{defLo,defHi});
            if isempty(answer)
                return
            end
            lm1 = str2double(answer{1});
            lm2 = str2double(answer{2});
            if any(isnan([lm1 lm2]))
                uialert(app.UIFigure,'Invalid numeric input.','Error'); return
            end

            fRange = sort(app.c./([lm1 lm2]*1e-9)/1e12);
            idx = fr > fRange(1) & fr < fRange(2);
            if ~any(idx)
                uialert(app.UIFigure,'No spectral points in the selected band.','Error'); return
            end

            d = uiprogressdlg(app.UIFigure,'Title','Spectral Angle Mapping', ...
                'Message','Computing...','Indeterminate','on');

            cubeAbs = abs(app.Hyperspectrum_cube(:,:,idx));
            specMat = reshape(cubeAbs, app.a*app.b, nnz(idx));
            refSel = specRef(idx);

            dotProd = specMat * refSel;
            normCube = sqrt(sum(specMat.^2,2));
            normRef = sqrt(sum(refSel.^2));

            cosTheta = dotProd ./ (normCube*normRef);
            cosTheta = max(min(cosTheta,1),-1);
            theta = reshape(acos(cosTheta) * 180/pi, app.a, app.b);

            close(d);

            figSAM = figure('Name','Spectral Angle Mapping','NumberTitle','off');
            axSAM = axes('Parent',figSAM);
            imagesc(axSAM, theta);
            colormap(axSAM, flipud(gray(256)));
            colorbar(axSAM);
            title(axSAM,'Spectral Angle Mapping (deg)');
            axis(axSAM,'equal'); axis(axSAM,'off');

            app.StatusLabel.Text = 'Spectral Angle Mapping computed.';
        end

        function ReflectivityButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            fr = app.fr_real(:)';

            choice = uiconfirm(app.UIFigure,'Choose reference (white) spectrum source:','Reflectivity map', ...
                'Options',{'Spectrum from ROI','Load external spectrum','Cancel'}, ...
                'DefaultOption',1,'CancelOption',3);
            if strcmp(choice,'Cancel')
                return
            end

            switch choice
                case 'Spectrum from ROI'
                    uialert(app.UIFigure,'Draw a ROI over the white/reference area.','Reflectivity map','Icon','info');
                    try
                        roi = drawpolygon(app.ImageAxes);
                    catch
                        return
                    end
                    if ~isvalid(roi) || isempty(roi.Position)
                        return
                    end
                    mask = createMask(roi, app.a, app.b);
                    delete(roi);
                    sel = mask(:) & (app.NoSaturationMap(:) == 1);
                    if ~any(sel)
                        uialert(app.UIFigure,'No valid pixels in ROI.','Empty ROI');
                        return
                    end
                    specMat = reshape(app.Hyperspectrum_cube, app.a*app.b, app.cc);
                    refSpec = abs(mean(specMat(sel,:),1))'; % cc x 1

                case 'Load external spectrum'
                    uiwait(msgbox(['The external spectrum has to be a .txt file with the first column ' ...
                        'representing the frequency [THz] and the second column representing the ' ...
                        'intensity. Its frequency range must cover the current hypercube''s range.'], ...
                        'External spectrum file format','warn'));
                    [fname,pname] = uigetfile('*.txt','Load reference (white) spectrum');
                    if isequal(fname,0)
                        return
                    end
                    try
                        inputData = load(fullfile(pname,fname));
                    catch
                        dataStruct = importdata(fullfile(pname,fname));
                        inputData = dataStruct.data;
                    end
                    specRefRaw = inputData(:,2);
                    frRef = inputData(:,1);

                    if abs(frRef(1)-fr(1)) < 1e-12
                        frRef(1) = fr(1);
                    end
                    if abs(frRef(end)-fr(end)) < 1e-12
                        frRef(end) = fr(end);
                    end

                    refSpec = interp1(frRef, specRefRaw, fr);
                    if any(isnan(refSpec))
                        uialert(app.UIFigure,['The external spectrum must cover the full frequency ' ...
                            'range of the current hypercube.'],'Error');
                        return
                    end
                    refSpec = refSpec(:);

                    answer = inputdlg({'Integration-time adjustment factor (current measurement vs. reference)'}, ...
                        'Spectralon multiplication factor',1,{'1'});
                    if isempty(answer)
                        return
                    end
                    factor = str2double(answer{1});
                    if isnan(factor)
                        uialert(app.UIFigure,'Invalid numeric input.','Error'); return
                    end
                    refSpec = refSpec.*factor;
            end

            reflChoice = uiconfirm(app.UIFigure,'Spectralon reflectivity:','Reflectivity map', ...
                'Options',{'Single value','Load reflectivity spectrum','Cancel'}, ...
                'DefaultOption',1,'CancelOption',3);
            if strcmp(reflChoice,'Cancel')
                return
            end

            switch reflChoice
                case 'Single value'
                    answer = inputdlg({'Spectralon reflectivity value (0 [black] to 1 [white])'}, ...
                        'Spectralon reflectivity',1,{'1'});
                    if isempty(answer)
                        return
                    end
                    reflVal = str2double(answer{1});
                    if isnan(reflVal) || reflVal == 0
                        uialert(app.UIFigure,'Invalid numeric input.','Error'); return
                    end
                    refSpec = refSpec./reflVal;

                case 'Load reflectivity spectrum'
                    [fname,pname] = uigetfile('*.txt','Load spectralon reflectivity spectrum');
                    if isequal(fname,0)
                        return
                    end
                    try
                        inputData = load(fullfile(pname,fname));
                    catch
                        dataStruct = importdata(fullfile(pname,fname));
                        inputData = dataStruct.data;
                    end
                    reflRaw = inputData(:,2);
                    frRefl = inputData(:,1);
                    reflSpec = interp1(frRefl, reflRaw, fr);
                    refSpec = refSpec./reflSpec(:);
            end

            d = uiprogressdlg(app.UIFigure,'Title','Reflectivity map', ...
                'Message','Computing...','Indeterminate','on');

            specMat = reshape(abs(app.Hyperspectrum_cube), app.a*app.b, app.cc);
            Re = specMat ./ refSpec';
            Re = reshape(Re, app.a, app.b, app.cc);

            close(d);

            app.offerHypercubeResult(Re, 'Reflectivity');
        end

        function TransmissionButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            uialert(app.UIFigure,'Draw a ROI over the reference area.','Transmission map','Icon','info');
            try
                roi = drawpolygon(app.ImageAxes);
            catch
                return
            end
            if ~isvalid(roi) || isempty(roi.Position)
                return
            end
            mask = createMask(roi, app.a, app.b);
            delete(roi);
            sel = mask(:) & (app.NoSaturationMap(:) == 1);
            if ~any(sel)
                uialert(app.UIFigure,'No valid pixels in ROI.','Empty ROI');
                return
            end

            specMat = reshape(app.Hyperspectrum_cube, app.a*app.b, app.cc);
            refSpec = abs(mean(specMat(sel,:),1))'; % cc x 1

            d = uiprogressdlg(app.UIFigure,'Title','Transmission map', ...
                'Message','Computing...','Indeterminate','on');

            specAbs = reshape(abs(app.Hyperspectrum_cube), app.a*app.b, app.cc);
            T = (specAbs - refSpec') ./ refSpec';
            T = reshape(T, app.a, app.b, app.cc);

            close(d);

            app.offerHypercubeResult(T, 'Transmission');
        end

        function offerHypercubeResult(app, cubeResult, label)
            choice = uiconfirm(app.UIFigure, ...
                sprintf('%s map computed. What would you like to do with it?', label), ...
                label, 'Options',{'Save to file','Replace current hypercube','Both','Cancel'}, ...
                'DefaultOption',3,'CancelOption',4);
            if strcmp(choice,'Cancel')
                return
            end

            if strcmp(choice,'Save to file') || strcmp(choice,'Both')
                try
                    if app.load_cal
                        save_hypercube(cubeResult, app.f, app.NoSaturationMap, ...
                            app.fr_real, app.file_totCal, sum(abs(cubeResult),3), app.dir2);
                    else
                        save_hypercube(cubeResult, app.f, app.NoSaturationMap, ...
                            [], [], sum(abs(cubeResult),3), app.dir2);
                    end
                    app.StatusLabel.Text = sprintf('%s hypercube saved.', label);
                catch ME
                    uialert(app.UIFigure, ME.message, sprintf('Error saving %s hypercube', label));
                end
            end

            if strcmp(choice,'Replace current hypercube') || strcmp(choice,'Both')
                app.Hyperspectrum_cube = cubeResult;
                app.Intens = sum(abs(cubeResult),3);
                if ~app.RGB_flag
                    app.ImmagineRGB = repmat(app.Intens,[1 1 3]);
                end
                if app.derivative_flag ~= 0
                    app.recomputeDerivative();
                end
                app.updateImageDisplay();
                app.StatusLabel.Text = sprintf('Working hypercube replaced with %s map.', label);
            end
        end

        function LambertianButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            uialert(app.UIFigure,['Load the Lambertian-surface hypercube. It must have the same ' ...
                'number of pixels and spectral points as the current hypercube.'], ...
                'Normalize on Lambertian','Icon','info');

            [fname,pname] = uigetfile({'*.mat;*.h5;*.mj2','Hypercube files (*.mat,*.h5,*.mj2)'}, ...
                'Load spectral Hypercube of Lambertian surface');
            if isequal(fname,0)
                return
            end
            fileTot = fullfile(pname,fname);

            d = uiprogressdlg(app.UIFigure,'Title','Loading Lambertian', ...
                'Message','Loading, please wait...','Indeterminate','on');

            try
                [~,~,ext] = fileparts(fname);
                switch lower(ext)
                    case '.h5'
                        cubeL = app.H5HypercubeRead(fileTot);
                    case '.mj2'
                        cubeL = app.MJ2HypercubeRead(fileTot);
                    otherwise
                        cubeL = app.MATHypercubeRead(fileTot);
                end
            catch ME
                close(d);
                uialert(app.UIFigure, ME.message, 'Error loading Lambertian hypercube');
                return
            end

            close(d);

            if app.absoluteVal == 1
                cubeL = abs(cubeL);
            end
            maxL = max(abs(cubeL(:)));
            cubeL(cubeL==0) = maxL/10000;

            [aL,bL,ccL] = size(cubeL);
            if aL ~= app.a || bL ~= app.b || ccL ~= app.cc
                uialert(app.UIFigure, sprintf(['Size mismatch: current hypercube is %dx%dx%d, ' ...
                    'Lambertian is %dx%dx%d. Aborting.'], app.a, app.b, app.cc, aL, bL, ccL), ...
                    'Normalize on Lambertian');
                return
            end

            answer = inputdlg({'Smoothing of Lambertian (10x10 Gaussian filter st.dev., 0 = none)', ...
                'Multiplication factor'}, 'Lambertian settings',1,{'0','1'});
            if isempty(answer)
                return
            end
            filt = str2double(answer{1});
            factor = str2double(answer{2});
            if any(isnan([filt factor]))
                uialert(app.UIFigure,'Invalid numeric input.','Error'); return
            end

            if filt > 0
                d = uiprogressdlg(app.UIFigure,'Title','Smoothing Lambertian', ...
                    'Message','Smoothing, please wait...','Value',0);
                H = fspecial('gaussian',10,filt/2);
                for sp = 1:app.cc
                    d.Value = sp/app.cc;
                    cubeL(:,:,sp) = imfilter(cubeL(:,:,sp),H,'replicate');
                end
                close(d);
            end

            app.Hyperspectrum_cube = app.Hyperspectrum_cube ./ (abs(cubeL).*factor);
            app.Intens = sum(abs(app.Hyperspectrum_cube),3);
            if ~app.RGB_flag
                app.ImmagineRGB = repmat(app.Intens,[1 1 3]);
            end
            if app.derivative_flag ~= 0
                app.recomputeDerivative();
            end
            app.updateImageDisplay();

            app.StatusLabel.Text = 'Hypercube normalised on Lambertian surface.';
        end

        function PeakMappingButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            maxSpectrum = max(abs(app.Hyperspectrum_cube(:)));
            answer = inputdlg({'Lower wavelength (nm)','Higher wavelength (nm)','Threshold', ...
                'Spectral interpolation factor (1 = no interpolation)'}, ...
                'Map Spectral Peaks',1, ...
                {num2str(min(app.lambda_nm)),num2str(max(app.lambda_nm)), ...
                num2str(maxSpectrum/10),'10'});
            if isempty(answer)
                return
            end
            lm1 = str2double(answer{1});
            lm2 = str2double(answer{2});
            threshold = str2double(answer{3});
            resolution = round(str2double(answer{4}));
            if any(isnan([lm1 lm2 threshold resolution]))
                uialert(app.UIFigure,'Invalid numeric input.','Error'); return
            end
            if resolution < 1
                resolution = 1;
            end

            fRange = sort(app.c./([lm1 lm2]*1e-9)/1e12);
            idx = app.fr_real > fRange(1) & app.fr_real < fRange(2);
            if nnz(idx) < 2
                uialert(app.UIFigure,'Select a wider spectral band (at least 2 points).','Error');
                return
            end
            f1 = app.fr_real(idx);
            nf1 = numel(f1);

            cubeAbs = abs(app.Hyperspectrum_cube(:,:,idx));

            PeakWl = zeros(app.a,app.b);
            IntWl = zeros(app.a,app.b);

            d = uiprogressdlg(app.UIFigure,'Title','Map Spectral Peaks', ...
                'Message','Finding peaks...','Value',0);

            for yy = 1:app.a
                d.Value = yy/app.a;
                for xx = 1:app.b
                    spec = squeeze(cubeAbs(yy,xx,:));

                    [~,peakIdx] = max(spec);
                    min1 = max(peakIdx-5,1);
                    max1 = min(peakIdx+4,nf1);

                    f2 = linspace(f1(min1),f1(max1),(max1-min1+1)*resolution);
                    specDense = interp1(f1(min1:max1),spec(min1:max1),f2,'spline');

                    [intVal,denseIdx] = max(specDense);
                    IntWl(yy,xx) = intVal;
                    PeakWl(yy,xx) = app.c./(f2(denseIdx)*1e12)/1e-9;
                end
            end

            close(d);

            PeakWl(IntWl < threshold) = NaN;

            figPeak = figure('Name','Spectral Peak Mapping','NumberTitle','off');
            axPeak = axes('Parent',figPeak);
            imagesc(axPeak, PeakWl);
            colormap(axPeak, jet(256));
            colorbar(axPeak);
            title(axPeak,'Spectral Peak Mapping (nm)');
            axis(axPeak,'equal'); axis(axPeak,'off');

            figInt = figure('Name','Main Peak Intensity','NumberTitle','off');
            axInt = axes('Parent',figInt);
            imagesc(axInt, IntWl);
            colormap(axInt, gray(256));
            colorbar(axInt);
            title(axInt,'Intensity of main peak');
            axis(axInt,'equal'); axis(axInt,'off');

            app.StatusLabel.Text = 'Spectral peak mapping computed.';
        end

        % ----------------------------------------------------------
        % ----------------------------------------------------------
        % Analysis: SVD denoising, K-means clustering
        % ----------------------------------------------------------
        function SVDButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            % Work on absolute values only, as in the original script.
            cube = double(abs(app.Hyperspectrum_cube));
            [a, b, p] = size(cube);
            n = a * b;

            X = reshape(cube, [n, p])'; % p x n: rows = spectral, cols = spatial

            d = uiprogressdlg(app.UIFigure,'Title','SVD denoising', ...
                'Message','Computing SVD (this may take a while)...','Indeterminate','on');

            S_vals = svd(X);

            close(d);

            % Show explained-variance plot in a standard figure.
            % Data cursor mode is enabled so the user can hover/click
            % any point to read off its exact index and variance value,
            % then type the chosen number in the dialog below.
            explainedVar = cumsum(S_vals) / sum(S_vals);
            figVar = figure('Name','SVD – Explained variance','NumberTitle','off');
            axVar = axes('Parent',figVar);
            plot(axVar, 1:numel(explainedVar), explainedVar*100, 'o-','LineWidth',1.5);
            xlabel(axVar,'Number of singular values');
            ylabel(axVar,'Cumulative explained variance [%]');
            title(axVar,'Inspect the curve, then type the number of SVs in the dialog');
            grid(axVar,'on');
            xlim(axVar,[1 numel(explainedVar)]);
            ylim(axVar,[0 100]);
            datacursormode(figVar,'on');

            answer = inputdlg({'Number of singular values to keep'}, ...
                'SVD denoising',1,{'2'});
            if isempty(answer)
                if isvalid(figVar); close(figVar); end
                return
            end
            nSVs = round(str2double(answer{1}));
            if isnan(nSVs) || nSVs < 1 || nSVs > numel(S_vals)
                uialert(app.UIFigure, sprintf('Enter a number between 1 and %d.', numel(S_vals)),'Invalid input');
                if isvalid(figVar); close(figVar); end
                return
            end

            % Highlight the selected point and close the figure.
            hold(axVar,'on');
            plot(axVar, nSVs, explainedVar(nSVs)*100, 'r*','MarkerSize',14,'LineWidth',2);
            title(axVar, sprintf('%d SVs selected (%.1f%% variance explained)', ...
                nSVs, explainedVar(nSVs)*100));
            drawnow;
            pause(1.5);
            if isvalid(figVar); close(figVar); end

            d = uiprogressdlg(app.UIFigure,'Title','SVD denoising', ...
                'Message',sprintf('Computing truncated SVD (%d SVs)...', nSVs),'Indeterminate','on');

            [U, S_mat, V] = svds(X, nSVs);

            close(d);

            % Optionally visualise the components.
            visChoice = uiconfirm(app.UIFigure, ...
                'Visualise all SVD components (spectral eigenfunction + score map)?', ...
                'SVD components','Options',{'Yes','No'},'DefaultOption',1);

            if strcmp(visChoice,'Yes')
                lam = app.currentLambda(:);
                for idx = 1:nSVs
                    scoreMap = reshape(V(:,idx), [a, b]);
                    figSV = figure('Name',sprintf('SVD component %d',idx), ...
                        'NumberTitle','off','Position',[100 50 1100 400]);
                    axSpec = subplot(1,5,[1,2],'Parent',figSV);
                    plot(axSpec, lam, U(:,idx),'LineWidth',2);
                    xlabel(axSpec, app.LabelX,'FontSize',12);
                    ylabel(axSpec, sprintf('Component %d',idx),'FontSize',12);
                    title(axSpec, sprintf('PC %d',idx),'FontSize',16);

                    axMap = subplot(1,5,[3,4,5],'Parent',figSV);
                    imagesc(axMap, scoreMap);
                    axis(axMap,'equal'); axis(axMap,'off');
                    colormap(axMap, gray);
                    colorbar(axMap);
                    title(axMap,'Score map','FontSize',16);
                end
            end

            % Reconstruct the denoised hypercube.
            cubeSVD = reshape((U * S_mat * V')', [a, b, p]);

            choice = uiconfirm(app.UIFigure, ...
                sprintf('SVD denoising complete (%d SVs). What would you like to do?', nSVs), ...
                'SVD result', ...
                'Options',{'Replace working hypercube','Save to file','Both','Cancel'}, ...
                'DefaultOption',3,'CancelOption',4);

            if strcmp(choice,'Cancel')
                return
            end

            if strcmp(choice,'Save to file') || strcmp(choice,'Both')
                [fname, pname] = uiputfile('*.mat','Save SVD-denoised hypercube as', app.dir2);
                if ~isequal(fname,0)
                    Hyperspectrum_cube = cubeSVD; %#ok<NASGU>
                    f      = app.f;               %#ok<NASGU>
                    fr_real = app.fr_real;        %#ok<NASGU>
                    save(fullfile(pname,fname), 'Hyperspectrum_cube','f','fr_real');
                    app.StatusLabel.Text = sprintf('SVD-denoised hypercube saved to %s', fname);
                end
            end

            if strcmp(choice,'Replace working hypercube') || strcmp(choice,'Both')
                app.Hyperspectrum_cube = cubeSVD;
                app.Intens = sum(abs(cubeSVD),3);
                if ~app.RGB_flag
                    app.ImmagineRGB = repmat(app.Intens,[1 1 3]);
                end
                if app.derivative_flag ~= 0
                    app.recomputeDerivative();
                end
                app.updateImageDisplay();
                app.clearSpectrumPlots();
                app.StatusLabel.Text = sprintf('Working hypercube replaced with SVD-denoised result (%d SVs).', nSVs);
            end
        end

        function KMeansButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            % Ask for parameters.
            answer = inputdlg({'Number of clusters','Lower wavelength (nm) [leave blank for full range]', ...
                'Higher wavelength (nm) [leave blank for full range]'}, ...
                'K-means clustering',1, ...
                {'3', num2str(min(app.currentLambda)), num2str(max(app.currentLambda))});
            if isempty(answer)
                return
            end
            nClusters = round(str2double(answer{1}));
            lm1 = str2double(answer{2});
            lm2 = str2double(answer{3});
            if isnan(nClusters) || nClusters < 1
                uialert(app.UIFigure,'Invalid number of clusters.','Error'); return
            end

            % Use the active (raw or derivative) cube.
            [dataCube, lambdaCur] = app.activeSpectralData();
            cube = double(abs(dataCube));
            [a, b, p] = size(cube);

            % Spectral crop if requested.
            if ~isnan(lm1) && ~isnan(lm2) && lm1 < lm2
                idx = lambdaCur >= min(lm1,lm2) & lambdaCur <= max(lm1,lm2);
                if any(idx)
                    cube = cube(:,:,idx);
                    lambdaCur = lambdaCur(idx);
                    p = nnz(idx);
                end
            end

            % Apply the current NoSaturationMap as a mask: pixels flagged
            % as 0 (saturated or threshold-masked) are excluded from
            % clustering and assigned cluster 0 in the output map.
            validMask = app.NoSaturationMap == 1;

            X = reshape(cube, [a*b, p]);
            Xvalid = X(validMask(:), :);

            if isempty(Xvalid)
                uialert(app.UIFigure,'No valid (unmasked) pixels to cluster.','Error'); return
            end

            d = uiprogressdlg(app.UIFigure,'Title','K-means clustering', ...
                'Message','Running k-means (this may take a while)...','Indeterminate','on');

           try
                [IDX,CENTROIDS] = kmeans(Xvalid,nClusters);
                CLUSTERS_valid = reshape(IDX,a,b,1); %CLUSTERS is a 2D map where each pixels has an integer value indicating the belonging cluster
                CENTROIDS = CENTROIDS'; %in this way the centroids are column spectra
            catch ME
                close(d);
                uialert(app.UIFigure, ME.message,'Error in kmeans_tool'); return
            end

            close(d);

            % Rebuild the full cluster map (masked pixels = 0).
            CLUSTERS = zeros(a, b, 1);
            CLUSTERS(validMask(:)) = CLUSTERS_valid(:);
            clusteredMap = reshape(CLUSTERS, [a, b]);
            % Colour palette.
            MAP_COLOR = eval(['parula', '(', num2str(nClusters), ')']);;
            lam = lambdaCur(:);
            maxC = max(CENTROIDS(:));
            minC = min(CENTROIDS(:));

            % One figure per cluster.
            for idx = 1:nClusters
                figC = figure('Name',sprintf('K-means – Cluster %d',idx), ...
                    'NumberTitle','off','Units','normalized','Position',[0.1 0.15 0.7 0.6]);

                axSpec = subplot(1,5,[1,2],'Parent',figC);
                plot(axSpec, lam, CENTROIDS(:,idx),'LineWidth',2,'Color',MAP_COLOR(idx,:));
                xlabel(axSpec, app.LabelX,'FontSize',16);
                ylabel(axSpec,'Amplitude','FontSize',16);
                title(axSpec,sprintf('Centroid %d',idx),'FontSize',14);
                axis(axSpec,[min(lam) max(lam) 0.9*minC 1.1*maxC]);
                ax = gca; ax.FontSize = 12;

                axMap = subplot(1,5,[3,4,5],'Parent',figC);
                R = zeros(a,b); G = R; B = R;
                R(clusteredMap == idx) = MAP_COLOR(idx,1);
                G(clusteredMap == idx) = MAP_COLOR(idx,2);
                B(clusteredMap == idx) = MAP_COLOR(idx,3);
                imagesc(axMap, cat(3,R,G,B));
                axis(axMap,'equal'); axis(axMap,'off');
                colormap(axMap,[0 0 0; MAP_COLOR(idx,:)]);
                title(axMap,sprintf('Cluster %d',idx),'FontSize',14);
            end

            % All clusters together — raw centroids.
            figAll = figure('Name','K-means – All clusters','NumberTitle','off', ...
                'Units','normalized','Position',[0.1 0.15 0.7 0.6]);
            axSpec2 = subplot(1,5,[1,2],'Parent',figAll);
            hold(axSpec2,'on');
            for idx = 1:nClusters
                plot(axSpec2, lam, CENTROIDS(:,idx),'LineWidth',2,'Color',MAP_COLOR(idx,:));
            end
            xlabel(axSpec2, app.LabelX,'FontSize',16);
            ylabel(axSpec2,'Amplitude','FontSize',16);
            title(axSpec2,'Centroids','FontSize',14);
            axis(axSpec2,[min(lam) max(lam) 0.9*minC 1.1*maxC]);
            axSpec2.FontSize = 12;

            axMap2 = subplot(1,5,[3,4,5],'Parent',figAll);
            imagesc(axMap2, clusteredMap);
            axMap2.CLim = [0 nClusters];
            axis(axMap2,'equal'); axis(axMap2,'off');
            colormap(axMap2,[0 0 0; MAP_COLOR]);
            title(axMap2,'Clusters','FontSize',14);
            axMap2.FontSize = 12;

            % All clusters together — normalised centroids.
            figNorm = figure('Name','K-means – Normalised centroids','NumberTitle','off', ...
                'Units','normalized','Position',[0.1 0.15 0.7 0.6]);
            axSpec3 = subplot(1,5,[1,2],'Parent',figNorm);
            hold(axSpec3,'on');
            for idx = 1:nClusters
                cNorm = CENTROIDS(:,idx) / max(CENTROIDS(:,idx));
                plot(axSpec3, lam, cNorm,'LineWidth',2,'Color',MAP_COLOR(idx,:));
            end
            xlabel(axSpec3, app.LabelX,'FontSize',16);
            ylabel(axSpec3,'Amplitude','FontSize',16);
            title(axSpec3,'Norm. Centroids','FontSize',14);
            axis(axSpec3,[min(lam) max(lam) 0 1]);
            axSpec3.FontSize = 12;

            axMap3 = subplot(1,5,[3,4,5],'Parent',figNorm);
            imagesc(axMap3, clusteredMap);
            axMap3.CLim = [0 nClusters];
            axis(axMap3,'equal'); axis(axMap3,'off');
            colormap(axMap3,[0 0 0; MAP_COLOR]);
            title(axMap3,'Clusters','FontSize',14);
            axMap3.FontSize = 12;

            app.StatusLabel.Text = sprintf('K-means clustering complete (%d clusters).', nClusters);
        end

        % ----------------------------------------------------------
        % Process: Crop/Smoothing, Derivative, Plot Hypercube
        % ----------------------------------------------------------
        function CropSmoothingButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            choice = uiconfirm(app.UIFigure,'Choose action:','Crop / Smoothing', ...
                'Options',{'Spectral crop','Spatial crop','Spatial smoothing','Cancel'}, ...
                'DefaultOption',1,'CancelOption',4);

            switch choice
                case 'Spectral crop'
                    app.spectralCrop();
                case 'Spatial crop'
                    app.spatialCrop();
                case 'Spatial smoothing'
                    app.spatialSmoothing();
                otherwise
                    return
            end
        end

        function spectralCrop(app)
            answer = inputdlg({'Lower wavelength (nm)','Higher wavelength (nm)'}, ...
                'Select spectral limits',1,{num2str(min(app.lambda_nm)),num2str(max(app.lambda_nm))});
            if isempty(answer)
                return
            end
            lm1 = str2double(answer{1});
            lm2 = str2double(answer{2});
            if any(isnan([lm1 lm2]))
                uialert(app.UIFigure,'Invalid numeric input.','Error'); return
            end

            fRange = sort(app.c./([lm1 lm2]*1e-9)/1e12);
            idx = app.fr_real > fRange(1) & app.fr_real < fRange(2);
            if ~any(idx)
                uialert(app.UIFigure,'No spectral points in the selected range.','Error'); return
            end

            app.Hyperspectrum_cube = app.Hyperspectrum_cube(:,:,idx);
            app.f = app.f(idx);
            app.fr_real = app.fr_real(idx);
            app.cc = numel(app.f);

            app.Intens = sum(abs(app.Hyperspectrum_cube),3);
            if ~app.RGB_flag
                app.ImmagineRGB = repmat(app.Intens,[1 1 3]);
            end

            app.finalizeAxes();
            app.updateImageDisplay();
            app.clearSpectrumPlots();
            app.SizeLabel.Text = sprintf('Size: %d x %d px, %d spectral pts', app.b, app.a, app.cc);
            app.StatusLabel.Text = sprintf('Hypercube cropped spectrally to %g - %g nm (%d points).', ...
                min(lm1,lm2), max(lm1,lm2), app.cc);
        end

        function spatialCrop(app)
            uialert(app.UIFigure,'Draw a rectangle over the area to keep.','Spatial crop','Icon','info');
            try
                roi = drawrectangle(app.ImageAxes);
            catch
                return
            end
            if ~isvalid(roi) || isempty(roi.Position)
                return
            end

            pos = roi.Position; % [x y w h]
            delete(roi);

            cmin = max(1, round(pos(1)));
            rmin = max(1, round(pos(2)));
            cmax = min(app.b, round(pos(1)+pos(3)));
            rmax = min(app.a, round(pos(2)+pos(4)));

            if cmax <= cmin || rmax <= rmin
                uialert(app.UIFigure,'Invalid crop area.','Error'); return
            end

            app.Hyperspectrum_cube = app.Hyperspectrum_cube(rmin:rmax,cmin:cmax,:);
            app.ImmagineRGB = app.ImmagineRGB(rmin:rmax,cmin:cmax,:);
            app.NoSaturationMap = app.NoSaturationMap(rmin:rmax,cmin:cmax);
            app.Intens = sum(abs(app.Hyperspectrum_cube),3);
            [app.a, app.b] = size(app.Hyperspectrum_cube,[1 2]);

            if app.useCustomAxes
                if numel(app.customXVec) >= cmax
                    app.customXVec = app.customXVec(cmin:cmax);
                else
                    app.useCustomAxes = false;
                    app.customXVec = [];
                    app.customYVec = [];
                end
            end
            if app.useCustomAxes
                if numel(app.customYVec) >= rmax
                    app.customYVec = app.customYVec(rmin:rmax);
                else
                    app.useCustomAxes = false;
                    app.customXVec = [];
                    app.customYVec = [];
                end
            end

            if app.derivative_flag ~= 0
                app.recomputeDerivative();
            end

            delete(app.ImageHandle);
            app.ImageHandle = [];
            app.blackLevel = 0; app.saturationLevel = 1; app.gammaVal = 1;
            app.BlackEditField.Value = 0;
            app.SaturationEditField.Value = 1;
            app.GammaEditField.Value = 1;

            app.updateImageDisplay();
            app.clearSpectrumPlots();
            app.SizeLabel.Text = sprintf('Size: %d x %d px, %d spectral pts', app.b, app.a, app.cc);
            app.StatusLabel.Text = 'Hypercube cropped spatially.';
        end

        function spatialSmoothing(app)
            answer = inputdlg({['Spatial smoothing (5x5 Gaussian filter st.dev., e.g. 10 = ' ...
                '5-pixel st.dev., 0 = none)']}, 'Smoothing',1,{'0'});
            if isempty(answer)
                return
            end
            nPix = str2double(answer{1});
            if isnan(nPix) || nPix < 0
                uialert(app.UIFigure,'Invalid numeric input.','Error'); return
            end

            if nPix > 0
                d = uiprogressdlg(app.UIFigure,'Title','Smoothing', ...
                    'Message','Smoothing hypercube, please wait...','Value',0);
                H = fspecial('gaussian',5,nPix/2);
                for sp = 1:app.cc
                    d.Value = sp/app.cc;
                    app.Hyperspectrum_cube(:,:,sp) = imfilter(app.Hyperspectrum_cube(:,:,sp),H,'replicate');
                end
                close(d);
            end

            app.Intens = sum(abs(app.Hyperspectrum_cube),3);
            if ~app.RGB_flag
                app.ImmagineRGB = repmat(app.Intens,[1 1 3]);
            end
            if app.derivative_flag ~= 0
                app.recomputeDerivative();
            end

            app.blackLevel = 0; app.saturationLevel = 1; app.gammaVal = 1;
            app.BlackEditField.Value = 0;
            app.SaturationEditField.Value = 1;
            app.GammaEditField.Value = 1;

            app.updateImageDisplay();
            app.StatusLabel.Text = sprintf('Hypercube smoothed (st.dev. = %g px).', nPix/2);
        end

        function DerivativeButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end
            answer = inputdlg({'Derivative order: 0 (none), 1, or 2'}, ...
                'Hypercube derivative',1,{num2str(app.derivative_flag)});
            if isempty(answer)
                return
            end
            val = round(str2double(answer{1}));
            if isnan(val) || val < 0 || val > 2
                uialert(app.UIFigure,'Enter 0, 1, or 2.','Invalid input');
                return
            end

            app.derivative_flag = val;
            app.recomputeDerivative();
            app.clearSpectrumPlots();

            switch val
                case 0
                    msg = 'No derivative: spectra show the raw hypercube.';
                case 1
                    msg = ['First derivative active: new ROI/pixel spectra and "Plot Hypercube" ' ...
                        'will show the first derivative of the spectrum.'];
                case 2
                    msg = ['Second derivative active: new ROI/pixel spectra and "Plot Hypercube" ' ...
                        'will show the second derivative of the spectrum.'];
            end
            uialert(app.UIFigure, msg,'Hypercube derivative','Icon','info');
            app.StatusLabel.Text = sprintf('Derivative order set to %d.', val);
        end

        function PlotHypercubeButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end
            try
                if app.derivative_flag == 0
                    PlotHypercube(app.fr_real, abs(app.Hyperspectrum_cube));
                else
                    PlotHypercube(app.currentFrReal, app.Hypercube_derivative);
                end
            catch ME
                uialert(app.UIFigure, ME.message, 'Error in PlotHypercube');
            end
        end

        function MaskButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            % Build a grayscale 0-255 version of the currently displayed
            % image, so the threshold and the improfile values use the
            % same intuitive scale.
            dispImg = app.computeDisplayImage();
            if size(dispImg,3) == 3
                grayImg = mean(dispImg,3);
            else
                grayImg = dispImg;
            end
            grayImg255 = grayImg*255;
            grayImg255_u8 = uint8(round(grayImg255));

            figMask = figure('Name','Mask: threshold preview','NumberTitle','off');
            axMask = axes('Parent',figMask);
            imshow(grayImg255_u8,'Parent',axMask);
            axis(axMask,'equal'); axis(axMask,'off');
            title(axMask,'Current image (0-255 scale)');

            profileFigs = [];
            profileChoice = uiconfirm(app.UIFigure, ...
                'Draw a line across the image to inspect its intensity profile (0-255)?', ...
                'Mask: intensity profile','Options',{'Yes','No'},'DefaultOption',1);
            if strcmp(profileChoice,'Yes') && isvalid(figMask)
                try
                    existingFigs = findall(groot,'Type','figure');
                    figure(figMask);
                    axes(axMask); %#ok<LAXES>
                    improfile;
                    allFigsAfter = findall(groot,'Type','figure');
                    profileFigs = setdiff(allFigsAfter, existingFigs);
                catch
                    % improfile may fail if the figure was closed or the
                    % user cancels the drawing; not critical.
                end
            end

            defaultThreshold = num2str(round(app.localPercentile(grayImg255(:),50)));
            keepMask = [];
            threshold = [];

            while true
                if ~isvalid(figMask)
                    return
                end

                answer = inputdlg({'Intensity threshold (0-255). Pixels below this value will be set to zero.'}, ...
                    'Mask threshold',1,{defaultThreshold});
                if isempty(answer)
                    close(figMask);
                    app.closeFigures(profileFigs);
                    return
                end

                threshold = str2double(answer{1});
                if isnan(threshold)
                    uialert(app.UIFigure,'Invalid numeric input.','Error');
                    continue
                end

                % A valid threshold has been entered: close the
                % improfile profile figure(s), if any.
                app.closeFigures(profileFigs);
                profileFigs = [];

                keepMask = grayImg255 >= threshold;
                nKeep = nnz(keepMask);

                % Preview: masked-out pixels shown in red
                overlay = repmat(grayImg255_u8,[1 1 3]);
                rCh = overlay(:,:,1); gCh = overlay(:,:,2); bCh = overlay(:,:,3);
                rCh(~keepMask) = 255;
                gCh(~keepMask) = 0;
                bCh(~keepMask) = 0;
                overlay = cat(3,rCh,gCh,bCh);

                if isvalid(figMask)
                    imshow(overlay,'Parent',axMask);
                    axis(axMask,'equal'); axis(axMask,'off');
                    title(axMask, sprintf('Threshold = %g: %d / %d pixels kept (red = would be masked out)', ...
                        threshold, nKeep, app.a*app.b));
                    drawnow;
                end

                choice = uiconfirm(app.UIFigure, ...
                    sprintf('Threshold = %g keeps %d of %d pixels. Apply this mask to the working hypercube?', ...
                    threshold, nKeep, app.a*app.b), ...
                    'Apply mask','Options',{'Apply','Change threshold','Cancel'}, ...
                    'DefaultOption',1,'CancelOption',3);

                switch choice
                    case 'Apply'
                        break
                    case 'Change threshold'
                        defaultThreshold = answer{1};
                        continue
                    otherwise
                        if isvalid(figMask)
                            close(figMask);
                        end
                        return
                end
            end

            if isvalid(figMask)
                close(figMask);
            end

            d = uiprogressdlg(app.UIFigure,'Title','Applying mask', ...
                'Message','Applying mask...','Indeterminate','on');

            maskCube = repmat(keepMask,[1 1 app.cc]);
            app.Hyperspectrum_cube(~maskCube) = 0;

            maskRGB = repmat(keepMask,[1 1 3]);
            app.ImmagineRGB(~maskRGB) = 0;

            app.Intens = sum(abs(app.Hyperspectrum_cube),3);
            app.NoSaturationMap(~keepMask) = 0;

            if app.derivative_flag ~= 0
                app.recomputeDerivative();
            end

            close(d);
            app.updateImageDisplay();
            app.StatusLabel.Text = sprintf('Mask applied (threshold = %g): %d / %d pixels kept.', ...
                threshold, nnz(keepMask), app.a*app.b);
        end

        % ----------------------------------------------------------
        % Calibrated (CIE) RGB
        % ----------------------------------------------------------
        function CalibratedRGBButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end
            if ~app.calibratedRGBAvailable
                uialert(app.UIFigure, ['Calibrated RGB requires the colorMatchFcn and illuminant ' ...
                    'functions on the MATLAB path. They were not available when the ' ...
                    'hypercube was loaded.'], 'Calibrated RGB not available');
                return
            end

            choice = uiconfirm(app.UIFigure,'This dataset is:','Calibrated RGB', ...
                'Options',{'Absolute Reflectivity','Emission / Fluorescence','Cancel'}, ...
                'DefaultOption',1,'CancelOption',3);
            if strcmp(choice,'Cancel')
                return
            end

            if strcmp(choice,'Absolute Reflectivity')
                I = app.Energy_i;
            else
                I = app.fr_real.^2;
            end
            I = I(:)';

            kappa = sum(app.y_lam.*I);
            if kappa == 0
                uialert(app.UIFigure,'Normalization coefficient is zero; cannot compute calibrated RGB.','Error');
                return
            end

            d = uiprogressdlg(app.UIFigure,'Title','Calibrated RGB', ...
                'Message','Computing...','Indeterminate','on');

            specMat = reshape(abs(app.Hyperspectrum_cube), app.a*app.b, app.cc);
            weighted = specMat .* I; % a*b x cc

            XC = (weighted * app.x_lam(:)) / kappa;
            YC = (weighted * app.y_lam(:)) / kappa;
            ZC = (weighted * app.z_lam(:)) / kappa;

            M = [ 2.0413690 -0.5649464 -0.3446944; ...
                 -0.9692660  1.8760108  0.0415560; ...
                  0.0134474 -0.1183897  1.0154096];

            RGBvals = [XC YC ZC] * M'; % a*b x 3

            app.ImmagineRGB = reshape(RGBvals, app.a, app.b, 3);
            app.RGB_flag = 1;

            app.blackLevel = 0; app.saturationLevel = 1; app.gammaVal = 1;
            app.BlackEditField.Value = 0;
            app.SaturationEditField.Value = 1;
            app.GammaEditField.Value = 1;

            close(d);
            app.updateImageDisplay();
            app.StatusLabel.Text = 'Calibrated (CIE) RGB image generated.';
        end

        % ----------------------------------------------------------
        % Save spectral GIF
        % ----------------------------------------------------------
        function SaveGIFButtonPushed(app, ~)
            if isempty(app.Hyperspectrum_cube)
                return
            end

            defLo = num2str(min(app.lambda_nm));
            defHi = num2str(max(app.lambda_nm));
            answer = inputdlg({'Lower wavelength (nm)','Higher wavelength (nm)', ...
                'Number of bands','Gamma value','Show spectral position bar (1 = yes, 0 = no)'}, ...
                'Save spectral GIF',1,{defLo,defHi,'10',num2str(app.gammaVal),'1'});
            if isempty(answer)
                return
            end
            lm1 = str2double(answer{1});
            lm2 = str2double(answer{2});
            bands = round(str2double(answer{3}));
            gammaGIF = str2double(answer{4});
            showBar = str2double(answer{5}) ~= 0;
            if any(isnan([lm1 lm2 bands gammaGIF])) || bands < 1
                uialert(app.UIFigure,'Invalid numeric input.','Error'); return
            end

            fRange = sort(app.c./([lm1 lm2]*1e-9)/1e12);
            idx = find(app.fr_real > fRange(1) & app.fr_real < fRange(2));
            if isempty(idx)
                uialert(app.UIFigure,'No spectral points in the selected range.','Error'); return
            end
            cc1 = min(idx);
            cc2 = max(idx);

            bands = max(1, min(bands, cc2-cc1+1));
            selBand = round(linspace(cc2,cc1,bands));

            allSpectra = abs(app.Hyperspectrum_cube(:,:,cc1:cc2));
            allSpectra = allSpectra(:);
            maxCubeSuggested = app.localPercentile(allSpectra,99.5);
            if maxCubeSuggested <= 0
                maxCubeSuggested = max(allSpectra);
            end

            answer2 = inputdlg({'Maximum intensity for the color scale (99.5th percentile suggested)'}, ...
                'GIF intensity scale',1,{num2str(maxCubeSuggested)});
            if isempty(answer2)
                return
            end
            maxCube = str2double(answer2{1});
            if isnan(maxCube) || maxCube <= 0
                uialert(app.UIFigure,'Invalid numeric input.','Error'); return
            end

            [fname,pname] = uiputfile('*.gif','Save GIF as', app.dir2);
            if isequal(fname,0)
                return
            end
            outFile = fullfile(pname,fname);

            d = uiprogressdlg(app.UIFigure,'Title','Saving GIF', ...
                'Message','Rendering frames...','Value',0);

            figGIF = figure('Visible','off','Color','w','Position',[100 100 600 650]);
            axGIF = axes('Parent',figGIF);
            colormap(figGIF, gray(512));

            for n = 1:bands
                d.Value = n/bands;

                frameData = abs(app.Hyperspectrum_cube(:,:,selBand(n)))./maxCube;
                image(axGIF, (frameData.^gammaGIF)*256);
                axis(axGIF,'equal'); axis(axGIF,'off');
                axGIF.YDir = 'reverse';

                if showBar
                    rectangle(axGIF,'FaceColor',[1 0 0],'EdgeColor','none', ...
                        'Position',[0 0 app.b*n/bands app.a/30]);
                end

                if app.load_cal
                    txt = sprintf('\\lambda = %d nm', round(app.lambda_nm(selBand(n))));
                else
                    txt = sprintf('%d (pseudo)', round(selBand(n)));
                end
                text(axGIF, app.b/2, -app.a*0.05, txt, 'HorizontalAlignment','center','FontSize',14);

                drawnow;
                frame = getframe(axGIF);
                im = frame2im(frame);
                [imind,cm] = rgb2ind(im,256);
                if n == 1
                    imwrite(imind,cm,outFile,'gif','LoopCount',inf,'DelayTime',0.2);
                else
                    imwrite(imind,cm,outFile,'gif','WriteMode','append','DelayTime',0.2);
                end

                cla(axGIF);
            end

            close(figGIF);
            close(d);

            app.StatusLabel.Text = sprintf('GIF saved to %s', outFile);
        end
    end

    % ---------------------------------------------------------------
    % Helper / utility methods
    % ---------------------------------------------------------------
    methods (Access = private)

        function setupCalibrationAndRGB(app)
            filepath = fileparts(mfilename('fullpath'));

            rgbDir = fullfile(filepath,'RGBspectra');
            if exist(rgbDir,'dir')
                addpath(genpath(rgbDir));
            end

            RGB_t_file = fullfile(filepath,'RGB_Transmission.mat');
            RGB_t = load(RGB_t_file);
            app.R = RGB_t.R/5.8559e+03;
            app.G = RGB_t.G/4.6082e+03;
            app.B = RGB_t.B/4.7163e+03;
            app.wl = RGB_t.wl;

            if ~isempty(app.fr_real)
                % fr_real in THz — highest priority.
                app.load_cal = true;
                app.spectralAxisType = 'fr_real_THz';
            elseif ~isequal(app.f(:)', 1:app.cc)
                % f in µm⁻¹ — use as fallback.
                app.load_cal = true;
                app.spectralAxisType = 'f_invum';
            else
                % Neither present: fall back to spectral index silently.
                app.fr_real = 1:app.cc;
                app.load_cal = false;
                app.spectralAxisType = 'index';
            end

            app.finalizeAxes();
        end

        function finalizeAxes(app)
            switch app.spectralAxisType
                case 'fr_real_THz'
                    % fr_real in THz: lambda [nm] = c [m/s] / (fr_real [THz] * 1e12) / 1e-9
                    app.lambda_nm = app.c ./ (app.fr_real(:)'*1e12) / 1e-9;
                    app.LabelX = 'Wavelength [nm]';
                case 'f_invum'
                    % f in µm⁻¹: use directly, no conversion.
                    app.lambda_nm = app.f(:)';
                    app.LabelX = 'Wavenumber [µm⁻¹]';
                otherwise
                    % No physical axis: use spectral index directly.
                    app.lambda_nm = 1:app.cc;
                    app.LabelX = 'Spectral index';
            end
            app.lambda_nm = app.lambda_nm(:)';

            app.R_THz = interp1(app.wl, app.R, app.lambda_nm) .* app.lambda_nm.^2 / app.c;
            app.R_THz(isnan(app.R_THz)) = 0;
            app.G_THz = interp1(app.wl, app.G, app.lambda_nm) .* app.lambda_nm.^2 / app.c;
            app.G_THz(isnan(app.G_THz)) = 0;
            app.B_THz = interp1(app.wl, app.B, app.lambda_nm) .* app.lambda_nm.^2 / app.c;
            app.B_THz(isnan(app.B_THz)) = 0;

            xlabel(app.SpectrumAxes, app.LabelX);
            xlabel(app.NormSpectrumAxes, app.LabelX);

            % Reset derivative state for the newly (re)defined spectral axis
            app.derivative_flag = 0;
            app.Hypercube_derivative = [];
            app.Intens_der = [];
            app.currentLambda = app.lambda_nm;
            app.currentFrReal = app.fr_real;

            % CIE color-matching functions + illuminant, for Calibrated RGB.
            % Only meaningful with a physical frequency axis.
            if app.load_cal
                try
                    [lambdaC, xC, yC, zC] = colorMatchFcn('1964_full');
                    lamC = app.lambda_nm;
                    dlamC = diff(lamC);
                    dlamC(end+1) = dlamC(end);
                    dlamC = -dlamC;

                    app.x_lam = interp1(lambdaC,xC,lamC).*dlamC; app.x_lam(isnan(app.x_lam)) = 0;
                    app.y_lam = interp1(lambdaC,yC,lamC).*dlamC; app.y_lam(isnan(app.y_lam)) = 0;
                    app.z_lam = interp1(lambdaC,zC,lamC).*dlamC; app.z_lam(isnan(app.z_lam)) = 0;

                    [lambda_i, ENERGY] = illuminant('D65');
                    app.Energy_i = interp1(lambda_i,ENERGY,lamC); app.Energy_i(isnan(app.Energy_i)) = 0;

                    app.calibratedRGBAvailable = true;
                catch
                    app.calibratedRGBAvailable = false;
                end
            else
                app.calibratedRGBAvailable = false;
            end
        end

        function [dataCube, lambdaCur] = activeSpectralData(app)
            % Returns the cube and wavelength axis to use for spectral
            % extraction (ROI/pixel spectra), accounting for the
            % current hypercube-derivative setting.
            if app.derivative_flag == 0
                dataCube = app.Hyperspectrum_cube;
            else
                dataCube = app.Hypercube_derivative;
            end
            lambdaCur = app.currentLambda;
        end

        function recomputeDerivative(app)
            switch app.derivative_flag
                case 1
                    app.Hypercube_derivative = diff(abs(app.Hyperspectrum_cube),1,3);
                    app.currentLambda = app.lambda_nm(1:end-1);
                    app.currentFrReal = app.fr_real(1:end-1);
                case 2
                    app.Hypercube_derivative = diff(abs(app.Hyperspectrum_cube),2,3);
                    app.currentLambda = app.lambda_nm(1:end-2);
                    app.currentFrReal = app.fr_real(1:end-2);
                otherwise
                    app.Hypercube_derivative = [];
                    app.currentLambda = app.lambda_nm;
                    app.currentFrReal = app.fr_real;
            end

            if app.derivative_flag ~= 0
                app.Intens_der = sum(abs(app.Hypercube_derivative),3);
            else
                app.Intens_der = [];
            end
        end

        function closeFigures(~, figs)
            for k = 1:numel(figs)
                if isvalid(figs(k))
                    close(figs(k));
                end
            end
        end

        function dispImg = computeDisplayImage(app)
            app.maxImage = max(app.ImmagineRGB(:));
            if app.maxImage == 0
                app.maxImage = 1;
            end
            dispImg = (abs(app.ImmagineRGB./app.maxImage - app.blackLevel)/app.saturationLevel).^app.gammaVal;
            dispImg = max(min(dispImg,1),0);
        end

        function updateImageDisplay(app)
            dispImg = app.computeDisplayImage();

            if isempty(app.ImageHandle) || ~isvalid(app.ImageHandle)
                cla(app.ImageAxes);
                app.ImageHandle = image(app.ImageAxes, dispImg);
                axis(app.ImageAxes,'equal');
                app.ImageAxes.YDir = 'reverse';
                app.ImageHandle.ButtonDownFcn = @(~,evt) app.imageClicked(evt);
                box(app.ImageAxes,'on');
            else
                app.ImageHandle.CData = dispImg;
            end

            app.applyAxesCoordinates();
        end

        function applyAxesCoordinates(app)
            if isempty(app.ImageHandle) || ~isvalid(app.ImageHandle)
                return
            end

            % Keep the image's data coordinates equal to pixel indices
            % (1..b, 1..a) so that ROI drawing, createMask, and
            % pixel-click coordinates remain correct. Custom axes are
            % shown purely via tick labels.
            app.ImageHandle.XData = [1, app.b];
            app.ImageHandle.YData = [1, app.a];
            app.ImageAxes.XLimMode = 'auto';
            app.ImageAxes.YLimMode = 'auto';

            if app.useCustomAxes && numel(app.customXVec) == app.b && numel(app.customYVec) == app.a
                numXTicks = min(6, app.b);
                xTickPos = unique(round(linspace(1, app.b, numXTicks)));
                app.ImageAxes.XTick = xTickPos;
                app.ImageAxes.XTickLabel = arrayfun(@(p) sprintf('%.3g',app.customXVec(p)), xTickPos, 'UniformOutput', false);

                numYTicks = min(6, app.a);
                yTickPos = unique(round(linspace(1, app.a, numYTicks)));
                app.ImageAxes.YTick = yTickPos;
                app.ImageAxes.YTickLabel = arrayfun(@(p) sprintf('%.3g',app.customYVec(p)), yTickPos, 'UniformOutput', false);

                xlabel(app.ImageAxes, app.customXLabel);
                ylabel(app.ImageAxes, app.customYLabel);
            else
                app.ImageAxes.XTick = [];
                app.ImageAxes.YTick = [];
                xlabel(app.ImageAxes, '');
                ylabel(app.ImageAxes, '');
            end
        end

        function clearSpectrumPlots(app)
            % Delete every tracked plotted object (lines, shaded
            % std-dev patches, RGB filter curves) explicitly by handle.
            for k = 1:numel(app.SpectrumPlotHandles)
                h = app.SpectrumPlotHandles(k);
                if isvalid(h)
                    delete(h);
                end
            end
            app.SpectrumPlotHandles = gobjects(1,0);

            for k = 1:numel(app.NormSpectrumPlotHandles)
                h = app.NormSpectrumPlotHandles(k);
                if isvalid(h)
                    delete(h);
                end
            end
            app.NormSpectrumPlotHandles = gobjects(1,0);

            % Fallback: remove anything else left on the axes
            delete(app.SpectrumAxes.Children);
            delete(app.NormSpectrumAxes.Children);

            hold(app.SpectrumAxes,'on');
            hold(app.NormSpectrumAxes,'on');
            grid(app.SpectrumAxes,'on');
            grid(app.NormSpectrumAxes,'on');

            title(app.SpectrumAxes,'Spectra for selected regions');
            ylabel(app.SpectrumAxes,'Intensity [arb.un.]');
            xlabel(app.SpectrumAxes, app.LabelX);

            title(app.NormSpectrumAxes,'Spectra normalised to the area');
            ylabel(app.NormSpectrumAxes,'Intensity [norm.]');
            xlabel(app.NormSpectrumAxes, app.LabelX);

            app.num_spectrum = 0;
            app.Spectrum_subAve = [];
            app.Spectrum_subStd = [];

            % Delete tracked ROI objects (drawpolygon/drawrectangle)
            for k = 1:numel(app.RoiHandles)
                h = app.RoiHandles{k};
                if isvalid(h)
                    delete(h);
                end
            end
            app.RoiHandles = {};

            % Delete tracked pixel-spectrum markers
            for k = 1:numel(app.PixelMarkerHandles)
                h = app.PixelMarkerHandles(k);
                if isvalid(h)
                    delete(h);
                end
            end
            app.PixelMarkerHandles = matlab.graphics.chart.primitive.Line.empty;

            % Fallback: remove any remaining ROI overlays / lines on the
            % image axes that were not tracked above. findall (not
            % findobj) is needed because ROI objects have
            % HandleVisibility set to 'off'.
            leftoverRois = findall(app.ImageAxes,'-isa','images.roi.ROI');
            delete(leftoverRois);
            leftoverLines = findall(app.ImageAxes,'Type','line');
            delete(leftoverLines);

            % Force a full repaint of the spectrum axes - deleting
            % objects from a UIAxes does not always trigger an
            % immediate visual refresh.
            app.SpectrumAxes.Visible = 'off';
            app.SpectrumAxes.Visible = 'on';
            app.NormSpectrumAxes.Visible = 'off';
            app.NormSpectrumAxes.Visible = 'on';
            drawnow;

            % Re-apply labels/titles/grid, since toggling Visible can
            % reset some axes decorations.
            hold(app.SpectrumAxes,'on');
            hold(app.NormSpectrumAxes,'on');
            grid(app.SpectrumAxes,'on');
            grid(app.NormSpectrumAxes,'on');
            title(app.SpectrumAxes,'Spectra for selected regions');
            ylabel(app.SpectrumAxes,'Intensity [arb.un.]');
            xlabel(app.SpectrumAxes, app.LabelX);
            title(app.NormSpectrumAxes,'Spectra normalised to the area');
            ylabel(app.NormSpectrumAxes,'Intensity [norm.]');
            xlabel(app.NormSpectrumAxes, app.LabelX);
        end

        function addSpectrumToPlots(app, specAve, specStd)
            app.num_spectrum = app.num_spectrum + 1;
            idx = mod(app.num_spectrum-1,8)+1;
            col = app.mm(idx,:);

            x = app.currentLambda(:);
            y = specAve(:);
            e = specStd(:);

            xconf = [x; flipud(x)];
            yconf = [y+e; flipud(y-e)];
            hFill = fill(app.SpectrumAxes, xconf, yconf, col, ...
                'FaceAlpha',0.2,'EdgeAlpha',0,'HandleVisibility','off');
            hLine = plot(app.SpectrumAxes, x, y,'LineWidth',2,'Color',col);
            app.SpectrumPlotHandles(end+1) = hFill;
            app.SpectrumPlotHandles(end+1) = hLine;

            areaNorm = trapz(y);
            if areaNorm == 0
                areaNorm = 1;
            end
            hNorm = plot(app.NormSpectrumAxes, x, y/areaNorm,'LineWidth',2,'Color',col);
            app.NormSpectrumPlotHandles(end+1) = hNorm;

            app.Spectrum_subAve(:,app.num_spectrum) = y;
            app.Spectrum_subStd(:,app.num_spectrum) = e;
        end

        function cubeOut = spatialBin(app, cube, binSize)
            binSize = round(binSize);
            if binSize <= 1
                cubeOut = cube;
                return
            end
            H = ones(binSize);
            normMat = imfilter(ones(app.a,app.b), H);
            normMat = repmat(normMat,[1 1 app.cc]);
            cubeOut = imfilter(cube, H) ./ normMat;
        end

        function exportSpectrumFigures(app, outFile)
            % Re-create the image and the two spectrum plots in a
            % standard (non-UI) figure and export that. exportgraphics
            % on a uifigure can produce a blank/white image, so this is
            % more reliable.

            figTemp = figure('Visible','off','Color','w','Position',[100 100 1600 500]);

            ax0 = subplot(1,3,1,'Parent',figTemp);
            app.copyImageAxesContent(app.ImageAxes, ax0);

            ax1 = subplot(1,3,2,'Parent',figTemp);
            app.copyAxesContent(app.SpectrumAxes, ax1);

            ax2 = subplot(1,3,3,'Parent',figTemp);
            app.copyAxesContent(app.NormSpectrumAxes, ax2);

            exportgraphics(figTemp, outFile, 'Resolution',150);
            close(figTemp);
        end

        function copyImageAxesContent(~, srcAx, destAx)
            % Copy the image and any pixel markers (but not ROI overlay
            % objects, which cannot be copied across figures) to destAx.
            children = srcAx.Children;
            if ~isempty(children)
                keep = arrayfun(@(h) ~isa(h,'images.roi.ROI'), children);
                copyable = children(keep);
                if ~isempty(copyable)
                    copyobj(copyable, destAx);
                end
            end
            destAx.XLim = srcAx.XLim;
            destAx.YLim = srcAx.YLim;
            axis(destAx,'equal');
            destAx.YDir = 'reverse';
            destAx.XTick = [];
            destAx.YTick = [];
            title(destAx, srcAx.Title.String, 'Interpreter','none');
            box(destAx,'on');
        end

        function copyAxesContent(~, srcAx, destAx)
            if ~isempty(srcAx.Children)
                copyobj(srcAx.Children, destAx);
            end
            destAx.XLim = srcAx.XLim;
            destAx.YLim = srcAx.YLim;
            title(destAx, srcAx.Title.String);
            xlabel(destAx, srcAx.XLabel.String);
            ylabel(destAx, srcAx.YLabel.String);
            grid(destAx,'on');
            box(destAx,'on');
        end
    end

    % ---------------------------------------------------------------
    % File readers (translated from the original script's local functions)
    % ---------------------------------------------------------------
    methods (Static, Access = private)

        function p = localPercentile(data, pct)
            s = sort(data);
            n = numel(s);
            idx = max(1, min(n, round(pct/100*n)));
            p = s(idx);
        end

        function [cube,f,satMap,file_totCal,fr_real,Intens] = MATHypercubeRead(file_tot)
            input_data = load(file_tot);

            cube = input_data.Hyperspectrum_cube;

            if isfield(input_data,'f')
                f = input_data.f;
            else
                f = 1:size(cube,3);
            end

            if isfield(input_data,'fr_real')
                fr_real = input_data.fr_real;
            else
                fr_real = [];
            end

            if isfield(input_data,'file_totCal')
                file_totCal = input_data.file_totCal;
            else
                file_totCal = [];
            end

            if isfield(input_data,'saturationMap')
                satMap = input_data.saturationMap;
            else
                satMap = ones(size(cube,1),size(cube,2));
            end

            cube(isnan(cube)) = 0;

            if isa(cube,'uint16')
                maximum = input_data.maximum;
                minimum = input_data.minimum;
                cube = double(cube)./(2.^16-1).*maximum + minimum;
            elseif isa(cube,'single')
                cube = double(cube);
            end

            if size(cube,3) == 2*numel(f)
                half = size(cube,3)/2;
                cube_real = cube(:,:,1:half);
                cube_imag = cube(:,:,half+1:end);
                cube = cube_real + 1i.*cube_imag;
            end

            if isfield(input_data,'Intens')
                Intens = input_data.Intens;
            else
                Intens = [];
            end
        end

        function [cube,f,satMap,file_totCal,fr_real,Intens] = H5HypercubeRead(filename)
            % Translated from HyperspectralAnalysis_Spectrum.m / H5HypercubeRead

            info = h5info(filename);

            if isempty(cell2mat({info.Datasets}))
                file_totCal = [];
            else
                H5_datasets_list = cell2mat({info.Datasets.Name});
                if contains(H5_datasets_list,'file_totCal')
                    file_totCal = cell2mat(h5read(filename,'/file_totCal'));
                else
                    file_totCal = [];
                end
            end

            info_datasets = h5info(filename,'/SpectralHypercube');
            H5_variables_list = cell2mat({info_datasets.Datasets.Name});

            cube = h5read(filename,'/SpectralHypercube/Hyperspectrum_cube');

            if contains(H5_variables_list,'f')
                f = h5read(filename,'/SpectralHypercube/f');
            else
                f = (1:size(cube,3))';
            end

            if contains(H5_variables_list,'saturationMap')
                satMap = h5read(filename,'/SpectralHypercube/saturationMap');
            else
                satMap = ones(size(cube,1),size(cube,2));
            end

            if contains(H5_variables_list,'fr_real')
                fr_real = h5read(filename,'/SpectralHypercube/fr_real');
            else
                fr_real = [];
            end

            if contains(H5_variables_list,'Intens')
                Intens = h5read(filename,'/SpectralHypercube/Intens');
            else
                Intens = [];
            end

            if contains(H5_variables_list,'minimum')
                minimum = h5read(filename,'/SpectralHypercube/minimum');
            else
                minimum = [];
            end

            if contains(H5_variables_list,'maximum')
                maximum = h5read(filename,'/SpectralHypercube/maximum');
            else
                maximum = [];
            end

            if isa(cube,'uint16')
                cube = double(cube)./(2.^16-1).*maximum + minimum;
            elseif isa(cube,'single')
                cube = double(cube);
            end

            if size(cube,3) == 2*numel(f)
                half = size(cube,3)/2;
                cube_real = cube(:,:,1:half);
                cube_imag = cube(:,:,half+1:end);
                cube = cube_real + 1i.*cube_imag;
            end
        end

        function [cube,f,satMap,file_totCal,fr_real,Intens] = MJ2HypercubeRead(filename)
            % Translated from HyperspectralAnalysis_Spectrum.m / MJ2HypercubeRead

            obj = VideoReader(filename); %#ok<TNMLP>

            S = load([filename(1:end-4) '_VALUES.mat']);

            if isfield(S,'f')
                f = S.f;
            else
                f = [];  % filled after cube is read
            end

            if isfield(S,'saturationMap')
                satMap = S.saturationMap;
            else
                satMap = [];
            end
            if isfield(S,'file_totCal')
                file_totCal = S.file_totCal;
            else
                file_totCal = [];
            end
            if isfield(S,'fr_real')
                fr_real = S.fr_real;
            else
                fr_real = [];
            end
            if isfield(S,'Intens')
                Intens = S.Intens;
            else
                Intens = [];
            end
            if isfield(S,'minimum')
                minimum = S.minimum;
            else
                minimum = [];
            end
            if isfield(S,'maximum')
                maximum = S.maximum;
            else
                maximum = [];
            end

            images = obj.read; %#ok<NASGU>
            cube = double(squeeze(images(:,:,1,:)))./(2.^16-1).*maximum + minimum;
            clear images

            if isempty(f)
                f = (1:size(cube,3))';
            end

            if size(cube,3) == 2*numel(f)
                half = size(cube,3)/2;
                cube_real = cube(:,:,1:half);
                cube_imag = cube(:,:,half+1:end);
                cube = cube_real + 1i.*cube_imag;
            end
        end
    end
end

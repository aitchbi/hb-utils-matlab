function [hf,Boundary] = hb_surfplot(x,hemi,atlas,varargin)
% HB_SURFPLOT plot data on cortical surface; an extended wrapper of a
% modified version of https://github.com/StuartJO/plotSurfaceROIBoundary;
% see dependencies below.
%
% *******************************************************
% ***** "preliminary" help; not accurate & thorough *****
% *******************************************************
%
% Inputs: 
%   x: data to plot on left or right hemisphere. 
%
%   hemi: hemisphere, left ('lh') or right ('rh')
%
%   atlas: atlas e.g. 'Schaefer200Yeo17', 'Glasser360', 'Yeo7', ...
%
%   Name-Value Pair Arguments (optional): 
%
%   FSavgDir: absolute path to fsaverage_hb folder. 
%
%   FSMatlabDir: absolute path to freesurfer/matlab folder. 
%
%   PSROIBDir: absolute path to plotSurfaceROIBoundary_modified.
%
%   BoundaryType: 'faces' 'midpoint' 'centroid' 'edge_vertices' 'none'
%
%   BoundaryAtlas: 
%
%   BoundaryEdgeColor: 1x3 vector, with values within [0 1].
%
%   BoundaryEdgeLineWidth: a scalar.
%
%   WhichSurf: 'pial' | 'white' | 'inflated'  
%   
%   PlotLabel: character array; label for plot, to be displayed with the
%   colorbar.
%
%   Colormap: Nx3 matrix, with values within [0 1].
%
%   ColorbarTicks: ... e.g. to show Yeo7 networks
%
%   ColorbarTickLabels: ... % e.g. to show Yeo7 networks
%
%   FigureHandle:
%
%   DataRange: either a 1x2 vector or []. If the specified range values
%   fall "within" the range of the actual data, the data outside this range
%   will be saturated. If specified range values fall "outside" actual data
%   range, only the colormap limits will be broader (e.g. to make colormap
%   symmetric around zero in case of +/- values).
%
%   CamLight: [], 'none'
%
%   CamView: [] or struct with fields "left" & "right" (each a 1x2 numeric)
%
% Outputs:
%   h: handles: figure, axes, plots, and colorbar. 
%
% Examples:
% 
%
% Dependencies: 
% .https://github.com/aitchbi/matlab-utils/misc/plotSurfaceROIBoundary_modified
% .https://github.com/aitchbi/matlab-utils/hb_get_atlasinfo.m
% ...
%
% Hamid Behjat

%-Process inputs.
opts = processinputs(varargin,inputParser);

%-Process surface data.
[x, surf, labels] = processsurfdata(x,hemi,atlas,opts);

%-Make plot.
[hf,POS]  = initfig(opts,hemi);
hf.ax{1}  = axes('Position',POS.Plot1);
if isempty(opts.Boundary)
    [hf.plt{1}, opts.Boundary] = doplot(x, surf, labels, hemi, opts, 'lateral');
else
    hf.plt{1} = doplot(x, surf, labels, hemi, opts, 'lateral');
end
hf.ax{2}  = axes('Position',POS.Plot2);
hf.plt{2} = doplot(x, surf, labels, hemi, opts, 'medial');
hf = docolors(opts, x, hf, POS);
dotitle(hemi, opts, hf);
Boundary = opts.Boundary;
end

%==========================================================================
function opts = processinputs(optinputs,inparser)
d_func = fileparts(mfilename('fullpath'));
d = fullfile(d_func,'external','freesurfer','fsaverage_hb');
if exist(d, 'dir')
    d_fsavghb = d;
else
    d_fsavghb = [];
end
d = fullfile(d_func,'external','freesurfer','matlab');
if exist(d, 'dir')
    d_fsmatlab = d;
else
    d_fsmatlab = [];
end
d = fullfile(d_func,'external','plotSurfaceROIBoundary_modified');
if exist(d, 'dir')
    d_psroib = d;
else
    d_psroib = [];
end

d = inparser;
addParameter(d,'FSavgDir', d_fsavghb);
addParameter(d,'FSMatlabDir', d_fsmatlab);
addParameter(d,'PSROIBDir', d_psroib);
addParameter(d,'BoundaryType', 'midpoint');
addParameter(d,'BoundaryAtlas', []);
addParameter(d,'BoundaryEdgeColor', [0 0 0]);
addParameter(d,'BoundaryEdgeLineWidth', 1);
addParameter(d,'WhichSurf', 'inflated'); 
addParameter(d,'SkipAssertionChecks', false);
addParameter(d,'PlotLabel', 'none');
addParameter(d,'Colormap', turbo(256));
addParameter(d,'OneColorbar', true);
addParameter(d,'ColorbarTickLabels', []); % applicable if ColorbarTicks is a vector
addParameter(d,'ColorbarTicks', []); % a vector, 'none', or [] ([]: default ticks)
addParameter(d,'FigureHandle', []);
addParameter(d,'DoublePlot', []);
addParameter(d,'DataRange', []);
addParameter(d,'CamLight', []);
addParameter(d,'CamView', []); 
addParameter(d,'ShowLeftRightHemisphereTitle', true); 
addParameter(d,'Boundary', []); 
parse(d,optinputs{:});
opts = d.Results;

if not(isempty(opts.FSMatlabDir))
    addpath(opts.FSMatlabDir);
end
end

%==========================================================================
function [x,surf,lbls] = processsurfdata(x,hemi,atlas,opts)

if isempty(opts.BoundaryAtlas)
    atlas_b = atlas; 
else
    %error('BoundaryAtlas input option yet to be fixed.');
    atlas_b = opts.BoundaryAtlas; 
end
[surf,lbls] = hb_get_surfatlas(atlas_b, hemi, ...
    opts.FSavgDir, ...
    opts.WhichSurf, ...
    'SkipAssertionChecks', opts.SkipAssertionChecks);

if not(isempty(opts.DataRange))
    r = opts.DataRange;
    x(x<r(1)) = r(1); % saturate values below given range
    x(x>r(2)) = r(2); %              .. above ..
end
if isvector(x)
    x = x(:);
else
    error('debug/extend.');
end
if ~isequal(atlas,atlas_b)
    [~,lbls_data,Nr_hemi] = hb_get_surfatlas(atlas,hemi, ...
    opts.FSavgDir, ...
    opts.WhichSurf, ...
    'SkipAssertionChecks', opts.SkipAssertionChecks);
    xx = zeros(size(lbls_data));
    for iR=1:Nr_hemi
        xx(lbls_data==iR) = x(iR);
    end
    x = xx(:);
end

end
%==========================================================================
function dotitle(hemi,opts,hf)
if opts.ShowLeftRightHemisphereTitle
    switch hemi
        case 'lh'
            d = 'left hemisphere';
        case 'rh'
            d = 'right hemisphere';
    end
    if isempty(opts.DoublePlot)
        text(hf.ax{1}.XLim(2),hf.ax{1}.YLim(2),d)
    else
        switch opts.DoublePlot
            case 'top-bottom'
                title(hf.ax{2}, d);
            case 'left-right'
                title(hf.ax{1}, d, 'FontSize',13);
            case 'one-row'
                blank = repmat(' ',1,68);
                switch hemi
                    case 'lh'
                        d = [d, blank];
                    case 'rh'
                        d = [blank, d];
                end
                title(hf.ax{1}, d, 'FontSize',13);

                % Below I tried to place title as text between the two views.. 
            % but it didn't work.
            % x-position is correct but y-position becomes center not top
            %
            %case 'one-row'
            %    xl = xlim(hf.ax{1});
            %    xr = xl(2)-xl(1);
            %    x_txt = xl(1)-0.05*xr;
            %    yl = ylim(hf.ax{1});
            %    yr = yl(2)-yl(1);
            %    y_txt = yl(2)-0.01*yr;
            %    text(hf.ax{1}, x_txt, y_txt, d, ...
            %        'HorizontalAlignment', 'center', ...
            %        'FontSize',13);
        end
    end
end
end

%==========================================================================
function hf = docolors(opts,x,hf,POS)
opts.Colormap(opts.Colormap<0) = 0;
opts.Colormap(opts.Colormap>1) = 1;
colormap(opts.Colormap);
if isempty(opts.DataRange)
    assert(nnz(isnan(x))==0, 'Data contains NaNs.')
    %caxis([nanmin(x(:,1)) nanmax(x(:,1))]);
    if min(x)~=max(x)
        caxis([double(min(x)) double(max(x))]); % double(.) since might be logical
    end
else
    caxis(opts.DataRange);
end
hf.c = colorbar('Location','southoutside');
set(hf.c, 'Position',POS.Cbar, 'FontSize',13);
if not(strcmp(opts.PlotLabel,'none'))
    hf.c.Label.String = opts.PlotLabel;
end
if not(isempty(opts.ColorbarTicks))
    if strcmp(opts.ColorbarTicks, 'none')
        hf.c.Ticks = [];
    else
        assert(isvector(opts.ColorbarTicks));
        hf.c.Ticks = opts.ColorbarTicks;
        if not(isempty(opts.ColorbarTickLabels))
            assert(length(opts.ColorbarTickLabels)==length(opts.ColorbarTicks));
            hf.c.TickLabels = opts.ColorbarTickLabels;
        end
    end
end
end

%==========================================================================
function [h,POS] = initfig(opts,hemi)
h = struct;
if isempty(opts.FigureHandle)
    h.fig = figure;
    set(h.fig,'Position',[461 462 650 300]);
else
    h.fig = opts.FigureHandle;
end
h.ax  = cell(1,2);
h.plt = cell(1,2);

POS = getpositions(opts,hemi);
end

%==========================================================================
function POS = getpositions(opts,hemi)

if isempty(opts.DoublePlot)
    P1 = [0.005 0.33 0.49 0.66];
    P2 = [0.505 0.33 0.489 0.66];
    C  = [0.2 0.2 0.8 0.05];
else
    switch opts.DoublePlot
        case 'one-row'
            switch hemi
                case 'lh'
                    PlotLeft1 = 0.25;
                    PlotLeft2 = 0.005;
                case 'rh'
                    PlotLeft1 = 0.505;
                    PlotLeft2 = 0.75;
            end
            PlotBottom = 0.26;
            P1 = [PlotLeft1 PlotBottom 0.24 0.65];
            P2 = [PlotLeft2 PlotBottom 0.24 0.65];
            if opts.OneColorbar
                CbarLeft  = 0.3;
                CbarWidth = 0.4;
            else
                switch hemi
                    case 'lh'
                        CbarLeft = 0.05;
                    case 'rh'
                        CbarLeft = 0.55;
                end
                CbarWidth = 0.4;
            end
            CbarBottom = 0.17;
            C = [CbarLeft CbarBottom CbarWidth 0.04];

        case 'left-right'
            switch hemi
                case 'lh'
                    PlotLeft = 0.005;
                case 'rh'
                    PlotLeft = 0.505;
            end
            P1 = [PlotLeft 0.57 0.49 0.33];
            P2 = [PlotLeft 0.17 0.49 0.33];
            if opts.OneColorbar
                CbarLeft  = 0.1;
                CbarWidth = 0.8;
            else
                switch hemi
                    case 'lh'
                        CbarLeft = 0.05;
                    case 'rh'
                        CbarLeft = 0.55;
                end
                CbarWidth = 0.4;
            end
            C = [CbarLeft 0.1 CbarWidth 0.02];

        case 'top-bottom'
            error('debug/extend.');
            switch hemi
                case 'lh'
                    PlotB = 0.57;
                    CbarB = 0.6;
                case 'rh'
                    PlotB = 0.17;
                    CbarB  = 0.1;
            end
            P1 = [0.005 PlotB 0.49 0.33];
            P2 = [0.505 PlotB 0.49 0.33];
            C = [0.2 CbarB 0.8 0.02];
    end
end
POS = struct;
POS.Plot1 = P1;
POS.Plot2 = P2;
POS.Cbar  = C;
end

%==========================================================================
function [hp,Boundary] = doplot(x, surf, labels, hemi, opts, WhichView)
if ~isfield(opts, 'Boundary')
    opts.Boundary = [];
end
[hp,~,d] = plotSurfaceROIBoundary_hb(...
    surf,...
    labels,...
    x,...
    opts.BoundaryType,...
    opts.Colormap,...
    'BoundaryEdgeLineWidth',opts.BoundaryEdgeLineWidth,...
    'BoundaryEdgeColor',opts.BoundaryEdgeColor,...
    'ColorbarLimits',opts.DataRange,...
    'Boundary',opts.Boundary);
if isempty(opts.Boundary)
    Boundary = d;
else
    Boundary = opts.Boundary;
end
if isempty(opts.CamLight)
    camlight(80,-10);
    camlight(-80,-10);
elseif isequal(opts.CamLight, 'none')

else
    error('extend');
end
switch WhichView
    case 'lateral'
        a1 = -90;
        a2 = 90;
        lr = 'left';
    case 'medial'
        a1 = 90;
        a2 = -90;
        lr = 'right';
end
if isempty(opts.DoublePlot)
    if isempty(opts.CamView)
        view([a1 0])
    else
        view(opts.CamView.(lr))
    end
else
    switch opts.DoublePlot
        case 'top-bottom'
            if isempty(opts.CamView)
                view([a1 0])
            else
                view(opts.CamView.(lr))
            end
        case {'left-right', 'one-row'}
            switch hemi
                case 'lh'
                    if isempty(opts.CamView)
                        view([a1 0])
                    else
                        view(opts.CamView.(lr))
                    end
                case 'rh'
                    if isempty(opts.CamView)
                        view([a2 0])
                    else
                        view(opts.CamView.(lr))
                    end
            end
    end
end
axis image
axis off
end

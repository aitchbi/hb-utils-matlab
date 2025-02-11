function [S, f_reg, f_load] = hb_nii2gsig(f, G, varargin)
% HB_NII2GSIG extract graph signal from given input nifti file.
%
% Inputs:
%   f: full path of nifti file
%   G: graph structure with fields indices etc.
%
%   Name-Value Pair Arguments:
%   GraphRefNii: if fields .dim and .mat not given in G, specify a
%   reference file which is in register with the space in which the graph
%   was defined (T1wSPace or DiffusionSpace depending on the graph);
%   typically the G.f.mask/source file.
%
%   BypassRegistrationVerification: logical (true or false; default:
%   false). If you are sure f and G are in register, set to true to bypass
%   verification.
%
%   ResliceNiiIfNotInRegisterWithG: logical (true or false; default:
%   false). If set to true, GraphRefNii should also be set, in which case f
%   will be resliced to match the space in which G was defiend
%   (GraphRefNii). The resliced file (f_reg) is returned, which is best to
%   be be verified.
%
%   WhichFrames: a 1 X F vector of indices, where F denotes the 4th
%   dimension of an input nifti; if input is a 3D nifti, WhichFrames is not
%   applicable. The indices specify which frames to extract graph signals
%   from. By default a graph signal is extracted from all frames, i.e.,
%   WhichFrames = 1:length(spm_vol(f)).
%
% Outputs:
%   S: graph signals, one per column.
%   f_reg: the registered version if f, if applicable, otherwise [].  
%
% Examples:
%-standard call, regiter between f & G verified via fileds dim & mat in G:
% S = hb_nii2gsig(f, G);
%
%-bypass verifying whether or not f & G are in register:
% S = hb_nii2gsig(f, G, 'BypassRegistrationVerification', true);
% This is helpful e.g. if you are sure f & G are in register, and G does
% not contain both required fields for verification; and you don't have
% GraphRefNii.
%
%-verify whether or not f & f_ref (graph ref nii) are in register:
% [S, f_reg] = hb_nii2gsig(f, G, 'GraphRefNii', f_ref);
%
%-not only verify, but also ensure (reslice) if needed:
% [S, f_reg] = hb_nii2gsig(f, G, 'GraphRefNii', f_ref, 'ResliceNiiIfNotInRegisterWithG', true);
%
%-just some of the frames:
% S = hb_nii2gsig(f, G, 'WhichFrames', [1:10, 90:100]);
%
% Dependencies:
% . SPM12 package
% . hb_nii_load.m
% . etc.
%
% Hamid Behjat

%-Process inputs.
[opts, CleanUp] = processinputs(f,G,varargin,inputParser);

%-Verify f & G are in register.
[f_load, f_reg, I] = verifyregist(f, G, opts);

%-Extract gsigs.
S = extractgsigs(f_load, I, opts);

%-Cleanup.
docleanup(f,CleanUp);
end

%==========================================================================
function [opts,CleanUp] = processinputs(f,G,varinputs,p)
if endsWith(f, '.gz')
    fgz = f;
    f = strrep(f, '.nii.gz', '.nii');
else
    fgz = [f, '.gz'];
end
if exist(f, 'file')
    CleanUp = false;
else
    if exist(fgz, 'file')
        gunzip(fgz);
        CleanUp = true;
    else
        error('file not found');
    end
end
assert(isfield(G,'indices'));
funcLogi = @(x) assert(islogical(x));
funcPath = @(x) assert(ischar(x) || isempty(x));
funcNumb = @(x) assert(isnumeric(x) || ismember(x, [0 1]));
funcVect = @(x) assert(isnumeric(x) || isvector(x));
addParameter(p, 'GraphRefNii', [], funcPath);
addParameter(p, 'BypassRegistrationVerification', false, funcLogi);
addParameter(p, 'ResliceNiiIfNotInRegisterWithG', false, funcLogi);
addParameter(p, 'ResliceInterpolationOrder', 1, funcNumb);
addParameter(p, 'WhichFrames', [], funcVect);
parse(p,varinputs{:});
opts = p.Results;
end

%==========================================================================
function [f_load, f_reg, I] = verifyregist(f, G, opts)
if opts.BypassRegistrationVerification
    f_reg = [];
    f_load = f;
else
    h_f = spm_vol([f, ',1']);
    if not(isempty(opts.GraphRefNii))
        h_G = spm_vol(hb_gunzip(opts.GraphRefNii));
    else
        h_G = struct;
        h_G.dim = G.dim;
        h_G.mat = G.mat;
    end
    chk1 = not(isequal(h_f.dim, h_G.dim));
    chk2 = not(all(abs(h_f.mat-h_G.mat)<1e-6,'all'));
    if any([chk1, chk2])
        if opts.ResliceNiiIfNotInRegisterWithG
            fprintf('\n..Reslicing input to match G..');
            ord = opts.ResliceInterpolationOrder;
            f_reg = hb_nii_reslice(f, opts.GraphRefNii, ord);
            f_load = f_reg;
        else
            errmsg = 'File not in register with space of graph.';
            error(errmsg);
        end
    else
        f_reg = [];
        f_load = f;
    end
end
I = G.indices;
end

%==========================================================================
function S = extractgsigs(f_load,I,opts)
h = spm_vol(f_load);
Nv = length(h);
if isempty(opts.WhichFrames)
    frames = 1:Nv;
else
    frames = opts.WhichFrames;
end
Nf = length(frames);
assert(Nf<=Nv);
assert(all(ismember(frames,1:Nv)));
v = hb_nii_load(f_load, 'IndicesToLoad', I, 'FramesToLoad',frames);
Ng = length(I);
S = zeros(Ng, Nf);
for iF=1:Nf
    if iF==1 && Nv==1
        d = v;
    else
        if Nf>1
            showprgs(iF, Nf, 'Extracting graph signals..');
        end
        d = v(:,:,:,iF);
    end
    S(:,iF) = d(I) ;
end
end

%==========================================================================
function docleanup(f,CleanUp)
if CleanUp
    delete(f);
end
end

%==========================================================================
function showprgs(n,N,tag)
l = numel(num2str(N));
if n==1
    fprintf('\n..%s ',tag);
else
    fprintf(repmat('\b',1,2*l+1),n);
end
eval(['fprintf(''%-',num2str(l),'d/%-',num2str(l),'d'',n,N)'])
end
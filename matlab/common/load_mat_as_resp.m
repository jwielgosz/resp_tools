function [ EKG ] = load_mat_as_resp(varargin)
% EKG_with_timeseries Adds a timeseries object for resp belt data
% Arg 1: raw EKG matfile
% Arg 2: quality-checked EKG matfile, created by quality_flags()

switch nargin
    case 0
        
        help load_mat_as_resp
        error 'No matfile specified'
        
    case 1
        matfile = varargin{1};
        qualfile = '';

    case 2
        matfile = varargin{1};
        resp_channel = varargin{2};
        qualfile = '';
        
    case 3
        matfile = varargin{1};
        resp_channel = varargin{2};
        qualfile = varargin{3};
        
    otherwise
        error 'Too many args'
end


if exist(qualfile, 'file') % try to load quality file
    
    qf = qualfile;
    disp(['Loading quality checked file: ' qf])
    cur = load(qf);
    EKG = cur.EKG;
    
else % try to load original matfile
    
    cur = load(matfile);
    
    if isfield(cur, 'EKG')
        
        disp(['Loading processHRV output: ' matfile])
        EKG = init_processHRV(cur, matfile);
        
    elseif isfield(cur, 'channels')
        
        disp(['Loading acq2mat file: ' matfile])
        EKG = init_acq2mat(cur, matfile, resp_channel);
        
    else
        
        disp(['Dont'' know what to do with matfile. Must be output from'
            ' either acq2mat or processHRV']);
        
    end
    
end

end

%----------------------------------------------------------------
function EKG = init_processHRV(cur, matfile)

EKG = cur.EKG;
EKG.RSPmatfile = matfile;
EKG.RSP_ts = init_ts(EKG);
end

%----------------------------------------------------------------
function EKG = init_acq2mat(cur, matfile, resp_channel)
EKG = struct();
EKG.RSPsignal = cur.channels{resp_channel}.data;
EKG.RSPmatfile = matfile;
EKG.RSPsignal = reshape(EKG.RSPsignal, length(EKG.RSPsignal), 1);
EKG.sampRate = cur.channels{resp_channel}.samples_per_second;
EKG.RSP_ts = init_ts(EKG);
end

%----------------------------------------------------------------
function ts = init_ts(EKG)

ts = timeseries(EKG.RSPsignal, 'Name', 'Respiration belt signal');
ts = setuniformtime(ts,'Interval', 1 / EKG.sampRate);

ts = detrend(ts, 'constant');

ts.QualityInfo.Code = [0 1];
ts.QualityInfo.Description = {'good' 'bad'};
ts.Quality = zeros(1, length(EKG.RSPsignal));
end



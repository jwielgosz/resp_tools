function EKG = calc_resp_stats(EKG)
% calc_resp_stats Calculate respiration stats from a timeseries
% Uses an adaptation of the "EKG" structure 
% (holdover from Larry Greischar's processHRV()
%
% Required field:
% EKG.RSP_ts (resp signal as a 'timeseries' object)
%
% Optional fields:
% EKG

%------------------------------------------------------------------------
% Helpers

function mask = outliers(vec)
    mask = (abs(vec - nanmean(vec)) > 3 * nanstd(vec));
end

%------------------------------------------------------------------------
% Setup

% Always used
if ~isfield(EKG, 'minSecBetweenPeaks ');  EKG.minSecBetweenPeaks = 1.0;  end;

% ON by default (best settings)
if ~isfield(EKG, 'useSmoothed');          EKG.useSmoothed =     false ; end;
% if ~isfield(EKG, 'peak_outlier_std ');    EKG.peak_outlier_std   = 3;    end;
% if ~isfield(EKG, 'dropOutlierIntervals'); EKG.dropOutlierIntervals = false; end;

% OFF by default (for testing use)
%if ~isfield(EKG, 'useThreshold');         EKG.useThreshold = false; end;
if ~isfield(EKG, 'minStdForPeak');        EKG.minStdForPeak      = 1/3;  end;



RESP = EKG.RSP_ts.Data;
RESP_len = length(RESP);

%------------------------------------------------------------------------
% Get rid of bad data (don't want include in mean calculations, etc.)
RESP(EKG.RSP_ts.Quality ~= 0) = NaN;


%------------------------------------------------------------------------
% Detrend
EKG.signal_bias = nanmean(RESP);

RESP = RESP - EKG.signal_bias;

EKG.signal_std = nanstd(RESP);


%------------------------------------------------------------------------
% Calculate power spectral density over resp range, and peak
% Don't bother trying to deal with bad segments 

%RESP_full = squeeze(EKG.RSP_ts.Data);
RESP_full = EKG.RSP_ts.Data;
res = 1;
[pxx,f] = pwelch(RESP_full,[],[],round(res*length(RESP_full)),EKG.sampRate);

EKG.RSPstats.PSD.welch_pxx = pxx;
EKG.RSPstats.PSD.welch_f = f;

f_lo = 0.02;
f_hi = 1;
resp_mask = (f > f_lo) & (f < f_hi);
f_resp = f(resp_mask);
pxx_resp = pxx(resp_mask);

[max_y, max_idx] = max(pxx_resp);


EKG.RSPstats.PSD.freq_range_lo = 0.02;
EKG.RSPstats.PSD.freq_range_hi = 1;
EKG.RSPstats.PSD.peak_freq = f_resp(max_idx);

EKG.RSPstats.RR_psd = 60 * EKG.RSPstats.PSD.peak_freq;


%------------------------------------------------------------------------
% Set minimums for peaks
RESP_for_thresh = RESP(~outliers(RESP));

EKG.threshold = nanstd(RESP_for_thresh) * EKG.minStdForPeak;
EKG.minSampsBetweenPeaks = EKG.minSecBetweenPeaks * EKG.sampRate;



%% ------------------------------------------------------------------------
% Process segments individually

all_peaks = zeros(0,1);
all_trghs = zeros(0,1);
all_intvl = zeros(0,1);
all_intvl_in = zeros(0,1);
all_intvl_ex = zeros(0,1);


valid_segs = find_segments(EKG.RSP_ts.Quality, 0);
num_segs = size(valid_segs, 1);

for seg_idx = 1 : num_segs

    %--- Extract segment
    seg_start = valid_segs(seg_idx, 1);
    seg_end = valid_segs(seg_idx, 2);
    RESP_seg_orig = RESP(seg_start:seg_end);
    
    %--- Denoise
%     if EKG.useSmoothed
%         RESP_seg = wavelet_denoise_resp(RESP_seg_orig);
%     else
        RESP_seg = RESP_seg_orig;
%     end
    
    %--- Get troughs
    seg_trghs = find_peaks_thresh(RESP_seg * -1, EKG.threshold, EKG.minSampsBetweenPeaks);

    %--- Check for at least one full cycle
    if size(seg_trghs) < 2 
        continue
    end
    
    %--- Get peaks
    seg_peaks = [];
    for pk = 1:(length(seg_trghs)-1)
        start_loc = seg_trghs(pk);
        end_loc = seg_trghs(pk+1);
        [max_y, max_loc] = max(RESP_seg(start_loc:end_loc));
        seg_peaks(pk,1)  = max_loc + (start_loc - 1);
    end
    
%     trgh_start = seg_trghs(1);
%     trgh_end = seg_trghs(end);
% 
%     RESP_seg_for_peaks = RESP_seg;
%     RESP_seg_for_peaks([1:trgh_start trgh_end:end]) = 0; % make sure trgh is first & last
%     % don't know if there will be a  peak after the last trgh, so best to be consistent
%     %    RESP_seg_for_peaks([1:trgh_start]) = 0;
%     seg_peaks = find_peaks_thresh(RESP_seg_for_peaks, EKG.threshold, EKG.minSampsBetweenPeaks);

    %--- Calculate intervals
    seg_intvl = diff(seg_trghs);
    seg_intvl_in = seg_peaks - seg_trghs(1:end-1);
    seg_intvl_ex = seg_trghs(2:end) - seg_peaks;
    
    %--- Append to full recording
    % Add NaN to mark discontinuity

    seg_trghs = seg_trghs + seg_start; 
    seg_peaks = seg_peaks + seg_start;
    all_trghs = [ all_trghs ; seg_trghs ];
    all_peaks = [ all_peaks ; seg_peaks; NaN ];
    
    all_intvl = [ all_intvl ; seg_intvl; NaN ]; 
    all_intvl_in = [ all_intvl_in ; seg_intvl_in ; NaN ];
    all_intvl_ex = [ all_intvl_ex ; seg_intvl_ex ; NaN ];
    
end

% Populate stats 

all_intvl_sec = all_intvl / EKG.sampRate;

EKG.RSPstats.sampling_rate = EKG.sampRate;

EKG.RSPstats.n_sec = RESP_len / EKG.sampRate;
EKG.RSPstats.n_good_segments = num_segs;
EKG.RSPstats.pct_good = sum(EKG.RSP_ts.Quality == 0) / RESP_len;

EKG.RSPstats.n_resp_intervals = length(all_intvl(~isnan(all_intvl)));

EKG.RSPstats.peaks = all_peaks;
EKG.RSPstats.trghs = all_trghs;

EKG.RSPstats.RR_instant = 60 ./ (all_intvl_sec);
EKG.RSPstats.IE_instant = all_intvl_in ./ all_intvl_ex;

EKG.RSPstats.RR_mean = (60 / nanmean(all_intvl)) * EKG.sampRate;
EKG.RSPstats.RR_std = nanstd(EKG.RSPstats.RR_instant);
EKG.RSPstats.RR_coef_var = EKG.RSPstats.RR_std / EKG.RSPstats.RR_mean;

EKG.RSPstats.IE_ratio_mean = nanmean(all_intvl_in) / nanmean(all_intvl_ex);
EKG.RSPstats.IE_ratio_std_log10 = nanstd(log10(all_intvl_in ./ all_intvl_ex));

end







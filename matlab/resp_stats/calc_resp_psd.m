function PSD = calc_resp_psd(ts)
% Generate PSD estimate for respiration signal


%----
% Run Welch's power spectral density estimate

% By default, x is divided into the longest possible sections to
% obtain as close to but not exceed 8 segments with 50% overlap.
% Each section is windowed with a Hamming window. The modified periodograms
% are averaged to obtain the PSD estimate. If you cannot divide the length
% of x exactly into an integer number of sections with 50% overlap, x is
% truncated accordingly.

% pxx = pwelch(x,window,noverlap,nfft) specifies the number of discrete
% Fourier transform (DFT) points to use in the PSD estimate. The default
% nfft is the greater of 256 or the next power of 2 greater than the length
% of the segments.

% [pxx,f] = pwelch(___,fs) returns a frequency vector, f, in cycles per
% unit time. The sampling frequency, fs, is the number of samples per unit
% time. If the unit of time is seconds, then f is in cycles/sec (Hz). For
% real?valued signals, f spans the interval [0,fs/2] when nfft is even and
% [0,fs/2) when nfft is odd. For complex-valued signals, f spans the
% interval [0,fs).

% [___,pxxc] = pwelch(___,'ConfidenceLevel',probability) returns the
% probability × 100% confidence intervals for the PSD estimate in pxxc.

signal = ts.Data;

res = 1;
window = []; %default
%window = round(length(signal)/10);
noverlap = []; %default
nfft = round(res*length(signal));
fs = 1 / ts.TimeInfo.Increment;

[pxx,f, pxxc] = pwelch(signal,window,noverlap,nfft,fs, 'ConfidenceLevel',0.95);

%----

PSD.welch_pxx = pxx;
PSD.welch_f = f;
PSD.welch_pxxc = pxxc;
PSD.freq_range_lo = 1  / 60 ; % 1 breath / minute in Hz
PSD.freq_range_hi = 60 / 60 ; % 60 breaths / minute in Hz

resp_mask = (f > PSD.freq_range_lo) & (f < PSD.freq_range_hi);
f_resp = f(resp_mask);
pxx_resp = pxx(resp_mask);
pxxc_resp = pxxc(resp_mask,:);

[max_y, max_idx] = max(pxx_resp);

PSD.peak_freq = f_resp(max_idx);

PSD.max_95lo = pxxc_resp(max_idx);

if sum(pxx_resp>PSD.max_95lo) > 3
    [pk_val, pk_idx] = findpeaks(pxx_resp(pxx_resp>PSD.max_95lo));
    PSD.peak_n = length(pk_val);
    PSD.peak_range_hz = max(f_resp(pk_idx)) - min(f_resp(pk_idx));
else
    PSD.peak_n = 1;
    PSD.peak_range_hz = 0;
end

if (~(PSD.peak_n == 1))
    warning(sprintf('Peak confidence below 95%% (%d peaks, range %.2f)', PSD.peak_n, PSD.peak_range_hz * 60));
    %PSD.peak_freq = NaN;
end


end


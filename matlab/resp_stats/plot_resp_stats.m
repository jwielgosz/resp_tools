function plot_resp_stats(EKG)

%  Generate a detailed plot for a RESP signal processed by calc_resp_stats.m

%--- helpers

    function x = rm_nan(x)
        x = x(~isnan(x));
    end

    function cs = arr2cellstr(a, fmt) % ugh
        cs = cellfun(@(x)({num2str(x, fmt)}), num2cell(a));
    end

    function lh = horz_line(varargin)
        y = varargin{1}; color = varargin{2};
        lh = line(xlim, [y y], 'AlignVertexCenters', 'on', ...
            'Color', color, varargin{3:end});
    end

    function lh = vert_line(varargin)
        x = varargin{1}; color = varargin{2};
        lh = line([x x], ylim, 'AlignVertexCenters', 'on', ...
            'Color', color, varargin{3:end});
    end

    function rh = solid_rect(x, y, color)
       rect_px = [ min(x), min(y), max(x)-min(x), max(y)-min(y) ];
       rh = rectangle('Position',rect_px, 'FaceColor', color,'EdgeColor', 'none');
    end

    function time_axis
        xlabel('Seconds');
        xlim([0 max_x]);
        set(gca, 'XTick', 0:30:max_x);
        
    end

    function col = lighten(col, pct)
        col = ((1-col) * (pct/100)) + col;
    end    


%--- useful values

RESP = EKG.RSP_ts.Data;

x_secs = ((1:length(RESP)) - 1) ./ EKG.sampRate;
max_x = x_secs(end);

valid_mask = (EKG.RSP_ts.Quality == 0);

trgh_x_secs = rm_nan(EKG.RSPstats.trghs - 1) ./ EKG.sampRate;
peak_x_secs = rm_nan(EKG.RSPstats.peaks - 1) ./ EKG.sampRate;

ignored_mask = false(length(x_secs),1);
ignored_mask(x_secs < trgh_x_secs(1)) = true;
ignored_mask(x_secs > trgh_x_secs(end)) = true;

for p = 1:length(EKG.RSPstats.peaks)-1
    if isnan(EKG.RSPstats.peaks(p))
        ig_s = EKG.RSPstats.trghs(p);
        ig_e = EKG.RSPstats.trghs(p+1);
        ignored_mask(ig_s:ig_e) = true;
    end
end

subplot_margin = 0.05;

%--- color scheme

gray95 = [0.95, 0.95, 0.95];
gray80 = [0.8, 0.8, 0.8];
gray70 = [0.7, 0.7, 0.7];
gray60 = [0.6, 0.6, 0.6];
gray30 = [0.3, 0.3, 0.3];

parula = [ % saved here so not reliant on gca
    0         0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840
    ];

palette.signal = parula(1,:);
palette.peak = parula(2,:);
palette.trgh = parula(3,:);
palette.RR = parula(4,:);
palette.IE = parula(6,:);
palette.outlier = [1 .7 .7];
palette.ignored = lighten(palette.signal, 50);

% figure dimensions
screen_size = get(0, 'ScreenSize');
screen_width = screen_size(3);
screen_height = screen_size(4);
figure('Position',[0 screen_height screen_width screen_width])

%% ====================================================================
% (1) PLOT: SIGNAL


%subplot_tight('Position', [0 .5 .75 .5 ])
subplot_tight(4, 4, [1:3 5:7], subplot_margin)
hold on
time_axis()
set(gca, 'XGrid', 'on')

max_y = max(abs([min(RESP) max(RESP)])) * 1.1;
min_y = -1 * max_y;

ylim([min_y,max_y])
ylabel('Signal (mV)')

%--- draw x-axis
horz_line(0, gray80);

%--- draw threshold lines for peak/trgh detection
h_thresh = horz_line(EKG.threshold, gray70, 'LineStyle', '--');
horz_line(EKG.threshold * -1, gray70, 'LineStyle', '--');

%--- draw outlier lines for bad signal
signal_outlier_amp = 3 * nanstd(RESP);

h_outlier = horz_line(signal_outlier_amp, palette.outlier);
horz_line(signal_outlier_amp * -1, palette.outlier);

%--- draw good signal
xvals = x_secs;

yvals = RESP;
yvals(~valid_mask) = NaN;
yvals(ignored_mask) = NaN;

h_valid = plot(xvals, yvals);

%--- draw ignored signal
xvals = x_secs;

yvals = RESP;
yvals(~ignored_mask | ~valid_mask) = NaN;

h_ignore = plot(xvals, yvals, 'Color', palette.ignored);

%--- draw bad signal
xvals = x_secs;

yvals = RESP;
yvals(valid_mask) = NaN;

h_bad = plot(xvals, yvals, 'Color', gray60);

%--- set dot size
peak_dot_size = 60;
trgh_dot_size = peak_dot_size;

%--- draw peaks
xvals = peak_x_secs;
yvals = RESP(rm_nan(EKG.RSPstats.peaks)); % use original signal
scsize = peak_dot_size;
h_peak = scatter(xvals, yvals, scsize, 'o', 'MarkerEdgeColor', palette.peak);

%--- draw troughs
xvals = trgh_x_secs;
yvals = RESP(EKG.RSPstats.trghs); 
scsize = trgh_dot_size;
h_trgh = scatter(xvals, yvals, scsize, 'MarkerEdgeColor', palette.trgh);

legend([h_ignore, h_valid, h_bad, h_thresh, h_outlier],...
    'Signal',...
    'Valid T-T cycle',...
    'Marked invalid',...
    'Peak detection threshold', ...
    '+/- 3SD from signal mean' )

%% ====================================================================
% (2) PLOT: RR (instantaneous)

%subplot_tight('Position', [0 .25 .75 .25])
subplot_tight(4, 4, 9:11, subplot_margin)
hold on
grid on
time_axis()

ylabel('RR (b/min)');
ylim([0 40]);

%--- draw 1SD lines
RR_sd = EKG.RSPstats.RR_std;
RR_sd_hi = EKG.RSPstats.RR_mean + RR_sd;
RR_sd_lo = EKG.RSPstats.RR_mean - RR_sd;

solid_rect(xlim, [RR_sd_lo RR_sd_hi], gray95);

RR_outlier_hi = EKG.RSPstats.RR_mean + 3 * RR_sd;
RR_outlier_lo = EKG.RSPstats.RR_mean - 3 * RR_sd;

h_outlier = horz_line(RR_outlier_hi, palette.outlier);
horz_line(RR_outlier_lo, palette.outlier);

%--- draw RR mean
h_RR = horz_line(EKG.RSPstats.RR_mean, palette.RR);

%--- draw RR trace
xvals = EKG.RSPstats.trghs(2:end,1) ./ EKG.sampRate;
yvals = EKG.RSPstats.RR_instant(1:end-1);

col = palette.RR;
linetype = '-o';
plot(xvals, yvals, linetype, 'Color', col, 'MarkerFaceColor', col, 'MarkerSize', 4);

legend([h_RR, h_outlier],...
    'RR (mean of intervals, b/min)', ...
    '+/- 3SD' );


%% ====================================================================
% (3) PLOT: IE (instantaneous)

%subplot_tight('Position', [0 0 .75 .25])
subplot_tight(4, 4, 13:15, subplot_margin)
hold on
grid on
time_axis()

ylabel('I/E ratio (log)');
ylim([-1 1]); % .1 to 10 on log10 scale

h = gca;
h.YTick = -1 : .5 : 1;
h.YTickLabel = arr2cellstr(10 .^ h.YTick, '% #5.2f');

%--- draw 1SD lines
IE_sd = EKG.RSPstats.IE_ratio_std_log10;
IE_sd_hi = log10(EKG.RSPstats.IE_ratio_mean) + IE_sd;
IE_sd_lo = log10(EKG.RSPstats.IE_ratio_mean) - IE_sd;

solid_rect(xlim, [IE_sd_lo IE_sd_hi], gray95);

IE_outlier_hi = log10(EKG.RSPstats.IE_ratio_mean) + 3 * IE_sd;
IE_outlier_lo = log10(EKG.RSPstats.IE_ratio_mean) - 3 * IE_sd;

h_outlier = horz_line(IE_outlier_hi, palette.outlier);
horz_line(IE_outlier_lo, palette.outlier);

%-- draw center line (1:1 ratio)
horz_line(0, gray60);

%--- draw IE mean
h_IE = horz_line(log10(EKG.RSPstats.IE_ratio_mean), palette.IE);

%-- draw IE trace
xvals = EKG.RSPstats.trghs(2:end,1) ./ EKG.sampRate;
yvals = log10(EKG.RSPstats.IE_instant(1:end-1));

col = palette.IE;
linetype = '-o';
plot(xvals, yvals, linetype, 'Color', col, 'MarkerFaceColor', col, 'MarkerSize', 4);

legend([h_IE, h_outlier],...
    'IE ratio (mean log)', ...
    '+/- 3SD (log)' )


%% ====================================================================
% (4) PLOT: Power spectral density
subplot_tight(4, 4, [4 8], subplot_margin)

palette.median = parula(3,:);

PSD = EKG.RSPstats.PSD;
%plot(PSD.welch_f * 60, log10(PSD.welch_pxx));
plot(PSD.welch_f * 60, PSD.welch_pxx);
xlim([PSD.freq_range_lo PSD.freq_range_hi] * 60);
xlabel('Frequency (b/min)')
%ylim([0 11])
%ylabel('Spectral power log10(W/Hz)')
ylabel('Spectral power (W/Hz)')
l1 = vert_line(EKG.RSPstats.RR_psd, parula(3,:));
l2 = vert_line(EKG.RSPstats.RR_mean, palette.RR);
legend([l1 l2], 'RR (dominant frequency, b/min)', 'RR (mean of intervals, b/min)');

grid on

%% ====================================================================
% (5) Stats table

table_vals = { 
    'Signal length (sec)' EKG.RSPstats.n_sec
    'Percent valid' EKG.RSPstats.pct_good * 100
    'RR (mean of intervals, b/min)' EKG.RSPstats.RR_mean
    'RR (dominant frequency, b/min)' EKG.RSPstats.RR_psd
    'Coef. of variability (intervals)'   EKG.RSPstats.RR_coef_var
    'I/E ratio' EKG.RSPstats.IE_ratio_mean
    };

tab_pos = [.75 (0 + subplot_margin)];
tab_size = [(.25 - subplot_margin) (.5 - 2*subplot_margin)];

tab = uitable('Data', table_vals, ...  
    'RowName',[], 'ColumnName', [], ...
    'Units', 'normalized', 'Position', [tab_pos tab_size], ...
    'RowStriping', 'off');

tab.ColumnWidth = {200 'auto'};
% tab.RowHeight = tab.Extent(4) ./ height(table_vals)

hold off

end

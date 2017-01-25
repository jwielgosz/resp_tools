function init_resp_stats_table(varargin)
%init_resp_stats: set up structure for saving stats table

global resp_file_info_fields;
global resp_stats_fields;
global resp_csv_header;
global resp_csv;

switch nargin
    case 0
        resp_file_info_fields = {};
    otherwise
        resp_file_info_fields = varargin{1};
end


resp_stats_fields =  {
    'n_sec'
    'n_good_segments'
    'pct_good'
    'n_resp_intervals'
    'RR_mean'
    'RR_std'
    'RR_psd'
    'RR_coef_var'
    'IE_ratio_mean'
    'IE_ratio_std_log10'
    };

resp_csv_header = {
    resp_file_info_fields{:} resp_stats_fields{:}
    };

resp_csv = resp_csv_header;


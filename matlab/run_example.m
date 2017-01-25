% Plot and save respiration stats from example recordings

b = struct;

b.list_file = '../example/file_list.csv';
b.fname_col = 'filename';
b.info_cols = {'speed','depth'};
%b.list_rows = [1];

b.intervals.file = '../example/data_check/example_respiration_check_intervals.csv';
b.intervals.cols = {'filename', 'start', 'end'} ;
b.intervals.treat_as = 'bad';
% b.save_intervals = true;

b.mat_path = '../example/biopac';
b.resp_channel = 2;
b.stop_on_error = true;

% b.quality_path = '../example/quality_checked';
% b.load_quality = true;
% b.mark_quality = true;

b.stats_path = '../example/resp_stats/example_resp_stats.csv';
b.save_stats = true;


b.plot_path = '../example/plots';
b.plot_format = 'png';
b.save_plots = true;

bad_rows = do_resp_batch(b)



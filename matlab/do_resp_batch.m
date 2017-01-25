function bad_rows = do_resp_batch(b)
% Top level script for extracting respiration stats from example recordings
%
% b: struct containing the following fields:
%
%   INPUT (required)
%
%   list_file:    input CSV containing .mat files to process.
%                 (if extension is not .mat, will be automatically changed)
%   
%      OPTIONS
%
%      fname_col:    column in input CSV containing recording filenames
%                    (default is 'filename')
%      list_rows:    Array of specific rows in input CSV to process
%                    (e.g. for debugging)
%      mat_path:     path to prepend to filenames
%                    (e.g. if list_file contains .acq instead)
%      resp_channel: if data is acq2mat output, which channel is respiration?
%                    (ignored if data is processHRV output)
%      stop_on_error: if true, then abort if processing fails; 
%                     if false (default), insert blank stats and keep going
%
%   INPUT (optional)
%
%   load_quality: load quality-checked .mat files, when available
% 
%       REQUIRED
%       quality_path: path to quality-checked .mat files (bad regions flagged)
%
%
%   interval:     substructure with following fields:
%       .file:      input CSV containing valid regions for each file
%       .cols:      three-element list of column names for filename, 
%                  interval start, and interval end, respectively
%       .treat_as: 'good' or 'bad'
%
%
%   OUTPUT       (specify at least one)
%
%   save_intervals: save region info from interval CSV into
%                   quality-checked .mat files
%
%      REQUIRED
%      interval:     (see above)
%      quality_path: (see above)
%
%   mark_quality:   flag bad regions and save quality-checked .mat files
%
%      REQUIRED
%      quality_path: (see above)
%
%   save_stats:   write stats to output CSV
%
%      REQUIRED
%      info_cols: columns from the input CSV to include in the output CSV
%      stats_path: complete path for output CSV
%
%   save_plots:   write stats to output CSV
%
%      REQUIRED
%      plot_path:     directory where plots will be saved
%      plot_format:   'png' or 'eps'

%---------------------------------------------------------------------
% Batch options
use_intervals =  isfield(b, 'intervals');
save_intervals = isfield(b, 'save_intervals') && b.save_intervals;
save_plots =     isfield(b, 'save_plots')     && b.save_plots;
save_stats =     isfield(b, 'save_stats')     && b.save_stats;
mark_quality =   isfield(b, 'mark_quality')   && b.mark_quality;
load_quality =   isfield(b, 'load_quality')   && b.load_quality;

ftab = readtable(b.list_file);
if use_intervals
    itab = readtable(b.intervals.file);
end

if isfield(b, 'resp_channel')
    resp_channel = b.resp_channel;
else
    resp_channel = []; 
end


if isfield(b, 'list_rows')
    f_rows = b.list_rows;
else
    f_rows = 1:height(ftab);
end

if save_stats
    init_resp_stats_table(b.info_cols)
end

%---------------------------------------------------------------------

bad_rows = [];

for f_idx = f_rows
    
    f = ftab.(b.fname_col){f_idx};
    
    [pathstr,name,ext] = fileparts(f);
    
    if isfield(b, 'mat_path')
        % Replace .acq extension, and prepend mat_path
        f_mat = [b.mat_path filesep name '.mat'];
    else
        f_mat = [pathstr name '.mat'];
    end
    
    if isfield(b, 'quality_path')
        q_mat = [b.quality_path filesep name '.mat'];
    else
        q_mat = '';
    end
    
    try
        if load_quality
            EKG = load_mat_as_resp(f_mat, resp_channel, q_mat);
        else
            EKG = load_mat_as_resp(f_mat, resp_channel);
        end
        
        if use_intervals
            [EKG, is_modified] = apply_interval_table(EKG, itab, b.intervals, name);
            if is_modified && save_intervals
                disp(['Saving matfile with marked intervals to: ' q_mat]);
                EKG.RSP_quality_marked = q_mat;
                save(q_mat, 'EKG');
            end                
        end
        
        if mark_quality
            EKG.RSP_ts = quality_flag(EKG.RSP_ts, ['Respiration: ' name]);
            EKG.RSP_quality_marked = q_mat;
            disp(['Saving matfile with marked intervals to: ' q_mat]);
            save(q_mat, 'EKG');
        end
            
        EKG = calc_resp_stats(EKG);
        
        if save_stats
            append_resp_stats_table(ftab, f_idx, EKG)
        end
        
        if save_plots
            plot_out = [b.plot_path filesep name];
            save_resp_plot(EKG, plot_out, b.plot_format);
        end
        
    catch err
        
        if isfield(b, 'stop_on_error') && b.stop_on_error
            rethrow(err)
        elseif save_stats
            disp('Skipping due to problems:')
            disp(err.message)
            bad_rows = [bad_rows f_idx];
            append_resp_stats_table(ftab, f_idx, struct())
        end

    end
end

if save_stats; disp(' '); save_resp_stats_table(b.stats_path); end



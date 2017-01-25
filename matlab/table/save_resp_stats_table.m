function save_resp_stats_table( out_path )
% Save resp stats to disk

disp(['Saving respiration stats to: ' out_path]);

global resp_csv;
cell2csv(out_path, resp_csv);

end


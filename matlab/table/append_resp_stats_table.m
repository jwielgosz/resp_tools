function append_resp_stats_table(file_table, file_idx, EKG )

global resp_file_info_fields;
global resp_stats_fields;
global resp_csv_header;
global resp_csv;

row = struct();

for i = 1:length(resp_file_info_fields)
    stat = resp_file_info_fields{i};
    row.(stat) = get_table_entry(file_table, stat, file_idx);
end

if (isfield(EKG, 'RSPstats'))
    for i = 1:length(resp_stats_fields)
        stat = resp_stats_fields{i};
        row.(stat) = EKG.RSPstats.(stat);
    end
else
    for i = 1:length(resp_stats_fields)
        stat = resp_stats_fields{i};
        row.(stat) = NaN;
    end
end

% copy fields into cell array
row_cell = {};
for i = 1:length(resp_csv_header);
    row_cell{i} = row.(resp_csv_header{i});
end

resp_csv = [resp_csv ; row_cell];

function val = get_table_entry(table, var, row)
% ugh
if isa(table.(var), 'cell')
    val = table.(var){row};
else
    val = table.(var)(row);
end


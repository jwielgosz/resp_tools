function peaks = faster_peak(signal, peak_thresh, sensitivity)

%% find where signal passes above/below threshold and (-1 * threshold)

%--- use rise + fall over threshold to mark off "segments" with peaks
peak_cross = diff(signal > peak_thresh);
seg_start = find(peak_cross == 1);
seg_end = find(peak_cross == -1);

if (isempty(seg_start) || isempty(seg_end))
    peaks = [];
    return
end

% make sure we only use complete segments for true local maxima
if seg_end(1) < seg_start(1)
    seg_end = seg_end(2:end);
end
n_seg = length(seg_end);
seg_start = seg_start(1:n_seg);

%--- use dips below (-1 * threshold) to separate "windows"
% which can contain multiple "segments"

trgh_cross = diff(signal < -1 * peak_thresh);
dip = find(trgh_cross == 1);
n_dip = length(dip);

if (isempty(trgh_cross) || isempty(seg_start) || isempty(seg_end))
    peaks = [];
    return
end

%% state machine

state = -1;

while true
   
    switch state
        
        case -1 % initialize
            
            s = 1;  % counter for segments
            d = 1; 
            pc = 1; % counter for actual peaks
            win_start = seg_start(1);

            % counter for dips
            d = find(dip(d:end) > win_start, 1) + (d-1); 
            win_end = dip(d);
            
            % set "previous" window to current one, so we 
            % make sure to check if second window is well-separated
            [max_y, max_x] = max(signal(win_start:win_end));
            max_x = max_x + win_start;

            % initialize list of finalized peaks
            peaks = nan(n_seg, 1); % most rows we'll need
            
            state = 0;
        
        case 0 % valid window
            
            % extract max value from current window
            
            [win_max_y, win_max_x] = max(signal(win_start:win_end));
            win_max_x = win_max_x + win_start;
            
            if (win_max_x - max_x) < sensitivity
                state = 1;
            else
                state = 2;
            end
            
        case 1 % valid but too close to previous window
            
            if (win_max_y > max_y ) % take the new peak if it's bigger
                max_y = win_max_y;
                max_x = win_max_x;
            end
            state = 3;
            
        case 2 % valid and distinct window
            
            % save previous window
            peaks(pc) = max_x;
            pc = pc + 1;
            
            % reset max to the current peak
            max_y = win_max_y;
            max_x = win_max_x;
            state = 3;
            
        case 3 % see if we have another valid window
            
            % first see if there's another segment
            next_s = find(seg_start(s:end) > win_end, 1) + (s-1);
            if ~isempty(next_s)
                state = 4;
            else
                state = 7;
            end
            
        case 4 % more segments after current window
            s = next_s;
            win_start = seg_start(s);
            
            % see if there's another dip after the next segment
            next_d = find(dip(d:end) > win_start, 1) + (d-1);
            if ~isempty(next_d)
                state = 5;
            else
                state = 6;
            end
            
        case 5 % more dips after next segment
            
            % set end of window to next dip
            d = next_d;
            win_end  = dip(d);
            state = 0;
            
        case 6 % no more dips after next segment
            
            % set window to all remaining segments
            win_end  = seg_end(n_seg);
            state = 0;
            
        case 7 % no more segments after current window
            
            % current max is final, save it
            peaks(pc) = max_x;
            
            % get rid of unused rows
            peaks = peaks(~isnan(peaks));
            
            break % and done!
 
    end
end






function [ segs ] = find_segments(x, val )
%get_segments Find contiguous segments equal to a given value

%val = reshape(val, [], 1);
x = x(:);
d = diff(x == val);
seg_starts = find(d == 1) + 1;
seg_ends = find(d == -1);
if x(1) == val
    seg_starts = [1 ; seg_starts];
end
if x(length(x)) == val
    seg_ends = [seg_ends ; length(x)];
end

segs = [ seg_starts seg_ends ];


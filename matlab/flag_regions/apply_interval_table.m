function [EKG, is_modified] = apply_interval_table(EKG, itab, info, name)
% Set quality flags based on intervals from table

    cols = matlab.lang.makeValidName(info.cols);

    rows = find(cellfun(@length, regexp(itab.(cols{1}), name)));

    segs = itab{rows, cols(2:3)};
    
    switch info.treat_as
        case 'good'
            qflag = 0;
        case 'bad'
            qflag = 1;
    end

    old_q = EKG.RSP_ts.Quality;
    
    %t = EKG.RSP_ts.Time; % time units
    
    EKG.RSP_ts.Quality = ~qflag;
    
    for i = 1:size(segs,1)
        disp(sprintf('Masking interval (%s): %d to %d', EKG.RSP_ts.TimeInfo.Units, segs(i,1), segs(i,2)));
        %EKG.RSP_ts.Quality(t >= segs(i,1) & t <= segs(i,2)) = qflag; %time units
        EKG.RSP_ts.Quality(segs(i,1):segs(i,2)) = qflag; % sample units
    end
    
    is_modified = ~isequal(old_q, EKG.RSP_ts.Quality);
    
end


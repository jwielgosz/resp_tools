function save_resp_plot(EKG, plot_out, plot_format)
% Generate and save peak/trough plots for EEG data

%plot_out = [ plot_out filesep plot_format filesep ];
% 
% [pathstr,name,ext] = fileparts(EKG.RSPmatfile);
% plot_fname = name;

disp(['Saving plot to: ' plot_out]);

plot_resp_stats(EKG);


x_pix = 6400; % should determine file size for raster images
y_pix = 3200; % shouldn't matter for vectors

dpi = 100; % shouldn't change raster image file size, but will affect fonts, etc.

all_axes = findobj('Type', 'axes');

title_s = ['resp_tools: ', EKG.RSPmatfile];
title(all_axes(end), title_s, 'interpreter', 'none');

all_labels = get(all_axes,{'XLabel' 'YLabel', 'Title'});

set(gcf,'PaperUnits','inches','PaperSize',[x_pix/dpi,y_pix/dpi],'PaperPosition',[0 0 x_pix/dpi y_pix/dpi]);

set([all_labels{:}], 'FontSize', 15);
set(all_axes, 'FontSize', 10);

switch plot_format
    case 'png'
        print('-dpng', sprintf('-r%d', dpi), [plot_out '_resp_stats.png']);
    case 'eps'
        print('-depsc2', sprintf('-r%d', dpi), [plot_out '_resp_stats.eps']);
end

close

end


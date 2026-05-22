function saveData(coarseResults, fineResults, bestCoarsePos, bestFinePos, figs)
    % Save all the data from one autofocus run

    % 1. Create a folder for today's session
    todayDate = datestr(now, 'yyyy_mm_dd');
    sessionFolder = ['../data/session_', todayDate];

    if exist(sessionFolder, 'dir') == 0
        mkdir(sessionFolder);
    end

    % 2. Figure out the run number (run_1, run_2, run_3...)
    existingRuns = dir([sessionFolder, '/run_*']);
    runNumber = length(existingRuns) + 1;
    runFolder = [sessionFolder, '/run_', num2str(runNumber)];
    mkdir(runFolder);

    % 3. Save the scan data (already packaged by the scan functions)
    writematrix(coarseResults, [runFolder, '/coarse_scan.csv']);
    writematrix(fineResults, [runFolder, '/fine_scan.csv']);
    writematrix([bestCoarsePos, bestFinePos], [runFolder, '/best_focus.csv']);

    % 4. Save the figures (as PNG and as MATLAB .fig)
    for i = 1:length(figs)
        if ~isgraphics(figs(i))
            warning('Figure at index %d is invalid or has been closed, skipping.', i);
            continue;
        end
        figName = figs(i).Name;
        if isempty(figName)
            figName = ['figure_', num2str(figs(i).Number)];
        else
            figName = strrep(figName, ' ', '_');
        end

        saveas(figs(i), [runFolder, '/', figName, '.png']);
        savefig(figs(i), [runFolder, '/', figName, '.fig']);
    end

    disp(['All done! Data saved in: ', runFolder]);
end
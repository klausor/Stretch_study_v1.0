% For calibration with fluorescence brightness signal
%
% Cuts r_smooth in pieces of length 2*<nr_pts_half> and finds the minimum of each
% shift: Index in r_smooth where the searching for first minimum starts
% bool_test: Testing on/off
% Outputs: 
%    min_idx: Indices of cal minima in calvec; last_max_idx: Last max.
%    [], [] if <2 regularily spaced min

function [min_idx, last_max_idx] = cal_find_minima(calvec, nr_pts_half, shift, bool_test)
    min_idx = 0;
    r_smooth = movmean(calvec, nr_pts_half/8);
    if bool_test, f = figure; a1 = gca; hold on; plot(calvec); end
    for j = 1 : floor((length(calvec)-shift)/(2*nr_pts_half))
        % Index range in which to search jth minimum
        idx_range = [1 + (2*(j-1))*nr_pts_half + shift : 1 + (2*(j-1)+2)*nr_pts_half + shift]';
        [~, idx] = min(r_smooth(idx_range));
        min_idx(j,1) = idx + idx_range(1)-1;
        % If min is first or last idx in range for one of the first 2 ramps -> Window badly placed -> shift and search
        if ((min_idx(j) == idx_range(1)) && (j==1||j==2)) || ((min_idx(j) == idx_range(end))&&(j==1||j==2))
            [min_idx, last_max_idx] = cal_find_minima(calvec, nr_pts_half, shift+5, bool_test);
            if exist('f', 'var'), delete(f); end
            return;
        end
        if bool_test
            line([idx_range(1) idx_range(1)], [min(calvec) max(calvec)], 'Color', [0 0 0]); line([idx_range(end) idx_range(end)], [min(calvec) max(calvec)], 'Color', [0 0 0]);
            plot(a1, min_idx(j), calvec(min_idx(j)), '*', 'Color', [0 0 0]);
        end
    end
    deltax = diff(min_idx); 
    % Are there at least 2 regularily spaced ramps?
    if abs(deltax(1) - 2*nr_pts_half)>nr_pts_half/10
        title('Skipped: Less than 2 ramp minima or nr_pts_half wrong', 'FontSize', 16);
        min_idx = []; last_max_idx = [];
        return;
    end %

    % ONLY THE FIRST, REGULARILY SPACED MINIMA OF EQUAL HEIGHT ARE KEPT
    deltax = [deltax(1); deltax]; % To compensate diff shift; for comparison
    % logical one where step in x and y fits regular ramp profile; Deviation in x and y of <= 5%=
    isramp = abs(diff(deltax)) < nr_pts_half/10 & diff(calvec(min_idx)) < (max(calvec(1:2*nr_pts_half))-min(calvec(1:2*nr_pts_half)))/20;
    if ~isramp(1)
        title('Skipped: Non regularily spaced mins');
        min_idx = [];
        last_max_idx = [];
        return;
    end
    last_min = find(~isramp, 1); % idx of first step not corresponding to ramp
    min_idx = min_idx(1:last_min);
    
    % Search between last 2 minimums
    [~, last_max_idx] = max(r_smooth(min_idx(end-1)+5 : min_idx(end)-5));
    last_max_idx = last_max_idx + min_idx(end-1)+4;
    if bool_test
        plot(a1, last_max_idx, calvec(last_max_idx), '+', 'Color', 'r', 'MarkerSize', 12); 
    end
end

% Tests: 10 Stretching-Kurven: Gut gefitet mit polynom 6. Ordnung; Einmal
% das 2. statt 4. Minimum als letztes erkannt (08.06.21)
% 16.06.
% 19 Stretching-Kurven (10.06. p1): Programm mit breakpoints getestet, fits noch nicht ideal, lief durch, Fall <2 min hinzugefügt.
% Mit Testdatensatz gut
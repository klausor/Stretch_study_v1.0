% plots and fits radius-over-z ramps
% Test ok; Inspected with breakpoints; 
% Fitparameters stored in stretch_study(i).cal identical and in same order as their calculation in the script including non tracked ones
% See CAOS_METHODS_EVALUATION -> Stretching for diagrams for example rsquare thresholds; 0.88 seems to be good 10.03.21
% Radius smoothed to a resolution of 20 ms

function stretch_study = arbitrary_calibration(stretch_study, bool_test)
% fit_frac: The triangular ramp is fitted from t(minimum) to t(min + % fitfrac*t_halframp); Additionally, only ramps are taken into account that have a significant slope at the start
    
    version = '1.0';
    % Which parameter should be fitted for height calibration?
    parm_list = {'mean_brightness', 'r'};
    idx = listdlg('ListString', parm_list, 'InitialValue', 1, 'Name', 'Select height calibration parameter');
    parm_name = parm_list{idx};
    fitmode = questdlg('Linear or arbitrary shape calibration', '', '6th order poly', 'linear', 'Abbrechen', 'linear');

    %f1 = figure; ax1 = gca; title(sprintf('%s , smoothed to 20ms', parm_name)); hold on; legend('show');
    for i = 1:length(stretch_study)
        tracked_idx = find(stretch_study(i).tracked{1,:});
        cal = zeros(size(stretch_study(i).tracked));
        bright_to_height = []; a = []; cal_matrix = zeros(1, length(stretch_study(i).tracked{1,:}));
        for k = tracked_idx
            % Extract attributes from table properties
            MPT = stretch_study(i).MPT{k};
            ampl = MPT.Properties.CustomProperties.ampl_ramp;
            f_ramp = MPT.Properties.CustomProperties.f_ramp;
            Delta_t = MPT.Properties.CustomProperties.Delta_t;
            Delta_z = ampl/(0.5*(1/f_ramp)/Delta_t);
            calparm = MPT.(parm_name);
            
            % Find one maximum and regularily spaced minima
            nr_pts_half = round(ampl/Delta_z);
            [min_idx, last_max_idx] = cal_find_minima(calparm, nr_pts_half, 0, bool_test); % finds the last ramp before stretching
            % If less than 2 regularily spaced min -> particle treated as if not tracked
            if isempty(last_max_idx)
                stretch_study(i).tracked{1,k} = 0;
                continue;
            end
            % Range between last max and last min fitted
            x = Delta_z*(0 : min_idx(end) - last_max_idx)';
            y = calparm(last_max_idx : min_idx(end));
            switch fitmode
                case '6th order poly'
                    cal_matrix(:, k) = cal_polyfit(x, y, bool_test); % [<7500 pts brightness vec from poly fit> | height]
                case 'linear'
                    % Stretching ~ 0.33 * 0.6µm (Gesamtrange); Dabei ist auch Aberration durch Laser -> 0.25 ok
                    fit_frac = 0.25; % Only central fraction with constant slope fitted, slightly shifted to start point
                    range = round(1 : fit_frac*length(x));
                    % Averaging over 2 linear fits on both sides of last max
                    x2 = x; y2 = calparm(min_idx(end-1) : min_idx(end-1)+length(x)-1);
                    % Fit range symmetric around max
                    a =  cal_linfit([x x2], [y y2], [range' abs(length(x)-flip(range)+1)'], bool_test);
                    cal_matrix(:, k) = 1/a; % [a]: µm/<brightness units>
                case 'Abbrechen'
                    disp('aborted'); return
            end
        end
        if any(cal_matrix, 'all')
            if strcmp(fitmode, '6th order poly')
                stretch_study(i).cal = array2table([bright_vec bright_to_height(:,2)], 'VariableNames', [stretch_study(i).tracked.Properties.VariableNames {'height [µm]'}]);
                stretch_study(i).cal.Properties.Description = sprintf('1st column: Height; Others: Corresponding %s, created from inverse of 6th order poly fit of ramps (arbitrary_calibration v. %s)', parm_name, version);
            elseif strcmp(fitmode, 'linear')
                stretch_study(i).cal = array2table(cal_matrix, 'VariableNames', stretch_study(i).tracked.Properties.VariableNames);
                stretch_study(i).cal.Properties.Description = sprintf('slope of central fraction(%.2f); [a] = µm/<%s units>, (arbitrary_calibration v. %s)', fit_frac, parm_name, version);
            end
            stretch_study(i).cal = addprop(stretch_study(i).cal, 'Delta_z', 'table'); stretch_study(i).cal.Properties.CustomProperties.Delta_z = Delta_z;
        end
    end
end

% Test: Linear: FUnktioniert; 2 Datensätze
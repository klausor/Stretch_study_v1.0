% Inputs: x: [x1 x2] (vectors to perform multiple fits and average); y: [y1 y2]
%     range: [idxrange1 idxrange2], oder 'full' to plot whole input range
% Output: [fitted_brightnesses ]

function a = cal_linfit(x, y, range, bool_test)
% to plot whole input range
if strcmp(range, 'full')
    range = [(1:length(x))' (1:length(x))']; 
end

    ft = fittype(@(a, b, x) a.*x + b, 'independent', 'x');
    a = [0 0];
    if bool_test, figure; hold on; end
    % 2 Slopes are fit and the result is averaged
    for j = 1:2
        % From min to min +- fit_frac * one nominal slope lenth;
        [f, gof] = fit(x(range(:,j),j), y(range(:,j),j), ft, 'StartPoint',[1 500]);
        % Rsquared: Mittl. quadratische Abw. d. Regression vom Mittelwert /(durch) mittl quadr. Abweichung der stichproben vom Mittelwert
        %if gof.rsquare < rsquare_thresh
        if bool_test
            plot(x(:,j), y(:,j));
            fplot(@(x) f.a.*x+f.b, [x(range(1,j), j) x(range(end, j), j)], 'Color', 'r', 'linewidth', 1, 'DisplayName', sprintf('r^2: %.2f', gof.rsquare));
        end
        a(j) = f.a;
    end
    a = mean(abs(a));
end
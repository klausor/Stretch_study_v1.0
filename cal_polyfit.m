% Input: y: brightness | x: Deltax *(idx(min)-idx(max))
% Output: brightness(7500pts aus polyfit func) | height

function bright_to_height = cal_polyfit(x, y, bool_test)
% a1 must be <0 so that slope at z = 0 is not positive (damit Fitfunktion keinen Bogen macht sondern stetig fällt)
    fo = fitoptions('Method','NonlinearLeastSquares', 'Robust', 'on', ...            
                    'Upper', [Inf, 0, Inf, Inf, Inf, Inf, Inf], ... 
                    'StartPoint',[600, -100, 0, 0, 0, 0, 0]);
    ft = fittype(@(a0, a1, a2, a3, a4, a5, a6, z) a0+a1*z+a2*z.^2+a3*z.^3+a4*z.^4+a5*z.^5+a6*z.^6, 'independent', 'z', 'options', fo);
    [poly, gof] = fit(x, y, ft); % 170 fps: 1 fitparm per 5.5 datapts; AdjustedR^2 const above 4th order poly
    % Create brightness |height - lookup-table
    bright_to_height = [feval(poly, linspace(0, max(x), 7500)) linspace(0, max(x), 7500)'];
    if bool_test
        figure; plot(y, x, '.', 'MarkerSize', 6, 'Color', [0 0 0]); xlabel(parm_name); ylabel('z height [µm]');
        hold on; plot(bright_to_height(:,1), bright_to_height(:,2), 'Color', 'r');
    end
end
% Returns Tobi Neckernuß's solution for the 4-Parameter model for fitting
% stretching curves
% Output: Function handle
function fun = modelBurgersFixed(E1, E2, eta1, eta2)
  s0 = 0.5;
  tstart = 0;
  fun = @(t) s0*1/306*(153*(1/E1 + 1/E2) + ...
     exp(-23409*(t - tstart)^2) / (sqrt(pi) * eta1) + ...
     (153*(t - tstart))/eta1 + ...
     (153*(1/E1 + 1/E2) + (153*(t - tstart))/eta1)*erf(153*(t - tstart)) ...
      - (153 *exp((E2 (E2 - 93636*(t - tstart)*eta2))/(93636*eta2^2)) ...
        * erf(153*t - 153*tstart - E2/(306*eta2)))/E2 ...
      - (153*exp(-((E2*(-0.0000106797*E2 + (-8.7784*10^-7 + t - tstart)*eta2))/eta2^2)) ...
        *erf(30.6 + (0.00326797*E2)/eta2))/E2);
end
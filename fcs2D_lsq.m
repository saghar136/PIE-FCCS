function err = fcs2D_lsq(parameter,real_x, real_y)

global weight 

% for parameter(n), 
%             n=1 --> N_eff, avg population #
%             n=2 --> tau_D, avg dwell time
%             n=3 --> normalization factor?

fit = ((1./parameter(1)).*(1./(1+(real_x/parameter(2)))))+parameter(3);
err = fit - real_y;

% weight the error according to the |WEIGHT| vector
% err_weighted = err./weight;
% err = err_weighted;

end
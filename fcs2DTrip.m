function err = fcs2DTrip(parameter,real_x, real_y)

global weight 
%trip = (1+(parameter(4)/1-parameter(4))*exp(real_x/parameter(5)));
% trip = (1+(parameter(3)./(1-parameter(3))).*exp(-real_x./parameter(4)));
% TwoD = (1./parameter(1)).*(1./(1+(real_x/parameter(2))));
% for parameter(n), 
%             n=1 --> N_eff, avg population #
%             n=2 --> tau_D, avg dwell time
%             n=3 --> T, triplet fraction
%             n=4 --> tau_T, triplet relaxation
%             n=5 --> normalization factor?
fit =((1+(parameter(3)./(1-parameter(3))).*exp(-real_x./parameter(4))).*(1./parameter(1)).*(1./(1+(real_x/parameter(2)))))+parameter(5);
err = fit - real_y;

% weight the error according to the |WEIGHT| vector
% err_weighted = err./weight;
% err = err_weighted;

end
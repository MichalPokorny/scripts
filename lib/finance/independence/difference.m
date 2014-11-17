% T = total years to predict
% i = interest rate
% r = savings rate
% N = years in retirement
function d = difference(i, r, T, N)
	Tx = N + (((1+i)*(1-r))/(i*r)) * (1 - (1/(1+i))^N);
	d = Tx - T;
end

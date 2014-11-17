% T = total years to predict
% i = interest rate
% r = savings rate
% N = years in retirement
function Mx = yearsToWork(i, r, T)
	[Nx, Tx, info] = fsolve(@(N) difference(i, r, T, N), 1);
	Mx = T - Nx;
end

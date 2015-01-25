r = [0.001 0.01:0.03:1 1];
% interestRates = [0.01; 0.03; 0.04; 0.05; 0.07; 0.1; 0.2; 0.5];
interestRates = [0.02; 0.03; 0.04; 0.05; 0.06];

years = zeros(size(r,2),5);
for i=1:size(r,2)
	for j=1:size(interestRates)
		years(i,j)=yearsToWork(interestRates(j),r(i),60);
	end
end
plot(r, years);
title("Working years (2%,3%,4%,5%,6% interest)")
grid on;
grid minor on;
ylim([0 60]);
ylabel("Years to work");
xlabel("Savings rate");

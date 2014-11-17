#!/usr/bin/octave -qf

% argv: (interest rate, savings rate, total years)

args = argv();

printf("%f\n", yearsToWork(str2double(args(1)), str2double(args(2)), str2double(args(3))));


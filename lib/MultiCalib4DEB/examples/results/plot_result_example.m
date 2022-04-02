global pets 

% The pet to calibrate
pets = {'Dipodomys_deserti'};
% Check pet consistence
check_my_pet(pets);

% Get pet data
[data, auxData, metaData, txtData, weights] = mydata_pets;

% Load the solution set (example for Clarias Gariepinus). 
%load('solutionSet_Clarias_gariepinus_20-Apr-2021_20:42:00.mat')

% Plot the solutions!
plot_results(result, ..., 
            result.solutionSet.txtPar, result.solutionSet.data, ...,
            result.solutionSet.auxData, metaData, ..., 
            result.solutionSet.txtData, weights, 'Set');
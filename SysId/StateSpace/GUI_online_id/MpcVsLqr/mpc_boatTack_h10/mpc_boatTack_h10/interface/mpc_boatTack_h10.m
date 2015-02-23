% mpc_boatTack_h10 - a fast interior point code generated by FORCES
%
%   OUTPUT = mpc_boatTack_h10(PARAMS) solves a multistage problem
%   subject to the parameters supplied in the following struct:
%       PARAMS.minusAExt_times_x0 - column vector of length 3
%       PARAMS.Hessians - column vector of length 4
%       PARAMS.HessiansFinal - matrix of size [4 x 4]
%       PARAMS.lowerBound - column vector of length 2
%       PARAMS.upperBound - column vector of length 2
%       PARAMS.C - matrix of size [3 x 4]
%       PARAMS.D - matrix of size [3 x 4]
%
%   OUTPUT returns the values of the last iteration of the solver where
%       OUTPUT.u0 - column vector of size 1
%
%   [OUTPUT, EXITFLAG] = mpc_boatTack_h10(PARAMS) returns additionally
%   the integer EXITFLAG indicating the state of the solution with 
%       1 - Optimal solution has been found (subject to desired accuracy)
%       0 - Maximum number of interior point iterations reached
%      -7 - Line search could not progress
%
%   [OUTPUT, EXITFLAG, INFO] = mpc_boatTack_h10(PARAMS) returns 
%   additional information about the last iterate:
%       INFO.it        - number of iterations that lead to this result
%       INFO.res_eq    - max. equality constraint residual
%       INFO.res_ineq  - max. inequality constraint residual
%       INFO.pobj      - primal objective
%       INFO.dobj      - dual objective
%       INFO.dgap      - duality gap := pobj - dobj
%       INFO.rdgap     - relative duality gap := |dgap / pobj|
%       INFO.mu        - duality measure
%       INFO.sigma     - centering parameter
%       INFO.lsit_aff  - iterations of affine line search
%       INFO.lsit_cc   - iterations of line search (combined direction)
%       INFO.step_aff  - step size (affine direction)
%       INFO.step_cc   - step size (centering direction)
%       INFO.solvetime - Time needed for solve (wall clock time)
%
% See also COPYING
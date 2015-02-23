function sim_MpcVsLqr(realModel, idModel, predHor_steps, ...
                      weights, deltas, constraints, typeTack)

% Weights 
qYawRate = weights(1);
qYaw = weights(2);
rU = weights(3);
sChattering = weights(4);

%constraints
rudderMax = constraints(1);
rudderVelocity = constraints(2); %cmd / s

%deltas
deltaYawRate = deltas(1); %in deg!
deltaYaw = deltas(2); %in deg!
deltaRudder = deltas(3);

%take sampling time of the real model and of the identified model
realDt_s = realModel.Dt;
idDt_s = idModel.Dt;

%realDt_s must be <= idDt_s
if(realDt_s > idDt_s)
   msgbox({'The system assumed as the real one', ...
           'must have a Dt smaller than the one used', ...
           'to compute the MPC and the LQR'}, 'Error','error'); 
   return;
end

%build cost matrices
Q = blkdiag(qYawRate, qYaw, rU);
R = sChattering;
%build hessina matrix for MPC
H = blkdiag(sChattering, qYawRate, qYaw, rU);

%build extended state and extended model
extRealMod = tool_extendModel(realModel);
extIdMod = tool_extendModel(idModel);
    
%compute gain matrix for the LQR and the solution of the discrete riccati
%equation. M will be used as final cost in the MPC
[K_LQR, M, ~] = dlqr(extIdMod.A, extIdMod.B, Q, R);

%based on predHor_steps value see which MPC solve has to be used
mpcHandler = -1;
if(predHor_steps == 10)
    addpath('mpc_boatTack_h10');
    mpcHandler =  @mpc_boatTack_h10;
end

%before starting the two simulations, load usefull paramters
initParam = loadInitParams(realModel, typeTack);

end

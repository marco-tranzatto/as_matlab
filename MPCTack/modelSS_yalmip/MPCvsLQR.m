%TODO resolve problem about velocity constraint!!!

clc;
clear;
%close all;
addpath(genpath('yalmip/'));

yalmip('clear');

typeOfModel = 'little';%little (a,b) or capital (A,B)

%simulate using real state or estimated state by K.F. ?
useRealState = 1;

display('---------- Info ----------');

if(strcmp(typeOfModel, 'little'))
    %load identified model with a and b
    load('linModelScalar');
    linModel = linModelScalar;
    display('Model with a and b.');
    %select wich  model you want to use
    nameModel = 'tack8';
else
    %load identified model with A and B
    load('linModelFull');
    linModel = linModelFull;
    display('Model with A and B.');
    %select wich  model you want to use
    nameModel = 'tack6';
end

%% tunable parameters

%choose if you want to increase the sample time of the model you selected
factorSampleTime = 10;

% %choose every how many seconds a new optimal control by the MPC must be
% %computed
% timeComputeMPC = 0.1;%seconds

%prediction horizon of the MPC
predHor = 10;

%total simulation time, in seconds
tF = 5;

%take the linear model to use in simulation
eval(['model = linModel.' nameModel ';']);

%change the sample time of the model, this undersampled model will be used
%be the MPC
oldDt = model.Dt;
modelDownSampled = tool_changeModelSampleTime(model, factorSampleTime);
display(['Model for the MPC, sample time changed by a factor of ' num2str(factorSampleTime) ...
    ': from ' num2str(oldDt) ' to ' num2str(modelDownSampled.Dt) ' [sec].']);

% Weights 
qYawRate = 0.00001;
qYaw = 10;
rU = 0.001;
sChattering = 5;

%matrices
Q = blkdiag(qYawRate, qYaw, rU);
R = sChattering;

%rudder value before starting the tack
rudderBeforeTack = 0; %between -0.9 and 0.9

%take the sample time of the selected model, in seconds
meanTsSec = model.Dt;

%convert timeComputeMPC in simulation time
%timeComputeMPCSim = round(timeComputeMPC / meanTsSec);

%take the sample time of the model used by MPC or LQR
meanTsSecDown = modelDownSampled.Dt;

display(['Horizon MPC: ' num2str(predHor * meanTsSecDown) ...
         ' [sec]; number of prediction steps: ' num2str(predHor) '.']);
display('--------------------------');
%total simulation steps to reach tF
N = round(tF / meanTsSec);

%initial conditions
tack = 'p2s'; %p2s s2p
absAlphaNew = 45 * pi / 180;

%gaussian noise on measurements
varYawRate = 2 * pi / 180;
varYaw = 10 * pi / 180;
varRudder = 1e-6;

          
measNoise = [sqrt(varYawRate) * randn(1, N);
             sqrt(varYaw) * randn(1, N);
             sqrt(varRudder) * randn(1, N)];
         
%covariance matrices for Kalman filter
convarianceStr.R1 = 0 * eye(3); %perfect model
convarianceStr.R2 = blkdiag(varYawRate, varYaw, varRudder); %noisy measurements

%constraints
rudderMax = 0.9;%0.9;
rudderVelocity = 1.8 / 0.5; %command/sec: rudder can go full right to full lest in 0.5 sec
absDeltaYaw = 10 * pi / 180;

%convert rudderVelocity from command/sec to command/simulationStep

%rudder velocity based on simulation time of the model used by MPC
rudderVelMPC = rudderVelocity * meanTsSecDown;

%rudder velocity in simulation time
rudderVelSim = rudderVelocity * meanTsSec;

% extended model xHat = [yawRate_k, yaw_k, rudder_{k-1}],
% uHat = [rudder_{k} - rudder{k-1}];
% we use the extended model to achieve the same cost function in the
% LQR and in the MPC. Since the LQR can have a cost function of the form
% x' * Q * x + u' * R * u, that tries to bring the system to the origin, we
% start with a yaw angle = -yawRef and we bring the system to the origin.
AExt = [model.A,                      model.B;
        zeros(1, length(model.A)),    1];
    
BExt = [model.B;
        1];
    
CExt = blkdiag(1, 1, 1);

%use extended state space model for the kalman filter and the lqr
model.A = AExt;
model.B = BExt;
model.C = CExt;

%extended even the model downsampled used by the MPC
AExtDown = [modelDownSampled.A,                      modelDownSampled.B;
            zeros(1, length(modelDownSampled.A)),    1];
    
BExtDown = [modelDownSampled.B;
            1];
        
%compute yawReference based on type of tack
if(strcmp(tack, 'p2s'))
    alpha0 = 45 .* pi / 180;
    yawRef = -absAlphaNew - alpha0;
else
    alpha0 = -45 .* pi / 180;
    yawRef = +absAlphaNew - alpha0;
end

%remeber that you have extended the state of the mdoel
xHatRef = [ 0;
            0;
            0];
%guess on the initial state of the KF
guessX1Hat = [  5 * pi / 180;
                -yawRef + (15 * pi / 180);
                rudderBeforeTack];
guessP1_1 = blkdiag(0.2 * eye(2), 0);

%usefull index
yawRateIndex = 1;
yawIndex = 2;
%another useful index for the extended state
lastRudderIndex = 3;

%% Build MPC using model downsampled!
display('Building MPC');
%yalmip options
options = sdpsettings('solver', 'mosek', 'verbose', 1);

% Number of states and inputs
[nx, nu] = size(BExtDown); 

uHatMPC = sdpvar(repmat(nu,1,predHor), repmat(1,1,predHor));
xHatMPC = sdpvar(repmat(nx,1,predHor+1), repmat(1,1,predHor+1));

constraints = [];
objective = 0;

for k = 1 : predHor
    %remember that the extended model has the form:
    % xMPC{k} = [yawRate_k, yaw_k, rudder_{k-1}],
    % uMPC{k} = [rudder_{k} - rudder{k-1}];
    
    %update cost function
    objective = objective + ...
                norm(Q * xHatMPC{k}, 2) + ...
                norm(R * uHatMPC{k}, 2);
               
    %add system dynamic to constraints
    constraints = [constraints, xHatMPC{k+1} == AExtDown * xHatMPC{k} + BExtDown * uHatMPC{k}];
    
    %limit input action to be within feasible set
    %rudder to real system = uHatMPC{k} + xHatMPC{k}(lastRudderIndex)
    constraints = [constraints, ...
                  -rudderMax <= uHatMPC{k} + xHatMPC{k}(lastRudderIndex) <= rudderMax];
    
    %limit input velocity
    constraints = [constraints, abs(uHatMPC{k}) <= rudderVelMPC];
 
    %limit maximum yaw overshoot based on which haul you want to have at
    %the end
    if(strcmp(tack, 'p2s'))
        %constraints = [constraints, xHatMPC{k}(yawIndex)  >= yawRef - absDeltaYaw];
        constraints = [constraints, xHatMPC{k}(yawIndex)  >= -absDeltaYaw];
    else
        %constraints = [constraints, xHatMPC{k}(yawIndex) <= yawRef + absDeltaYaw];
        constraints = [constraints, xHatMPC{k}(yawIndex) <= absDeltaYaw];
    end

 
end

%compute Riccati solution and use it as final cost
[~, M, ~] = dlqr(AExtDown, BExtDown, Q, R);

%add final cost 
objective = objective + norm(M * xHatMPC{predHor + 1}, 2);

parameters_in = xHatMPC{1};
solutions_out = uHatMPC{1};

mpcController = optimizer(constraints, objective, options, parameters_in, solutions_out);


%% Build LQR using normally sampled model
display('Building LQR');


[K_LQR, ~, ~] = dlqr(AExt, BExt, Q, R); 

%% Sim MPC and LQR 

% ---- MPC ----
% compute the 'real' system evolution using the normally sampled model called model.
% run the MPC every 'factorSampleTime' simulation step
display('Computing MPC response');

%start with yawRate = 0 and yaw = -yawRef 
xHatSimMPC1 = [    0;
                -yawRef;
                rudderBeforeTack];
            
xHatSimMPC = zeros(nx, N);

%init
xHatSimMPC(:, 1) = xHatSimMPC1;
rudHatMPC = [];

%initial value of covariance prediction error
P_k1_k1 = guessP1_1;
xHatEst_k1_k1 = guessX1Hat;

xHatEstMPC = zeros(nx, N-1);

%rudder value before tacking
u_k1 = rudderBeforeTack;

%simulation steps when MPC run
timeRunMPC = [];

%index to acces rudHatMPC and timeRunMPC
indexRunMPC = 1;

%input to the extended system
uHat = 0;

for k = 1 : N-1
    
   %we are starting now the step k, prediction phase
   [K_k, P_k_k] = kfPrediction(model, convarianceStr, P_k1_k1);
   
   %now we read the corrupted measurements
   meas_k = xHatSimMPC(:, k) + measNoise(:, k);
   
   %update step to predict the real state at step k with info up to k
   [xEst_k_k] = kfUpdate(model, K_k, meas_k, u_k1, xHatEst_k1_k1);

   %save predicted step for later plots
   if(k == 1)
       xHatEstMPC(:, 1) = guessX1Hat;
   else
       xHatEstMPC(:, k) = xEst_k_k;
   end
   
   %compute MPC control every timeComputeMPCSim steps
   if(k == 1 || mod(k, factorSampleTime) == 0)
       %compute new optimal control using meas
       %rudHatMPC(indexRunMPC) = mpcController{xEst_k_k};
       
       if useRealState
           %compute new optimal control using real state
           rudHatMPC(indexRunMPC) = mpcController{xHatSimMPC(:, k)};
       else
           %compute new optimal control using meas
           rudHatMPC(indexRunMPC) = mpcController{xEst_k_k};
       end
       
       %save simulation step when a new optimal control was comptuted
       timeRunMPC(1, indexRunMPC) = k;
       %update uHat
       uHat = rudHatMPC(indexRunMPC);
       indexRunMPC = indexRunMPC + 1;
   else
       %no new MPC was computed, do not change the rudder input, in the
       %extended state model this means that uHat is 0
       uHat = 0;
   end
   
   %update system dynamic using the last rudder input computed
   xHatSimMPC(:, k+1) = AExt * xHatSimMPC(:, k) + BExt * uHat;
   
   %save kalman filter variables at the end of step k
   P_k1_k1 = P_k_k;
   u_k1 = uHat;
   xHatEst_k1_k1 = xEst_k_k;
end


% translate system response
%xHatSimMPC(yawIndex, :) = xHatSimMPC(yawIndex, :) + yawRef;
yawMPC = xHatSimMPC(yawIndex, :);
%xHatEstMPC(yawIndex, :) = xHatEstMPC(yawIndex, :) + yawRef;

%from uHatMPC compute rudder sequence for the normal system (not the
%extended one)
rudMPC = cumsum([rudderBeforeTack, rudHatMPC]);
%at time 0, rudder was equal to rudderBeforeTack
timeRunMPC = [0, timeRunMPC];

% ---- LQR ----

display('Computing LQR response');

%start with yawRate = 0 and yaw = -yawRef 
xHatSimLQR1 = [    0;
                -yawRef;
                rudderBeforeTack];
            
xHatSimLQR = zeros(nx, N);

%init
xHatSimLQR(:, 1) = xHatSimLQR1;
rudHatLQR = zeros(1, N);

%initial value of covariance prediction error, estimated step and first
%control input
P_k1_k1 = guessP1_1;
xHatEst_k1_k1 = guessX1Hat;
%u_k1 = rudLQR(1);

xHatEstLQR = zeros(nx, N-1);
xHatEstLQR(:, 1) = guessX1Hat;

%rudder value before tacking
u_k1 = rudderBeforeTack;

%rudder to the real boat at the previous step
rudReal_k1 = rudderBeforeTack;

for k = 1 : N-1
   %we are starting now the step k, prediction phase
   [K_k, P_k_k] = kfPrediction(model, convarianceStr, P_k1_k1);
   
   %now we read the corrupted measurements
   meas_k = xHatSimLQR(:, k) + measNoise(:, k);
   
   %update step to predict the real state
   [xEst_k_k] = kfUpdate(model, K_k, meas_k, u_k1, xHatEst_k1_k1);
   %save predicted step for later plots
   if(k == 1)
        xHatEstLQR(:, 1) = guessX1Hat;
   else
        xHatEstLQR(:, k) = xEst_k_k;
   end
   
   if useRealState
       %compute LQR control input using real state
       rudHatLQR(k) = -K_LQR * xHatSimLQR(:, k);
   else
       %compute LQR control input using meas
       rudHatLQR(k) = -K_LQR * xEst_k_k;
   end

   %input to the real system (not extended)
   uRealSys = rudHatLQR(k) + xEst_k_k(lastRudderIndex);
   
   %velocity constrain
   if(abs(uRealSys - rudReal_k1) >= rudderVelSim)
       %velocity constrain violated
       if((uRealSys - rudReal_k1) >= 0)
           uRealSys = rudReal_k1 + rudderVelSim;
       else
           uRealSys = rudReal_k1 - rudderVelSim;
       end
   end
   
   %saturation constrain
   if(uRealSys > rudderMax)
       uRealSys = rudderMax;
   elseif(uRealSys < -rudderMax)
      uRealSys = -rudderMax;
   end
   %save uRealsys for next iteration
   rudReal_k1 = uRealSys;
   
   %rewrite uRealSys as input to the extended state
   rudHatLQR(k) = uRealSys - xEst_k_k(lastRudderIndex);
   
   %update system dynamic
   xHatSimLQR(:, k+1) = AExt * xHatSimLQR(:, k) + BExt * rudHatLQR(k);
   
   %save kalman filter variables at the end of step k
   P_k1_k1 = P_k_k;
   u_k1 = rudHatLQR(k);
   xHatEst_k1_k1 = xEst_k_k;
end

% translate system response
%xHatSimLQR(2, :) = xHatSimLQR(2, :) + yawRef;
yawLQR = xHatSimLQR(2, :);
%xHatEstLQR(2, :) = xHatEstLQR(2, :) + yawRef;

%from uHatMPC compute rudder sequence for the normal system (not the
%extended one)
rudLQR = cumsum([rudderBeforeTack, rudHatLQR]);

%% plot
% ---- plot comparison ----

%compute simulation time, starting from time 0
time = (0:N) .* meanTsSec; 

%time when rudder input by MPC was computed, converted in seconds
timeRunMPC = timeRunMPC .* meanTsSec;

%compute yaw overshoot limit
if(strcmp(tack, 'p2s'))
    limitYaw = -absDeltaYaw;
else
    limitYaw = absDeltaYaw;
end

figure;

set(gcf,'name', ...
    ['MPC (yalmip), steps prediction Horizon: ' num2str(predHor) ...
    '; type of model: ' typeOfModel], ...
    'numbertitle', 'off');

lW0 = 1.3;

if useRealState
    leg = {{'\psi real MPC', 'limit'}, ...
           {'\psi real LQR', 'limit'}, ...
           'rud MPC', 'rud LQR'};
else
    leg = {{'\psi real MPC', 'limit', '\psi by KF'}, ...
           {'\psi real LQR', 'limit', '\psi by KF'}, ...
           'rud MPC', 'rud LQR'};
end

yawReal = [yawMPC;
           yawLQR];
%rudder for the real system, NOT for the extended one    
rudder{1} = rudMPC;
rudder{2} = rudLQR;
      
rudderTime{1} = timeRunMPC;
rudderTime{2} = time;
    
%state estimated by the time vayring Kalman filter
yawEstVector = [xHatEstMPC(2,:);
                xHatEstLQR(2,:)];

for i = 1 : 2
   index = i;
   
   subplot(2, 2, index);
   title('state');
   
   plot(time(2:end), yawReal(i, :) .* 180 / pi, ...
       'LineWidth', 1.9, 'Color', [88 25 225] ./ 255);
   hold on;
   plot([time(2) time(end)], [limitYaw limitYaw] .* 180 / pi, 'r-.', 'LineWidth', lW0);
   
   if useRealState == 0
       plot(time(2:end-1), yawEstVector(i, :) .* 180 / pi, 'c-.', ...
           'LineWidth', 1.9, 'Color', [245 86 1] ./ 255);
   end
   grid on;
   ylabel('[deg]');
   xlabel('Time [sec]');
   xlim([time(1) time(end)]);
   legend(leg{index});
   
   %add yawRef as tick in Y axis
%    tmp = get(gca, 'YTick');
%    tmp = [tmp yawRef * 180 / pi];
%    tmp = sort(tmp);
%    set(gca, 'YTick', tmp);
   
   index = i + 2;
   
   subplot(2, 2, index);
   title('input');
   
   timeR = rudderTime{i};
   plot(timeR, rudder{i}, 'm--*', 'LineWidth', 1.4);
   hold on;
   plot([timeR(1) timeR(end)], [rudderMax rudderMax], 'r-.', 'LineWidth', lW0);
   plot([timeR(1) timeR(end)], [-rudderMax -rudderMax], 'r-.', 'LineWidth', lW0);
   grid on;
   ylabel('Rudder [cmd]');
   xlabel('Time [sec]');
   xlim([timeR(1) timeR(end)]);
   legend(leg{index}, 'Location', 'southwest');
   
end

% plot estimated state

% xEstVector = [xEstMPC;
%               xEstLQR];
%             
% leg = {'w MPC', '\psi MPC', 'w LQR', '\psi LQR'};
% labels= {'deg/s', 'deg', 'deg/s', 'deg'};
% 
% lW2 = 1.2;
% 
% figure;
% 
% for i = 1 : 4
%    subplot(2, 2, i);
%    
%    plot(time(1:end-1), xEstVector(i, :) .* 180 / pi, 'LineWidth', lW2);
%    grid on;
%    ylabel(labels{i});
%    xlabel('Time [sec]');
%    xlim([time(1) time(end-1)]);
%    legend(leg{i});
%    
% end




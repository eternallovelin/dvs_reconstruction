%function [ map, gradients, theta_est ] = trackingTest2()

imagepath = 'camera_simulation/testimages/panorama.png';
% imagepath = 'camera_simulation/testimages/checkerboard_small.jpg';
% imagepath = 'camera_simulation/testimages/churchtest_downscaled.jpg';
% imagepath = 'camera_simulation/testimages/SonyCenter.jpg';

step_size = 0.000001;



thetaCheckpoints = ...
    0.001 * ...
   [pi/4, pi/4, 0 ; ...
   -pi/4, -pi/4, 0; ...
   pi/4, -pi/4, 0; ...
   -pi/4, pi/4, 0];

omegas = ...
    step_size * ...
    [-1, -1, 0; ...
    1, 0, 0; ...
    -1, 1, 0];


%[events_raw1, TS1, theta_gt1, endState1] = flyDiffCam2(imagepath, [0 0 0], steps*omega, omega, zeros(simulationPatchSize()));


allAddr = [];
allTS = 0; %set first number 0 to have reference for first bunch of stamps
allThetas = [];
intermediateState = zeros(simulationPatchSize());

for i = 1:size(thetaCheckpoints, 1) - 1
    
    fprintf('simulating subpath %d/%d\n', i, size(omegas, 1));
    
    [addr, ts, thetas, intermediateState] = flyDiffCam2(imagepath, thetaCheckpoints(i, :), thetaCheckpoints(i+1, :), omegas(i, :), intermediateState);
    
    allAddr = [allAddr; addr];
    allTS = [allTS; ts + allTS(end)];
    allThetas = [allThetas; thetas]; % ground truth
    
    disp([ ' ---> ' num2str(size(addr)) ' events generated']);
end

allTS = allTS(2:end); %remove pending 0;


disp([ num2str(size(allAddr)) ' events generated']);

[map, gradients, theta_est ] = trackingTest_combinedAverage(allAddr, allTS, allThetas, imagepath);

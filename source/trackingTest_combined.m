function [ map, gradients, theta_est ] = trackingTest_combined(events_raw, TS, theta_gt, imagepath)

if nargin < 4
    imagepath = 'camera_simulation/testimages/panorama.png';
end

img = im2double(rgb2gray(imread(imagepath)));


[x, y, pol] = extractRetinaEventsFromAddr(events_raw);
events = [double(x+1) double(y+1) double(pol) double(TS)];

for i = 1:10
    disp(['event ' num2str(i) ' at ' num2str([events(i,1) events(i,2)]) ' pol = ' num2str(events(i,3)) '(' num2str(events(i,:)) ')']);
end

disp(['got ' num2str(size(events,1)) ' events']);

% prepare variables for reconstruction
outputImageSize = [500, 1000];
boundary_image = 0.5*ones(outputImageSize);
% origin = outputImageSize ./ 2;
% gradients = zeros([2, outputImageSize]);
covariances = 10*repmat(eye(2), [1, 1, outputImageSize]);
lastSigs = zeros(128);

% lastPos = round(reshape(cameraToWorldCoordinatesBatch(getInvKPsforPatch(cameraIntrinsicParameterMatrix()), [0 0 0], outputImageSize)', [2 128 128]));
% lastPos = repmat(origin', [1, 128 128]);
lastPos = repmat([1000000000 1000000000]', [1, 128 128]);

secToLastSigs = lastSigs;
secToLastPos = lastPos;

[gradients, nextInd] = integrateInitialEvents(events, 2000, outputImageSize);

pgrads = permute(gradients, [2 3 1]);
% size(pgrads)
% size(boundary_image)
map = poisson_solver_function(pgrads(:,:,2), pgrads(:,:,1), boundary_image);
if ~exist('intermediate_map_figure', 'var') || ~ishandle(intermediate_map_figure)
    intermediate_map_figure = figure('Name', 'Currently used map');
else
    figure(intermediate_map_figure);
end
imshow(map);
drawnow;


% update on events
N = 200;
[particles, tracking_state] = initParticles(N, [128 128]);



theta_est = zeros(size(events, 1), 3);

lastPosUpdated = false;

% initialPatch = cameraToWorldCoordinatesBatch(getInvKPsforPatch(cameraIntrinsicParameterMatrix()), [0 0 0], outputImageSize);
originInitial = cameraToWorldCoordinates(64, 64, cameraIntrinsicParameterMatrix(), [0 0 0], outputImageSize);
% movementDetectedTimestamp = 1000000000;
% useGeneratedMap = false;
last_timestamp = events(nextInd-1,4);
events(nextInd:end,4) = events(nextInd:end,4);

for i = nextInd:size(events,1)
    
    deltaT_global = events(i,4) - last_timestamp;
    last_timestamp = events(i,4);
    
    % actually perform Bayesian update
    particles = predict(particles, deltaT_global);
    
        [particles, tracking_state] = updateOnEvent(particles, events(i,:), map, tracking_state);
%     [particles, tracking_state] = updateOnEvent(particles, events(i,:), img, tracking_state);
    
    theta_est(i,:) = particleAverage(particles);

    
    if ~lastPosUpdated && (sum(abs(originInitial - cameraToWorldCoordinates(64, 64, cameraIntrinsicParameterMatrix(), theta_est(i,:), outputImageSize))) > 5)
        lastPosUpdated = true;
        newLastPos = reshape(cameraToWorldCoordinatesBatch(getInvKPsforPatch(cameraIntrinsicParameterMatrix()), [0 0 0], outputImageSize)', [2 128 128]);
        covariances = 10*repmat(eye(2), [1, 1, outputImageSize]);
        lastPos(lastPos == repmat([1000000000 1000000000]', [1, 128 128])) = newLastPos(lastPos == repmat([1000000000 1000000000]', [1, 128 128]));
    end
    
    [gradients, covariances, lastSigs, lastPos, secToLastSigs, secToLastPos] = updateMosaic(events(i,1), events(i,2), events(i,3), events(i,4), theta_est(i,:), gradients, covariances, lastSigs, lastPos, secToLastSigs, secToLastPos);
    
%     if useGeneratedMap && mod(i,100) == 0
    if mod(i, 100) == 0
        pgrads = permute(gradients, [2 3 1]);
        map = poisson_solver_function(pgrads(:,:,2), pgrads(:,:,1), boundary_image);
%         disp(['map extreme values: [' num2str(min(min(map))) ', ' num2str(max(max(map))) ']']);
% %         disp(['image extreme values: [' num2str(min(min(img))) ', ' num2str(max(max(img))) ']']);
%     elseif ~useGeneratedMap
%         useGeneratedMap = norm(theta_est(i,1:2)) > 0.3;
    end
    
    %     if deltaT_global > 0; [map, ~] = reconstructMosaic(events_raw(1:i), TS(1:i), theta_est(1:i, :)); end;
   
    
    
    if mod(i, 100) == 0
        disp(['updated on event ' num2str(i) ...
            ' (time ' num2str(events(i,4)) ')' ...
            ' = ' num2str(events(i,1:3)) ...
            ' err = ' num2str(norm(theta_gt(i,:) - theta_est(i,:))) ...
            ' deltaT_global = ' num2str(deltaT_global) ...
            ' mean = ' num2str(particleAverage(particles)) ...
            ' eff. no. = ' num2str(effectiveParticleNumber(particles))]);
    end
    
    if mod(i, 500) == 0
        if ~exist('intermediate_map_figure', 'var') || ~ishandle(intermediate_map_figure)
            intermediate_map_figure = figure('Name', 'Currently used map');
        else
            figure(intermediate_map_figure);
        end
        plotCameraPositionsInImage(map, theta_est(1:i,:), theta_gt(1:i,:));
        drawnow;
        
%         if ~exist('new_map_figure', 'var') || ~ishandle(new_map_figure)
%             new_map_figure = figure('Name', 'Build map');
%         else
%             figure(new_map_figure);
%         end
%         pgrads = permute(gradients, [2 3 1]);
%         newMap = poisson_solver_function(pgrads(:,:,2), pgrads(:,:,1), boundary_image);
%         imshow(newMap);
%         drawnow;
%         
%         if ~exist('new_scaled_map_figure', 'var') || ~ishandle(new_scaled_map_figure)
%             new_scaled_map_figure = figure('Name', 'Build map (scaled)');
%         else
%             figure(new_scaled_map_figure);
%         end
%         imagesc(newMap);
%         colorbar;
%         colormap('gray');
        drawnow;
    end
    
    if mod(i, 1000) == 0
        
        if ~exist('tracking_test2_figure', 'var') || ~ishandle(tracking_test2_figure)
            tracking_test2_figure = figure('Name', 'Particles');
        else
            figure(tracking_test2_figure);
        end
        plotParticles(particles, theta_gt(i,:)); drawnow; %waitforbuttonpress;
        
        if ~exist('scaled_map_figure', 'var') || ~ishandle(scaled_map_figure)
            scaled_map_figure = figure('Name', 'scaled map');
        else
            figure(scaled_map_figure);
        end
        imagesc(map)
        colorbar;
        colormap(scaled_map_figure, 'gray');
        
        if ~exist('map_gradient_figure', 'var') || ~ishandle(map_gradient_figure)
            map_gradient_figure = figure('Name', 'map gradient');
        else
            figure(map_gradient_figure);
        end
        [X, Y] = meshgrid(1:size(gradients,3), 1:size(gradients,2));
        quiver(X, Y, permute(gradients(1,:,:), [2 3 1]), permute(gradients(2,:,:), [2 3 1]));
        
        drawnow;
        disp(['map extreme values: [' num2str(min(min(im2uint8(map)))) ', ' num2str(max(max(im2uint8(map)))) ']']);
        disp(['image extreme values: [' num2str(min(min(img))) ', ' num2str(max(max(img))) ']']);
    end
        
    
    % resample distribution if particles become too unevenly distributed
    if effectiveParticleNumber(particles) < size(particles,1)/2; % paper uses 50%state
        particles = resample(particles);
        effno = effectiveParticleNumber(particles);
        disp(['resampled -> mean = ' num2str(mean(particles,1)) '  eff. no. = ' num2str(effno)]);
%         if ~exist('tracking_test2_figure', 'var') || ~ishandle(tracking_test2_figure)
%             tracking_test2_figure = figure();
%         else
%             figure(tracking_test2_figure);
%         end
%         plotParticles(particles, theta_gt(i,:)); drawnow;% waitforbuttonpress;
    end
    drawnow;
end

disp(['final mean = ' num2str(particleAverage(particles)) '  eff. no. = ' effectiveParticleNumber(particles)]);

travelled_distance = sqrt(sum(theta_gt.^2, 2))';
err = sqrt(sum((theta_gt - theta_est).^2, 2))';
relerr = err ./ travelled_distance;

if ~exist('errorplot_figure', 'var') || ~ishandle(errorplot_figure)
    errorplot_figure = figure();
else
    figure(errorplot_figure);
end
semilogy(1:size(theta_gt,1), err, 'r', 1:size(theta_gt,1), relerr, 'b', 1:size(theta_gt,1), travelled_distance, 'g');
legend('total error', 'error relative to overall movement', 'overall movement');


pgrads = permute(gradients, [2 3 1]);
map = poisson_solver_function(pgrads(:,:,2), pgrads(:,:,1), boundary_image);
disp(['map extreme values: [' num2str(min(min(map))) ', ' num2str(max(max(map))) ']']);
disp(['image extreme values: [' num2str(min(min(img))) ', ' num2str(max(max(img))) ']']);

if ~exist('intermediate_map_figure', 'var') || ~ishandle(intermediate_map_figure)
    intermediate_map_figure = figure();
else
    figure(intermediate_map_figure);
end
plotCameraPositionsInImage(map, theta_est, theta_gt);
% colormap(intermediate_map_figure, 'gray');

if ~exist('scaled_map_figure', 'var') || ~ishandle(scaled_map_figure)
    scaled_map_figure = figure('Name', 'scaled map');
else
    figure(scaled_map_figure);
end
imagesc(map)
colorbar;
colormap(scaled_map_figure, 'gray');
drawnow;

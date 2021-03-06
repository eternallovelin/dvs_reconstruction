function [camCoords, width, height] = initialWorld2CamBatch(imgSize)

% get global parameters
params = getParameters();

lt = round(cameraToWorldCoordinates(1, 1, params.cameraIntrinsicParameterMatrix, [0 0 0], imgSize));
rt = round(cameraToWorldCoordinates(params.simulationPatchSize, 1, params.cameraIntrinsicParameterMatrix, [0 0 0], imgSize));
lb = round(cameraToWorldCoordinates(1, params.simulationPatchSize, params.cameraIntrinsicParameterMatrix, [0 0 0], imgSize));

origin = imgSize/2;

xRange = (lt(2)+1):(rt(2)-1);
yRange = (lt(1)+1):(lb(1)-1);

camCoords = zeros(2, size(yRange,2), size(xRange,2));

for x = xRange
    for y = yRange
        p = params.cameraIntrinsicParameterMatrix * [tan(([y x] - origin)*(2*pi)/imgSize(2)), 1]';
        camCoords(:, y-yRange(1)+1, x-xRange(1)+1) = p(1:2);
    end
end
width = size(xRange,2);
height = size(yRange,2);
camCoords = permute(camCoords, [2 3 1]);
camCoords = reshape(camCoords, [], 2);
end
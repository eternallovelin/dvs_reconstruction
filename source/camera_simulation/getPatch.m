function patch = getPatch(img, K, alpha, beta, gamma)

% Extracts a 128*128 pixel patch out of the given image, assuming this is a 360�
% panorama. The FOV depends on the given camera intrinsic parameter matrix
% K and the camera orientation in angles alpha, beta, gamma around x-, y-
% and z-axis in image space (z axis points away from camera)

patch = uint8(zeros(128));
invK = inv(K);

origin = round(size(img)/2);

for u = 1:128
    for v = 1:128
        invKP = invK*[u v 1]';
        thetaAlpha = atan(cos(-gamma)*invKP(2) + sin(-gamma)*invKP(1));
        thetaBeta = -atan(cos(-gamma)*invKP(1) - sin(-gamma)*invKP(2));
        targetP = [beta + thetaBeta, alpha + thetaAlpha]; 
        
        patch(v, u) = img(round(targetP(2)*size(img, 2)/(2*pi)) + origin(1), round(targetP(1)*size(img, 2)/(2*pi)) + origin(2));
    end
end
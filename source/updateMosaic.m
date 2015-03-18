function [gradients, covariances, lastSigs, lastPos] = updateMosaic(u, v, pol, timestamp, theta, K, gradients, covariances, lastSigs, lastPos)

% This function an event and updates the mosaic, gradients, covariances and
% history with an EKF

C = pixelIntensityThreshold(); %DUMMY - log intensity change that causes an event
R = 20; %DUMMY - measurement noise

% debug output
% u
% v
% theta
% timestamp
% pause(0.1);

% compute tau
tau = double(timestamp - lastSigs(v, u));

%compute pixel in global image space
invKP = K \ [u v 1]';
deltaAlpha = atan(cos(-theta(3))*invKP(2) + sin(-theta(3))*invKP(1));
deltaBeta = atan(cos(-theta(3))*invKP(1) - sin(-theta(3))*invKP(2));
p = [-(theta(2) + deltaBeta)*size(gradients, 3)/(2*pi) , (theta(1) + deltaAlpha) * size(gradients, 3)/(2*pi)];
pmt = round(p + ([size(gradients, 3), size(gradients, 2)] ./ 2))';

% get last position of this pixel
pmTau = lastPos(:, v, u);

% compute speed
velocity = (pmt - pmTau) ./ tau;

% get global pixel gradient from matrix
gTau = gradients(:, pmt(2), pmt(1));

z = 1/tau;

h = (gTau' * velocity) / (pol*C); %different from paper - possible bugfix??

% compute innovation
nu = z - h;

% compute dh/dg - formula 15
% dhdg = [velocity(2) velocity(1)] ./ C;
dhdg = pol * velocity' ./ C;

% get covariances from matrix
PgTau = covariances(:,:,pmt(2),pmt(1));

% compute innovation covariance
S = dhdg * PgTau * dhdg' + R;

% compute Kalman gain
W = PgTau * dhdg' ./ S;

% compute updated covariance
% Pgt = PgTau - (W * S * W');
Pgt = PgTau - (PgTau * dhdg' * W'); % try to avoid numerical errors

% compute updated gradient
gt = gTau + (W * nu);
% gt = min([[1;1], max([[-1;-1], gTau + (W * nu)], [], 2)], [], 2); %clamp values

% if sum(sum(gt > 1)) + sum(sum(gt < -1)) > 0
%     fprintf('clamping gradient to [-1, 1]\n');
%     gt(gt > 1) = 1;
%     gt(gt < -1) = -1;
% end

% debug
% if pol == -1
%     pol
%     tau
%     pmt
%     pmTau
%     velocity
%     gTau
%     z
%     h
%     nu
%     dhdg
%     PgTau
%     S
%     W
%     Pgt
%     gt
%     0;
% end

% if abs(gt(1)) > 0.05 || abs(gt(2)) > 0.05
%     tau = tau
%     gTau = gTau
%     velocity = velocity
%     zh = [z h]
%     nu = nu
%     PgTau = PgTau
%     S = S
%     W = W
%     dhdg = dhdg
%     gt = gt
%     pause(1);
% end

if sum(isnan(gt)) > 0
    fprintf('gradient is NaN (updateMosaic)\n');
%     u
%     v
%     pol
%     theta
    tau
%     timestamp
%     lastSigs(v, u)
%     pmt
%     pmTau
%     velocity
%     gTau
%     z
%     h
%     nu
%     dhdg
%     PgTau
%     S
%     W
%     Pgt
%     gt
%     pause(0.1);
    return;
end

% update matrices
covariances(:,:,pmt(2),pmt(1)) = Pgt;
gradients(:,pmt(2),pmt(1)) = gt;
lastSigs(v, u) = timestamp;
lastPos(:,v,u) = pmt;

% fprintf('updating gradients(%d, %d) = [%f, %f]\n', pmt(2), pmt(1), gt(1), gt(2));
% pause(1)

return;
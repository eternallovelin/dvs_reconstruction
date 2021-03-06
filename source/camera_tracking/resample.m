function particles = resample(old_particles)
% resamples particles by copy a particle with probability according to its weight
%
% input:  Nx4 list of particles [normalized weight, 3xrot]
% output: Nx4 resampled list of particles

% TODO: there are exacter ways to implement resampling

particles = zeros(size(old_particles));
for i = 1:size(particles,1)
    
    % choose a particle
    u = rand(1);
    
    % actually find chosen particle
    tmp_sum = 0;
    for k = 1:size(old_particles,1)
        if (u >= tmp_sum) && (u < tmp_sum+old_particles(k,1))
            break;
        end
        tmp_sum = tmp_sum + old_particles(k,1);
    end
    
    % copy
    particles(i,2:end) = old_particles(k,2:end);
    
    % assign new weight
    %particles(i,1) = 1/size(particles,1); % uniform
    particles(i,1) = old_particles(k,1); % keep old weight
    %particles(i,1) = old_particles(k,1) + 1/size(particles,1); % some sort of weighted average
end

% renormalize weights
particles(:,1) = particles(:,1) / sum(particles(:,1));

s = sum(particles(:,1));
assert((s >= 1-1e-13) && (s <= 1+1e-13), ['New weights must sum to 1. diff = ' num2str(1-s)]);
assert(sum(particles(:,1)<0) == 0, 'New weights must be >= 0.');
assert(~any(isnan(particles(:))), 'No invalid values (NaN).');

end
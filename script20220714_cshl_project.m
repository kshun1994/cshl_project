%% Set color and defaults

close all
clear
clc

color.imperialRed   = [230  57  70] ./ 255;
color.tuftsBlue     = [ 48 131 220] ./ 255;
color.oceanGreen    = [115 186 155] ./ 255;
color.carrotOrange  = [244 157  55] ./ 255;
color.africanViolet = [180 126 179] ./ 255;
color.yellowGreen   = [159 211  86] ./ 255;
color.safetyYellow  = [235 211  49] ./ 255;
color.darkSlateBlue = [ 82  72 156] ./ 255;
color.rhythm        = [119 125 167] ./ 255;
color.warmBlack     = [  3  71  72] ./ 255;

colors = struct2cell(color);

set(0, 'DefaultLineLineWidth', 1)
set(0, 'DefaultFigureWindowStyle', 'docked')
set(0, 'DefaultAxesFontSize', 20)

%% Create a tuning curve

% Default tuning curve using Ecker et al. parameters
paramDefault = [1, 19, 2, 0];
orientations = linspace(0, 180, 1e3);
tuningDefault = FuncInputToUnit(paramDefault, orientations);

figure('Name', 'Default Tuning Curve')
plot(orientations, tuningDefault, 'Color', color.imperialRed)
title('Default Tuning Curve')
xlim([orientations(1) orientations(end)])
xlabel(sprintf('Stimulus Orientation (^o)'))
xticks(linspace(orientations(1), orientations(end), 5))
ylim([0 max(tuningDefault(:))])
ylabel('Response (ips)')

%% Multiple tuning curves

% Generate a bunch of tuning curves with uniform random peaks
n = 50;
prefOris = linspace(-90, 90, n); % rand(n, 1) .* 180 - 90;
params = repmat(paramDefault, [n, 1]);
params(:, end) = prefOris;
tunings = FuncInputToUnit(params, orientations);

figure('Name', 'Sampling Orientation Preferences')
hold on
for i = 1:n
  plot(orientations, tunings(i, :), ...
    'Color', colors{1 + mod(i, numel(colors))})
end
title('Tuning Curves')
xlim([orientations(1) orientations(end)])
xlabel(sprintf('Stimulus Orientation (^o)'))
xticks(linspace(orientations(1), orientations(end), 5))
ylim([0 max(tunings(:))])
ylabel('Response (ips)')

%% Varying tuning width

% Generate a bunch of tuning curves with uniformly sampled peaks and 
%   random tuning widths
n = 50;
prefOris = linspace(-90, 90, n); % rand(n, 1) .* 180 - 90;

% Create list of possible gamma values
possibleGammas = 2 .^ (0:0.5:4);
% Sample with replacement n times from possible gammas
gammas = datasample(possibleGammas, n);

params = repmat(paramDefault, [n, 1]);
params(:, end) = prefOris;
params(:, 3) = gammas;
tunings = FuncInputToUnit(params, orientations);

figure('Name', 'Varying Tuning Width')
hold on
for i = 1:n
  plot(orientations, tunings(i, :), ...
    'Color', colors{1 + mod(i, numel(colors))})
end
title('Tuning Curves')
xlim([orientations(1) orientations(end)])
xlabel(sprintf('Stimulus Orientation (^o)'))
xticks(linspace(orientations(1), orientations(end), 5))
ylim([0 max(tunings(:))])
ylabel('Response (ips)')

%% Varying tuning width and peak height

% Generate a bunch of tuning curves with uniformly sampled peaks and 
%   random tuning widths, random peak firing rates
n = 50;
prefOris = linspace(-90, 90, n); % rand(n, 1) .* 180 - 90;

% Create list of possible gamma values
possibleGammas = 2 .^ (0:0.5:4);
% Sample with replacement n times from possible gammas
gammas = datasample(possibleGammas, n);

% Random peak firing rates (Gaussian distributed around 30 with sigma 10)
betas = normrnd(30, 10, [n 1]) - paramDefault(1);
betas(betas < paramDefault(1)) = paramDefault(1); % Baseline

params = repmat(paramDefault, [n, 1]);
params(:, 2) = betas;      % Assign peaks
params(:, 3) = gammas;     % Assign widths
params(:, end) = prefOris; % Assign preferred orientations
tunings = FuncInputToUnit(params, orientations);

figure('Name', 'Varying Tuning Width/Height')
hold on
for i = 1:n
  plot(orientations, tunings(i, :), ...
    'Color', colors{1 + mod(i, numel(colors))})
end
title('Tuning Curves')
xlim([orientations(1) orientations(end)])
xlabel(sprintf('Stimulus Orientation (^o)'))
xticks(linspace(orientations(1), orientations(end), 5))
ylim([0 max(tunings(:))])
ylabel('Response (ips)')

%% Actual simulation stuff

% Number of units
n = 1e3;

orientations = linspace(0, 180, 1e3);

% Parameters
preferredOris   = rand(n, 1) .* max(orientations);
spontaneousRate = ones(n, 1);                               % alpha
peakRate        = normrnd(15, 10, [n 1]) - spontaneousRate; % beta
peakRate(peakRate < 0) = 0;
widths          = datasample(2 .^ (0:0.25:3), n)';          % gamma

% Construct params vector
params = [spontaneousRate peakRate widths preferredOris];
paramLabels = { ...
  'Spontaneous Rate', ...
  'Peak Firing Rate', ...
  'Curve Width Parameter', ...
  'Preferred Orientation' ...
  };

% Plot distributions of parameters
figure('Name', 'Parameter Distributions')
for i = 1:size(params, 2)

  subplot(2, 2, i)
  histogram(params(:, i), 'FaceColor', colors{i}, 'EdgeColor', 'none')
  title(sprintf('%s Distribution', paramLabels{i}))
    ylabel('Count')

  % Constrain x axis just for orientation domain
  if (strcmp(paramLabels{i}, 'Preferred Orientation'))

    xlim([orientations(1) orientations(end)])
    xticks(linspace(orientations(1), orientations(end), 5))

  end

end

%% Test model output

testOri = [0 5]; % deg
testCon = 1;

testStimuli.orientation = testOri;
testStimuli.contrast    = testCon;

testNoise.type = 'Poisson';
testNoise.parameters = [0 20];

output = FuncInputToModel(params, testStimuli, testNoise);

% Plot firing rates as a function of preferred orienation
figure('Name', 'Model Output')
hold on
for i = 1:numel(testOri)

%   subplot(1, numel(testOri), i)
  scatter(preferredOris, output(:, i), 50, ...
    'MarkerFaceColor', colors{i}, 'MarkerEdgeColor', 'none', ...
    'MarkerFaceAlpha', 0.75)
  
end

title(sprintf('Population Response\n%s Noise', testNoise.type))
xlabel(sprintf('Unit Preferred Orientation (^o)'))
xlim([0 max(orientations)])
xticks([linspace(0, max(orientations), 5)])
ylabel('Response (ips)')
ylim([0 max(output(:))])
lgd = legend(cellfun(@(x) sprintf('%g^o', x), num2cell(testOri), ...
  'UniformOutput', false));
title(lgd, 'Stimulus Orientation')

%% Try discriminating whatever



%%
% 
% corrMagnitude = 0.2;
% mu = 50;
% sigma = 5;
% N = 3;
% M = mu + sigma*randn(1000,N);
% % R = [1 corrMagnitude corrMagnitude;corrMagnitude corrMagnitude 1];
% R = eye(N);
% R(~R) = corrMagnitude;
% L = chol(R);
% M = M*L;
% x = M(:,1);
% y = M(:,2);
% % corr(x,y)
% % corr(M(:,1), M(:,3))


%% Functions

function unitOutput = FuncInputToUnit(param, stimulus)
% From Ecker et al. 2011:
%   R(theta) = alpha + beta * exp(gamma * (cos(theta - phi) - 1))
%     phi -> preferred orientation
%     alpha, beta, gamma -> parameters fit to data
%        [alpha, beta, gamma] = [1, 19, 2] in Ecker et al. 2010,
%        gives tuning curves with a max firing rate of 20 Hz
% param -> 4-element vector
%   param(1) -> alpha; baseline firing rate
%   param(2) -> beta; peak height above baseline
%   param(3) -> gamma; changes tuning width w/o changing peak height
%   param(4) -> preferred orientation [in degrees]
% ori -> stimulus orientation

  alpha   = param(:, 1);
  beta    = param(:, 2);
  gamma   = param(:, 3);
  prefOri = param(:, 4);

  if (isstruct(stimulus))

    ori = stimulus.orientation;
    con = stimulus.contrast;

  elseif (isnumeric(stimulus))

    ori = stimulus;
    con = 1;

  end

  % Multiply everything by two to get things to be circular within [0 180)
  ori     = 2 .* ori;
  prefOri = 2 .* prefOri;

  unitOutput = alpha + beta .* exp(gamma .* ...
    (cosd(repmat(ori, [size(param, 1) 1]) - prefOri) - 1));

  unitOutput = unitOutput .* con;

% unitOutput = alpha + ((2 .* beta) .* (exp(gamma .* cosd(ori - prefOri))) ...
%   ./ (2 .* pi .* besseli(0, gamma)));

% unitOutput = exp(gamma .* cosd(ori - prefOri)) ...
%   ./ (2 .* pi .* besseli(0, gamma));
% 
% % Scale max response to designated max
% unitOutput = unitOutput .* (beta ./ max(unitOutput, [], 2));
% 
% % Add baseline
% unitOutput = unitOutput + alpha;

end

% FuncInputToUnit = @(param, ori) ...
%   param(:, 1) + param(:, 2) .* exp(param(:, 3) ...
%   .* (cosd(repmat(ori, [size(param, 1) 1]) - param(:, 4)) - 1));

function modelOutput = FuncInputToModel(varargin)

  % Takes a set of N units defined by four tuning parameters, gets 
  %   each unit's response to the given stimOri, then noises the response

  param     = varargin{1};
  stimulus  = varargin{2};

  modelOutput = FuncInputToUnit(param, stimulus);

  % If a noise parameter isn't specified, model output is unnoised
  if (nargin > 2)

    assert(isstruct(varargin{3}), 'Noise parameter is not a struct.')
    noiseParams = varargin{3};

    switch lower(noiseParams.type)

      case 'unnoised'

        % Do nothing to output if noiseless is specified

      case 'poisson'

        modelOutput = poissrnd(modelOutput);

      case 'gaussian'

        assert(isfield(noiseParams, 'parameters'), ...
          'Gaussian noise parameters not specified.')

        assert(isnumeric(noiseParams.parameters) && ...
               (numel(noiseParams.parameters) == 2), ...
          ['Gaussian noise parameters must be input as a 2-element ' ...
          'vector with format [mu sigma]'])

        mu    = noiseParams.parameters(1);
        sigma = noiseParams.parameters(2);

        modelOutput = modelOutput + normrnd(mu, sigma, size(modelOutput));

      otherwise

        warning("Noise parameter must be either 'Unnoised', " + ...
          "'Poisson', or 'Gaussian'. Defaulting to Unnoised model output.")

    end

  end


end























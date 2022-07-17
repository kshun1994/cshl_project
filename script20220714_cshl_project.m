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
spontaneousRate = normrnd(2, 1, [n 1]);                    % alpha
spontaneousRate(spontaneousRate < 0) = 0;
peakRate        = normrnd(15, 10, [n 1]) - spontaneousRate; % beta
peakRate(peakRate < 0) = 0;
widths          = datasample(2 .^ (0:0.25:3), n)';          % gamma

% Construct params vector
clear params
params.tuningParameters = [spontaneousRate peakRate widths preferredOris];
paramLabels = { ...
  'Spontaneous Rate', ...
  'Peak Firing Rate', ...
  'Curve Width Parameter', ...
  'Preferred Orientation' ...
  };

% Plot distributions of parameters
figure('Name', 'Parameter Distributions')
for i = 1:size(params.tuningParameters, 2)

  subplot(2, 2, i)
  histogram(params.tuningParameters(:, i), 'FaceColor', colors{i}, 'EdgeColor', 'none')
  title(sprintf('%s Distribution', paramLabels{i}))
    ylabel('Count')

  % Constrain x axis just for orientation domain
  if (strcmp(paramLabels{i}, 'Preferred Orientation'))

    xlim([orientations(1) orientations(end)])
    xticks(linspace(orientations(1), orientations(end), 5))

  end

end

%% Test model output

testOri = [85 90]; % deg
testCon = .05;

stimuli.orientation = testOri;
stimuli.contrast    = testCon;

testNoise.type = 'Poisson';
testNoise.parameters = [0 20];

output = FuncInputToModel(params, stimuli, testNoise);

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

% Create decoder by subtracting unnoised responses from one another
decoderData = FuncInputToModel(params, stimuli);
decoder = decoderData(:, 2) - decoderData(:, 1);

% Normalize decoder to [-1, 1]
decoder(decoder > 0) = decoder(decoder > 0) ./ max(decoder(:));
decoder(decoder < 0) = decoder(decoder < 0) ./ abs(min(decoder(:)));

figure('Name', 'Decoder Weights')
scatter(preferredOris, decoder, 50, ...
  'MarkerFaceColor', color.carrotOrange, 'MarkerEdgeColor', 'none', ...
  'MarkerFaceAlpha', 0.75)
title(sprintf('Population Decoder Weights (%g^o - %g^o)', ...
  stimuli.orientation(2), stimuli.orientation(1)))
xlabel(sprintf('Unit Preferred Orientation (^o)'))
xlim([0 max(orientations)])
xticks([linspace(0, max(orientations), 5)])
ylabel('Weights')

% Generate a bunch of trials
nTrials = 1e4;
trialNoise.type = 'Poisson';
stimOri = repmat(testOri, [1 (nTrials / numel(testOri))]);

% Generate model response
trialResponses = FuncInputToModel(params, stimOri, trialNoise);

% Get DVs using decoder
dv = squeeze(sum(trialResponses .* decoder, 1));

% Display DVs split between stimulus conditions
figure('Name', 'No-NC DVs')
hold on
for i = 1:numel(unique(stimOri))

  tStim = testOri(i);
  tDV = dv(stimOri==tStim);

  histogram(tDV, 'FaceColor', colors{i}, 'EdgeColor', 'none')

end
xline(median(dv), '--', 'Criterion', 'FontSize', 20)
title(sprintf('Decision Variable Distribution (N = 10^{%g} trials)', ...
  log10(nTrials)))
xlabel('DV Value')
ylabel('Count')
lgd = legend(cellfun(@(x) sprintf('%g^o', x), num2cell(testOri), ...
  'UniformOutput', false));
title(lgd, 'Stimulus Orientation')

%% Create a second population with global noise correlations

paramsNC = params;
% paramsNC(:, 1) = zeros(size(paramsNC, 1), 1)+0.01;
noiseCorrMagnitude = 0.2;
trialNoiseNC = trialNoise;

R = eye(n);
R(~R) = noiseCorrMagnitude;

paramsNC.correlationMatrix = R;

% Test correlation with 0% contrast stimuli
nTrials = 1e2;
stimOri = zeros(1, nTrials);
stimuliZeroCon = stimuli;
stimuliZeroCon.orientation = stimOri;
stimuliZeroCon.contrast = 0;

% Generate model response
trialResponsesTest = ...
  FuncInputToModel(paramsNC, stimuliZeroCon, trialNoiseNC);

% Calculate correlations
corrs = corr(trialResponsesTest');

% Calculate mean NC magnitude (excluding the 1s down the diagonal)
meanNC = mean(corrs(~eye(size(corrs, 1))));
fprintf('Noise correlations of %0.2f\n', meanNC)

%% Do the same stuff

% Create decoder by subtracting unnoised responses from one another
decoderData = FuncInputToModel(params, stimuli);
decoder = decoderData(:, 2) - decoderData(:, 1);

% Normalize decoder to [-1, 1]
decoder(decoder > 0) = decoder(decoder > 0) ./ max(decoder(:));
decoder(decoder < 0) = decoder(decoder < 0) ./ abs(min(decoder(:)));

% Generate a bunch of trials
nTrials = 1e4;
stimOri = repmat(testOri, [1 (nTrials / numel(testOri))]);
stimuliGlobalNC = stimuli;
stimuliGlobalNC.orientation = stimOri;
% stimuli.contrast = 0;

% Generate model response
trialResponsesNC = FuncInputToModel(paramsNC, stimuliGlobalNC, trialNoiseNC);

% Get DVs using decoder
dvNC = squeeze(sum(trialResponsesNC .* decoder, 1));

% Display DVs split between stimulus conditions
figure('Name', 'Global-NC DVs')
hold on
for i = 1:numel(unique(stimOri))

  tStim = testOri(i);
  tDV = dvNC(stimOri==tStim);

  histogram(tDV, 'FaceColor', colors{i}, 'EdgeColor', 'none')

end
xline(median(dvNC), '--', 'Criterion', 'FontSize', 20)
title(sprintf(['Decision Variable Distribution ' ...
  '(N = 10^{%g} trials)\nR_{NC} = %0.2f'], ...
  log10(nTrials), noiseCorrMagnitude))
xlabel('DV Value')
ylabel('Count')
lgd = legend(cellfun(@(x) sprintf('%g^o', x), num2cell(testOri), ...
  'UniformOutput', false));
title(lgd, 'Stimulus Orientation')

%% Create population with tuning-local noise correlation

% Create a population:
n = 1e3;
% Parameters
% preferredOris   = linspace(0, orientations(end), n)'; 
preferredOris   = rand(n, 1) .* max(orientations);
spontaneousRate = normrnd(2, 1, [n 1]);                     % alpha
spontaneousRate(spontaneousRate < 0) = 0;
peakRate        = normrnd(15, 10, [n 1]) - spontaneousRate; % beta
peakRate(peakRate < 0) = 0;
widths          = datasample(2 .^ (0:0.25:3), n)';          % gamma

paramsLocalNC.tuningParameters = ...
  [spontaneousRate peakRate widths preferredOris];

% Ecker 2011
% Correlation structure is:
%   c(|theta1 diff theta2|) = c_0 * exp(-(|theta1 diff theta2|) / L)
%   c_0 -> correlation of 2 neurons with identical preferred tuning
%   L -> controls spatial scale; L = 1 in Ecker 2011

FuncThetaCorr = @(theta1, theta2, c0, L) ...
  c0 .* exp(-(abs(deg2rad(theta1) - deg2rad(theta2))) / L);

% Create triangular matrices of tuning preferences for population
% Matrix of preferred tunings repeated across columns (rows are all 1 val)
thetaMatHorz = tril(repmat(preferredOris, [1 n]));
% Matrix of preferred tunings repeated across rows (columns are all 1 val)
thetaMatVert = tril(repmat(preferredOris', [n 1]));

% figure
% subplot(1,2,1)
% imagesc(thetaMatHorz)
% axis image
% set(gca,'xticklabel',[],'yticklabel',[])
% colorbar
% subplot(1,2,2)
% imagesc(thetaMatVert)
% axis image
% set(gca,'xticklabel',[],'yticklabel',[])
% colorbar

c0 = 0.2;
L = 0.25;
corrMatLocalNC = tril(FuncThetaCorr(thetaMatHorz, thetaMatVert, c0, L));
corrMatLocalNC(eye(n, 'logical')) = 1;
corrMatLocalNC = triu(corrMatLocalNC.', 1) + tril(corrMatLocalNC);
% corrMatLocalNC(triu(ones(n, 'logical'), 1)) = triu(rot90(), 1)

figure('Name', 'Tuning-based Corrs')
imagesc(corrMatLocalNC)
axis image
set(gca,'xticklabel',[],'yticklabel',[])
colorbar
title('Correlation Matrix')

paramsLocalNC.correlationMatrix = corrMatLocalNC;

%% The same

% Create decoder by subtracting unnoised responses from one another
decoderData = FuncInputToModel(paramsLocalNC, stimuli);
decoder = decoderData(:, 2) - decoderData(:, 1);

% Normalize decoder to [-1, 1]
decoder(decoder > 0) = decoder(decoder > 0) ./ max(decoder(:));
decoder(decoder < 0) = decoder(decoder < 0) ./ abs(min(decoder(:)));

% Generate a bunch of trials
nTrials = 1e4;
stimOri = repmat(testOri, [1 (nTrials / numel(testOri))]);
stimuliLocalNC = stimuli;
stimuliLocalNC.orientation = stimOri;
% stimuliLocalNC.contrast = 1;

% Generate model response
trialResponsesLocalNC = ...
  FuncInputToModel(paramsLocalNC, stimuliLocalNC, trialNoiseNC);

% Get DVs using decoder
dvLocalNC = squeeze(sum(trialResponsesLocalNC .* decoder, 1));

% Display DVs split between stimulus conditions
figure('Name', 'Local-NC DVs')
hold on
for i = 1:numel(unique(stimOri))

  tStim = testOri(i);
  tDV = dvLocalNC(stimOri==tStim);

  histogram(tDV, 'FaceColor', colors{i}, 'EdgeColor', 'none')

end
xline(median(dvLocalNC), '--', 'Criterion', 'FontSize', 20)
title(sprintf(['Decision Variable Distribution ' ...
  '(N = 10^{%g} trials)\nPeak R_{NC} = %0.2f'], ...
  log10(nTrials), c0))
xlabel('DV Value')
ylabel('Count')
lgd = legend(cellfun(@(x) sprintf('%g^o', x), num2cell(testOri), ...
  'UniformOutput', false));
title(lgd, 'Stimulus Orientation')

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

  unitOutput = alpha + beta .* con .* exp(gamma .* ...
    (cosd(repmat(ori, [size(param, 1) 1]) - prefOri) - 1));

%   unitOutput = unitOutput;

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

  assert(isstruct(param), ...
    'Parameters should be input in the form of a struct.')

  assert(isfield(param, 'tuningParameters'), ...
    'Tuning parameters not specified.')

  modelOutput = FuncInputToUnit(param.tuningParameters, stimulus);

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

  % Noise correlation stuff
  % If correlation matrix isn't specified
  if (~isfield(param, 'correlationMatrix'))

%     % Assume no correlation if none is specified
%     R = eye(size(params, 1));

  else

    R = param.correlationMatrix;

    % Get Cholesky decomposition
    L = chol(R);

    % Matrix multiply output by L
    modelOutput = (modelOutput' * L)';

  end

%   % Don't bother doing the work if there are no correlations
%   if (~all(R == 0))
% 
%   end

end

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























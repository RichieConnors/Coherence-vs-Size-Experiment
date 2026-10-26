%% Trial parameters setup & initialisation 

% Shuffle RNG
rng('shuffle');

% Define number of levels and targets
RDK_Radius_Sizes_Deg = [1.5, 2, 2.75, 3.75, 5]; % Target radius (deg)
RDK_Radius_Sizes = round(RDK_Radius_Sizes_Deg .* ppd); % Used ppd to convert sizes in degrees into pixels
Target_Degree_Sizes = round((RDK_Radius_Sizes .* 2 / ppd), 1); % Converts RDK targets from radius into diameter size in deg
coherencePercentageArray = [.3, .4, .55, .75, 1]; % Sets coherence percents (0-1) (can have as many as needed) 
levelsS = length(RDK_Radius_Sizes); % Num levels for size
levelsC = length(coherencePercentageArray); % Num levels for coherence
repetitions = 10; % How many repetitions of each variable
numTargets = levelsS * levelsC * repetitions; % Defines total num of targets

% Creates a random index for first target
RDK_Index = randi([1, numTargets]);

% Creates a grid which matches the levels of coherence and size together
[coherenceGrid, sizeGrid] = meshgrid(coherencePercentageArray, RDK_Radius_Sizes); 
coherencePairs = coherenceGrid(:); % Puts into a single array making it easier to repeat
sizePairs = sizeGrid(:);

% Repeat these pairs to cover all repetitions
coherenceArray = repmat(coherencePairs, 1, repetitions);
sizeArray = repmat(sizePairs, 1, repetitions);

% Creates a structure to store all target locations and variables more
% elegantly than arrays
targetLevels = struct();

% Create and assign locations so they appear even amount of times each
Locations = [15, 0; -15, 0]; % Field locations in degrees

% Calls a function which converts visual degrees to pixel coordinates
convertedLocations = VisualDegreesToPixels(Locations, width, height, ppd, vppd); % Call function to convert degree locations into pixel coords

% Some simple code to equally assign left and right target locations (Only
% works for two targets)
for i = 1:numTargets
    if i > numTargets/2
        targetLevels.Locations(:, i) = convertedLocations(:, 1);
    else
        targetLevels.Locations(:, i) = convertedLocations(:, 2);
    end
end

%% Target randomisation
% Randomise target appearances so not sequential. Shuffles based on num
% targets which keeps the coherence and size matched.
randIndices = randperm(numTargets); % Creates a set of random indices which can then be used to reshuffle other levels in a matched 
                                    % fashion so they still appear the correct amount of times.
targetLevels.Coherence = coherenceArray(randIndices);
targetLevels.Radius = sizeArray(randIndices);
targetLevels.Locations = targetLevels.Locations(:, randIndices);
coherencePercentage = targetLevels.Coherence(RDK_Index); % Randomly selects one of the given coherence percentages
RDK_Center_Random_Location = targetLevels.Locations(:, RDK_Index); % Gets random location for target and is the var used to define target position
RDK_Radius = targetLevels.Radius(RDK_Index); % Gets the random size of target
OG_RDK_Radius = RDK_Radius; % Store for original RDK radius so it can be reset more effectively for each kb press (this is more relevant for other versions)
lastExpansion = GetSecs(); % Tracks time of last expansion (not relevant here)
%%

%% Trial parameters
noTrials = numTargets; % Number of trials to run = amount of visual field locations
trialCount = 0; % Tracks current trial iteration
storeIndex = 1; % Index used to store relevant metrics at end of each trial (has to start from 1 in matlab)
KEY = false; % Logical which defines a Keyboard press or not
allowedKeys = KbName({'RightArrow', 'LeftArrow', 'UpArrow', 'DownArrow'});
maxTime = 10; % Max time before 'no response' per target
maxTimeOG = maxTime;
min_isi = .2; % Set min time for inter stimulus interval
max_isi = .5; % Set max time for inter stimulus interval (if wanting fixed isi, change interStimulusInterval in mainLoop to a set number)  

% Pause features
numBreaks = 5; % Set number of breaks wanted
breaks = round(linspace(0, noTrials, numBreaks+2)); % Create breaks spaced evenly from beginning to end
breaks = breaks(2:end-1); % Remove first and last breaks as they occur at first and end
PAUSE = false; % Toggle to pause experiment until p is pressed again
takeBreak = false; % Boolean for breaks
preResponse = 1; % Used to keep pause from crashing
%%

%% Dot Parameters
dotSizeDeg = .3; %.25; % Input size of dots in degrees (.25 deg = 10px on my screen)
dotsPerDegree = 6.5; %10.44; % Can input num dots wanted or percentage which represents the num of dots per pixel area, again with 10% representing 10% of pixels available
dotVelocityDeg = 3; %1.0878; % Desired velocity in degrees per second
dotColour = [.5 .5 .5]; % Colour of dots
minLifetime = .2; % Set the minimum length of time (s) which dots move before chosing a new path
maxLifetime = .75; % Set the maximimum length of time (s) which dots move before chosing a new path

% Transformed parameters
dotSize = round(dotSizeDeg * ppd); % Size of dot radii (pixels)
if dotSize < 1
    dotSize = 1; % Ensure dots are at least 1 pixel in size as this is min value psychtoolbox drawdot() allows
end
noDots = round(dotsPerDegree*screenAreaDeg); % Number of overall dots
dotColours = repmat(dotColour, noDots, 1); % Used to assign each dot an individual colour value (used for creating a 'glaucoma' mask effect) 
dotVelocity = round((dotVelocityDeg/frameRate) * ppd, 2); % Speed of dots, approx pixels per frame (if using delta time convert to pixels per second (* 60)). Multiply by fps to get pixels per second. Can input directly as px amount if preferred.

% Set timers for dots
maxLifetime = (RDK_Radius*2) / (dotVelocity*frameRate);%.2 / dotVelocityDeg; % Set the minimum length of time (s) which dots move before chosing a new path
minLifetime = maxLifetime*.75; %.75 / dotVelocityDeg; % Set the maximimum length of time (s) which dots move before chosing a new path
dotTimers = minLifetime + (maxLifetime - minLifetime) .* rand(1, noDots); % Random timers for random dots before they are given new movement paths (not lifetimes but similar in a sense)

% Other variables
newPath = false(1, noDots); % Logical array to track if random dots need a new path after reaching their timer
dotRadians = rand(1, noDots) * pi * 2; % Create radians for which to base angular movement on, and allow 360 movement paths for dots
dotSizes = repmat(dotSize, 1, noDots);
OGdotSizes = dotSizes;
originalDotColours = dotColours; % Used to keep original dot colours so if mask is applied the colour can be reset for new trials
dotDensityPerPixel = round(noDots/screenArea, 4); % Prints final density per pixel (useful for checking density)
%%

% Variables regarding inside radius as well as coherence indices
insideRadius = false(1, noDots); % Creates logical array later used to check if dots are inside radius or not
dotTracker = 0; % Used as a variable to ensure RDK dots are uniquely identified

% Ranges of movement defined by distance in pixel amount (1 means 1 pixel
% in a direction, > 1 means a farther path which movment can travel. Recommended to keep at 1.
xRange_RDK = 1;
yRange_RDK = 1;
RDK_Direction = [-xRange_RDK, xRange_RDK, -yRange_RDK, yRange_RDK]; % Creates array of 4 ranges of x and y which are used as motion directions
Index = randi(size(RDK_Direction)); % An index which isused to randomly select a direction for RDK motion

% Logic for setting random paths for random non-coherent dots
xRandomValues = NaN(noDots, 1);
yRandomValues = NaN(noDots, 1); 
% This loop uses previously created dot radians for each dot and calculates
% the cos and sin values for each which allows angular movement at a
% consistent magnitude of 1 to match the RDK_Direction
for i = 1:noDots
    xRandomValues(i) = cos(dotRadians(i));
    yRandomValues(i) = sin(dotRadians(i)); 
end

% Visulisation arrows
triangleBaseMultiplier = 1; % width of arrow base relative to dot
triangleHeightMultiplier = .85; % length of arrow (points forward)
triangleOffsetMultiplier = 1.45; % how far ahead of the dot to place the arrow tip
triangleSize = round(dotSize * triangleBaseMultiplier); % width across (base)
triangleHeight = round(dotSize * triangleHeightMultiplier); % length in motion direction
arrowOffset = round(dotSize * triangleOffsetMultiplier); % offset ahead of dot
triangleShape = [-triangleSize, -triangleHeight/2; % left corner
    -triangleSize,  triangleHeight/2;  % right corner
     0,    0]; % tip of arrow (points right)
triangleShape = triangleShape'; % Make it 2x3
triangleColour = [0 1 0]; % Colour

% Min and Max values for x and y spawning
movementPos = rand(2, noDots) .* repmat([width; height], 1, noDots); % Creates random spawn positions for dots within screen bounds
dotOriginalPositions = movementPos; % Stores the original value of movementPos prior to updates allowing for movement to be reset to its original position

% Optional RDK target fixation dot paramaters
RDK_fixationColour = [1 0 0];
fixationDotSize = 10; % (px)

%% Stored response variables and arrays
startTime = GetSecs();
newTrialTime = GetSecs();
trackerTime = GetSecs() * ones(1, noDots);
timePassed = zeros(1, noDots);
responseTimeStore = zeros(noTrials, 1);
RDK_Center_Array = noTrials([]);
RDK_Radius_Array = zeros(noTrials, 1);
Location_Array = zeros(noTrials, 2);
motionDirectionStore = cell(noTrials, 1);
keyResponseStore = cell(noTrials, 1);
accuracy = zeros(noTrials, 1);
coherenceStore = zeros(noTrials, 1);
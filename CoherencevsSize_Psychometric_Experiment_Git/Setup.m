%% Setup of psychtoolbox & other screen requirements

% First add relevant folders to path, including input, output, and functions
addpath("Functions\");
addpath("Output Files\");

%% Psychtoolbox setup
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1); % Skip PTB Sync-Test (0 is no skip, 1 is skip)
Screen('Preference', 'VisualDebugLevel', 0); % Skips visual debug
Screen('Preference', 'SuppressAllWarnings', 1); % Hides all output messages in console from PTB

% Open a window
screenNumber = 1;%max(Screen('Screens')); % Gets the Max Screen number meaning if using multiple screens it will not choose laptop 
                                       % (set to relevant screen manually if more than 2)
background_Colour = .33; % From 0-1 currently
[windowPtr, ~] = PsychImaging('OpenWindow', screenNumber, background_Colour); % Opens window on specified screen with the colour inputted
[width, height] = Screen('WindowSize', windowPtr); % Gets screen width and height in pixels
screenArea = width * height;
minDimension = min(width, height);

xCenter = width/2; % Gets x center coordinate of screen
yCenter = height/2; % Gets y center coordinate of screen
%
%% Screen width and height in cm (change based on screen for accurate locations)
% Screen lists
laptop = struct('width', 35.97, 'height', 26.03);
oldLab_Screen = struct('width', 59.67, 'height', 33.57);
bulbitech_Screen = struct('width', 62.3, 'height', 37.3);
newLab_Screen = struct('width', 54, 'height', 30);
ScreenWidth = newLab_Screen.width;
ScreenHeight = newLab_Screen.height;
viewingDistance = 60; % Viewing distance from screen
%
%% Calculation for Pixels Per Degree
fov = 2 * atan(ScreenWidth / (2 * viewingDistance)); % Works out max horizontal degrees 
fov = rad2deg(fov); % Convert back to degrees for ease
vfov = 2 * atan(ScreenHeight / (2 * viewingDistance)); % Works out max vertical degrees
vfov = rad2deg(vfov);
ppd = width / fov; % Works out pixels per degree by diving width in pixels by max horizontal degrees
vppd = height / vfov; % Works out pixels per degree vertical 
screenAreaDeg = (width/ppd) * (height/ppd); % Screen area in visual degrees
%
%% Desired frame rate
frameRate = Screen('NominalFrameRate', windowPtr); % Desired frame rate used in ifi calculation
vbl = Screen('Flip', windowPtr);  % First flip, returns the initial vbl
Screen('Flip', windowPtr); % Do a flip to allow v-sync to settle
ifi = Screen('GetFlipInterval', windowPtr); % Calculates the relevant inter frame interval to add to vbl in order to update at specified frame rate
%
%% Fixation cross parameters
crossLenthDeg = .8; % This gives me 35px cross length
crossWidthDeg = .2417; % this gives 10px width
crossLength = round(crossLenthDeg*ppd); % Length of the cross arms in pixels
if rem(crossLength, 2) ~= 0 % Check is cross length is even, if not +1 so it is and doesn't cause an offcenter fixation cross
    crossLength = crossLength + 1;
end
crossWidth = round(crossWidthDeg*ppd); % Width of the cross arms in pixels
if crossWidth > 10
    crossWidth = 10;
elseif crossWidth < 0
    crossWidth = .1;
end
crossColour = [0 1 0]; % Colour values for fixation cross
crossX = [xCenter - crossLength/2, xCenter + crossLength/2; yCenter, yCenter]; % Calculates the x coordinates for a horizontal line
crossY = [xCenter, xCenter; yCenter - crossLength/2, yCenter + crossLength/2]; % Calculates the y coordinates for a vertical line
%
%% Text styling
textSize = round(ppd * .68); % Use visual degrees to scale text. ~80% of ppd seems to work well

% % For screen proportional text sizing
% textSize = round(base_textSize * (base_screenWidth_px/width)); 
%%
% Hide cursor
HideCursor(windowPtr);
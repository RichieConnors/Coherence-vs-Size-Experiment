%% MAIN LOOP (runs for noTrials)

%% FPS Setup and density tracking (TEMP)
frameCount = 0; % Counter for frames
fpsDisplayInterval = 1; % Interval in seconds to display FPS
fps = 0; % Initialize fps
FPStotal = 0;
loopTrack = 0;
startTimeFPS = GetSecs();

% Density tracking variables
TL_TotDensity = 0;
TR_TotDensity = 0;
BL_TotDensity = 0;
BR_TotDensity = 0;
mainLoopTrack = 0;
%%

%% MAIN LOOP FOR EXPERIMENT
while trialCount < noTrials 

    currentLoopTime = GetSecs(); % Gets the time at the start of each loop iteration
    
    % Tracks total time of test
    elapsedTime = currentLoopTime - startTime; % Tracks total time of experiment
    elapsedLoopTime = currentLoopTime - newTrialTime; % Tracks total time of each loop

    % Checks if a key is pressed and sets bool to true and tracks the key
    % pressed (only works for defined keys)
    [KeyIsDown, ~, keyCode] = KbCheck;
    if KeyIsDown && ~KEY && any(keyCode(KbName({'-_'}))) 
        targetVisualise = true;
    else 
        targetVisualise = false;
    end

    %% Pausing
    % Checks if it a break should occur and then sets bool to true.
    % preResponse is important to ensure it doesn't constantly reset the
    % takeBreak flag to true causing constant pause screen.
    if ismember(trialCount, breaks) && preResponse == 1 
        takeBreak = true;
        preResponse = 0;
    end

    % Sets pause to true to pause everything happening 
    if KeyIsDown && ~KEY && any(keyCode(KbName({'p'}))) || takeBreak
        PAUSE = true;
    end

    % Pause experiment
    if PAUSE        
        % Track time pause has lasted
        pauseStart = GetSecs(); % Start timer for pause
        pauseDuration = 0; % Work out total duration
        maxPauseTime = 120; % Max amount of time which 

        while true
            pauseDuration = GetSecs() - pauseStart; % Tracks paused time    
            percent = min(pauseDuration / maxPauseTime, 1);  % Update the percentage of pause time used
        
            % Call the PauseScreen script (which uses shared variables)
            PauseScreen;  
        
            % Exit pause if any key is pressed or time limit reached
            [keyDown, ~, ~] = KbCheck;
            if keyDown || pauseDuration >= maxPauseTime
                break;
            end
        end

        %KbWait(-1, 0, maxPauseTime); % Wait for key to continue experiment
        WaitSecs(1); % Wait 1 second to stop instant next trial

        pauseDuration = GetSecs() - pauseStart; % Update pauseduration to account for waitsecs
        
        % Update all relevant timers by subtracting the pause duration
        startTime = startTime + pauseDuration;
        newTrialTime = newTrialTime + pauseDuration;    
        startTimeFPS = startTimeFPS + pauseDuration;
        trackerTime = trackerTime + pauseDuration;

        % Reset flags
        PAUSE = false;
        takeBreak = false;
    end
    %%

    % Tracks time passed since random dot reset. When the timer exceeds the
    % dotTimer preset time, it sets newPath to true and gets a new direction.
    for i = 1:noDots
        % Calculate time passed since last reset
        timePassed(i) = currentLoopTime - trackerTime(i); 
    
        % Check if the time passed exceeds the timer for this dot
        if timePassed(i) >= dotTimers(i)
            % Set selectNewPath for dot to true
            newPath(i) = true;

            % Reset individual timers if exceeded
            timePassed(i) = 0;
            trackerTime(i) = currentLoopTime; % Update the tracker time for the dot  
            dotTimers(i) = minLifetime + (maxLifetime - minLifetime) * rand(); % Give a new timer for the dot
        end
    end
    
    % Draws a visualiser for the circumference of RDK region to show where
    % it is
    if targetVisualise
        Screen('FrameOval', windowPtr, [1 0 0], [RDK_Center_Random_Location(1)-RDK_Radius RDK_Center_Random_Location(2)-RDK_Radius RDK_Center_Random_Location(1)+RDK_Radius RDK_Center_Random_Location(2)+RDK_Radius], 4);
    end
    
    % Calculate eucledian distances for all dots from the center of the given RDK
    % target location
    distances = sqrt((movementPos(1, :) - RDK_Center_Random_Location(1)).^2 + (movementPos(2, :) - RDK_Center_Random_Location(2)).^2);
    
    % Check which dots are inside the current target radius
    insideRadius = distances <= RDK_Radius;
    disp(sum(insideRadius))
    % Makes sure a dot withinside the target is always considered a dot
    % inside the target
    if dotTracker <= 1
        isRDKDot = insideRadius;
        dotTracker = 2;
    end

    % Finds dots within different screen areas 
    TL_Density = movementPos(1, :) > 0 & movementPos(1, :) < width/2 & movementPos(2, :) > 0 & movementPos(2, :) < height/2;
    TR_Density = movementPos(1, :) > width/2 & movementPos(1, :) < width & movementPos(2, :) > 0 & movementPos(2, :) < height/2;
    BL_Density = movementPos(1, :) > 0 & movementPos(1, :) < width/2 & movementPos(2, :) > height/2 & movementPos(2, :) < height;
    BR_Density = movementPos(1, :) > width/2 & movementPos(1, :) < width & movementPos(2, :) > height/2 & movementPos(2, :) < height;
    % Sums the amount of dots in these screen areas to keep track of how
    % density of that area over the experiment
    TL_TotDensity = sum(TL_Density == 1) + TL_TotDensity;
    TR_TotDensity = sum(TR_Density == 1) + TR_TotDensity;
    BL_TotDensity = sum(BL_Density == 1) + BL_TotDensity;
    BR_TotDensity = sum(BR_Density == 1) + BR_TotDensity;
    mainLoopTrack = mainLoopTrack + 1; % Keeps track of absolute loop iterations, used to calculate the density per loop
   
    % Optionally prints the density withinside the current RDK target
    %fprintf("Density = %i\n", sum(insideRadius == 1));
   
    % Calls function for dot motion
    [movementPos, xRandomValues, yRandomValues, newPath, dotRadians, dotSizes, dotColours] = RDK_Motion(noDots, dotVelocity, width, height, coherencePercentage, movementPos, ...
        insideRadius, RDK_Radius, RDK_Center_Random_Location, RDK_Direction, Index, NOMOVEMENTNOISE, ...
        xRandomValues, yRandomValues, newPath, dotRadians, isRDKDot, dotSizes, OGdotSizes, fade, dotColours, targetVisualise);

    % Stores current direction index as the corresponding motion direction in regard
    % to arrow keys
    for i = 1:Index
        if Index == 1
            motionDirection = 'LeftArrow';
        elseif Index == 2
            motionDirection = 'RightArrow';
        elseif Index == 3
            motionDirection = 'UpArrow';
        else
            motionDirection = 'DownArrow';
        end
    end
    
    % Draw all dots on screen
    Screen('DrawDots', windowPtr, movementPos(1:2,:), dotSizes', dotColours', [], 1);

    % Draw fixation cross at screen center
    Screen('DrawLines', windowPtr, crossX, crossWidth, crossColour);
    Screen('DrawLines', windowPtr, crossY, crossWidth, crossColour);
    
    % Sets fixation dot within the RDK
    if RDK_Fixation == true
        Screen('DrawDots', windowPtr, RDK_Center_Random_Location, fixationDotSize, RDK_fixationColour, [], 1);
    end

    if ARROWS
        for i = 1:noDots
            % Draws arrow on every nth defined dot
            if ~isRDKDot(i) && mod(i, 4) ~= 0
                continue;
            end

            if isRDKDot(i) && mod(i, 2) ~= 0
                continue;
            end

            if Index <= 2
                RDK_DirX = RDK_Direction(Index);
                RDK_DirY = 0;
            else
                RDK_DirX = 0;
                RDK_DirY = RDK_Direction(Index);
            end

            RDK_Angle = atan2(RDK_DirY, RDK_DirX);  % Produces angle in radians

            % Rotation matrix for visualisation arrows
            R_RDK = [cos(RDK_Angle), -sin(RDK_Angle); sin(RDK_Angle), cos(RDK_Angle)];
            R = [cos(dotRadians(i)), -sin(dotRadians(i)); sin(dotRadians(i)), cos(dotRadians(i))];
        
            % Rotate triangle
            rotatedTriangleRDK = R_RDK * triangleShape;
            rotatedTriangle = R * triangleShape;

            leadX_RDK = movementPos(1, i) + arrowOffset * RDK_DirX;
            leadY_RDK = movementPos(2, i) + arrowOffset * RDK_DirY;

            leadX = movementPos(1, i) + arrowOffset * xRandomValues(i);
            leadY = movementPos(2, i) + arrowOffset * yRandomValues(i);
        
            % Translate to dot position
            translatedTriangleRDK = rotatedTriangleRDK + [leadX_RDK; leadY_RDK];
            translatedTriangle = rotatedTriangle + [leadX; leadY];
            
            % Draw triangle
            if isRDKDot(i)
                Screen('FillPoly', windowPtr, [0 1 0], translatedTriangleRDK', 1);
            else
                Screen('FillPoly', windowPtr, [1 0 0], translatedTriangle', 1);
            end
        end
    end

    % Checks if a key is pressed and sets bool to true and tracks the key
    % pressed (only works for defined keys)
    if KeyIsDown && ~KEY && any(keyCode(KbName({'RightArrow', 'LeftArrow', 'UpArrow', 'DownArrow'}))) 
        KEY = true; % Set flag to true to prevent multiple counts
        keysPressed = find(keyCode); % Find all keys pressed
        allowedPressed = intersect(keysPressed, allowedKeys); % Matches all keys pressed to only allow the arrow keys
        if ~isempty(allowedPressed)
            firstKey = allowedPressed(1); % Only take the first key pressed
            keyResponseStore{storeIndex} = KbName(firstKey); % Store first key pressed
        end
    end
    
    % Continues and resets trial parameters whilst ensuring only one key
    % press is counted, or the maximum time has been reached
    if KEY && ~KeyIsDown || elapsedLoopTime >= maxTime
        % Store location and radius of each target once responded
        RDK_Center_Array = [RDK_Center_Array, RDK_Center_Random_Location];
        RDK_Radius_Array(storeIndex) = RDK_Radius;
        Location_Array(storeIndex, 1) = RDK_Center_Random_Location(1, 1);
        Location_Array(storeIndex, 2) = RDK_Center_Random_Location(2, 1);
        
        % Stores key responses
        if elapsedLoopTime >= maxTime
            keyResponseStore{storeIndex} = 'NoResponse'; % Just names no response cases for ease in output
        end
        motionDirectionStore{storeIndex} = motionDirection;

        % Stores coherence on each trial
        coherenceStore(storeIndex) = coherencePercentage; 

        % Compares strings of key pressed with the motion direction, if a
        % match it sets accuracy to 1
        if strcmpi(keyResponseStore(storeIndex), motionDirectionStore(storeIndex)) == 1
            accuracy(storeIndex) = 1;
        end
        
        % Updating logic for next trial
        trialCount = trialCount + 1; % Update trial number
        if storeIndex < noTrials % If loop is so it doesn't cause an error on last iteration of experiment
            storeIndex = storeIndex + 1; % Update store number which is used to store responses
        end
        targetLevels.Locations(:, RDK_Index) = []; % Removes previous location before deciding next 
        targetLevels.Coherence(RDK_Index) = []; % Remove last coherence, so no repeat
        targetLevels.Radius(RDK_Index) = []; % Remove last size, so no repeat
        if isempty(targetLevels.Locations) || isempty(targetLevels.Coherence) || isempty(targetLevels.Radius) % Checks if any targetLevles are empty and notifies if so
            fprintf("All locations finished\n"); % Print if all locations have been selected
        else % If not empty, a new index is chosen
            RDK_Index = randi([1, size(targetLevels.Locations, 2)]); % Reset the RDK_Index to correct length

            % Gives new position
            RDK_Center_Random_Location = targetLevels.Locations(:, RDK_Index); % Picks indexed position in the preshuffled convertedLocations
            
            % Gives new coherence
            coherencePercentage = targetLevels.Coherence(RDK_Index);

            % Gives new radius
            RDK_Radius = targetLevels.Radius(RDK_Index);
        end

        % Give updated dot timers
        maxLifetime = (RDK_Radius*2) / (dotVelocity*frameRate);
        minLifetime = maxLifetime*.8;
        dotTimers = minLifetime + (maxLifetime - minLifetime) .* rand(1, noDots);
       
        % Resets more logic for next trial
        Index = randi(size(RDK_Direction)); % Gives new index for motion direction
        KEY = false; % sets check for KEY back to false
        movementPos = dotOriginalPositions; % Puts dots back to their original positions

        % Resets the check for dots inside radius
        insideRadius(:) = false;
        dotColours = originalDotColours;
        dotTracker = 0;
        dotSizes = OGdotSizes;
        newPath(:) = true; % Give all dots a new path from start of new trial

        preResponse = 1;
        
        % Response time metrics
        if trialCount == 1 % Check for first trial so responseTime is stored correctly
            responseTime = currentLoopTime - newTrialTime; % Without ISI consideration since first run
        else
            responseTime = (currentLoopTime - newTrialTime) - interStimulusInterval; % Takes ISI away to correct response time
                                                                           % (Note that this means in the workspace maxTime will be higher than it's originally set value)
        end
        responseTimeStore(trialCount) = responseTime; % Stores response time
        newTrialTime = currentLoopTime; % Resets timer
        interStimulusInterval = round(min_isi + (max_isi - min_isi) .* rand(), 2); % Give a random new isi
        maxTime = maxTimeOG + interStimulusInterval; % Update maxTime for future trials which need ISI adjustment

        % Before flipping the screen wait a period so next presentation doesn't
        % occur immediately after last.
        Screen('FillRect', windowPtr, background_Colour);
        Screen('DrawLines', windowPtr, crossX, crossWidth, crossColour);
        Screen('DrawLines', windowPtr, crossY, crossWidth, crossColour);
        Screen('Flip', windowPtr);
        Screen('DrawLines', windowPtr, crossX, crossWidth, crossColour);
        Screen('DrawLines', windowPtr, crossY, crossWidth, crossColour);
        WaitSecs(interStimulusInterval);
    end

    % Check for escaped key press to exit early
    if keyCode(KbName('Escape')) % Exit if esc pressed
        break;
    end

    % IGNORE / COMMENT OUT OR IN IF WANTING FPS TRACKER
    % FPS TEMP TEST STUFF
    if FPS_Show
        % Increment the frame counter
        frameCount = frameCount + 1;
        %renderingTime = currentLoopTime - startTimeFPS; % Measure rendering time
        %fprintf('Rendering time: %.2f\n', renderingTime);
        % Check if it's time to display FPS
        if currentLoopTime - startTimeFPS >= fpsDisplayInterval
            % Calculate and display FPS
            fps = frameCount / (currentLoopTime - startTimeFPS);
            fprintf('Current FPS: %.2f\n', fps); % Display the FPS
            FPStotal = FPStotal + fps;
            loopTrack = loopTrack + 1;
    
            % Reset for the next interval
            frameCount = 0;
            startTimeFPS = currentLoopTime; % Update start time
        end
            % Draw FPS on the screen
            DrawFormattedText(windowPtr, sprintf('FPS: %.2f', fps), 50, 50, [1 1 1]);
    end

    % Flip the screen
    vbl = Screen('Flip', windowPtr, vbl + 0.5 * ifi);
end
%%
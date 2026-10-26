%% Script for practice trials

practiceTrials = 5; % Set num trials
practiceCoherence = 1; % Set coherence
practiceSize = 180; % Set target size (px)
practiceCount = 0; % Track iterations
practiceKeyResponseStore = cell(practiceTrials, 1); % Stores responses for practice
practiceMotionDirectionStore = cell(practiceTrials, 1); % Stores motion direction for practice trials
practiceIndex = 1; % Index
practiceInterStimulusInterval = .35;

% Text styling
Screen('TextStyle', windowPtr, 1); % Sets text to bold
scaled_feedbackText = round(textSize * 2.7); % Scales text size for feedback (scaled by a factor from original design)
Screen('TextSize', windowPtr, scaled_feedbackText);

temp = 0;

while practiceCount < practiceTrials

    currentLoopTime = GetSecs(); % Gets the time at the start of each loop iteration

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

    % Calculate eucledian distances for all dots from the center of the given RDK
    % target location
    distances = sqrt((movementPos(1, :) - RDK_Center_Random_Location(1)).^2 + (movementPos(2, :) - RDK_Center_Random_Location(2)).^2);
    
    % Check which dots are inside the current target radius
    insideRadius = distances <= practiceSize;
    if temp <= 1
        isRDKDot = insideRadius;
        temp = 2;
    end

    % Calls function for dot motion
    [movementPos, xRandomValues, yRandomValues, newPath, dotRadians, dotSizes, dotColours] = RDK_Motion(noDots, dotVelocity, width, height, practiceCoherence, movementPos, ...
    insideRadius, practiceSize, RDK_Center_Random_Location, RDK_Direction, Index, NOMOVEMENTNOISE, ...
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

    % Checks if a key is pressed and sets bool to true and tracks the key
    % pressed (only works for defined keys)
    [KeyIsDown, ~, keyCode] = KbCheck;
    if KeyIsDown && ~KEY && any(keyCode(KbName({'RightArrow', 'LeftArrow', 'UpArrow', 'DownArrow'}))) 
        KEY = true; % Set flag to true to prevent multiple counts
        practiceKeyResponseStore{practiceIndex} = KbName(find(keyCode));
    end

    % Continues and resets trial parameters whilst ensuring only one key
    % press is counted, or the maximum time has been reached
    if KEY && ~KeyIsDown

        practiceMotionDirectionStore{practiceIndex} = motionDirection; % Stores motion direction

        % Compares strings of key pressed with the motion direction, if a
        % match it sets accuracy to 1
        if strcmpi(practiceKeyResponseStore(practiceIndex), practiceMotionDirectionStore(practiceIndex))
            if language == 0
                DrawFormattedText(windowPtr, 'Correct', 'center', height*.65, [0 1 0]);
            elseif language == 1
                DrawFormattedText(windowPtr, 'Juist', 'center', height*.65, [0 1 0]);
            end
        else
            if language == 0
                DrawFormattedText(windowPtr, 'Incorrect', 'center', height*.65, [1 0 0]);
            elseif language == 1
                DrawFormattedText(windowPtr, 'Onjuist', 'center', height*.65, [1 0 0]);
            end
        end
        Screen('Flip', windowPtr);
        WaitSecs(1); % Show feedback for 1 second
        
        % Updating logic for next trial
        practiceCount = practiceCount + 1; % Update trial number
        RDK_Center_Random_Location = convertedLocations(:, randi(length(convertedLocations)));
        if practiceIndex < practiceTrials % If loop is so it doesn't cause an error on last iteration of experiment
            practiceIndex = practiceIndex + 1; % Update store number which is used to store responses
        end
       
        % Resets more logic for next trial
        Index = randi(size(RDK_Direction)); % Gives new index for motion direction
        KEY = false; % sets check for KEY back to false
        movementPos = dotOriginalPositions; % Puts dots back to their original positions

        % Resets the check for dots inside radius
        insideRadius(:) = false;
        temp = 0;
        dotSizes = OGdotSizes;
        
        % Before flipping the screen wait a period so next presentation doesn't
        % occur immediately after last.
        Screen('FillRect', windowPtr, background_Colour);
        Screen('DrawLines', windowPtr, crossX, crossWidth, crossColour);
        Screen('DrawLines', windowPtr, crossY, crossWidth, crossColour);
        Screen('Flip', windowPtr);
        Screen('DrawLines', windowPtr, crossX, crossWidth, crossColour);
        Screen('DrawLines', windowPtr, crossY, crossWidth, crossColour);
        WaitSecs(practiceInterStimulusInterval);
    end

    % Check for escaped key press to exit early
    [~, ~, keyCode] = KbCheck;
    if keyCode(KbName('Escape')) % Exit if esc pressed
        break;
    end

    % Flip the screen
    vbl = Screen('Flip', windowPtr, vbl + 0.5 * ifi); % Sets next timestamp with breathing room of .5* for more precise fps control
end

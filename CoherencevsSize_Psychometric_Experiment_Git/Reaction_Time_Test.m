%%% REACTION TIME TEST %%%%
function motorRT = Reaction_Time_Test(TrialNumber, windowPtr, vbl, ifi, participant_ID)

    % Save directory for all motor response times
    saveDir = sprintf('Output Files/AllMotorRTs');
    if ~exist(saveDir, 'dir') 
        mkdir(saveDir);  % Creates folder if new participant number
    end
    
    % Present grey screen and wait before starting
    Screen('FillRect', windowPtr, [.33 .33 .33]);
    Screen('Flip', windowPtr);
    WaitSecs(1); 
    
    % Pre allocation
    newTrialTime = GetSecs();
    trialCount = 0;
    responseTimeStore = zeros(1, TrialNumber);
    KEY = false; % Logical which defines a Keyboard press or not
    LOCK = false; % Logical to ensure timestamp for green presenation is not overwritten
    validKeys = {'RightArrow', 'LeftArrow', 'UpArrow', 'DownArrow'}; % List for valid keys allowed to press
    maxAllowedTime = 2; % Max time allowed from time of green screen presentation
    greenElapsed = 0; % Timer to track how long green screen has been shown
    responseTime = 0;

    % Random time before green flash
    minTime = .75; % Secs
    maxTime = 2.5; % Secs
    randomTime = round(minTime + (maxTime - minTime) * rand(), 2);
    
    while trialCount < TrialNumber
        currentLoopTime = GetSecs(); % Gets the time at the start of each loop iteration
    
        % Tracks total loop time
        elapsedLoopTime = currentLoopTime - newTrialTime; % Tracks total time of each loop

        % Screen changes
        if elapsedLoopTime < randomTime 
           % Present red screen if randomTime not reached
            Screen('FillRect', windowPtr, [.33 .33 .33]);
        elseif elapsedLoopTime >= randomTime && ~LOCK
            % Present green screen if randomTime reached
            Screen('FillRect', windowPtr, [.7 .7 .7]);
            greenTimer = currentLoopTime;
            LOCK = true;
        end
        
        % Track the time which green has been presented
        if LOCK
            greenElapsed = currentLoopTime - greenTimer;
        end
         
        % Checks if a key is pressed
        [KeyIsDown, ~, keyCode] = KbCheck;
        if LOCK && KeyIsDown && ~KEY && any(keyCode(KbName(validKeys)))
            KEY = true; % Set flag to true to prevent multiple counts
            responseTime = currentLoopTime - greenTimer;
        end

        if greenElapsed >= maxAllowedTime
            responseTime = greenElapsed;
        end
    
        % Continues and resets trial parameters whilst ensuring only one key
        % press is counted, or the maximum time has been reached
        if KEY && ~KeyIsDown || greenElapsed >= maxAllowedTime
            % Increment trialcount
            trialCount = trialCount + 1;

            % Response time metrics
            %responseTime = currentLoopTime - greenTimer; % Without ISI consideration since first run
            responseTimeStore(trialCount) = responseTime; % Stores response time
            
            % Reseting variables for next trial
            randomTime = round(minTime + (maxTime - minTime) * rand(), 2); % Get new random time to present green screen
            LOCK = false;
            KEY = false; % sets check for KEY back to false
            Screen('FillRect', windowPtr, [.33 .33 .33]); % Set screen to grey for small intermission
            Screen('Flip', windowPtr);
            WaitSecs(.25); % Brief pause before next trial starts
            newTrialTime = GetSecs(); % Resets timer
            greenElapsed = 0; % Reset the greenElapsed
        end

        % Check for escaped key press to exit early
        if KeyIsDown && keyCode(KbName('Escape'))
            break;
        end
       
        % Flip the screen
        vbl = Screen('Flip', windowPtr, vbl + 0.5 * ifi);
    end

    % Store all the outcomes in case of bad completion
    writematrix(responseTimeStore, fullfile(saveDir, sprintf('AllMotorRTs_ID_%s.txt', participant_ID)));

    % Output the average reaction time
    motorRT = median(responseTimeStore);
    
end

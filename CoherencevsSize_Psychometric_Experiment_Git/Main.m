%% Main script which calls all other relevant scripts as well as clean up

% Clear workspace before running
clear;

%% Participant information
participant_ID = 'na';
participant_Name = '';
participant_Age = '';
participant_Sex = '';
language = 1; % 0 for English, 1 for Dutch

%% Calling of relevant scripts
% Run reaction time pre test
Setup;
InstructionsReactionTest;
KbWait(-1, 2);
MotorRT = Reaction_Time_Test(7, windowPtr, vbl, ifi, participant_ID); % Starts reaction time test. First input is number of trials.

% Clean up after practice trials
clearvars -except participant_ID participant_Name participant_Age participant_Sex language MotorRT
sca;
WaitSecs(1);

% Run practice
rerun = true;
while rerun
    Setup;
    InstructionsPractice;
    if language_error
        sca;
        return;
    end
    KbWait(-1, 2);
    PreTrialScreen; % Grey screen background with fixation before trial start
    WaitSecs(1);
    Options;
    WaitSecs(1);
    Trial_Parameters;
    Practice;

    % Ask participant if they want to rerun practice
    Screen('TextSize', windowPtr, textSize);
    Screen('TextFont', windowPtr, 'Arial');
    if language == 0
        DrawFormattedText(windowPtr, 'Ask the experimenter to repeat practice, or press any key to continue.', 'center', 'center', 255);
    else
        DrawFormattedText(windowPtr, 'Vraag de onderzoeker om de oefening te herhalen, of druk op een toets om verder te gaan.', 'center', 'center', 255);
    end
    Screen('Flip', windowPtr);
    
    % Wait for a key press
    [~, keyCode, ~] = KbWait;  % Wait for key press
    if keyCode(KbName('r'))
        rerun = true; % Rerun loop
    else
        rerun = false; % Exit loop
    end
end

% Clean up after practice trials
clearvars -except participant_ID participant_Name participant_Age participant_Sex language MotorRT
sca;
WaitSecs(1);

% Run main task
Setup;
InstructionsMain;
KbWait(-1, 2);
PreTrialScreen; % Grey screen background with fixation before trial start
WaitSecs(1);
Options;
WaitSecs(1);
Trial_Parameters;
Main_Loop;
Output;

%% Some checks for fps and density
averageFPS = FPStotal / loopTrack;
averageDensityTL = round(TL_TotDensity / mainLoopTrack);
averageDensityTR = round(TR_TotDensity / mainLoopTrack);
averageDensityBL = round(BL_TotDensity / mainLoopTrack);
averageDensityBR = round(BR_TotDensity / mainLoopTrack);

%% Clean up
sca;
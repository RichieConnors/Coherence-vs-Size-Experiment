%% Pre trial screen
% Presents grey screen with fixation cross pre task start
Screen('FillRect', windowPtr, background_Colour);
Screen('DrawLines', windowPtr, crossX, crossWidth, crossColour);
Screen('DrawLines', windowPtr, crossY, crossWidth, crossColour);
Screen('Flip', windowPtr);
Screen('DrawLines', windowPtr, crossX, crossWidth, crossColour);
Screen('DrawLines', windowPtr, crossY, crossWidth, crossColour);
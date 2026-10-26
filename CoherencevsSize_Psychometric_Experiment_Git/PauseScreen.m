% Message displayed during pause
if language == 0
    pauseMessage = ['You may now take a short break if you wish.' ...
        '\nThe experiment will automatically continue after 2 minutes.'...
        '\nIf you wish to continue the experiment immediately, press any key.'...
        '\nIf you take a break but wish to continue early, press any key at anytime.'];
elseif language == 1
    pauseMessage = ['Je mag nu een korte pauze nemen als je dat wilt.' ...
        '\nHet experiment gaat automatisch verder na 2 minuten.' ...
        '\nAls je het experiment meteen wilt voortzetten, druk dan op een toets.' ...
        '\nAls je een pauze neemt maar eerder wilt doorgaan, druk dan op elk moment op een toets.'];
end


% Present a screen whilst paused
Screen('FillRect', windowPtr, background_Colour);

% Define a progress bar
barWidth = width * .8;
barHeight = 30;
filledWidth = percent * barWidth; % Tracks progress
baseRect = CenterRectOnPoint([0 0 barWidth barHeight], xCenter, height * .9); % Draws base rectangle
fillRect = [baseRect(1), baseRect(2), baseRect(1) + filledWidth, baseRect(4)]; % Draws filling rectangle

% Draw progress bar background and fill
Screen('FillRect', windowPtr, background_Colour .* 1.1, baseRect);  % Grey bar background
Screen('FillRect', windowPtr, [0 200 0], fillRect); % Green fill

% Percentage text
if language == 0
    DrawFormattedText(windowPtr, sprintf('Break progress: %d%%', round(percent * 100)), 'center', height*.95, [1 1 1]);
elseif language == 1
    DrawFormattedText(windowPtr, sprintf('Voortgang van de pauze: %d%%', round(percent * 100)), 'center', height*.95, [1 1 1]);
end

% Draw pause message in center of screen
Screen('TextSize', windowPtr, textSize);
Screen('TextFont', windowPtr, 'Arial');
DrawFormattedText(windowPtr, pauseMessage, 'center', 'center', [1, 1, 1], [], [], [], 2);
Screen('Flip', windowPtr); 
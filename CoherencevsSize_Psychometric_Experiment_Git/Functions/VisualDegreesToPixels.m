%% Function which converts visual degrees to pixel coordinates based on given viewing distance
function convertedAngles = VisualDegreesToPixels(degreeLocations, width, height, ppd, vppd)
    % Transpose array if necessary
    if size(degreeLocations, 2) <= 2
        degreeLocations = transpose(degreeLocations);
    end
    
    % Calculate and translate degrees into pixel coords from pixels per
    % degree (ppd) and adjusted from screen center
    convertedx = ppd * degreeLocations(1, :) + width / 2; % Calculate x pixel coord
    convertedy = -vppd * degreeLocations(2, :) + height / 2; % Calculate y pixel coord
    convertedAngles =  [convertedx; convertedy]; % Store the converted coordinates
end
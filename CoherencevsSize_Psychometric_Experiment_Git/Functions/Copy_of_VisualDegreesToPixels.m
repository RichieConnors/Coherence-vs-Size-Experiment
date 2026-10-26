%% Converts visual degrees into screen pixel coordinates
function convertedAngles = VisualDegreesToPixels(degreeLocations, width, height, viewingDistance, Swidth, Sheight)
    % Transpose array if necessary
    if size(degreeLocations, 2) <= 2
        degreeLocations = transpose(degreeLocations);
    end
    % Get x and y pixel coordinates from visual degree location
    convertedAngles = zeros(size(degreeLocations));

    % Calculates the pixels per mm of screen in both the x and y direction
    pixPerMMx = width / Swidth;
    pixPerMMy = height / Sheight;

    % Center location for x and y
    centerX = width / 2;
    centerY = height / 2;

    for a = 1:size(degreeLocations, 2)
        degreesx = degreeLocations(1, a);
        degreesy = degreeLocations(2, a);
        radiansx = deg2rad(degreesx); % Convert degrees to radians
        radiansy = deg2rad(degreesy); % Convert degrees to radians
        
        % Calculate offset of angle based on viewing distance
        offsetX = tan(radiansx) * viewingDistance;
        offsetY = tan(radiansy) * viewingDistance;
    
        % Apply the offset from center by correct number of pixels
        convertedx = centerX + offsetX * pixPerMMx;
        convertedy = centerY + offsetY * pixPerMMy;

        convertedAngles(:, a) =  [convertedx; convertedy]; % Store the converted coordinates
    end
end
%% Function defining movement for RDK targets (add deltaTime if wanted)
function [movementPos, xRandomValues, yRandomValues, newPath, dotRadians, dotSizes, dotColours] = RDK_Motion(noDots, Speed, width, height, ...
    coherence, movementPos, insideRadius, RDK_Radius, RDK_Center, RDK_Direction, Index, NOMOVEMENTNOISE, ...
    xRandomValues, yRandomValues, newPath, dotRadians, isRDKDot, dotSizes, OGdotSizes, fade, dotColours, targetVisualise)
 
   % Finds the ith position of dots inside radius
   insideIndices = find(isRDKDot); % Finds all indices of dots within radius
   coherenceAmount = round(numel(insideIndices) * coherence); % Multiplies the length of insideIndices by coherence to 
                                                              % give a subset of dots to move coherently
   coherenceIndices = insideIndices(1:coherenceAmount); % Creates an array of dot indices from insideIndices to length of 
                                                        % coherence amount, allowing set of dots inside target to move coherently

    %% Loop for assigning movements 
    for k = 1:noDots % Loops over all dots    
        % This if block checks if any dots are inside the RDK radius
        % which aren't a part of the coherenceIndices array, then gives
        % them random movement
        if isRDKDot(k) && ~any(k == coherenceIndices)
            movementPos(1, k) = movementPos(1, k) + xRandomValues(k) * Speed; % Applies speed to the direction given
            movementPos(2, k) = movementPos(2, k) + yRandomValues(k) * Speed; % Applies speed to the direction given

            if targetVisualise
                dotColours(k, :) = [1 0 0]; % Set Colour red for incoherent dots
            else
                dotColours(k, :) = .5; % Set normal
            end
                     
            % Calculates euclidean distance to check if dot has moved
            % outside radius
            distanceRandomMove = sqrt((movementPos(1, k) - RDK_Center(1))^2 + (movementPos(2, k) ...
                - RDK_Center(2))^2);
            if distanceRandomMove > RDK_Radius % Resets dot if moved outside RDK
                % Calculate normal vector from circle center to dot
                normalVector = movementPos(:, k) - RDK_Center; % Vector from center to dot
                normalVector = normalVector / norm(normalVector); % Normalize to unit length

                dotProduct = xRandomValues(k) * normalVector(1) + yRandomValues(k) * normalVector(2);

                % Compute reflected velocity
                xRandomValues(k) = xRandomValues(k) - 2 * dotProduct * normalVector(1);
                yRandomValues(k) = yRandomValues(k) - 2 * dotProduct * normalVector(2);

                newPath(k) = false;  % Reset the flag after use

                % Absolute check: If still outside, force it inside
                if distanceRandomMove >= RDK_Radius * 1.01
                    movementPos(:, k) = RDK_Center + normalVector * (RDK_Radius * sqrt(rand()));
                end
            elseif newPath(k)
                % Recaclulate a new random radian for the current dot
                dotRadians(k) = rand() * pi * 2;

                % Normalises the direction to a magnitude of 1 so it has
                % same speed as RDK_Direction values
                xRandomValues(k) = cos(dotRadians(k));
                yRandomValues(k) = sin(dotRadians(k)); 

                newPath(k) = false;  % Reset the flag after use
            end
        % Controls random background dot movements (not inside RDK)
        elseif ~isRDKDot(k)
            if NOMOVEMENTNOISE == true %&& movementPos(1, k) > 1280 % Stops all movement outside of the RDK
                continue;
            end
            % Generate random noise movement outside of radius
            movementPos(1, k) = movementPos(1, k) + xRandomValues(k) * Speed; % Applies speed to the direction given
            movementPos(2, k) = movementPos(2, k) + yRandomValues(k) * Speed; % Applies speed to the direction given

            % Check if dot is within screen boundaries
            insideWidth = movementPos(1, k) < width && movementPos(1, k) > 0;
            insideHeight = movementPos(2, k) < height && movementPos(2, k) > 0;
            
            % Checks how close a dot is to the RDK target (used to keep
            % dots from going into the target radius)
            distanceFromTarget = sqrt((movementPos(1, k) - RDK_Center(1))^2 + (movementPos(2, k) ...
            - RDK_Center(2))^2);

            % This if block checks if a dot is about to be out of screen
            % bounds, or is getting to close to the RDK target. Then it
            % reverses the direction to move it away. The elseif gives
            % the dot a new random path if it isn't meeting the if

            if ~insideWidth || ~insideHeight
                % Reverse dot direction if too close to one of the above
                % conditions
                xRandomValues(k) = -xRandomValues(k);
                yRandomValues(k) = -yRandomValues(k);       
            elseif distanceFromTarget <= RDK_Radius
                % Apply vector reflection to dots approaching RDK boundary
                normalVectorRanDots = movementPos(:, k) - RDK_Center; % Vector from center to dot            
                normalVectorRanDots = normalVectorRanDots / norm(normalVectorRanDots); % Normalize to unit length

                dotProductRanDots = xRandomValues(k) * normalVectorRanDots(1) + yRandomValues(k) * normalVectorRanDots(2);

                % Compute reflected velocity
                xRandomValues(k) = xRandomValues(k) - 2 * dotProductRanDots * normalVectorRanDots(1);
                yRandomValues(k) = yRandomValues(k) - 2 * dotProductRanDots * normalVectorRanDots(2);

                newPath(k) = false;  % Reset the flag after use
            elseif newPath(k)
                % Recaclulate a new random radian for the current dot
                dotRadians(k) = rand() * pi * 2;

                % Normalises the direction to a magnitude of 1 so it has
                % same speed as RDK_Direction values
                xRandomValues(k) = cos(dotRadians(k));
                yRandomValues(k) = sin(dotRadians(k)); 

                newPath(k) = false;  % Reset the flag after use
            end
        end
    end

    % Controls coherent motion within the RDK
    for l = 1:numel(coherenceIndices)
        if Index <= 2 % Index of 2 or less refers to x movement (right or left)
            movementPos(1, coherenceIndices(l)) = movementPos(1, coherenceIndices(l)) + RDK_Direction(Index) * Speed;
        else % Index greater than 2 refers to y movement (up or down)
            movementPos(2, coherenceIndices(l)) = movementPos(2, coherenceIndices(l)) + RDK_Direction(Index) * Speed;
        end

        if targetVisualise
            dotColours(coherenceIndices(l), :) = [0 1 0]; % Set Colour green for coherent dots
        else
            dotColours(coherenceIndices(l), :) = .5; % Set normal
        end
        

        % Calculates euclidean distance for coherent dots moving inside the
        % RDK target
        distanceFromCenter = sqrt((movementPos(1, coherenceIndices(l)) - RDK_Center(1))^2 ...
            + (movementPos(2, coherenceIndices(l)) - RDK_Center(2))^2);
        
        % Sets the fade factor if option is on
        if fade ~= true
            fadeFactor = 0;
        else
            fadeFactor = min(1, max(0, (distanceFromCenter - RDK_Radius *.97) / (.03 * RDK_Radius))); 
        end

        if distanceFromCenter > RDK_Radius * .97 && isRDKDot(coherenceIndices(l)) % Same mechanism as before for resetting dots
            % Interpolate colour to fade into background until 20%
            % extra out of OG RDK
            shrinkFactor = exp(-fadeFactor); % Can multiply by a number like '3' for slower/faster fade
            dotSizes(coherenceIndices(l)) = OGdotSizes(coherenceIndices(l)) * shrinkFactor + 1 * (1 - shrinkFactor);
            if distanceFromCenter > RDK_Radius
                % Calculate the ratio of the distance from the edge to the radius
                ratio = (distanceFromCenter - (RDK_Radius*2)) / RDK_Radius;
                
                % Reset dot position proportionally inside the circle
                if Index <=2
                    movementPos(1, coherenceIndices(l)) = RDK_Center(1) + ratio * (movementPos(1, coherenceIndices(l)) - RDK_Center(1));
                else
                    movementPos(2, coherenceIndices(l)) = RDK_Center(2) + ratio * (movementPos(2, coherenceIndices(l)) - RDK_Center(2));
                end
            end
        elseif distanceFromCenter > RDK_Radius
            % Calculate the ratio of the distance from the edge to the radius
            ratio = (distanceFromCenter - (RDK_Radius*2)) / RDK_Radius;
            
            % Reset dot position proportionally inside the circle
            if Index <=2
                movementPos(1, coherenceIndices(l)) = RDK_Center(1) + ratio * (movementPos(1, coherenceIndices(l)) - RDK_Center(1));
            else
                movementPos(2, coherenceIndices(l)) = RDK_Center(2) + ratio * (movementPos(2, coherenceIndices(l)) - RDK_Center(2));
            end
        else
            % If the dot is within the non-fading area, return to original size
            dotSizes(coherenceIndices(l)) = OGdotSizes(coherenceIndices(l));
        end
    end
end

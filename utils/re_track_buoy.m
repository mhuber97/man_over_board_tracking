function [x, y] = re_track_buoy(frame, x_old, y_old)
    % This function is responsible for the re-tracking of the buoy if it got
    % lost. Therefore we consider the former coordinate [x, y] of the buoy as 
    % the center of the area of interest with a border. We color the rest of
    % the image green, in order to make the blob-analysis filter those parts
    % out.

    border = 20;

    image = insertShape(frame, 'FilledRectangle', [0 0 size(frame, 2) y_old-border], 'Color', {'green'});
    image = insertShape(image, 'FilledRectangle', [0 0 x_old-border size(image, 1)], 'Color', {'green'});
    image = insertShape(image, 'FilledRectangle', [x_old+border 0 size(image, 2)-x_old-border size(image, 1)], 'Color', {'green'});
    image = insertShape(image, 'FilledRectangle', [0 y_old+border size(image, 2) size(image, 1)-y_old+border], 'Color', {'green'});  

    I = image;

    %Defined thresholds for Red
    channel1Min = 10.000 / 255;
    channel1Max = 255.000 / 255;
    
    %Defined thresholds for Green
    channel2Min = 150.000 / 255;
    channel2Max = 255.000 / 255;
    
    %Defined thresholds for Blue
    channel3Min = 150.000 / 255;
    channel3Max = 255.000 / 255;

    % Applies thresholds to Image I
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    
    % We apply blob-analysis to detect objects with an area between 2 and 5.
    % Furthermore we want only one area to be considered as the target buoy.
    hBlobAnalysis = vision.BlobAnalysis('MinimumBlobArea', 2, ...
        'MaximumBlobArea',5, 'MaximumCount', 1);
    [objArea, objCentroid, bboxOut] = step(hBlobAnalysis, sliderBW);
    
    % only returns cooridnates if the blob-analysis found something.
    if ~isempty(objCentroid)
        x = objCentroid(1);
        y = objCentroid(2);
    else
        x = NaN;
        y = NaN;
    end
end

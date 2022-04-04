%% Cleanup
clear variables;
close all;

filename = 'stabilized_video.avi';
hVideoSrc = VideoReader(filename);

videoPlayer = vision.VideoPlayer('Position', [100, 100, 680, 520]);

writerObj = VideoWriter('tracked_buoy.avi'); %Will write results to file
writerObj.FrameRate = 25; %Initializes the frame rate of resulting video
open(writerObj);

%skipping the first few frames where the buoy is not seeable
readFrame(hVideoSrc);readFrame(hVideoSrc);readFrame(hVideoSrc);readFrame(hVideoSrc);

imgA = im2single(readFrame(hVideoSrc)); % Read first frame into imgA

% initial coordinates of the buoy
x=674;
y=515;

tracker = vision.PointTracker('MaxBidirectionalError', 1, 'BlockSize', [9, 9]);

initialize(tracker, [x, y], imgA);

undetected = false;
while hasFrame(hVideoSrc)

    if undetected
        frame = im2single(readFrame(hVideoSrc));
        [x, y] = re_track_buoy(frame, points(1), points(2));
        if ~isnan(x)
            release(tracker);
            initialize(tracker, [x, y], frame);

            out = insertMarker(frame, [x, y], '+', 'Size', 10);

            videoPlayer(out);
            writeVideo(writerObj, out);
            pause(1 / hVideoSrc.FrameRate);
        end
    end

    if ~undetected || ~isnan(x)
        frame = im2single(readFrame(hVideoSrc));
        [new_points, validity] = tracker(frame);
    end
    
    if validity ~= 0
        points = new_points;
        out = insertMarker(frame, points(validity, :),'+', 'Size', 10);
        undetected = false;
    else 
        disp("not detected");
        out = insertText(frame, [100 100], "No Buoy Found", 'FontSize', 24);
        undetected = true;
    end

    videoPlayer(out);
    pause(1 / hVideoSrc.FrameRate);
    writeVideo(writerObj, out);
end 

release(videoPlayer);
close(writerObj); %Stops writing to file

function [x, y] = re_track_buoy(frame, x_old, y_old)
    border = 20;
    frame = im2gray(frame) * 255;  

    image = insertShape(frame,'FilledRectangle', [0 0 size(frame, 2) y_old-border],'Color',{'green'});
    image = insertShape(image,'FilledRectangle', [0 0 x_old-border size(image, 1)],'Color',{'green'});
    image = insertShape(image,'FilledRectangle', [x_old+border 0 size(image, 2)-x_old-border size(image, 1)],'Color',{'green'});
    image = insertShape(image,'FilledRectangle', [0 y_old+border size(image, 2) size(image, 1)-y_old+border],'Color',{'green'});  

%     image = insertShape(frame,'FilledRectangle', [0 0 2000 483],'Color',{'green'});
%     image = insertShape(image,'FilledRectangle', [0 0 655+i/2 2000],'Color',{'green'});
%     image = insertShape(image,'FilledRectangle', [1062+i/3 0 500 2000],'Color',{'green'});
%     image = insertShape(image,'FilledRectangle', [0 521 2000 700],'Color',{'green'});  
    I = image;

    %Defined thresholds for Red
    channel1Min = 10.000;
    channel1Max = 255.000;
    
    %Defined thresholds for Green
    channel2Min = 150.000;
    channel2Max = 255.000;
    
    %Defined thresholds for Blue
    channel3Min = 100.000;
    channel3Max = 255.000;

    % Applies thresholds to Image I
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    
    %Carries out blob analysis on objects between the range of 1 and 5
    %pixels with a maximum of 1 blob shown
    hBlobAnalysis = vision.BlobAnalysis('MinimumBlobArea', 2, ...
        'MaximumBlobArea',5, 'MaximumCount', 1);
    [objArea, objCentroid, bboxOut] = step(hBlobAnalysis, sliderBW);
    
    if ~isempty(objCentroid)
        x = objCentroid(1);
        y = objCentroid(2);
    else
        x = NaN;
        y = NaN;
    end
end

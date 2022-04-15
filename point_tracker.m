% Cleanup
clear variables;
close all;

% initialize stabilized input video
filename = 'stabilized_video.avi';
hVideoSrc = VideoReader(filename);

% initialize video player to show results
videoPlayer = vision.VideoPlayer('Position', [100, 100, 680, 520]);

% initialize file to write video into
writerObj = VideoWriter('tracked_buoy.avi');
writerObj.FrameRate = 25;
open(writerObj);

% read cameraParameters and read focal length and principal point from it
% (needed for the distance calcualation)
cp = load("cameraParams.mat");
camera_height = 2.5;
focal_length = cp.cameraParams.FocalLength;
principal_point = cp.cameraParams.PrincipalPoint;

% read the principal point list that defines the principal point at each
% frame. It is needed for the distance measurement.
principal_point_list = load("principal_point_list.mat").principal_point_list;

% skipping the first few frames where the buoy is not seeable
readFrame(hVideoSrc);readFrame(hVideoSrc);readFrame(hVideoSrc);readFrame(hVideoSrc);

% Read first frame
first_frame = im2single(readFrame(hVideoSrc));

% Approximated initial coordinates of the buoy
x = 667;
y = 511;

% initialize point tracker
tracker = vision.PointTracker('MaxBidirectionalError', 1, 'BlockSize', [9, 9]);
initialize(tracker, [x, y], first_frame);

detected = true;
height_history = [];
horizon_height_buffer_size = 10;

distances = [];
counter = 5; %start at 5 since 5 frames are already read
while hasFrame(hVideoSrc)
    % If in the previous iteration the buoy was not detected by the point
    % tracker, we use blob analysis to re-track it. If this gives us a
    % valid coordinate, we re-intantiate the point-tracker and insert a
    % marker at the detected position of the next frame.

    if detected == false
        frame = im2single(readFrame(hVideoSrc));
        counter = counter + 1;
        [x, y] = re_track_buoy(frame, points(1), points(2));
        if ~isnan(x)
            release(tracker);
            initialize(tracker, [x, y], frame);

            out = insertMarker(frame, [x, y], '+', 'Size', 10);
            
            horizon_height = gethorizonheight(frame, x);
            height_history(length(height_history)+1) = horizon_height;
            cleaned_horizon_height = get_stable_horizon(height_history, horizon_height_buffer_size);
            disp(cleaned_horizon_height);
            distance = calculate_distance(focal_length, principal_point_list(counter,:), [x, y], camera_height, cleaned_horizon_height);
            distances(length(distances)+1) = distance;
            
            out = insertText(out, [100 100], distance + " m", 'FontSize', 24);

            videoPlayer(out);
            writeVideo(writerObj, out);
            pause(1 / hVideoSrc.FrameRate);
        end
    end

    % if buoy is either detected or the re-tracking with the blob analysis 
    % found the buoy we insert a tracker to the next frame 
    if detected || ~isnan(x)
        frame = im2single(readFrame(hVideoSrc));
        counter = counter + 1;
        [new_points, validity] = tracker(frame);
    end
    
    % check if point tracker finds a valid point
    % insert marker at the position and calculate the distance to the buoy
    if validity ~= 0
        points = new_points;
        out = insertMarker(frame, points(validity, :),'+', 'Size', 10);
        
        horizon_height = gethorizonheight(frame, points(1));
        height_history(length(height_history)+1) = horizon_height;
        cleaned_horizon_height = get_stable_horizon(height_history, horizon_height_buffer_size);
        disp(cleaned_horizon_height);
        distance = calculate_distance(focal_length, principal_point_list(counter,:), points(validity, :), camera_height, cleaned_horizon_height);
        distances(length(distances)+1) = distance;
        out = insertText(out, [100 100], distance + " m", 'FontSize', 24);

        detected = true;
    else 
        % if buoy is not detected we insert a text indicating this.
        disp("not detected");
        out = insertText(frame, [100 100], "No Buoy Found", 'FontSize', 24);
        detected = false;
    end

    videoPlayer(out);
    pause(1 / hVideoSrc.FrameRate);
    writeVideo(writerObj, out);
end 

% close video player and writer
release(videoPlayer);
close(writerObj);

%%

% create scatter plot of the measured distances
x_arr = linspace(1, length(distances), length(distances));
figure; hold on;
scatter(x_arr, distances);

% Linear regression to plot the distance trend
coefficients = polyfit(x_arr, distances, 1);
fittedY = polyval(coefficients, x_arr);

% Do the plotting:
plot(x_arr, fittedY, 'rs-', 'LineWidth', 3, 'MarkerSize', 0.5);

title('Distance measurement over the video');
xlabel('Iteration');
ylabel('Measured distance (m)');


function [x, y] = re_track_buoy(frame, x_old, y_old)
% This function is responsible for the re-tracking of the buoy if it got
% lost. Therefore we consider the former coordinate [x, y] of the buoy as 
% the center of the area of interest with a border. We color the rest of
% the image green, in order to make the blob-analysis filter those parts
% out.

    border = 20;
    frame = im2gray(frame) * 255;  

    image = insertShape(frame, 'FilledRectangle', [0 0 size(frame, 2) y_old-border], 'Color', {'green'});
    image = insertShape(image, 'FilledRectangle', [0 0 x_old-border size(image, 1)], 'Color', {'green'});
    image = insertShape(image, 'FilledRectangle', [x_old+border 0 size(image, 2)-x_old-border size(image, 1)], 'Color', {'green'});
    image = insertShape(image, 'FilledRectangle', [0 y_old+border size(image, 2) size(image, 1)-y_old+border], 'Color', {'green'});  

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

function horizon_height = get_stable_horizon(horizon_height_history, buffer_size)
    % In order to smoothen possible mistakes of the horizon height
    % detection we build a buffer-array that considers the mean of the last
    % #buffer_size horizon heights.
    
    buffer_len = length(horizon_height_history);
    if length(horizon_height_history) >= buffer_size
        horizon_height = mean(horizon_height_history(buffer_len - buffer_size + 1: buffer_len));
    else
        horizon_height = mean(horizon_height_history);
    end
end

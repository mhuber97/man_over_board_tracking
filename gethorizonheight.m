function [height] = gethorizonheight(frame)
    % Since the video was stabilized before, we crop the frame to avoid
    % edges of the frame to be detected as the horizon. Thus, we define a
    % border that defines the main part of the image that we want to
    % consider for the horizon detection.

    border = 40;
    frame = frame(border:size(frame, 1)-border, border:size(frame, 2)-border);

    sigma1 = 0.02;
    sigma2 = 0.0016;
    frame_i = im2gray(frame);
    frame = ut_edge(frame_i, 'c', 's', 3, 'h', [sigma1, sigma2]);
    frame = mat2gray(frame);

    % We dilate the lines first only horizontally, in order to connect
    % possibly unconnected lines.
    SE = [1 1 1];
    for i=1:15
        frame = imdilate(frame, SE);
    end

    % Furthermore, we also dilate the lines a little bit vertically to
    % connect close lines.
    SE = [0 1 0; 1 1 1; 0 1 0];
    for i=1:4
        frame = imdilate(frame, SE);
    end

    % Apply hough transform
    [H, T, R] = hough(frame,'RhoResolution',1,'Theta',-90:0.5:89);

    P = houghpeaks(H, 5,'threshold',ceil(0.3*max(H(:))));

    lines = houghlines(frame, T, R, P, 'MinLength', 7, 'FillGap', 5);

    max_len = 0;
    % We now look for the longest detected line in the image that must be 
    % the horizon.
    for k = 1:length(lines)
        
        p1 = lines(k).point1;
        p2 = lines(k).point2;
        theta = lines(k).theta;
        line_length = norm(p1 - p2);
        
        % We only examine lines that have an absolute theta value over 70
        % what includes all lines that are nearly horizontal and excludes
        % all vertical lines. Furthermore, we only want lines that are more
        % or less in the vertical center of the image, so we exclude 
        if (line_length > max_len) && (p1(2) > 30) && (p2(2) > 30) && (abs(theta) > 70)
            max_len = line_length;
            longest_line = [p1; p2];
        end

    end
    % Take height of the center of the line
    height = (longest_line(1, 2) + longest_line(2,2))/2 + border; 
end

close all;
clear variables;

sigma1 =0.0019;
sigma2 = 0.0016;
SE = [0 1 0; 1 1 1; 0 1 0];

filename = 'project/MAH01462.MP4';

hVideoSrc = VideoReader(filename);
vfrUndist = vision.VideoFileReader(filename); % Video File Variable
videoPlayer = vision.VideoPlayer('Position',[100,100,1400,1000]);
vfwUndist = vision.VideoFileWriter('corrected_video.avi',...
    'FileFormat','AVI','FrameRate',vfrUndist.info.VideoFrameRate); % video file writer variable

y_initial = NaN;

while hasFrame(hVideoSrc)
    frame = rgb2gray(im2single(readFrame(hVideoSrc))); % Read first frame into imgA
    
    canny_ut = ut_edge(frame, 'c', 's', 3, 'h', [sigma1, sigma2]);
    canny_ut_gray = mat2gray(canny_ut);
    IM = canny_ut_gray;
    
    [im_height, im_width] = size(IM);
    vp_y = im_height / 2;
    
    % dilate the horizontal edges
    for i=1:5
        IM = imdilate(IM, SE);
    end
    
    % Apply huff
    [H,T,R] = hough(IM,'RhoResolution',1,'Theta',-90:0.5:89);
    
    P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
    
    lines = houghlines(IM,T,R,P,'FillGap',5,'MinLength',7);
    
    max_len = 0;
   
        
    for k = 1:length(lines)
        
        xy = [lines(k).point1; lines(k).point2];
    
        % Determine the endpoints of the longest line segment
        len = norm(lines(k).point1 - lines(k).point2);
        if ( len > max_len)
            max_len = len;
            xy_long = xy;
        end
    
    end
   
    if isnan(y_initial)
        y_initial = xy_long(1, 2);
    end
    
    dx = xy_long(2, 1) - xy_long(1, 1);
    dy = xy_long(2, 2) - xy_long(1, 2);
    x0 = xy_long(1, 1);
    y0 = xy_long(1, 2);
    c = -(dy / dx) * x0 + y0;
    
    % determine translation and rotation to stabilize the horizon
    translationY = vp_y - ( (im_width/2) * (dy/dx) + y0 );
    theta = acosd(dy / dx) - 90;
    
    % apply first translation and then rotation to the image
    IM_translated = imtranslate(frame, [0, translationY]);
    IM_stable = imrotate(IM_translated, -theta, 'bilinear', 'crop');

    %imshow(IM_stable), hold on;
    videoPlayer(IM_stable);
    pause(1 / hVideoSrc.FrameRate);

    step(vfwUndist, IM_stable); 
end

release(vfwUndist);    
release(videoPlayer);



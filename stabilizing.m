close all
clear variables

%% Initialization
filename = 'calibrated_video.avi'; %Initializes the original video

src_video = VideoReader(filename); %Reads the original video
%Initializes where to save stabilized video
video_writer=VideoWriter(['stabilized_video.avi']);
open(video_writer);
%Displaying the original and stabilized video on a single screen
video_player = vision.VideoPlayer('Name', 'Video Stabilization');
% Create a template matcher System object to compute the location of the
% best match of the target in the video frame. We use this location to find
% translation between successive video frames.
hTM = vision.TemplateMatcher('ROIInputPort', true, ...
                            'BestMatchNeighborhoodOutputPort', true);

% Load the stabilization settings 
load("stabilization_settings.mat")

%load the principal point from the camera calibration
cp = load("cameraParams.mat");
principal_point_origin = cp.cameraParams.PrincipalPoint;
principal_point_list = [];

%% Stream Processing Loop
for t=1:src_video.NumFrames %Loops for every frame of the video
    while hasFrame(src_video) %While there are still frames
        input = im2double(readFrame(src_video)); %Convert to gray video from RGB
        bw_input = im2gray(input);

        % Find location of Target in the input video frame
        if first_time %Finds the object used to stabilize
            Idx = int32(pos.template_center_pos);
            motion_vector = [100 100];
            first_time = false;
        else
            IdxPrev = Idx;
            % Builds the region of interest
            ROI = [search_region, pos.template_size+2*pos.search_border];
            Idx = hTM(bw_input,target,ROI);
            motion_vector = double(Idx-IdxPrev);
        end

        [offset, search_region] = updatesearch([W, H], motion_vector, ...
            search_region, offset, pos);

        stabilized_frame = imtranslate(input, offset, 'linear');
    
        % track where the principal point moves after the applying the
        % stabilizing transformation
        principal_point_list(size(principal_point_list, 1) + 1, :) = principal_point_origin + offset;

        target = stabilized_frame(target_row, target_col);

        % Add black border for display
        stabilized_frame(:, border_cols) = 0;
        stabilized_frame(border_rows, :) = 0;

        target_rect = [pos.template_orig-offset, pos.template_size];
        search_region_rect = [search_region, pos.template_size + 2*pos.search_border];

        %Draws rectangle on object used for stabilizing
        input = insertShape(input, 'Rectangle', [target_rect; search_region_rect],...
                            'Color', 'white');

        video_player([input(:,:,:) stabilized_frame]); %Display's video 
        writeVideo(video_writer,stabilized_frame); %Writes stabilized video to video file
    end
end

% save the list of the principal point in each frame
save('principal_point_list.mat','principal_point_list');
close(video_writer);
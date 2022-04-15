close all
clear variables

%% Initialization
filename = 'calibrated_video.avi'; %Initializes the original video

hVideoSource = VideoReader(filename); %Reads the original video
%Initializes where to save stabilized video
a=VideoWriter(['stabilized_video.avi']);
%%
open(a);

%%
% Create a template matcher System object to compute the location of the
% best match of the target in the video frame. We use this location to find
% translation between successive video frames.
hTM = vision.TemplateMatcher('ROIInputPort', true, ...
                            'BestMatchNeighborhoodOutputPort', true);
                        
%%
%Displaying the original and stabilized video on a single screen
hVideoOut = vision.VideoPlayer('Name', 'Video Stabilization');
hVideoOut.Position(1) = round(0.4*hVideoOut.Position(1));
hVideoOut.Position(2) = round(1.5*(hVideoOut.Position(2)));
hVideoOut.Position(3:4) = [1650 350];

%%
pos.template_orig = [950 260]; %Position of object used for stabilization
pos.template_size = [22 18];   %Size of area of object tracked
pos.search_border = [15 10];   % Amount of horizontal and vertical movement
pos.template_center = floor((pos.template_size-1)/2);
pos.template_center_pos = (pos.template_orig + pos.template_center - 1);
W = hVideoSource.Width; %Video Width
H = hVideoSource.Height; % Video Height
BorderCols = [1:pos.search_border(1)+4 W-pos.search_border(1)+4:W];
BorderRows = [1:pos.search_border(2)+4 H-pos.search_border(2)+4:H];
sz = [W, H];
TargetRowIndices = ...
  pos.template_orig(2)-1:pos.template_orig(2)+pos.template_size(2)-2;
TargetColIndices = ...
  pos.template_orig(1)-1:pos.template_orig(1)+pos.template_size(1)-2;
SearchRegion = pos.template_orig - pos.search_border - 1;
Offset = [0 0];
Target = zeros(1,2);
firstTime = true;

%load the principal point from the camera calibration
cp = load("cameraParams.mat");
principal_point_origin = cp.cameraParams.PrincipalPoint;
principal_point_list = [];

%% Stream Processing Loop
for t=1:433 %Loops for every frame of the video
    while hasFrame(hVideoSource) %While there are still frames
        input = im2double(readFrame(hVideoSource)); %Convert to gray video from RGB
        bw_input = im2gray(input);
        % Find location of Target in the input video frame
        if firstTime %Finds the object used to stabilize
            Idx = int32(pos.template_center_pos);
            MotionVector = [100 100];
            firstTime = false;
        else
            IdxPrev = Idx;
    
            ROI = [SearchRegion, pos.template_size+2*pos.search_border];
            Idx = hTM(bw_input,Target,ROI);
            
            MotionVector = double(Idx-IdxPrev);
        end

        [Offset, SearchRegion] = updatesearch(sz, MotionVector, ...
            SearchRegion, Offset, pos);

        Stabilized = imtranslate(input, Offset, 'linear');
    
        % track where the principal point moves after the applying the
        % stabilizing transformation
        principal_point_list(size(principal_point_list, 1) + 1, :) = principal_point_origin + Offset;

        Target = Stabilized(TargetRowIndices, TargetColIndices);

        % Add black border for display
        Stabilized(:, BorderCols) = 0;
        Stabilized(BorderRows, :) = 0;

        TargetRect = [pos.template_orig-Offset, pos.template_size];
        SearchRegionRect = [SearchRegion, pos.template_size + 2*pos.search_border];

        %Draws rectangle on object used for stabilizing
        input = insertShape(input, 'Rectangle', [TargetRect; SearchRegionRect],...
                            'Color', 'white');

        hVideoOut([input(:,:,:) Stabilized]); %Display's video 
        writeVideo(a,Stabilized); %Writes stabilized video to video file
    end
end

% save the list of the principal point in each frame
save('principal_point_list.mat','principal_point_list');

close(a);
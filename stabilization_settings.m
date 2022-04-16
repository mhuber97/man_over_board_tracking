filename = 'calibrated_video.avi'; %Initializes the original video
src_video = VideoReader(filename); %Reads the original video

pos.template_orig = [950 260]; %Position of object used for stabilization
pos.template_size = [22 18];   %Size of area of object tracked
pos.search_border = [15 10];   % Amount of horizontal and vertical movement
pos.template_center = floor((pos.template_size-1)/2);
pos.template_center_pos = (pos.template_orig + pos.template_center - 1);
W = src_video.Width; %Video Width
H = src_video.Height; % Video Height
border_cols = [1:pos.search_border(1)+4 W-pos.search_border(1)+4:W];
border_rows = [1:pos.search_border(2)+4 H-pos.search_border(2)+4:H];
target_row = ...
  pos.template_orig(2)-1:pos.template_orig(2)+pos.template_size(2)-2;
target_col = ...
  pos.template_orig(1)-1:pos.template_orig(1)+pos.template_size(1)-2;
search_region = pos.template_orig - pos.search_border - 1;
offset = [0 0];
target = zeros(1,2);
first_time = true;

save("stabilization_settings", "pos", "W", "H", "border_cols", "border_rows", ...
    "target_row", "target_col", "search_region", "offset", "target", "first_time")

function distance = calculate_distance(focal_length, principal_point, position, camera_height, horizon_height)
    % We calculate the distance from the camera to the buoy by considering
    % the earth radius, and given angles between the horizon and buoy.
    % Further instructions can be found in the report.

    % Definition of the earth radius
    radius_e = 6371000;            
    
    % Distance of the horizon to the camera
    distance_horizon = sqrt((radius_e + camera_height)^2 - radius_e^2); 

    % Angle on the image plane between the principal point and the buoy
    ang_obj_principal_axis = atan(double(abs(principal_point(2) - position(2))) / focal_length(1));

    % Angle on the image plane between the principal point and the horizon
    ang_horizon_principal_axis = atan(abs(principal_point(2) - horizon_height) / focal_length(1));
    
    % Angle between the line to the horizon and the vertical line between
    % the floor and the camera
    ang_image_plane_horizon_distance = acos(camera_height/distance_horizon);

    % Angle between the buoy and the horizon
    ang_obj_horizon = abs(ang_horizon_principal_axis - ang_obj_principal_axis);
    
    % Angle between the vertical line that carries the camera and the
    % connection line of the camera to the buoy
    ang_image_plane_buoy = abs(ang_image_plane_horizon_distance - ang_obj_horizon);

    % Distance of the camera to the buoy
    distance = tan(ang_image_plane_buoy) * camera_height;
end
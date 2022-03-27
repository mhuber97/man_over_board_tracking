function [height] = gethorizonheight(frame)
    line_feature = fibermetric(frame, 2);
    
    % threshold to find line_elments 
    P =100*(1 - 25/256);                                      % percentile: fraction of line elements is 25/256
    Tr = prctile(line_feature,P,[1,2]);                       % define threshold
    line_element_map = line_feature>Tr;                       % threshold
    
    % find line segments with minimum length - approach:
    % - apply template matching for orientation and positions
    len = 200;                                           % minimum lenght of line segment
    imacc = false(size(frame));                            % initialize with empty accu array
    line_element_map = imdilate(line_element_map,[0 1 0; 0 1 0; 0 0 0]);    % first, dilage a little bit
    % loop over all angles:
    deg=180;
    bline1 = strel('line',len,deg);                  % create a structuring element with angulated line segment
    bline2 = strel('line',len+4,deg);                  % create a structuring element with angulated line segment
    imdir = imdilate(imerode(line_element_map,bline1),bline2);  % apply opening: 
    imacc = imacc | imdir;   
    imskel = bwmorph(imacc,'spur',7);
    imskel = bwmorph(imskel,'spur',7);

    unsolved=true;
    x_i = 1;
    height = NaN;
    while x_i < length(frame) && unsolved
        result = find(imskel(:,x_i)==1);
        if result > 0
            for s=1:length(result)
                if frame(result(s), x_i) > 0 && result(s) > 70
                    height = result(s);
                    disp(height);
                    unsolved=false;
                    break;
                end
            end
        end
        x_i = x_i + 1;
    end
end

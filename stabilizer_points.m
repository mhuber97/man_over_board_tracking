%% Cleanup
clear variables;
close all;

filename = 'project/MAH01462.MP4';
hVideoSrc = VideoReader(filename);

imgA = rgb2gray(im2single(readFrame(hVideoSrc))); % Read first frame into imgA
imgB = rgb2gray(im2single(readFrame(hVideoSrc))); % Read second frame into imgB

horizon_height_A = gethorizonheight(imgA);
horizon_height_B = gethorizonheight(imgB);

pointsA = detectHarrisFeatures(imgA, "ROI", [1, 1, 1000, horizon_height_A]);
pointsB = detectHarrisFeatures(imgB, "ROI", [1, 1, 1000, horizon_height_B]);

% Extract FREAK descriptors for the corners
[featuresA, pointsA] = extractFeatures(imgA, pointsA);
[featuresB, pointsB] = extractFeatures(imgB, pointsB);

indexPairs = matchFeatures(featuresA, featuresB);
pointsA = pointsA(indexPairs(:, 1), :);
pointsB = pointsB(indexPairs(:, 2), :);

[tform, inlierIdx] = estimateGeometricTransform2D(pointsB, pointsA, 'projective');
pointsBm = pointsB(inlierIdx, :);
pointsAm = pointsA(inlierIdx, :);
imgBp = imwarp(imgB, tform, 'OutputView', imref2d(size(imgB)));
figure; imshow(imgBp);
hVideoOut = vision.VideoPlayer('Name', 'Video Stabilization');
ii = 1;
while hasFrame(hVideoSrc) && ii < 200
    imgNext = rgb2gray(im2single(readFrame(hVideoSrc))); % Read second frame into imgNext

    horizon_height_A_new = gethorizonheight(imgBp);
    horizon_height_B_new = gethorizonheight(imgNext);
    
    if ~isnan(horizon_height_A_new)
        horizon_height_A = horizon_height_A_new;
    end

    if ~isnan(horizon_height_B_new)
        horizon_height_B = horizon_height_B_new;
    end
    %pointsA = detectHarrisFeatures(imgBp, "ROI", [1, 1, 1000, horizon_height_A]);
    %pointsB = detectHarrisFeatures(imgNext, "ROI", [1, 1, 1000, horizon_height_B]);

    %pointsA = detectMinEigenFeatures(imgBp, "ROI", [1, 1, 1000, horizon_height_A]);
    %pointsB = detectMinEigenFeatures(imgNext, "ROI", [1, 1, 1000, horizon_height_B]);

    pointsA = detectSURFFeatures(imgBp, "ROI", [1, 1, 1000, horizon_height_A]);
    pointsB = detectSURFFeatures(imgNext, "ROI", [1, 1, 1000, horizon_height_B]);

    % Extract FREAK descriptors for the corners
    [featuresA, pointsA] = extractFeatures(imgBp, pointsA);
    [featuresB, pointsB] = extractFeatures(imgNext, pointsB);

    indexPairs = matchFeatures(featuresA, featuresB);
    pointsA = pointsA(indexPairs(:, 1), :);
    pointsB = pointsB(indexPairs(:, 2), :);

    if length(indexPairs) < 4
        tmp_A = insertShape(imgBp, 'FilledRectangle', [1, horizon_height_A, length(imgBp), 10],...
                        'Color', 'red');
        tmp_B = insertShape(imgNext, 'FilledRectangle', [1, horizon_height_B, length(imgNext), 10],...
                        'Color', 'red');
        figure; imshowpair(tmp_A, tmp_B, 'montage');
    end
    [tform, inlierIdx] = estimateGeometricTransform2D(pointsB, pointsA, 'projective');
    pointsBm = pointsB(inlierIdx, :);
    pointsAm = pointsA(inlierIdx, :);
    imgBp = imwarp(imgNext, tform, 'OutputView', imref2d(size(imgNext)));
    %figure; imshow(imgBp);
    imgBp_output = insertShape(imgBp, 'FilledRectangle', [1, horizon_height_A, length(imgBp), 10],...
                        'Color', 'red');
    hVideoOut(imgBp_output);
    %pause(1 / hVideoSrc.FrameRate);
    ii = ii+1;
end


figure; imshow(imgBp);





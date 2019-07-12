%{
%EXPERIMENT_ANALYSIS.m
%Kyle Inzunza
%}

%% video import

exp = 'Task2_wrist_trial2'; %expirement name

%close all waitbars if they exsist
try
    delete(findall(0));
catch
end
close all; %close windows
clc; %clear command window

disp('Loading videos...');
%comment out to save runtime
%load(exp); %load videos

manipulations = getmanframes(); %get frames that were manipulated in the expirement


%% sync videos

%get sync frames for all videos
disp('Syncing CANON...');
sync_top = getsyncframe(vid_top);
disp('Syncing ION CAMERA...');
sync_side = getsyncframe(vid_side);
disp('Syncing WEBCAM...');
sync_webcam = getsyncframe(vid_web);

%if manipulations exist adjust manipulations to sync
if ~isempty(manipulations{1})
    manipulations{1} = manipulations{1} - sync_side;
end
if ~isempty(manipulations{2})
    manipulations{2} = manipulations{2} - sync_webcam;
end

%trim videos
vid_top = vid_top(sync_top:end);
vid_side = vid_side(sync_side:end);
vid_web = vid_web(sync_webcam:end);

fnum = min([size(vid_top,2),size(vid_side,2),size(vid_web,2)]); %the shortest video's frame number is used for the global frame number


%% circle identification side view

%find circles in frame 1
%radii and sensitivity has to be manually calibrated
rad_side = [6 10];
sen_side = 0.95;
c_side_w = imfindcircles(vid_side{1}, rad_side, 'ObjectPolarity', 'bright','Sensitivity',sen_side);
c_side_b = imfindcircles(vid_side{1}, rad_side, 'ObjectPolarity', 'dark','Sensitivity',sen_side);

%white markers
printcircles(vid_side{1}, c_side_w); %print circles to user
wmarker_num = input('How many white markers are being tracked: ');
wmarkerid_side = zeros(wmarker_num,1); %id numbers of white markers
wmarkername_side = cell(wmarker_num,1); %names of whitemarkers

%loop through every marker
for ii = 1:wmarker_num
    %loop until valid input
    while true
        temp = input(['ID #' num2str(ii) ': ']);
        
        %has not been input before
        if sum(ismember(wmarkerid_side,temp)) ~= 0
            disp('ID has alread been input.');
            %is an integer
            %is within the bounds
        elseif floor(temp) == temp && temp <= size(c_side_w,1) && temp > 0
            wmarkerid_side(ii) = temp; %record circle index
            wmarkername_side{ii} = input('Marker name: ','s'); %get model id for that circle
            break; %end loop
        else
            disp('Input invalid, try again.');
        end
    end
end

%black markers
printcircles(vid_side{1}, c_side_b); %print circles to user
k = 1; %counts how many origins have been input
origin_side_name = cell(1,2); %cell array to hold names
origin_side = zeros(2); %array to hold origin coordinates
for ii = 1:2
    %loop until valid
    while true
        temp = input(['Circle of O' num2str(ii - 1) ' (if not visible/not being tracked type 0): ']);
        if temp == 0
            break; %end loop
            %check if input valid
        elseif floor(temp) == temp && temp <= size(c_side_b,1) && temp > 0
            origin_side(k,:) = c_side_b(temp,:); %record origin coordinates
            origin_side_name{k} = ['O' num2str(ii - 1)]; %record origin name
            k = k + 1; %increase counter
            break; %end loop
        else
            disp('Input invalid, try again.');
        end
    end
end

%truncate unused parts of arrays
origin_side(origin_side == 0) = [];
origin_side_name(cellfun(@isempty,origin_side_name)) = [];


%% circle identification top view

%find circles in frame 1
%radii and sensitivity has to be manually calibrated
rad_top = [14,20];
sen_top = 0.95;

c_top_w = imfindcircles(vid_top{1}, rad_top, 'ObjectPolarity', 'bright','Sensitivity',sen_top);
c_top_b = imfindcircles(vid_top{1}, rad_top, 'ObjectPolarity', 'dark','Sensitivity',sen_top);

%white markers
printcircles(vid_top{1}, c_top_w); %print circles to user
wmarker_num = input('How many white markers are being tracked: ');
wmarkerid_top = zeros(wmarker_num,1); %id numbers of white markers
wmarkername_top = cell(wmarker_num,1); %names of whitemarkers

%loop through every marker
for ii = 1:wmarker_num
    %loop until valid input
    while true
        temp = input(['ID #' num2str(ii) ': ']);
        %has not been input before
        if sum(ismember(wmarkerid_top,temp)) ~= 0
            disp('ID has alread been input.');
            %is an integer
            %is within the bounds
        elseif floor(temp) == temp && temp <= size(c_top_w,1) && temp > 0
            wmarkerid_top(ii) = temp; %record circle index
            wmarkername_top{ii} = input('Marker name: ','s'); %get model id for that circle
            break; %end loop
        else
            disp('Input invalid, try again.');
        end
    end
end

%black markers
printcircles(vid_top{1}, c_top_b); %print circles to user
k = 1; %counts how many origins have been input
origin_top_name = cell(1,2); %cell array to hold names
origin_top = zeros(2); %array to hold origin coordinates
for ii = 1:2
    %loop until valid
    while true
        temp = input(['Circle of O' num2str(ii - 1) ' (if not visible/not being tracked type 0): ']);
        if temp == 0
            break; %end loop
            %check if input valid
        elseif floor(temp) == temp && temp <= size(c_side_b,1) && temp > 0
            origin_top(k,:) = c_side_b(temp,:); %record origin coordinates
            origin_top_name{k} = ['O' num2str(ii - 1)]; %record origin name
            k = k + 1; %increase counter
            break; %end loop
        else
            disp('Input invalid, try again.');
        end
    end
end

%truncate unused parts of arrays
origin_top(origin_top == 0) = [];
origin_top_name(cellfun(@isempty,origin_top_name)) = [];


%% sort identified circles

%data structure
%ptop -> position top camera -> (circle,frame,xy)
%mtop -> map of circle index to marker name -> (id)
%pside -> position side camera -> (circle,frame,xy)
%mside -> map of circle index to marker name -> (id)
%pweb -> position webcam -> (circle,frame,xy)
% d = struct('ptop', zeros(size(wmarkerid_top, 1) + sum(origin_top ~= 0), fnum,2), 'mtop', cell(1, size(wmarkerid_top,1) + sum(origin_top ~= 0)),...
%     'pside', zeros(size(wmarkerid_side, 1) + sum(origin_side ~= 0), fnum,2), 'mside', cell(1, size(wmarkerid_side, 1)+ sum(origin_side ~= 0)),...
%     'pweb', zeros(6, fnum, 2));

%new data structure initialization
d = struct('ptop', zeros(size(wmarkerid_top, 1) + size(origin_top,1), fnum,2), 'mtop',[],'markernum_top', [size(wmarkerid_top,1), size(origin_top,1)],...
    'pside', zeros(size(wmarkerid_side, 1) + size(origin_side,1), fnum,2), 'mside',[],'markernum_side', [size(wmarkerid_side,1), size(origin_top,1)],...
    'pweb', zeros(6, fnum, 2));


%populate map arrays

%vertically concatonate the arrays
d.mside = [wmarkername_side;origin_side_name'];
d.mtop = [wmarkername_top;origin_top_name'];

%populate first frame of position data

%loop through white markers
for ii = 1:d.markernum_side(1)
    d.pside(ii,1,:) = c_side_w(wmarkerid_side(ii),:); %set position of circle ii in frame 1
end
for ii = 1:d.markernum_top(1)
    d.ptop(ii,1,:) = c_top_w(wmarkerid_top(ii),:); %set position of circle ii in frame 1
end

%loop through black markers if they are found
if d.markernum_side(2) ~= 0
    for ii = 1:d.markernum_side(2)
        d.pside(ii + d.markernum_side(1),1,:) = origin_side(ii,:); %set position
    end
end
if d.markernum_top(2) ~= 0
    for ii = 1:d.markernum_top(2)
        d.ptop(ii+ d.markernum_top(1),1,:) = origin_top(ii,:); %set position
    end
end

d.pweb(:,1,:) = webfindcircles(vid_web{1}); %write webcam marker position for initial frame


%% remaining frames (side)

frame_skip = 15; %amount of frames to skip when user id frame 
skip_counter = 0; %amount of frames that have been skipped
skip_mode = false; %if the loop should be skipping frames

missing_counter = 0; %amount of times attempted to id missing circles
missing_limit = 5; %max amount of attempts to reid missing circles

usr_id_mode = false; %if the user needs to re-identify the frames

wb = waitbar(0,'Analysing ION CAMERA frames...'); %start progress bar


%loop through remaining frames
for ii = 2:fnum
    waitbar(ii/fnum); %update progress bar
    
    %check if frame needs to be skipped
    if skip_mode && skip_counter < frame_skip
        skip_counter = skip_counter+1; 
        d.pside(:,ii,:) = nan*ones(size(d.pside(:,1,:))); %write skipped frame as not a number
        continue; %go to next iteration
    else
        %reset skip variables
        skip_mode = false;
        skip_counter = 0;
    end
    
    %check if frame ii is a manipulation frame
    if isman(ii,manipulations)
        d.pside(:,ii,:) = nan*ones(size(d.pside(:,1,:))); %write the whole frame as not a number
        continue; %skip this loop interation
    end
    
    prevwc = d.pside(1:d.markernum_side(1),ii-1,:); %postion of all previous frame white markers
    prevbc = d.pside(d.markernum_side(1)+1:end,ii-1,:); %postion of all previous frame black markers
    
    %if previous frame contained doens't contain NaN
    if sum(sum(isnan(prevwc))) == 0 && sum(sum(isnan(prevbc))) == 0
        
        maskedim_white = overlaycirclemask(vid_side{ii},prevwc); %overlay mask on current frame from positions of white markers in previous frame
        maskedim_blk = overlaycirclemask(vid_side{ii},prevbc); %overlay mask on current frame from positions of black markers in previous frame
        
        cw = imfindcircles(maskedim_white, rad_side, 'ObjectPolarity', 'bright','Sensitivity',sen_side); %get center of white circles in image
        cb = imfindcircles(maskedim_blk, rad_side, 'ObjectPolarity', 'dark','Sensitivity',sen_side + 0.02); %get center of black circles in image
        
        try
            cw = idcircles(cw,prevwc,d.markernum_side(1));%identify white circles
            cb = idcircles(cb,prevbc,d.markernum_side(2));%identify black circles
            
            d.pside(:,ii,:) = [cw;cb]; %save circle positions
            
        catch ME
            switch ME.identifier
                %some circles are not visible
                case 'MyComponent:notenoughmarkers'
                    disp(['Circles missing on IONCAMERA at frame ' num2str(ii)]);
                    d.pside(:,ii,:) = nan*ones(size(d.pside(:,1,:))); %write the whole frame as not a number
                    missing_counter = missing_counter + 1;
                
                %previous case was written all as nan
                case 'MyComponenet:nullprevframe'
                    disp("Error. \nProblem with if statement.");%if this error was thrown it passed the if statment that should stop nan values
                    rethrow(ME);
                    
                 %not expected error
                otherwise
                    rethrow(ME); %rethrow exception
            end
        end
        
    elseif missing_counter <= missing_limit && ~usr_id_mode %if the program needs to reid missing circles 
        missing_counter = missing_counter + 1; %add one to missing counter
        
        %get last known positions of circles
        prevwc = d.pside(1:d.markernum_side(1),ii-missing_counter,:); %white markers
        prevbc = d.pside(d.markernum_side(1)+1:end,ii-missing_counter,:); %black markers

        
%         %mask current frame images with previous circles
%         try
%             maskedim_white = overlaycirclemask(vid_side{ii},prevwc); %white markers
%             maskedim_blk = overlaycirclemask(vid_side{ii},prevbc); %black markers
%         catch ME
%             rethrow(ME);
%         end
        
        cw = imfindcircles(vid_side{ii}, rad_side, 'ObjectPolarity', 'bright','Sensitivity',sen_side); %get center of white circles in image
        cb = imfindcircles(vid_side{ii}, rad_side, 'ObjectPolarity', 'dark','Sensitivity',sen_side); %get center of black circles in image
        
        try
            cw = idcircles(cw,prevwc,d.markernum_side(1));%identify white circles
            cb = idcircles(cb,prevbc,d.markernum_side(2));%identify black circles
            
            d.pside(:,ii,:) = [cw;cb]; %save circle positions
            missing_counter = 0; %reset counter
            
        catch ME
            switch ME.identifier
                %some circles are not visible
                case 'MyComponent:notenoughmarkers'
                    disp(['Circles missing on IONCAMERA at frame ' num2str(ii)]);
                    d.pside(:,ii,:) = nan*ones(size(d.pside(:,1,:))); %write the whole frame as not a number
                %previous case was written all as nan
                case 'MyComponent:nullprevframe'
                    disp("Error. \nProblem with if statement.");%if this error was thrown it passed the if statment that should stop nan values
                    rethrow(ME)
                    %not expected error
                otherwise
                    rethrow(ME); %rethrow exception
            end
        end
    else %if the user needs to reid the circles
        usr_id_mode = true; %turn on user id mode
        missing_counter = 0; %reset missing counter
        try
            cw = imfindcircles(vid_side{ii}, rad_side, 'ObjectPolarity', 'bright','Sensitivity',sen_side); %get center of white circles in image
            cb = imfindcircles(vid_side{ii}, rad_side, 'ObjectPolarity', 'dark','Sensitivity',sen_side); %get center of black circles in image
            
            d.pside(:,ii,:) = usridcircles(vid_side{ii},cw,cb,d.mside); %get user to re-identify markers
        catch ME
            switch ME.identifier
                %all circles are still not visible in frame
                case 'MyComponent:wrongframe'
                    d.pside(:,ii,:) = nan*ones(size(d.pside(:,1,:))); %write the whole frame as not a number
                    skip_mode = true; %turn on skip mode to skip next n frames
                    continue; %go to next iteration of loop
                otherwise
                    rethrow(ME);
            end
        end
        usr_id_mode = false; %block can only be completed when user inputs correct values
    end
end

close(wb); %close progress bar


%% remaining frames (top)

wb = waitbar(0,'Analysing CANON CAMERA frames...'); %start progress bar

%loop through remaining frames
for ii = 2:fnum
    waitbar(ii/fnum); %update progress bar
    
    %check if frame needs to be skipped
    if skip_mode && skip_counter < frame_skip
        skip_counter = skip_counter+1; 
        d.ptop(:,ii,:) = nan*ones(size(d.ptop(:,1,:))); %write skipped frame as not a number
        continue; %go to next iteration
    else
        %reset skip variables
        skip_mode = false;
        skip_counter = 0;
    end
    
    %check if frame ii is a manipulation frame
    if isman(ii,manipulations)
        d.ptop(:,ii,:) = nan*ones(size(d.ptop(:,1,:))); %write the whole frame as not a number
        continue; %skip this loop interation
    end
    
    prevwc = d.ptop(1:d.markernum_top(1),ii-1,:); %postion of all previous frame white markers
    prevbc = d.ptop(d.markernum_top(1)+1:end,ii-1,:); %postion of all previous frame black markers
    
    %if previous frame contained doens't contain NaN
    if sum(sum(isnan(prevwc))) == 0 && sum(sum(isnan(prevbc))) == 0
        
        maskedim_white = overlaycirclemask(vid_top{ii},prevwc); %overlay mask on current frame from positions of white markers in previous frame
        maskedim_blk = overlaycirclemask(vid_top{ii},prevbc); %overlay mask on current frame from positions of black markers in previous frame
        
        cw = imfindcircles(maskedim_white, rad_top, 'ObjectPolarity', 'bright','Sensitivity',sen_top); %get center of white circles in image
        cb = imfindcircles(maskedim_blk, rad_top, 'ObjectPolarity', 'dark','Sensitivity',sen_top + 0.02); %get center of black circles in image
        
        try
            cw = idcircles(cw,prevwc,d.markernum_top(1));%identify white circles
            cb = idcircles(cb,prevbc,d.markernum_top(2));%identify black circles
            
            d.ptop(:,ii,:) = [cw;cb]; %save circle positions
            
        catch ME
            switch ME.identifier
                %some circles are not visible
                case 'MyComponent:notenoughmarkers'
                    disp(['Circles missing on IONCAMERA at frame ' num2str(ii)]);
                    d.ptop(:,ii,:) = nan*ones(size(d.ptop(:,1,:))); %write the whole frame as not a number
                    missing_counter = missing_counter + 1;
                
                %previous case was written all as nan
                case 'MyComponent:nullprevframe'
                    disp("Error. \nProblem with if statement.");%if this error was thrown it passed the if statment that should stop nan values
                    rethrow(ME);
                 %not expected error
                otherwise
                    rethrow(ME); %rethrow exception
            end
        end
        
    elseif missing_counter <= missing_limit && ~usr_id_mode %if the program needs to reid missing circles 
        missing_counter = missing_counter + 1; %add one to missing counter
        
        %get last known positions of circles
        prevwc = d.ptop(1:d.markernum_top(1),ii-missing_counter,:); %white markers
        prevbc = d.ptop(d.markernum_top(1)+1:end,ii-missing_counter,:); %black markers

        
%         %mask current frame images with previous circles
%         try
%             maskedim_white = overlaycirclemask(vid_side{ii},prevwc); %white markers
%             maskedim_blk = overlaycirclemask(vid_side{ii},prevbc); %black markers
%         catch ME
%             rethrow(ME);
%         end
        
        cw = imfindcircles(vid_top{ii}, rad_top, 'ObjectPolarity', 'bright','Sensitivity',sen_top); %get center of white circles in image
        cb = imfindcircles(vid_top{ii}, rad_top, 'ObjectPolarity', 'dark','Sensitivity',sen_top); %get center of black circles in image
        
        try
            cw = idcircles(cw,prevwc,d.markernum_top(1));%identify white circles
            cb = idcircles(cb,prevbc,d.markernum_top(2));%identify black circles
            
            d.ptop(:,ii,:) = [cw;cb]; %save circle positions
            missing_counter = 0; %reset counter
            
        catch ME
            switch ME.identifier
                %some circles are not visible
                case 'MyComponent:notenoughmarkers'
                    disp(['Circles missing on IONCAMERA at frame ' num2str(ii)]);
                    d.ptop(:,ii,:) = nan*ones(size(d.ptop(:,1,:))); %write the whole frame as not a number
                %previous case was written all as nan
                case 'MyComponent:nullprevframe'
                    disp("Error. \nProblem with if statement.");%if this error was thrown it passed the if statment that should stop nan values
                    rethrow(ME)
                    %not expected error
                otherwise
                    rethrow(ME); %rethrow exception
            end
        end
    else %if the user needs to reid the circles
        usr_id_mode = true; %turn on user id mode
        missing_counter = 0; %reset missing counter
        try
            cw = imfindcircles(vid_top{ii}, rad_top, 'ObjectPolarity', 'bright','Sensitivity',sen_top); %get center of white circles in image
            cb = imfindcircles(vid_top{ii}, rad_top, 'ObjectPolarity', 'dark','Sensitivity',sen_top); %get center of black circles in image
            
            d.ptop(:,ii,:) = usridcircles(vid_top{ii},cw,cb,d.mtop); %get user to re-identify markers
        catch ME
            switch ME.identifier
                %all circles are still not visible in frame
                case 'MyComponent:wrongframe'
                    d.ptop(:,ii,:) = nan*ones(size(d.ptop(:,1,:))); %write the whole frame as not a number
                    skip_mode = true; %turn on skip mode to skip next n frames
                    continue; %go to next iteration of loop
                otherwise
                    rethrow(ME);
            end
        end
        usr_id_mode = false; %block can only be completed when user inputs correct values
    end
end

close(wb); %close progress bar

%% remaining frame (webcam)

wb = waitbar(0,'Analysing webcam frames...'); %start progress bar

%loop through remaining frames
for ii = 2:fnum
    
    waitbar(ii/fnum); %update progress bar
    
    %check if manipulation frame
    if isman(ii,manipulations)
        d.pweb(:,ii,:) = nan*ones(6,2); %write the whole frame as not a number
        continue; %go to next iteration of loop
    end
    
    
    try
        d.pweb(:,ii,:) = webfindcircles(vid_web{ii}); %get marker positions
    catch ME
        switch ME.identifier
            case 'MyComponent:blocked'
                d.pweb(:,ii,:) = nan*ones(6,2); %write the whole frame as not a number
                disp(['Circles missing on WEBCAM at frame ' num2str(ii)]);
            case 'MyComponent:watchDog'
                d.pweb(:,ii,:) = nan*ones(6,2); %write the whole frame as not a number
                disp(['Too many circles on WEBCAM at frame ' num2str(ii)]);
                imshow(vid_web{ii}); %display current frame
            otherwise
                rethrow(ME); %error was not resolved
        end
    end
end

close(wb); %close progress bar

%% write data

%concatonate headers onto data
data_side = [d.mside';num2cell(d.pside)];
data_top = [d.mtop';num2cell(d.ptop)];
data_web = [{'Cord1','Cord2','Cord3','Cord4','Cord5','Cord6'},num2cell(d.pweb)];

%write data to files
writematrix(data_side, [expname '_side.xls']);
writematrix(data_top, [expname '_top.xls']);
writematrix(data_web, [expname '_web.xls']);








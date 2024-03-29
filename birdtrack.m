function pos = birdtrack(video)
%BIRDTRACK returns position of tracked circles from birds eye view of glove

cs = vid2struct(video); %breaks video down into frames
gs = RGBstrut2grey(cs);  %access elements of gs with gs{a}



rad = [80 100]; %radius range of circles
pol = 'dark'; %object polarity
sen = .95; %search sensitivity

cnum = circlenum(gs{1},rad,pol,sen); %number of circles
expc = cnum; %expected number of circles

expdist = zeros(cnum); %initial distances between circles

isvisible = ones(cnum,1); %array of booleans, of if circle is visible

gs = syncad(gs); %adjust for sync

[~,fnum] = size(gs); %get number of frames

%position -> (circle, frame, xyz coordinate)
%x = 1
%y = 2
%z = 3
pos = zeros(cnum,fnum,3); %populate position matrix

wb = waitbar(0,'Analysing frames from camera 1...'); %start progress bar 


%loop through frames
for jj = 1:fnum
    
    waitbar(jj/fnum); %update waitbar
    
    center = imfindcircles(gs{jj},rad, 'ObjectPolarity', pol,...
    'Sensitivity',sen); %find xy position of circle
   
    %check if there are more circles than in the initial frame 
    s = size(center); 
    if s(1) > cnum
        disp(jj)
        disp(s(1))
        error('Unexpected circle appeared.');
    %check if circles have dissapeared
    elseif s(1) < expc
        indexm = findmiss(pos(:,jj-1,1:2),center); %find all circles that have dissapeared
        a = size(indexm);
        %loop through vector
        for qq = 1:a(1)
            isvisible(qq) = 0; %mark circle qq as not visible
        end
        expc = expc - a(1); %adjust expected circles to number of circles in frame
            
    %check if circles have appeared
    elseif s(1) > expc
        %check if only one circle is missing
        if countmiss(isvisible) == 1
            
            %create matrix of circles that are in frame n-1
            oldc = zeros(s(1), 2);
            for hh = 1:cnum
                if isvisible(hh) == 1
                    oldc(hh,:) = pos(hh,jj,1:2); %only take x and y coordinate 
                end
            end
            
            index = findappear(oldc, center); %find the index of circle that has appeared
            
            %loop through boolean vector to find index of missing circle
            for tt = 1:cnum
                if isvisible(tt) == 0
                    pos(tt,jj,1:2) = center(index,:); %match added circle to list
                    %only add x and y component
                end
            end
        else
            error('More than one circle was missing. This case was not accounted for.');
        end
            
    end
    
    %loop through circles
    for ii = 1:cnum
        %if first frame
        if jj == 1
            pos(ii,jj,1) = center(ii,1); %set x
            pos(ii,jj,2) = center(ii,2); %set y
            
            
        %if not first frame
        else
            %only run if circle is in frame
            if isvisible(ii) == 1
                %the circle that is shortest distance from circle ii in previous
                %frame is treated as circle ii
                icirc = objmindist(pos(ii,jj-1,:),center,'xy'); %find circle of min dist
           
                pos(ii,jj,1) = center(icirc(1),1); %set x
                pos(ii,jj,2) = center(icirc(1),2); %set y
            end
        end
    end
    
    %if first frame
    if jj == 1
        %populate distance array
        %loop through columns
        for aa = 1:cnum
            %loop through rows
            for bb = 1:cnum
                expdist(aa,bb) = getdist(pos(aa,1,:),pos(bb,1,:)); %set value as dist 
            end
        end
    end

end

close(wb); %close progress bar
end


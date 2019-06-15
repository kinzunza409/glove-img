function maskedimage = overlaycirclemask(image,c)
%OVERLAYCIRCLEMAS overlays a mask of circles over an image

[h,w] = size(image); %get image dimensions

mask = zeros(h,w); % blank mask

r = 50; %radius of circles
cnum = size(c,1); %number of circles

%generate square mask of circle
circmatrix = ones(r*2);

%loop through rows
for ii = 1:r*2
    %loop through columns
    for jj = 1:r*2
        %if outside circle radius
        if sqrt((ii-r)^2 + (jj-r)^2) > r
            circmatrix(ii,jj) = 0; %make area black
        end
    end
end

%loop through circles
for ii = 1:cnum
    center = round(c(ii,:)); %get center of circle
        
    try
        mask(center(2)-r:center(2)+r,center(1)-r:center(1)+r) = circmatrix; %add circle to matrix
    catch ME
        
        x = [center(1)-r+1,center(1)+r]; %x indices
        y = [center(2)-r+1,center(2)+r]; %y indices
        
        %indices of circle matrix to be called
        xm = [1,100];
        ym = [1,100];
        
        %check cases of why error was thrown
        %adjusts indices
        if center(2)-r < 0
            y(1) = 1;
            ym(1) = abs(center(2)-r);
        end
        if center(2)+1 > h
            y(2) = h;
            ym(2) = center(2)+r - h;
        end
        if center(1)-r < 0
            x(1) = 1;
            xm(1) = abs(center(1)-r);
        end
        if center(1)+1 > w
            x(2) = w;
            xm(2) = center(1)+r - w;
        end

          try  
        mask(y(1):y(2),x(1):x(2)) = circmatrix(ym(1):ym(2),xm(1):xm(2)); %add partial circle to matrix
          catch ME
              disp('yeet');
          end

    end
        
 


end


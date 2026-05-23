function y=Apodization(window,size,center,index)

%  Apodization    -   Creates apodization window
%
%   y=Apodization(window,size,center,index)
%
%  window: 1  Happ-Genzel
%          2  3-term Blackman-Harris
%          3  4-term Blackman-Harris
%          4  Triangular
%          5  Supergaussian, with index
%          6  Trapezoidal (implemented directly in the HyperspectralAnalysis_Time code)
%  size  : number of samples
%  center: position of center of trace (number of vector element)
%  index : for supergaussian apodization

x=[1:size]-center;
% x=x-mean(x);
    
switch window

    case 1 % Happ-Genzel
        
        y=0.54+0.46*cos(2*pi*x/size);
        y( x<(-size/2) | x>(size/2) )=0;
        
    case 2 % 3-term Blackman-Harris
        
        y=0.42323+0.49755*cos(2*pi*x/size)+0.07922*cos(2*2*pi*x/size);
        
    case 3 % 4-term Blackman-Harris
        
        y=0.35875+0.48829*cos(2*pi*x/size)+0.14128*cos(2*2*pi*x/size)+0.01168*cos(3*2*pi*x/size);
        
    case 4 % Triangular
        
        if center>round(size/2)
            
            y=x(end)-abs(x); y=y/max(y);
            y(y<0)=0;
            
        else
            
            y=center-abs(x); y=y/max(y);
            y(y<0)=0;
        end;
        
    case 5 % Supergauss
        
        xmin=-min(abs(x(1)),abs(x(end)));
        xmax=min(abs(x(1)),abs(x(end)));
        y=superGauss(x,xmin,xmax,index,200);
        
    case 6 % Trapezoidal
        
end;

end

function y=superGauss(x,x1,x2,index,fraction)

% superGauss     -  generates a supergaussian function y(x)
%
%    y=superGauss(x,x1,x2,index,fraction);
%
% index : index of the supergaussian: exponent will be 2*index
% x1, x2: Points at which y=1/fraction;


x0=(x1+x2)/2;
tau=abs(x1-x0)/(log(fraction))^(1/(2*index));

y=exp(-((x-x0)/tau).^(2*index)); 
end

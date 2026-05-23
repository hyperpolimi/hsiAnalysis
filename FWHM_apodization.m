function [FWHM,APOD,f,apod,t]=FWHM_apodization(apodization_type,delta_t)

%function that gives the FWHM of the FT of apodization function

%apodization type:
% % % % 0 - none (rectangular)
% % % % 1 - Happ-Genzel
% % % % 2 - 3-term Blackmann-Harris
% % % % 3 - 4-term Blackmann-Harris
% % % % 4 - Triangular
%
%t_min: minimum in the delay axis
%t_max: maximum in the delay axis
%f_max: maximum frequency to evaluate the FT of apodization
%n_points_f: number of points in the frequency axis

f_max=10.*delta_t.^(-1); %maximum frequency to evaluate the FT of apodization (~10 times the resolution with rectangular apodization)
n_points_f=round(f_max./(delta_t.^(-1)./2000)); %number of points in the frequency axis (to guarantee 2000 points inside the resolution with rectangular apodization)

n_points_t=100.*(f_max./2).*delta_t; %number of delay axis points (to guarantee step 100 times smaller than the Nyquist-Shannon one)
t=linspace(-delta_t./2,delta_t./2,n_points_t); %delay scan

f=linspace(-f_max,f_max,n_points_f); %frequency axis

if apodization_type==0
    apod=ones(size(t)); %rectangular apodization function
else
    apod=Apodization(apodization_type,length(t),length(t)./2,7); %apodization function
end

APOD=abs(FourierDir(t,apod,f));

FWHM=interp1(APOD(f>0)./max(APOD),f(f>0),0.5)-interp1(APOD(f<0)./max(APOD),f(f<0),0.5);

end
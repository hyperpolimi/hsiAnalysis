% function four=FourierDir(t,s,nu);
%
% Calculates the Fourier Tranform over the frequency domain defined by nu
% Corresponding inverse Fourier Transform is FourierInv
%
% t,s,nu,four: row vectors

function four=FourierInv(t,s,nu)

% % number of points in the time domain
% N=length(t);
% Nf=length(nu);
% 
% % sampling step in the time domain
Dt=diff(t);
Dt(end+1)=Dt(end);
% 
% four=zeros(1,Nf);
% 
% for ii=1:Nf
%     
%     four(ii)=sum(Dt.*s.*exp(-1i*2*pi.*t.*nu(ii)));
%     
% end;

% metodo matriciale
four=(Dt.*s)*exp(1j*2*pi*t'*nu); % matrix
function fair(root, TI, TR, NAVGS, verbose)
%
%function fair(root, TI, TR, NAVGS, verbose)
%
% Computes perfusion map using Buxton's model
% for FAIR experiment
% uses the file Mot.dat, which was generated by 
% t1_map.m
% 
% magnitude data

%%  Assumed constants  %%%

if nargin==2
    NAVGS=TI
end

lambda_T2 = 0.7;
T1b = 2.9;
threshold = 60; % signal intensity threshold
scaleFactor = 1000;
alpha = 1;
del = 0.5;

Npoints=size(TI,2);

files = dir(strcat(root,'*.img'));
hfiles = dir(strcat(root,'*.hdr'));


% determine format of files
h = read_hdr(hfiles(1).name);

    
% Allocate space for the data.  Each TI is in a row
SS_data = zeros(Npoints , h.xdim*h.ydim*h.zdim);
NS_data = zeros(Npoints , h.xdim*h.ydim*h.zdim);
FAIR_data = zeros(Npoints, h.xdim*h.ydim*h.zdim );
FAIR_data_buffer = zeros(Npoints,2);
FAIR_size = size(FAIR_data);

% read the data
disp('Loading  NS data ...')
m=1;
for n=0: Npoints-1
   tmp = zeros(1,h.xdim*h.ydim*h.zdim);
   for k=0:NAVGS-1
       index=n*2*NAVGS +2 + 2*k ;
       fprintf('\nadding image %d to the data to point %d', index, m);
       tmp = tmp + read_img_data(h,files(index).name);
   end
   
   NS_data(m,:) = tmp/NAVGS;
   m=m+1;

end

fprintf('\nLoading  SS data ...')
m=1;
for n=0: Npoints-1
   tmp = zeros(1,h.xdim*h.ydim*h.zdim);
   for k=0:NAVGS-1
       index=n*2*NAVGS +1 + 2*k ;
       fprintf('\nadding image %d to the data to point %d', index, m);
       tmp = tmp + read_img_data(h,files(index).name);
   end
   
   SS_data(m,:) = tmp/NAVGS;
   m=m+1;

end

   
% the FAIR subtraction should be the abs of the complex subtraction
FAIR_data = abs(NS_data - SS_data);

fprintf('\nWriting subtraction images to disk ...')

for i=1:Npoints
    str = sprintf('FAIR%03d.img', i);
    fprintf('...\n%s',str);
    write_img_data(str, FAIR_data(i,:), h);
    str = sprintf('FAIR%03d.hdr',i);
    write_hdr(str,h);
end

if nargin==2
    return
end


fprintf('\nFitting ...')
%Mot=read_img_data(h,'Mot.img');
Mot = SS_data(m-1,:) ; 


% inital guesses for fit parameters
Tau_guess = 1;
Mob_f_guess = 300;
dt_guess = 1;

guess0 = [  Tau_guess Mob_f_guess dt_guess ];

guess_max = [3.5     5000   1];
guess_min = [1.5    10     0];

optvar=optimset('lsqnonlin');
optvar.TolFun=1e-10;
optvar.TolX=1e-10;
optvar.MaxIter=600;
optvar.Display='off'; 



for pix=1: size(FAIR_data, 2)
    
    if Mot(pix)> threshold
        signal = FAIR_data(:,pix);

        % both TI ans signal must have the same dimensions (row vectors)
        guess = lsqnonlin('FAIR_lsq',...
            guess0, guess_min, guess_max, ...
            optvar,...
            TI,...
            alpha, T1b, ...
            signal');
        
        Tau (pix)= guess(1);
        Mob_f(pix) = guess(2);
        dt(pix) = guess(3);    

        if verbose==1
            
            fprintf('\n pix = %d  Tau= %f  Mob*f= %f   dt= %f', pix, Tau(pix), Mob_f(pix), dt(pix));

            tmp= FAIR_lsq( guess , ...
                [0:0.2:10], ...
                alpha,  T1b);
% keyboard
            plot(TI,signal,'*',[0:0.2:10],tmp);
         
            drawnow
        end

   else
      Mob_f (pix)= 0;
      dt(pix) = 0;    
      Tau(pix) = 0;
      
   end
   
end


    figure
    subplot(221) , imagesc(reshape(Mob_f,64,64)), title('perfusion');
    subplot(222) , imagesc(reshape(Tau,64,64)), title('bolus width');
    subplot(223) , imagesc(reshape(dt,64,64)), title ('Arrival Time');
    
Mob_f_data = Mob_f ;
dt_data = dt*scaleFactor;
Tau_data = Tau*scaleFactor;


write_img_data('Mob_f.img',Mob_f_data,h);
write_hdr('Mob_f.hdr',h);


write_img_data('dt.img', dt_data , h);
write_hdr('dt.hdr',h);

write_img_data('Tau.img', Tau_data,h);
write_hdr('Tau.hdr',h);

disp('Finished flow maps')

return
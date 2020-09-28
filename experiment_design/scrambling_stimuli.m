%% Based on scrambling program written by Pierre Ahad in MCL
%% by Pascal Belin, 28 february 2006
%% this program scambles sounds which names are listed in the text file
%% "wav.txt"
%% the critical parameter is the size of the fft (line 17)
%% MUST be a multiple of 2.
%% the resulting sounds (SCR...) are cut to length equal to mutliples of
%% the half-window
%% Modified by WS to create scrambled stimuli for the CP00 study at ILCB, 2019-12-17
clear
fid = fopen('wav4scrambling.txt');
nsons=0;
while ~feof(fid)
    fgetl(fid);
    nsons=nsons+1;
end
fclose(fid);
SIZE=1024;  % size of fft window
inc=SIZE/2; % increment=1/2 fenetre
fid = fopen('wav4scrambling.txt');
for i=1:nsons
  nom_fichier_wav = fgetl(fid);       % Lire le nom d'un fichier .wav
  disp(nom_fichier_wav);            % Afficher du nom du fichier
  [son,FS]= audioread(nom_fichier_wav);    % Lire le .wav
  npoints=size(son,1);
  L=npoints-mod(npoints,inc);   % on reduit le son a un multiple de la 1/2 fenetre
  D=zeros(L,1);     % son "SCRAMBLED"
  start=1;stop=1;
  
  while start<L-1
      stop=stop+inc;
      vec=son(start:stop-1);
      ivec=fft(vec);
       perm=randperm(inc);
        for j=1:inc
            ivecperm(j)=ivec(perm(j));
        end
      invvec=ifft(ivecperm);
      D(start:stop-1)=invvec;
      start=start+inc;
  end

  audiowrite(fullfile('scrambled',[nom_fichier_wav(1:end-4),'.wav']),real(D),FS);
  
end
fclose(fid);

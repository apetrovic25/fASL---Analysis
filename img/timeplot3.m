function tdata = timeplot3(path, file,x,y,z)

% function result = timeplot3(path,file,x,y,z)
%
% Returns the intensity of the voxels in the point determined
%
% the data comes back as a row vector
%
    oldpath=pwd;
    cd (path);
    
    sz = size(file);
    root = file(1,1:sz(2)-8);
    
    files = dir(strcat(root,'*.img'));
    if (size(files)==[0 1])
        tdata=0;
        fprintf('%s-----images not found',file);
        return;
    end
    
    hfiles = dir(strcat(root,'*.hdr'));
    sz = size(files);
	hfiles(1).name;
	hdr = read_hdr(hfiles(1).name);
	
    
    position= z*(hdr.xdim*hdr.ydim) + y*hdr.xdim + x-1;
 
	% extract data from files
	tdata = zeros(1,sz(1));

	for i=1:sz(1)

		[fp mesg]= fopen(files(i).name);
      	%	disp(i)
		%disp  ( files(i).name)

		if fp == -1
			disp(mesg);
			return
		end
	   
      
  		switch hdr.datatype     
      		case 0
            		fmt = 'int8';
            		bytes = 1;

        	case 2
            		fmt = 'uint8';
            		bytes = 1;
        	case 4
            		fmt = 'short';
            		bytes = 2;
        	case 8
            		fmt = 'int';
            		bytes = 2;
        	case 16
            		fmt = 'float';
            		bytes = 4;
        	case 32
            		fmt = 'float';
            		xdim = hdr.xdim * 2;
            		ydim = hdr.ydim * 2;
            		bytes = 8;
      
        	otherwise
            		errormesg(sprintf('Data Type %d Unsupported. Aborting',hdr.bits));
            		return
            
  		end

		% average the ROI positions
		fseek(fp,position*bytes,'bof');     
		tdata(i) = fread(fp,1,fmt);
	  	fclose(fp);
	end

    cd(oldpath);
	%close
	
	
	%plot(tdata/max(tdata))  
	%save timeseries tdata  
	
	return
			





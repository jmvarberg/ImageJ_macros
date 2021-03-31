//macro for processing GFP/mCh timelapse datasets, allowing user to add ROIs, then crop, multichannel register, and save out Sum and Max projection files.

//open images and add ROIs for cells of interest. Crop and project, save output files
dir=getDirectory("Choose Input Directory");

maxdir=dir+"MaxPrj/";
if(!File.exists(maxdir))
	File.makeDirectory(maxdir);
sumdir=dir+"SumPrj/";
if(!File.exists(sumdir))
	File.makeDirectory(sumdir);

stackdir=dir+"Stacks/";
if(!File.exists(stackdir))
	File.makeDirectory(stackdir);
filelist = getFileList(dir); 
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".nd2")) { 
        //open(dir + filelist[i]);
        run("Bio-Formats Importer", "open=["+dir+filelist[i]+ "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack"); //open in virtual space to save memory
        orig=getTitle();
        run("Maximize");
        setSlice(23); //arbitrary, can change
        dupname=substring(orig,0,lengthOf(orig)-4);
        Stack.setDisplayMode("composite"); //set up channel LUTs and B/C defaults.
        waitForUser("Select TL channel.");
        run("Grays");
        run("Enhance Contrast", "saturated=0.35");
        waitForUser("Select GFP Channel");
        run("Yellow");
        run("Enhance Contrast", "saturated=0.35");
        waitForUser("Select mCh Channel");
        run("Magenta");
        run("Enhance Contrast", "saturated=0.35");
        roiManager("Show All with labels");
        waitForUser("Define ROIS", "Add ROIs for dividing cells and click to continue"); //User add ROIs to crop for registration
        roiManager("save", dir+dupname+"_ROISet.zip");
        rois=roiManager("count");
        for (j = 0; j < rois; j++) {
        	roiManager("Select", j);
        	run("Duplicate...", "duplicate");
        	save(stackdir+dupname+"_FOV_"+(j+1)+".tif");
        	rename("Dup");
        	run("Z Project...", "projection=[Max Intensity] all");
        	rename(dupname+"_MaxPrj_FOV_"+(j+1));
        	max=getTitle();
        	//print("MaxPrj Title: " + max);
        	save(maxdir+max+".tif");
        	run("multichannel stackreg", "transformation=[Rigid Body] temp=/tmp/");
        	//waitForUser("Click to continue once registration is complete");
        	maxreg=getTitle();
        	//print("MaxReg Title: "+ maxreg);
        	rename(max);
        	save(maxdir+max+"_stackreg.tif");
        	selectWindow("Dup");
        	run("Z Project...", "projection=[Sum Slices] all");
        	rename(dupname+"_SumPrj_FOV_"+(j+1));
        	sum=getTitle();
        	save(sumdir+sum+".tif");
			run("multichannel stackreg", "transformation=[Rigid Body] temp=/tmp/");
			//waitForUser("Click to continue once registration is complete");
			rename(sum);
			save(sumdir+sum+"_stackreg.tif");
        	close(max);
        	close(sum);
        	close("Dup");
        }
        close(orig);
        roiManager("reset");
        } 

    
}



//macro for processing yeast NE FRAP experiments where part of NE is bleached. 

#@ File (label="Input Directory", style="directory") directory 
#@ File (label="Output Directory", style="directory") out 
#@ Integer (label="Number pre-bleach images", value=5) pre
#@ String (label="File Suffix", value=".tif") strip
#@ boolean (label="Nuclei Already Cropped?") checkbox

roidir = out+File.separator+"ROIs/";
if (!File.exists(roidir)) {
	File.makeDirectory(roidir);
}
nucdir = out+File.separator+"FRAP_cropped_nuclei_out/";
if (!File.exists(nucdir)) {
	File.makeDirectory(nucdir);
}

measdir = out+File.separator+"Measurements/";
if (!File.exists(measdir)) {
	File.makeDirectory(measdir);
}

ctrldir = out+File.separator+"Control_cropped_nuclei_out/";
if (!File.exists(ctrldir)) {
	File.makeDirectory(ctrldir);
}

//clear any open images, existing ROIs or Results
run("Close All");
roiManager("reset");
Table.reset("Results");

if(checkbox == 0) {

//open up images in directory, have user set ROIs for nuclei of interest.

filelist = getFileList(directory); 
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".tiff")) { 
        open(directory + File.separator + filelist[i]);
        orig=getTitle();
        dupname=substring(orig,0,indexOf(orig, strip));
        run("Maximize"); //open image this size at this location
        waitForUser("Select slice and channel to analyze");
        Stack.getPosition(channel, slice, frame);
        print(channel, slice, frame);
        ch=channel;
        sl=slice;
        run("Duplicate...", "duplicate channels="+ch+" slices="+sl); //duplicate out channel of interest
        rename("Dup1");
        run("Subtract Background...", "rolling=15 stack");
        rename("Subtracted");
        run("Maximize");
        run("Enhance Contrast", "saturated=0.35");
        makeRectangle(10, 10, 50, 50);
        roiManager("Show All");

		//have user pick nuclei that were not bleached to measure for signal loss due to photobleaching.
		selectWindow("Subtracted");
		waitForUser("Add ROIs for control nuclei to be cropped for photobleaching measurement.");
		roiManager("save", roidir+dupname+"_control_nuclei.zip");
		cnt = roiManager("count");
		for(k=0; k < cnt; k++){
			roiManager("select", k);
			run("Duplicate...", "duplicate channels="+ch); //duplicate out channel of interest
	    	rename("Dup");
	    	run("StackReg", "transformation=[Rigid Body]"); //stack register to fix for movements of nuclei over timelapse
	    	rename("Reg");
	    	run("Maximize");
	    	run("Enhance Contrast", "saturated=0.35");
	    	saveAs("Tiff...", ctrldir+dupname+"_control_nucleus_"+(k+1)+"_bgsub_cropped_registered.tif");
	    	final=getTitle();
	    	close(final);
	    	close("Reg");
	    	close("Dup");
	    	selectWindow("Subtracted");
		}
	    roiManager("reset");

        //user add ROIs for FRAP'd nuclei
        selectWindow("Subtracted");
        waitForUser("Select ROIs of nuclei to be cropped for FRAP Analysis.");
        cnt=roiManager("count");
        run("Set Measurements...", "integrated redirect=None decimal=2");

		//if ROIs were added, then loop through and crop them out. Save to nucdir 
		if(cnt > 0) {
			roiManager("save", roidir+dupname+"_FRAP_nuclei_rois.zip");
			//duplicate out nuclei and have user add ROIs for measured regions
	        for (j=0; j < cnt; j++) {
	        	roiManager("select", j);
	        	run("Duplicate...", "duplicate channels="+ch); //duplicate out channel of interest
	        	rename("Dup");
	        	run("StackReg", "transformation=[Rigid Body]"); //stack register to fix for movements of nuclei over timelapse
	        	rename("Reg");
	        	run("Maximize");
	        	run("Enhance Contrast", "saturated=0.35");
	        	saveAs("Tiff...", nucdir+dupname+"_FRAP_nucleus_"+(j+1)+"_bgsub_cropped_registered.tif");
	        	close();
	        	close("Reg");
	        	close("Dup");
	        	selectWindow("Subtracted");
	        }
	        roiManager("reset");
	        close(orig);
	        close("Subtracted");
		}
		else {
			close();
		}
    }
}
}
//now, open each saved cropped, stack registered nucleus. Make FRAP intensity measurements

//first, open control nuclei and measure whole nucleus to get bleaching values
roiManager("reset");
clist=getFileList(ctrldir);
for(l=0; l < clist.length; l++) {
	if (endsWith(clist[l], ".tif")) {
	open(ctrldir + clist[l]);
	orig=getTitle();
	dupname=substring(orig,0,indexOf(orig, strip));
	checkout=ctrldir+dupname+"_photobleach_ROI.roi";
	if(File.exists(checkout)){
		print("Already analyzed "+orig);
		close(orig);
		continue
	}
	else {
	run("Maximize"); //open image this size at this location
	setTool("freehand"); 
	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	setMinAndMax("0.00", max/2);
	waitForUser("Add ROI for whole NE to measure photobleaching");
	tc=roiManager("count");
	if(tc==0){
		roiManager("add");
	}
    roiManager("save", ctrldir+dupname+"_photobleach_ROI.roi");
	roiManager("Select", 0);
	run("create spectrum jru v1", "spectrum=Avg");
	run("export plot jru v1", "save=["+ctrldir+dupname+"_avg_spectrum.pw2]"); close();
	roiManager("reset");
	close(orig);
		}
	}
}

//now open FRAP nuclei images, add ROIs and make spectra for each
nucfiles = getFileList(nucdir);
for (i = 0; i < lengthOf(nucfiles); i++) {
    if (endsWith(nucfiles[i], ".tif")) { 
        open(nucdir + nucfiles[i]);
        orig=getTitle();
    	dupname=substring(orig,0,indexOf(orig, strip));
    	checkout=measdir+dupname+"_FRAP_ROIs.zip";
    	if(File.exists(checkout)) {
    		print("Already analyzed "+orig);
    		close(orig);
    		continue
    	}
    	else{
        run("Maximize"); //open image this size at this location
        setTool("freehand");
		Stack.getStatistics(voxelCount, mean, min, max, stdDev);
		setMinAndMax("0.00", max/2);

        //add ROIs for FRAP analysis
        roiManager("reset");
        waitForUser("Add FRAP ROIs: 1) Whole NE; 2) Bleached Region; 3) Unbleached Region");
    	test=roiManager("count");
    		if(test != 3) {
    			waitForUser("Try Again. Add FRAP ROIs: 1) Whole NE; 2) Bleached Region; 3) Unbleached Region");
    			}
    	roiManager("save", measdir+dupname+"_FRAP_ROIs.zip");
    	selectWindow(orig);
    	roiManager("deselect");
    	roiManager("Multi Measure"); //measure each ROI through the timelapse

		//now, loop through Results table, correct bleached region for amount bleached, save out results csv table

		whole = Table.getColumn("IntDen1");
		bleached = Table.getColumn("IntDen2");
		unbleached = Table.getColumn("IntDen3");
		drop1 = whole[pre-1]; //measure Whole region pre bleach
		drop2 = whole[pre]; //measure Whole region post bleach
		drop =drop2/drop1; //calculate percentage of NE bleached as fraction Whole intensity after bleach 
		bleachCor = newArray(whole.length); //make new array to hold bleached region measurements corrected for fraction of NE bleached
		for (k=0; k<whole.length; k++) {
			bleachCor[k] = bleached[k]/drop;
		}
		Table.deleteColumn("RawIntDen1");
		Table.deleteColumn("RawIntDen2");
		Table.deleteColumn("RawIntDen3");
		Table.renameColumn("IntDen1", "Whole");
		Table.renameColumn("IntDen2", "Bleached");
		Table.renameColumn("IntDen3", "Unbleached");
		Table.setColumn("BleachedCorrected", bleachCor);
		Table.save(measdir+dupname+"_FRAP_Measurements.csv");
		Table.reset("Results");

		//save out spectra
		selectWindow(orig);
		roiManager("Select", 0);
		run("create spectrum jru v1", "spectrum=Avg");
		run("export plot jru v1", "save=["+measdir+dupname+"_avg_spectrum_whole.pw2]"); close();

		roiManager("Select", 1);
		run("create spectrum jru v1", "spectrum=Avg");
		run("export plot jru v1", "save=["+measdir+dupname+"_avg_spectrum_bleached.pw2]"); close();

		roiManager("Select", 2);
		run("create spectrum jru v1", "spectrum=Avg");
		run("export plot jru v1", "save=["+measdir+dupname+"_avg_spectrum_unbleached.pw2]"); close();
    
		//generate kymograph

		selectWindow(orig);
		run("Maximize");
		setTool("polyline");
		run("Line Width...", "line=5");
		waitForUser("Add polyline tracing the NE, starting opposite middle of bleached region");
		run("polyline kymograph jru v1", "profile_width=5 positioning=Centered");
		saveAs("Tiff...", measdir+dupname+"_FRAP_kymograph.tif");
    	}
      }
	}
	
	run("Close All");
	roiManager("Reset"); 



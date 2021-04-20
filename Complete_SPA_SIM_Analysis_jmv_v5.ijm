//Part I - setting up channels and defining ROIs centered on SPBs to be used for SPA-SIM analysis. Run on folder containing SIR_ALX.dv and SIR_ALX_PRJ.dv files.
//Choose input/output directories and generate output folders
roiManager("reset");
indir=getDirectory("Choose Input Directory");
output=getDirectory("Choose Output Directory");
outdir=output+"SPA_SIM_Output/";
if(!File.exists(outdir))
	File.makeDirectory(outdir);
roidir=outdir+"Nucleus_ROIs/";
if(!File.exists(roidir))
	File.makeDirectory(roidir);
nucdir=outdir+"Cropped_Nuclei/";
if(!File.exists(nucdir))
	File.makeDirectory(nucdir);

//Make arrays for PRJ and SIR_ALX files to be used for cropping nuclei
prj_files=newArray(0);
list=getFileList(indir);
for(i=0; i<list.length; i++){
	if(endsWith(list[i], "PRJ.dv")){
		prj_files=Array.concat(prj_files,list[i]);
	}
}
Array.sort(prj_files);

//Open up one image and have user define which channel is SPB channel and which is Other channel.
run("Bio-Formats Importer", "open=["+ indir + prj_files[0]+"]");
exptitle=getTitle();
expnewtitle=substring(exptitle,0,indexOf(exptitle,"_visit")-3);
waitForUser("Select SPB Channel", "Choose SPB Channel, click OK to proceed.");
Stack.getPosition(channel, slice, frame);
SPBChannel = channel;
waitForUser("Select Other Channel", "Choose Other Channel, click OK to proceed.");
Stack.getPosition(channel, slice, frame);
otherChannel = channel;
if (SPBChannel == otherChannel) {
	Dialog.create("Channels cannot be the same. Try again.");
	Dialog.show();
	waitForUser("Select SPB Channel", "Choose SPB Channel, click OK to proceed.");
	Stack.getPosition(channel, slice, frame);
	SPBChannel = channel;
	waitForUser("Select Other Channel", "Choose Other Channel, click OK to proceed.");
	Stack.getPosition(channel, slice, frame);
	otherChannel = channel;	
}

Dialog.create("Channel LUTs Setup");
Dialog.addChoice("SPB Channel:", newArray("Magenta", "Red", "Green", "Yellow", "Cyan", "Blue"));
Dialog.addChoice("Other Channel:", newArray("Magenta", "Red", "Green", "Yellow", "Cyan", "Blue"));
Dialog.show();
SPBcolor = Dialog.getChoice();
Othercolor = Dialog.getChoice();;

close();


zfiles=newArray(0);
list=getFileList(indir);
for(i=0; i<list.length; i++) {
	if(endsWith(list[i], "SIR_ALX.dv")){
		zfiles=Array.concat(zfiles,list[i]);
	}
}
Array.sort(zfiles);
start=getTime();
setBatchMode(false);
//Loop through all pairs in arrays, opening PRJ, thresholding nuclei, saving ROIs and using to crop nuclei in SIR Z-stack images
count=lengthOf(zfiles);
setTool("rectangle");
roiManager("show all with labels");
print("Number of SIM Images Analyzed:  "+count);
	for(i=0; i<count; i++){
		run("Bio-Formats Importer", "open=["+ indir + prj_files[i]+"]");
		orig=getTitle();
		run("Maximize");
		SetUp(orig);
		duporig=substring(orig,0,lengthOf(orig)-3);
		waitForUser("Add Nucleus ROIs to be cropped");
		cnt = roiManager("count");
		if (cnt==0) {
			run("Close All");
			roiManager("reset");
		}	
		else {
			roiManager("Save", roidir+duporig+"_ROISet.zip");
			run("Bio-Formats Importer", "open=["+ indir + zfiles[i]+"]");
			zname=getTitle();
			close(orig);
			selectWindow(zname);
			for (j=0; j<cnt; j++) { 
				roiManager("select", j);
				run("Duplicate...", "duplicate ");
				dup= getTitle();
				//print("duplicated stack: " + dup);
				dupname=substring(dup,0,lengthOf(dup)-5) + "_nuc";
				//print("New name: " + dupname);
				selectWindow(dup);
				save(nucdir+dupname+(j+1)+".tif");
				close();
			}
		roiManager("reset");
		run("Close All");
		}
	}

function SetUp(image) { 
// Set up channels for SPA-SIM images for cropping nuclei. Fix with if statements to address changes in stack order/channel order
Stack.setDisplayMode("composite");
Stack.setActiveChannels("11");
Stack.setChannel(SPBChannel);
run(SPBcolor);
run("Enhance Contrast", "saturated=0.05");
Stack.setChannel(otherChannel);
run(Othercolor);
run("Enhance Contrast", "saturated=0.25");
Stack.setDisplayMode("composite");
if(SPBChannel == 2) {
Stack.setActiveChannels("01");
Stack.setChannel(2);
}	else {
		Stack.setActiveChannels("10");
		Stack.setChannel(1);
	}
makeRectangle(481, 177, 80, 80);
}

//Part II: Open the cropped nuclei, find the brightest spot in the SPB channel, and have user add SPB point ROIs. 
//Saves as overlay to original image.

files = getFileList(nucdir);
print("Number of cropped nuclei: "+files.length);
for (k = 0; k < files.length; k++) {
	if(!endsWith(files[k], ".tif")) continue;
	open(nucdir+files[k]);
	if(Overlay.size > 0) { //this is to skip files that already have ROIs added. Was useful for reanalyzing data but could be removed from this macro.
		close();
	} else {
	run("Maximize");
	Stack.setChannel(SPBChannel);
	brightestMean = 0;
	brightestSlice = 1;
	for(l=1; l<nSlices; l++) {
		setSlice(l);
		Stack.setChannel(SPBChannel);
		getStatistics(area, mean);
		if(brightestMean<mean) {
			brightestMean = mean;
			brightestSlice = l;
		}
	}
	setSlice(brightestSlice);
	Stack.setChannel(SPBChannel);
	run("Enhance Contrast", "saturated=0.15");
	setTool("point");
	roiManager("reset");
	waitForUser("Add SPB ROIs to ROI Manager and click OK to proceed");
	roiManager("Show All");
	run("Save");
	close();
	roiManager("reset");
	}
}
run("Close All");

//Part III: Eusclidean Distance Transformation used to select nuclei where the SPBs are at least 400 nm away from the edge of the nucleus.
//The good nuclei are saved into their own subfolder for downstream analysis.

waitForUser("Next, you have option of filtering to select for SPB spots that are a set distance from the edge of the nuclear envelope.\nThis will only work for GFP proteins that localize throughout entire NE.\nCheck side-view to select for SPBs on side of NE (<100nm from NE edge). Defaults to Top Down view of SPB for SPBs in center (>400nm from edge of NE).\nLeave unchecked to skip this filtering step.");
distance=400;
Dialog.create("Euclidean Distance Filter");
Dialog.addNumber("Distance Cutoff (nm):", 400);
Dialog.addCheckbox("Perform EDT Filter Step", true);
Dialog.addCheckbox("SPB Side View", false);
Dialog.show();
distance = Dialog.getNumber();
filter = Dialog.getCheckbox();
sideview = Dialog.getCheckbox();;

if(filter==false) {
	print("Euclidean Distance Transformation Filter bypassed");
	continue;
} 

else { 
	list = getFileList(nucdir);
	output = nucdir+"/good_output_EDT/";
	File.makeDirectory(output);

	for (i = 0; i < list.length; i++) {
		if(!endsWith(list[i],".tif")) continue;
		open(nucdir+list[i]);
		orig = getTitle();
		if(Overlay.size!=2) continue;
		run("Duplicate...", "duplicate channels="+otherChannel);
		rename("DupNup");
		run("Z Project...", "projection=[Max Intensity]");
		run("Gaussian Blur...", "sigma=2");
		setAutoThreshold("Triangle dark");
		run("Convert to Mask");
		roiManager("reset");
		run("Analyze Particles...", "size=2-Infinity add");
		ct=roiManager("count");
		if (ct!=1) continue;
		roiManager("Select", 0);
		run("Exact Euclidean Distance Transform (3D)");
		roiManager("reset");
		selectWindow(orig);
		run("To ROI Manager");
		selectWindow("EDT");
		run("Set Measurements...", "mean redirect=None decimal=2");
		roiManager("multi-measure measure_all append");
		close("EDT");
		close("DupC2");
		close("MAX_DupC2");
		spb1 = getResult("Mean", 0);
		//print("SPB1 Distance: "+spb1);
		spb2 = getResult("Mean", 1);
		//print("SPB2 Distance: "+spb2);
		if(sideview==false) {
			if(spb1 >= distance/40 && spb2 >= distance/40) {
				print(orig+",Pass,"+spb1+","+spb2);
				selectWindow(orig);
				save(output+orig);
				close();
			}
			else {
				print(orig+",Fail,"+spb1+","+spb2);
				close();
			}
		}
		if(sideview) {
			if(spb1 <= distance/40 && spb2 <= distance/40) {
				print(orig+",Pass,"+spb1+","+spb2);
				selectWindow(orig);
				save(output+orig);
				close();
			}
			else {
				print(orig+",Fail,"+spb1+","+spb2);
				close();
			}
			
		}
		if (isOpen("Results")) { 
	         selectWindow("Results"); 
	         run("Close"); 
	    } 
		run("Close All");
	}
	selectWindow("Log");
	saveAs("Text...", output+expnewtitle+"_SPA_SIM_EDT_Filtering_Results_Log.txt");
	run("Close");
	roiManager("reset");
}


//Part IV: SPA-SIM Realignment. Run this on folder of EDT filtered nuclei. Will use pre-existing ROIs for spbs to realign and filter to keep only
//realignments that are between 16 and 30 pixels tall.

//run("From ROI Manager");
waitForUser("Now you'll perform SPA-SIM realignment of images. There is a built in filter to separate good and bad realignments based on dimensions of realigned images.\nImages between 16 and 30 pixels in Y-axis are kept as good realignments."); 
good_out = nucdir+"/good_realignments/";
File.makeDirectory(good_out);
bad_out = nucdir+"/bad_realignments/";
File.makeDirectory(bad_out);


function removeExtension(fname){
	var dotpos=lastIndexOf(fname,".");
	if(dotpos<0) return fname;
	else return substring(fname,0,dotpos);
}

if(filter==false){
	realigndir=nucdir;
} else {
	realigndir=output;
}

print(realigndir);
list=newArray(0);
flist=getFileList(realigndir);
for(i=0; i<flist.length; i++) {
	if(endsWith(flist[i], ".tif")){
		list=Array.concat(list, flist[i]);
	}
}

if(list.length < 1) {
	print("No images passed EDT filtering. Please repeat and adjust filtering parameters.");
	continue;
}
	else{
		open(realigndir+list[0]);
		exptitle=getTitle();
		expnewtitle=substring(exptitle,0,indexOf(exptitle,"_visit")-3);
		close(exptitle);
		
		for (i = 0; i < list.length; i++) {
			if(!endsWith(list[i],".tif")) continue;
			open(realigndir+list[i]);
			if(Overlay.size!=2) continue;
			run("To ROI Manager");
			ct=roiManager("count");
			print(ct);
			if (ct!=2) continue;
			fitch=SPBChannel; //the spb channel
			otherch=otherChannel; //the npc channel
			thickness=40; //width of the reconstructed image
			roiManager("Show All");
			//saveAs("Tiff");
			orig=getTitle();
			run("Duplicate...", "title=otherchan duplicate channels="+otherch);
			selectWindow(orig);
			run("Duplicate...", "title=fitchan duplicate channels="+fitch);
			selectWindow(orig); close();
			profname=removeExtension(orig);
			profname=profname+"_realigned.tif";
			selectWindow("fitchan");
			rename(profname);
			run("fit 3D multi gaussian jru v1", "z_ratio=3.12383 xy_stdev=0.95000 z_stdev=1.20000 calibrate? show");
			selectWindow(profname); rename("fitchan");
			run("thick 3D polyline profile jru v1", "3d=[MultiGaus Plot] z=[fitchan] thickness="+thickness+" z_ratio=3.12383 end=1.5 straighten single");
			rename("C"+fitch+"_realigned");
			run("thick 3D polyline profile jru v1", "3d=[MultiGaus Plot] z=[otherchan] thickness="+thickness+" z_ratio=3.12383 end=1.5 straighten single");
			rename("C"+otherch+"_realigned");
			run("Merge Channels...", "c1=[C1_realigned] c2=[C2_realigned] create");
			wait(200);
			selectWindow("Composite");
			rename(profname);
			Stack.getDimensions(width, height, channels, slices, frames);
			print(height);
			if(height <= 16 || height > 30){
				saveAs("Tiff...", bad_out+profname);
				run("Close All");
				roiManager("reset");
				}
			else {
				saveAs("Tiff...", good_out+profname);
				roiManager("reset");
				selectWindow("otherchan"); close();
				selectWindow("fitchan"); close();
				selectWindow("MultiGaus Plot"); close();
				selectWindow("Avg Projections"); close();
				selectWindow("Z Profiles"); close();
				selectWindow("fit");
				run("autoscale hyperstack jru v1"); close();
				selectWindow(profname); close();
				if (isOpen("Log")) { 
		         	selectWindow("Log"); 
		         	run("Close"); 
		    		} 
				}
				wait(400);
		}
	}

run("Close All");

//Part V: Combining good realignments and generating merged stack, averaged image and mirrored average image.

list=getFileList(good_out);
if(list.length < 1) {
	print("No images found in directory.");
	continue;
}
else {
	for (i = 0; i < list.length; i++) {
		open(good_out + list[i]);
	}
	run("merge all stacks jru v1");
	N=nSlices/2;
	Stack.setChannel(otherChannel);
	run(Othercolor);
	Stack.setChannel(SPBChannel);
	run(SPBcolor);
	saveAs("Tiff...", outdir+expnewtitle+"_n="+N+"_good_realignments_merged.tif");
	merged=getTitle();
	run("stack statistics jru v2", "statistic=Avg");
	saveAs("Tiff...", outdir+expnewtitle+"_n="+N+"_good_realignments_merged_avg.tif");
	Dialog.create("Mirror Image");
	Dialog.addCheckbox("Generate Mirrored Average Image?", true);
	Dialog.show();
	mirror = Dialog.getCheckbox();
	if(mirror==false) {
		continue;
	} 
	else {
		orig=getTitle();
		run("Duplicate...", "duplicate");
		dupname=getTitle();
		run("Flip Horizontally", "stack");
		imageCalculator("Average create stack", orig,dupname);
		saveAs("Tiff...", outdir+expnewtitle+"_n="+N+"_good_realignments_merged_avg_mirrored.tif");
		mirrored=getTitle();
		close(orig);
		close(dupname);
		close(merged);
		close(mirrored);
	}
}

//Measure Daughter/Mother SPB ratios, save out cell-cycle substacks for image and plot generation.
roiManager("reset");
DMratioout = outdir+"DMratios/";
File.makeDirectory(DMratioout);

open(outdir+merged);
setTool("rectangle");
orig = getTitle();
dupname=substring(orig,0,lengthOf(orig)-4);
//roiManager("Save", DMratioout+dupname+"_SPB_ROIs.zip");
run("Duplicate...", "duplicate channels="+SPBChannel);
rename("SPB Channel");
run("Maximize");
spbC1 = getTitle();
count = nSlices;
print("Number Slices: "+count);
waitForUser("Make 6x6 pixel ROIs for Mother and Daughter SPBs, click to continue.");
run("Set Measurements...", "mean redirect=None decimal=2");
selectWindow(spbC1);
roiManager("Multi Measure");
saveAs("Results", DMratioout+dupname+"_ROI_Mean_Intensities.csv");
G2M=newArray(0);
G1S=newArray(0);
G2=newArray(0);
for	(i=1; i < count+1; i++) {
	selectWindow(spbC1);
	spb1 = getResult("Mean1", (i-1));
	//print("SPB1 mean: "+spb1);
	spb2 = getResult("Mean2", (i-1));
	//print("SPB2 mean: "+spb2);
	dmRatio = spb2/spb1;
	//print("D/M Ratio: "+dmRatio);
	if(dmRatio >= 0.8) {
		G2M=Array.concat(G2M,i);
	}
	if(dmRatio <= 0.5) {
		G1S=Array.concat(G1S,i);
	}
	if(dmRatio > 0.5 && dmRatio < 0.8) {
		G2=Array.concat(G2,i);
	}
}
print("Number Images with DM Ratio over 0.8 (G2M): "+G2M.length);
Array.print(G2M);
print("Number Images with DM Ratio under 0.5 (G1S): "+ G1S.length);
Array.print(G1S);
print("Number Images with DM Ratio between 0.5 and 0.8 (G2): "+ G2.length);
Array.print(G2);
selectWindow("Log");
saveAs("Text...", DMratioout+dupname+"_DMRatios_Results.txt"); close();
close(spbC1);
close(orig);

G2Mstr = String.join(G2M, ",");
G1Sstr = String.join(G1S, ",");
G2str = String.join(G2, ",");

//open the merged image and generate substacks for cell cycle stages
open(outdir+merged);
N=nSlices/2;
saveAs("Tiff...", DMratioout+expnewtitle+"_n="+N+"_all_stages_merged.tif");
run("stack statistics jru v2", "statistic=Avg"); 
saveAs("Tiff...", DMratioout+expnewtitle+"_n="+N+"_all_stages_merged_avg.tif"); close();
Dialog.create("Cell Cycle Stage Selections");
Dialog.addCheckbox("G1S (D/M ratio < 0.5):", true);
Dialog.addCheckbox("G2 (D/M ratio between 0.5 and 0.8):", true);
Dialog.addCheckbox("G2M (D/M ratio > 0.8):", true);
Dialog.show();
g1s=Dialog.getCheckbox();
g2=Dialog.getCheckbox();;
g2m=Dialog.getCheckbox();;;

if (g1s==true && G1S.length > 0) {
	run("Make Substack...", "channels=1-2 frames="+G1Sstr);
	N=nSlices/2;
	saveAs("Tiff...", DMratioout+expnewtitle+"_n="+N+"_G1S_merged.tif"); 
	run("stack statistics jru v2", "statistic=Avg"); 
	saveAs("Tiff...", DMratioout+expnewtitle+"_n="+N+"_G1S_merged_avg.tif"); close();
	close();
	}
if (g2==true && G2.length > 0) {
	run("Make Substack...", "channels=1-2 frames="+G2str);
	N=nSlices/2;
	saveAs("Tiff...", DMratioout+expnewtitle+"_n="+N+"_G2_merged.tif"); 
	run("stack statistics jru v2", "statistic=Avg"); 
	saveAs("Tiff...", DMratioout+expnewtitle+"_n="+N+"_G2_merged_avg.tif"); close();
	close();
	}
if (g2m==true && G2M.length > 0) {
	run("Make Substack...", "channels=1-2 frames="+G2Mstr);
	N=nSlices/2;
	saveAs("Tiff...", DMratioout+expnewtitle+"_n="+N+"_G2M_merged.tif"); 
	run("stack statistics jru v2", "statistic=Avg"); 
	saveAs("Tiff...", DMratioout+expnewtitle+"_n="+N+"_G2M_merged_avg.tif"); close();
	close();
	}

run("Close All");

runMacro("spa_sim_tiffs_plots_batch_jmv.ijm");




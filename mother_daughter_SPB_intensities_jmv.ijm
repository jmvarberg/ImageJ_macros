//macro to analyze mother:daughter SPB ratios from SPA-SIM merged stacks.

#@ File (label="Choose merged stack", style="file") merged
#@ File (label="Choose SPA-SIM Output Directory", style="directory") outdir
#@ String (label = "Filename string for renaming") strip //put in characters immediately following what you want to keep. This and everything following will be stripped from title.


outdir = outdir+"/";

//Measure Daughter/Mother SPB ratios, save out cell-cycle substacks for image and plot generation.
roiManager("reset");
DMratioout = outdir+"/DMratios/";
File.makeDirectory(DMratioout);

open(merged);
setTool("rectangle");
orig = getTitle();
dupname=substring(orig,0,lengthOf(orig)-4);
expnewtitle=substring(orig,0,indexOf(orig,strip));

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

//go back to the merged image and generate substacks for cell cycle stages
open(merged);
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
//Finish SPA-SIM analysis from cropped nuclei with annotated SPB spot ROIs - use for when macro has error or to repeat
//analysis with changing EDT/SPA ratio settings.
#@ File (label="Choose Input directory of cropped nuclei", style="directory") nucdir
#@ File (label="Choose SPA-SIM Output Directory", style="directory") outdir
#@ File (label = "Choose Image for Setup") setupImg
#@ String (label = "Filename string for renaming") strip
#@ Integer (label = "Additional characters to remove", value=0) char

outdir = outdir+"/";
nucdir = nucdir+"/";


//Open up one image and have user define which channel is SPB channel and which is Other channel.
run("Bio-Formats Importer", "open=["+setupImg+"]");
exptitle=getTitle();
expnewtitle=substring(exptitle,0,indexOf(exptitle,strip)-char);
print(expnewtitle);
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
		setBatchMode(true);
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
			wait(500);
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
setBatchMode(false);
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
DMratioout = outdir+"/DMratios/";
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

//don't need Array2string anymore, found String.join function which does this and doesn't have bug of losing last item in array.
function Array2string(array) {
	str="";
	if(array.length == 0) continue;
	else {
		for (i=0; i<array.length-1; i++) 
        	str = str + array[i] + ","; 
     		str = str + array[array.length-1];
     		return str;
	}
}
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
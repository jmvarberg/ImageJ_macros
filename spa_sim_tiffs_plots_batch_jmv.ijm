//Macro to batch process SPA-SIM merged stacks to generate averaged TIFF images and plot profiles for each channel


//generate list of all TIFF stacks to use for TIFFs and plots

//Make arrays for TIFF files in directory containing merged stacks
input = getDirectory("Choose Directory with merged SPA-SIM tiff stacks");

images=newArray(0);
list=getFileList(input);
for(i=0; i<list.length; i++){
	if(endsWith(list[i], "avg.tif")){
		images=Array.concat(images,list[i]);
	}
}
Array.print(images);

open(input + images[0]);
waitForUser("Select SPB Channel", "Choose SPB Channel, click OK to proceed.");
Stack.getPosition(channel, slice, frame);
SPBChannel = channel;
waitForUser("Select Other Channel", "Choose Other Channel, click OK to proceed.");
Stack.getPosition(channel, slice, frame);
otherChannel = channel;
close();

Dialog.create("Channel LUTs Setup");
Dialog.addChoice("SPB Channel:", newArray("Magenta", "Red", "Green", "Yellow", "Cyan", "Blue"));
Dialog.addChoice("Other Channel:", newArray("Magenta", "Red", "Green", "Yellow", "Cyan", "Blue"));
Dialog.show();
SPBcolor = Dialog.getChoice();
Othercolor = Dialog.getChoice();;

Dialog.create("Scale Factor");
Dialog.addNumber("Set scale factor for final images:", 8);
Dialog.show();
scaleBy = Dialog.getNumber();

//Part VI: Make Cropped TIFFs and Plot Profiles for each channel
tifout=input+"TIFF_output/";
File.makeDirectory(tifout);
plotsout=input+"PlotProfiles_output/";
File.makeDirectory(plotsout);

roiManager("reset");
Dialog.create("TIFF and Plot Profiles");
Dialog.addCheckbox("Mirror Images for Line Profiles and Cropped Images", true);
Dialog.show();
mir = Dialog.getCheckbox();
for (i = 0; i < images.length; i++) {
	roiManager("reset");
	open(input+images[i]);
	orig=getTitle();
	if (mir == true) {
		run("Duplicate...", "duplicate");
		dupname=getTitle();
		run("Flip Horizontally", "stack");
		imageCalculator("Average create stack", orig,dupname);
		rename("Original_Mirrored");
		close(orig);
		close(dupname);
	}
	
	dupname=substring(orig,0,lengthOf(orig)-4);
	run("Maximize");
	Stack.getDimensions(width, height, channels, slices, frames);
	midx=width/2;
	midy=height/2;
	print(width, midx, height, midy);
	startx=midx-10;
	starty=midy-10;
	print(startx, starty);
	makeRectangle(startx, starty, 20, 20);
	roiManager("Add");
	//waitForUser("Center ROI over SPB region and hit 'Update' in ROI Manager");
	roiManager("Select", 0);
	run("Duplicate...", "title=cropped duplicate");
	dup=getTitle();
	run("Split Channels");
	selectWindow("C1-cropped");
	makeLine(10, 2, 10, 18);
	Roi.setStrokeWidth(4);
	run("Plot Profile");
	selectWindow("Plot of C1-cropped");
	rawname="Plot of C1 " + dupname + "_north_south_raw.pw2";
	rename(rawname);
	run("export plot jru v1", "save=["+plotsout+rawname+"]");
	selectWindow(rawname);
	run("normalize trajectories jru v1", "normalization=Max");
	plotname="Plot of C1 " + dupname + "_north_south_normalized.pw2";
	run("export plot jru v1", "save=["+plotsout+plotname+"]");
	
	selectWindow("C2-cropped");
	makeLine(10, 2, 10, 18);
	Roi.setStrokeWidth(4);
	run("Plot Profile");
	selectWindow("Plot of C2-cropped");
	rawname2="Plot of C2 " + dupname + "_north_south_raw.pw2";
	rename(rawname2);
	run("export plot jru v1", "save=["+plotsout+rawname2+"]");
	selectWindow(rawname2);
	run("normalize trajectories jru v1", "normalization=Max");
	plotname2="Plot of C2 " + dupname + "_north_south_normalized.pw2";
	run("export plot jru v1", "save=["+plotsout+plotname2+"]");
	
	selectWindow("C1-cropped");
	makeLine(2, 10, 18, 10);
	Roi.setStrokeWidth(10);
	run("Plot Profile");
	selectWindow("Plot of C1-cropped");
	rawname="Plot of C1 " + dupname + "_east_west_raw.pw2";
	rename(rawname);
	run("export plot jru v1", "save=["+plotsout+rawname+"]");
	selectWindow(rawname);
	run("normalize trajectories jru v1", "normalization=Max");
	plotname="Plot of C1 " + dupname + "_east_west_normalized.pw2";
	run("export plot jru v1", "save=["+plotsout+plotname+"]");
	
	selectWindow("C2-cropped");
	makeLine(2, 10, 18, 10);
	Roi.setStrokeWidth(10);
	run("Plot Profile");
	selectWindow("Plot of C2-cropped");
	rawname="Plot of C2 " + dupname + "_east_west_raw.pw2";
	rename(rawname);
	run("export plot jru v1", "save=["+plotsout+rawname+"]");
	selectWindow(rawname);
	run("normalize trajectories jru v1", "normalization=Max");
	plotname="Plot of C2 " + dupname + "_east_west_normalized.pw2";
	run("export plot jru v1", "save=["+plotsout+plotname+"]");
	
	selectWindow("C1-cropped");
	run("Select None");
	rename("C1_" + dupname + "_original.tif");
	name=getTitle();
	saveAs("Tiff", tifout+name);
	run("Enhance Contrast", "saturated=0.35");
	if(SPBChannel==1) {
		run(SPBcolor);
		}
	if(otherChannel==1) {
		run(Othercolor);
		}
	
	run("Scale...", "x="+scaleBy+" y="+scaleBy+" interpolation=Bilinear average create");
	run("RGB Color");
	rename("C1_" + dupname + "_final.tif");
	name=getTitle();
	saveAs("Tiff...", tifout+name);
	
	selectWindow("C2-cropped");
	run("Select None");
	rename("C2_" + dupname + "_original.tif");
	name=getTitle();
	saveAs("Tiff", tifout+name);
	getStatistics(area, mean, min, max, std, histogram);
	maxInt = max;
	thresh = 0.25 * maxInt;
	print("Max: ",maxInt, "Min: ",thresh);
	setMinAndMax(thresh, maxInt);
		if(otherChannel==2) {
		run(Othercolor);
		}
		if(SPBChannel==2) {
		run(SPBcolor);
		}
	run("Scale...", "x="+scaleBy+" y="+scaleBy+" interpolation=Bilinear average create");
	run("RGB Color");
	rename("C2_" + dupname + "_final.tif");
	name=getTitle();
	saveAs("Tiff...", tifout+name);

	if (mir == true) {
		selectWindow("Original_Mirrored");
	} else {
		selectWindow(orig);
	}
	roiManager("Select", 0);
	run("Duplicate...", "title=cropped duplicate");
	run("Scale...", "x="+scaleBy+" y="+scaleBy+" interpolation=Bilinear average create");
	Stack.setChannel(SPBChannel);
	run("Enhance Contrast", "saturated=0.35");
	//getStatistics(area, mean, min, max, std, histogram);
	//maxInt = max;
	//thresh = 0.25 * maxInt;
	//print("Max: ",maxInt, "Min: ",thresh);
	//setMinAndMax(thresh, maxInt);
	run(SPBcolor);
	Stack.setChannel(otherChannel);
	getStatistics(area, mean, min, max, std, histogram);
	maxInt = max;
	thresh = 0.25 * maxInt;
	print("Max: ",maxInt, "Min: ",thresh);
	setMinAndMax(thresh, maxInt);
	run(Othercolor);
	Stack.setDisplayMode("composite");
	Stack.setActiveChannels("11");
	run("RGB Color");
	rename(dupname + "_final_merged.tif");
	name=getTitle();
	saveAs("Tiff", tifout+name);
	close("*");
	close("\\Others");
}

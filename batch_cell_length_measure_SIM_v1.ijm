//Macro to take cell length measurements after manual/semi-automated annotation of all cropped nuclei.
run("Close All");
roiManager("reset");

directory = getDirectory("Choose Input Directory"); //this should be where TL images are

roidir = directory + "Analysis/Nucleus ROIs/"; //this is directory generated from nuclei cropping macro and will always be the same
Rdir = directory + "Analysis/R Analysis/"; // directory to save out Results table for R analysis downstream

tls = newArray(0); //make array to store TL file names and sort
filelist = getFileList(directory); 
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".dv") && indexOf(filelist[i], "_TL") > 0) {
    	tls=Array.concat(tls, filelist[i]);
    } 
}
Array.sort(tls);
print("Number of TL Images: ", lengthOf(tls), tls[0]);

rois = newArray(0); //make array to store ROI set names and sort to match TL images names
roilist = getFileList(roidir);
for (i = 0; i < lengthOf(roilist); i++) {
    if (endsWith(roilist[i], "ROISet.zip")) { 
        rois=Array.concat(rois,roilist[i]);
    } 
}
Array.sort(rois);
print("Number of ROI sets: ", lengthOf(rois), rois[0]);

Labels = newArray(0);
Lengths = newArray(0);
Septal = newArray(0);
//open all TL images and scale 2x since dimensions are 512x512 and SIM images are 1024x1024. Pick slice in focus, add line ROIs for length measurements.
for (i = 0; i < lengthOf(tls); i++) {
	open(directory + tls[i]);
	run("Maximize");
	rename(rois[i]);
	new=getTitle();
	dupname=substring(new,0,lengthOf(new)-10);
	//print(dupname);
	waitForUser("Choose desired focal plane and click to continue");
	run("Duplicate...", "use");
	rename("duporig");
	run("Scale...", "x=2 y=2 z=1.0 width=1024 height=1024 depth=16 interpolation=Bilinear average process create");
	rename("midslice");
	close("duporig");
	close(new);
	open(roidir+rois[i]);
	roiManager("Show All with labels");
	run("Flatten");
	rename(dupname);
	close("midslice");
	roiManager("reset");
	setTool("line");
	run("Maximize");
	waitForUser("Add cell length line ROIs and click to continue");
	count=roiManager("count");
		for(j=0; j<count; j++) {
			roiManager("Select", j);
			roiManager("Rename", "nuc"+(j+1));
		}
	run("Set Measurements...", "display redirect=None decimal=2");
	results=nResults;
	roiManager("Deselect");
	roiManager("Measure");
	//now have pop-up box to let user put in which cells have septum and which are binucleate.
	Dialog.create("Annotate Septated Cells");
	Dialog.addString("Septated: ", "");
	Dialog.addString("Binucleate: ", "");
	Dialog.show();
	sept = Dialog.getString();
	binuc = Dialog.getString();;
	sarray = split(sept, ",");
	narray = split(binuc, ",");
	if(lengthOf(sarray) > 0) {
		for(k=0; k < lengthOf(sarray); k++) {
			setResult("Septated", results+sarray[k]-1, "yes"); // if septated, also binucleate by definition, saves user input/typing
			setResult("Binucleate", results+sarray[k]-1, "yes");
			updateResults();
		}
	}
	if(lengthOf(narray) > 0) {
		for(k=0; k < lengthOf(narray); k++) {
			setResult("Binucleate", results+narray[k]-1, "yes");
			updateResults();
		}
	}
	roiManager("Save", roidir+dupname+"cell_lengths_ROIs.zip"); //save out the line ROIs of cell length measurements for each input image
	roiManager("reset");
	close(dupname);
}

// Clean up Results table and save out to specified diretory

selectWindow("Results");
Table.deleteColumn("Angle");

// want to change "Lable" formatting to make it easier to match name of nucleus images analyzed for NPCs later on in R.
for (i=0; i<nResults; i++) {
	oldLabel = getResultLabel(i);
	newLabel = replace(oldLabel, "\\:", "");
	setResult("Label", i, newLabel);
}

// Interactive window open to allow user to define file name for saving output file.
Dialog.create("Save Output");
Dialog.addString("Output Filename: (YYYYMMDD_Protein-Tag_Background ", "");
Dialog.show();
outname=Dialog.getString();
saveAs("Results",  Rdir + outname+"_cell_cycle_staging.csv");


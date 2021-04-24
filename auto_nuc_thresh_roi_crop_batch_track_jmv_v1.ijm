//setOption("JFileChooser", true);
SIMindir=getDirectory("Choose Input File Directory");
dir=SIMindir+"Analysis/";
if(!File.exists(dir))
	File.makeDirectory(dir);
SIMoutdir=dir+"Nucleus TIFFs/";
if(!File.exists(SIMoutdir))
	File.makeDirectory(SIMoutdir);
SIMroioutdir=dir+"Nucleus ROIs/";
if(!File.exists(SIMroioutdir))
	File.makeDirectory(SIMroioutdir);
trackoutdir=dir+"Batch Track Output/";
if(!File.exists(trackoutdir))
	File.makeDirectory(trackoutdir);

ranalysis=dir+"R Analysis/";
if(!File.exists(ranalysis))
	File.makeDirectory(ranalysis);
xlsout=ranalysis+"data/";
if(!File.exists(xlsout))
	File.makeDirectory(xlsout);

//Make arrays for PRJ and SIR files to be used for cropping nuclei
prj_files=newArray(0);
list=getFileList(SIMindir);
for(i=0; i<list.length; i++){
	if(endsWith(list[i], "PRJ.dv")){
		prj_files=Array.concat(prj_files,list[i]);
	}
}
Array.sort(prj_files);

zfiles=newArray(0);
list=getFileList(SIMindir);
for(i=0; i<list.length; i++) {
	if(endsWith(list[i], "SIR.dv")){
		zfiles=Array.concat(zfiles,list[i]);
	}
}
Array.sort(zfiles);
start=getTime();
setBatchMode(false);
roiManager("reset");

//open up first PRJ image so that user can see channels and specify which channel is Nup if needed.

open(SIMindir+prj_files[0]);
//have user check for one or two channel. if two channel, prompt for which is NPCs
Dialog.create("Channel Setup");
Dialog.addCheckbox("Two Channel?:", false);
Dialog.addNumber("NPC Channel:", 1);
Dialog.show();
channels = Dialog.getCheckbox();
nup = Dialog.getNumber();
close();

//Loop through all pairs in arrays, opening PRJ, thresholding nuclei, saving ROIs and using to crop nuclei in SIR Z-stack images
count=lengthOf(zfiles);
print("Number of Images Analyzed:  "+count);
	for(i=0; i<count; i++){
		run("Bio-Formats Importer", "open=["+ SIMindir + prj_files[i]+"]");
		if (channels==true) {
			Stack.setChannel(nup);
		}
		prjname=getTitle();
		prjdupname=substring(prjname,0,lengthOf(prjname)-7);
		run("Duplicate...", " ");
		duplicatedname=getTitle();
		run("8-bit");
		run("Gaussian Blur...", "sigma=2");
		run("Auto Local Threshold", "method=Phansalkar radius=15 parameter_1=0 parameter_2=0 white");
		run("Options...", "iterations=4 count=1 black do=Nothing");
		//run("Threshold...");
		run("Convert to Mask");
		run("Dilate");
		run("Fill Holes");
		run("Analyze Particles...", "size=1.75-Infinity circularity=0.25-1.00 show=Nothing exclude add");
		selectWindow(prjname);
		run("Enhance Contrast", "saturated=0.35");
		roiManager("Show All with Labels");
		waitForUser("Delete or Add ROIs and click to continue");
		run("Flatten", "slice");
		flatname=getTitle();
		flatdup=substring(flatname,0,lengthOf(flatname)-5);
		save(SIMroioutdir+flatdup+"_flattenedNucROIs.tif");
		close(flatname);
		close(prjname);
		close(duplicatedname);
		run("Bio-Formats Importer", "open=["+SIMindir+zfiles[i]+"]");
		if (channels==true) {
			Stack.setChannel(nup);
		}
		zname=getTitle();
		zdupname=substring(zname,0,lengthOf(zname)-3);
		cnt = roiManager("count");
			for ( j=0; j<cnt; j++ ) { 
				roiManager("select", j);
				run("Duplicate...", "duplicate");
				dup= getTitle();
				print("duplicated stack: " + dup);
				dupname=substring(dup,0,lengthOf(dup)-5) + "_nuc";
				print("New name: " + dupname);
				selectWindow(dup);
				save(SIMoutdir+dupname+(j+1)+".tif");
				roiManager("rename", dupname+j);
				selectWindow(dup);
				run("track max not mask 3D jru v1", "threshold=Max z_edge_buffer=3 z_ratio=3.125 min_separation=8 thresh_fraction=0.25 edge_buffer=5 max_blobs=10000 display_frame=1 display_slice=10 link_range=10.00000 max_link_delay=1 min_traj_length=0 min_separation_z=5");
				wait(200);
				if(isOpen("Trajectories")){
					run("pair correlation function jru v1", "2d_normalization");
					pcfname=dupname+(j+1)+"_pcf.txt";
					print("pcfname: "+pcfname);
					rename(pcfname);
					run("export plot jru v2", "save=["+xlsout+pcfname+"]");
					close();
					selectWindow("Trajectories");
					trajname=dupname+(j+1)+".pw2";
					print("trajname: "+trajname);
					run("set 3D shapes jru v1", "shape=square color=black");
					rename(trajname);
					run("export plot jru v2", "save=["+trackoutdir+trajname+"]");
					close();
					tabname=dupname+(j+1)+".xls";
					print("tabname: "+tabname);
					run("rename table jru v1", "windows=[Traj Data] new="+tabname);
					run("export table jru v1", "table1=["+tabname+"] format=xls(tab) save=["+xlsout+tabname+"]");
					run("close table jru v1", "table=["+tabname+"]");
					selectWindow(dup);
					saveAs("Tiff...", trackoutdir+dupname+(j+1)+".tif");
					close();
	}				 
					else {
						//print("No points detected in the file "+dupname+(j+1)"); 
						run("close table jru v1", "table=[Traj Data]");
						close(dup);
					}
			}	
		roiManager("Save", SIMroioutdir+zdupname+"_ROISet.zip");
		close(zname);
		//close("ROI Manager");
		roiManager("deselect");
		roiManager("delete");	
	}


//macro to open cropped files, separate channels and set LUTs, combine and save as an AVI movie file. Testing.

#@ File (label="Choose directory containing images to analyze", style="directory") directory
#@ File (label="Choose image to setup LUTs and channels") srcFile
run("Close All");

print(directory);

open(srcFile);
setLocation(150, 150, 512, 512);
waitForUser("Examine Channels");

//Dialog box to set up channels wanted and LUTs

Dialog.create("Set Up");
Dialog.addChoice("Channel 1 LUT", newArray("Green", "Magenta", "Yellow", "Red", "Grays", "Grays (Inverted)"));
Dialog.addChoice("Channel 2 LUT", newArray("Green", "Magenta", "Yellow", "Red", "Grays", "Grays (Inverted)"));
Dialog.addChoice("Channel 3 LUT", newArray("Green", "Magenta", "Yellow", "Red", "Grays", "Grays (Inverted)"));
Dialog.addNumber("Scale Factor", 5);
Dialog.addNumber("Frames Per Second Output", 4);
Dialog.addCheckbox("Combine Vertically", 0);
Dialog.addString("File Suffix to Analyze", "cropped.tif");
Dialog.show();

C1lut = Dialog.getChoice();
C2lut = Dialog.getChoice();;
C3lut = Dialog.getChoice();;;
scale = Dialog.getNumber();
fps = Dialog.getNumber();;
vert = Dialog.getCheckbox();
suffix = Dialog.getString();

close(srcFile);
run("Close All");

//setBatchMode(true);
filelist = getFileList(directory)  
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], suffix)) { 
        open(directory + File.separator + filelist[i]);
        orig=getTitle();
        dupname=substring(orig, 0, lengthOf(orig)-4)+".avi";
        dupshort=substring(dupname,0,lengthOf(dupname)-4)+".tif";
        rename("original");
        run("Split Channels");
        close(orig);
      	selectWindow("C1-original");
	    rename("C1");
	    setLocation(150, 150, 512, 512);
	    run("Subtract Background...", "rolling=10 stack");
	    run("Scale...", "x=3 y=3 z=1.0 interpolation=Bilinear average process create");
	    run("Bleach Correction", "correction=[Simple Ratio] background=0");
	    close("C1");
	    close("C1-1");
	    rename("C1");
	       	if(C1lut == "Grays (Inverted)") {
	        	run("Grays");
				run("Invert LUT");
	        }
	        else {
	        	run(C1lut);
	        }
		run("Enhance Contrast", "saturated=0.35");
		run("RGB Color");
		save(directory+"/C1_edited_"+dupshort);
		rename("C1");
		
       if(isOpen("C2-original")) {
        	selectWindow("C2-original");
	        rename("C2");
	        setLocation(150, 150, 512, 512);
	        run("Subtract Background...", "rolling=10 stack");
		    run("Scale...", "x=3 y=3 z=1.0 interpolation=Bilinear average process create");
		    run("Bleach Correction", "correction=[Simple Ratio] background=0");
		    close("C2");
		    close("C2-1");
		    rename("C2");
	        if(C2lut == "Grays (Inverted)") {
	        	run("Grays");
				run("Invert LUT");
	        }
	        else {
	        	run(C2lut);
	        }
			run("Enhance Contrast", "saturated=0.35");
			run("RGB Color");
			save(directory+"/C2_edited_"+dupshort);
			rename("C2");
	      }
	      
        if(isOpen("C3-original")) {
        	selectWindow("C3-original");
	        rename("C3");
	        setLocation(150, 150, 512, 512);
	        run("Subtract Background...", "rolling=10 stack");
		    run("Scale...", "x=3 y=3 z=1.0 interpolation=Bilinear average process create");
		    run("Bleach Correction", "correction=[Simple Ratio] background=0");
		    close("C3");
		    close("C3-1");
		    rename("C3");
	        if(C3lut == "Grays (Inverted)") {
	        	run("Grays");
				run("Invert LUT");
	        }
	        else {
	        	run(C3lut);
	        }
			run("Enhance Contrast", "saturated=0.35");
			run("RGB Color");
			save(directory+"/C3_edited_"+dupshort);
			rename("C3");
	     }
	
	//loop through to find names of open channels for combining into movie
	n = nImages; 
	list = newArray(n); 
	setBatchMode(true); 
	for (j=1; j<=n; j++) { 
		selectImage(j); 
		list[j-1] = getTitle; 
	} 
	Array.print(list);
	setBatchMode(false); 
	
	if(list.length == 3 && vert == 1) {
		run("Combine...", "stack1=C1 stack2=C2 combine");
		run("Combine...", "stack1=[Combined Stacks] stack2=C3 combine");
	}
	if(list.length == 3 && vert == 0) {
	run("Combine...", "stack1=C1 stack2=C2");
	run("Combine...", "stack1=[Combined Stacks] stack2=C3");
	}
	if(list.length == 2 && vert == 1) {
		run("Combine...", "stack1=C1 stack2=C2 combine");
	}
	if(list.length == 2 && vert == 0) {
		run("Combine...", "stack1=C1 stack2=C2");
	}
	run("AVI... ", "compression=JPEG frame=4 save=["+directory+"/"+dupname+"]");
	close();
	run("Close All");
	print("Finished Image: "+dupname+". Images Left: " + filelist.length - (i+1));
	    }
	}

print("It's a beaut, Clark!");
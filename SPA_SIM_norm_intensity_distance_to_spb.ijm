//macro to examine relationship between distance to SPBs and intensity or NPC number. Extracts coordinates and intensities.
//distance to SPBs are calculated in R downstream of this macro.

//Open up the merged stack - not the averaged stack, need individual slices.

#@ File (label="Choose Merged Stack", style="file") image
#@ File (label="Choose Output Directory", style="directory") outdir
outdir=outdir+"/"

open(image);
orig=getTitle();
dupname=substring(orig,0,lengthOf(orig)-4);
setLocation(150, 150, 750, 750);

//Prompt user to specify channel with NPCs

waitForUser("Select NPC channel");
Stack.getPosition(channel, slice, frame);
npcs=channel;

//Duplicate out NPC channel full image stack for doing normalizations.
run("Duplicate...", "duplicate channels="+npcs);
rename("NPC");
run("normalize stack jru v1", "normalization=Max multiplication=1.00000"); //normalize each slice individually to avoid issues for different slices/nuclei having different intensities.
rename("normalized");

//for normalized stack, go through each slice, duplicate out, run track max not max to find spots and add to ROI manager.
nSlices
setBatchMode(true)
for (i = 1; i <= nSlices; i++) {
    setSlice(i);
    run("Duplicate...", " ");
    rename("dupslice");
    run("track max not mask fast jru v1", "threshhold=Max min_separation=8 thresh_fraction=0.25 edge_buffer=0 max_blobs=1000 display_frame=1 link_range=10.00000 max_link_delay=1 min_traj_length=0");
    run("close table jru v1", "table=[Traj Data]");

    //run measure trajectories to set a circle of radius 2 pixels (80nm; 160 nm diameter) and measure average intensities of those spots. 
    if(isOpen("Trajectories")) {
    	run("measure trajectories jru v1", "image=dupslice trajectory=Trajectories statistic=Avg measure_radius=2 measure_radius_z=5.00000 z_ratio=1.00000 circ_radius=1.00000 circ_stat=Min");
    	run("rename table jru v1", "windows=[Traj Stats] new="+dupname+"_slice_"+i);
    	close("Trajectories");
    	close("dupslice");  
    }
    else {
    	close("dupslice");
    }
    
}

run("combine all tables jru v1", "add_titles close");
run("export table jru v1", "table1=[Combined Table] format=csv save=["+outdir+dupname+"_intensity_distance_results.csv"+"]");
run("Close All");
run("close table jru v1", "table=[Combined Table]");

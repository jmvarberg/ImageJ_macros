//batch simulate NPC data
#@ File (label="Output Directory", style="directory") outdir
#@ Integer (label="Number of NPCs", value=125, persist=false) points 
#@ Integer (label="Radius (nm)", value=1000, persist=false) rad 
#@ Integer (label="Number of Simulations", value=100, persist=false) sims 
#@ Integer (label="X/Y Pixel Size (nm)", value=40, persist=false) pix 
#@ Integer (label="Z step size (nm)", value=125, persist=false) zsize

zscale=pix/zsize;

print(points, rad, sims, zscale);

//simulate the NPCs and save out re-scaled tiff images to be tracked
setBatchMode(true);
for (i = 0; i < sims; i++) {
	run("simulate npcs jru v1", "sphere_radius="+rad+" min_npc_dist=100 number_of_points="+points+" psf_fwhm=100.00000 psf_z_fwhm=300.00000 pixel_size="+pix+" max_intensity=100.00000 add_noise read_noise_stdev=40.00000 gain=50.00000 spb_max_intensity=100.00000 spb_separation=180.00000");
	close("Simulated Coordinates: Npcs");
	close("Sphere Positions Image: Npcs");
	close("Sphere Positions: Npcs");
	selectWindow("Sim NPCs");
	run("Scale...", "x=1.0 y=1.0 z="+zscale+" width=128 height=128 depth=41 interpolation=Bilinear average process create"); //correct for difference in x/y and z sizes
	close("Sim NPCs");
	name="Simulated_"+points+"_NPCs_radius_"+rad+"_nm_nucleus_"+(i+1)+".tif";
	saveAs("Tiff...", outdir+File.separator+name);
	close();
}

//find NPCs with track max not mask and save out csv file of x/y/z coordinates

filelist = getFileList(outdir)
for (j = 0; j < lengthOf(filelist); j++) {
    if (endsWith(filelist[j], ".tif")) { 
        open(outdir + File.separator + filelist[j]);
        orig=getTitle();
        dupname=substring(orig,0, lengthOf(orig)-4);
        run("track max not mask 3D jru v1", "threshold=Max z_edge_buffer=3 z_ratio=3.125 min_separation=8 thresh_fraction=0.25 edge_buffer=5 max_blobs=10000 display_frame=1 display_slice=10 link_range=10.00000 max_link_delay=1 min_traj_length=0 min_separation_z=5");
		wait(400);
		if(isOpen("Trajectories")){
			run("pair correlation function jru v1", "2d_normalization");
			pcfname=dupname+"_pcf.txt";
			rename(pcfname);
			run("export plot jru v2", "save=["+outdir+File.separator+pcfname+"]");
			close();
			selectWindow("Trajectories");
			close();
			tabname=dupname+".xls";
			print("tabname: "+tabname);
			run("rename table jru v1", "windows=[Traj Data] new="+tabname);
			run("export table jru v1", "table1=["+tabname+"] format=xls(tab) save=["+outdir+File.separator+tabname+"]");
			run("close table jru v1", "table=["+tabname+"]");
			close(orig);
			} 
			 	else {
						//print("No points detected in the file "+dupname+(j+1)"); 
						run("close table jru v1", "table=[Traj Data]");
						close(orig);
					}
    }
}
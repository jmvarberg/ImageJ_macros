//batch simulate NPC SPA-SIM data
#@ File (label="Output Directory", style="directory") outdir
#@ Integer (label="Number of NPCs", value=125, persist=false) points 
#@ Integer (label="Radius (nm)", value=1000, persist=false) rad 
#@ Integer (label="Number of Simulations", value=100, persist=false) sims 
#@ Integer (label="X/Y Pixel Size (nm)", value=40, persist=false) pix 
#@ Integer (label="Z step size (nm)", value=125, persist=false) zsize

for (i=0; i < sims; i++) {
	//simulate the points
	run("simulate npcs jru v1", "sphere_radius="+radius+" min_npc_dist="+sep+" number_of_points="+points+" psf_fwhm=100.00000 psf_z_fwhm=300.00000 pixel_size="+pixel+" max_intensity=100.00000 add_noise read_noise_stdev=40.00000 gain=50.00000 add_spb spb_max_intensity=100.00000 spb_separation=180.00000 spb_on_top");
	close("Sphere");
	close("Sphere Positions Image: Npcs");
	close("Sphere Positions: Npcs");
	close("Simulated Coordinates: Npcs");
	close("Sphere Positions Image: SPB");
	close("Sphere Positions: SPB");
	close("Simulated Coordinates: SPB");
	selectWindow("Sim NPCs");
	
	//rescale z dimension to match data off the OMX. Add SPB point ROIs and save out TIFF with ROI overlay.
	run("Scale...", "x=1.0 y=1.0 z=0.32 width=128 height=128 depth=41 interpolation=Bilinear average process create");
	newname= "Simulated_NPCs_SPA_SIM_"+points+"_points_radius_"+radius+"_nucleus_"+(i+1);
	x2=64;
	y2=64;
	x1=64;
	y1=59.549786;
	Stack.setSlice(30);
	makePoint(x1, y1);
	roiManager("add");
	makePoint(x2, y2);
	roiManager("add");
	roiManager("Show All");
	save(output+"/"+newname+".tif"); close();
	close("Sim NPCs");
	}



//batch simulate NPC SPA-SIM data
#@ File (label="Output Directory", style="directory") outdir
#@ Integer (label="Number of NPCs", value=125, persist=false) points
#@ Integer (label="Min NPC Separation (nm)", value=100, persist=false) sep 
#@ Integer (label="Radius (nm)", value=1000, persist=false) rad 
#@ Integer (label="Number of Simulations", value=100, persist=false) sims 
#@ Integer (label="X/Y Pixel Size (nm)", value=40, persist=false) pix 
#@ Integer (label="Z step size (nm)", value=125, persist=false) zsize

zscale=pix/zsize;

for (i=0; i < sims; i++) {
	//simulate the points
	run("simulate npcs jru v1", "sphere_radius="+rad+" min_npc_dist="+sep+" number_of_points="+points+" psf_fwhm=100.00000 psf_z_fwhm=300.00000 pixel_size="+pix+" max_intensity=100.00000 add_noise read_noise_stdev=40.00000 gain=50.00000 add_spb spb_max_intensity=100.00000 spb_separation=180.00000 spb_on_top");
	close("Sphere");
	close("Sphere Positions Image: Npcs");
	close("Sphere Positions: Npcs");
	close("Simulated Coordinates: Npcs");
	close("Sphere Positions Image: SPB");
	close("Sphere Positions: SPB");
	close("Simulated Coordinates: SPB");
	selectWindow("Sim NPCs");
	newname= "Simulated_NPCs_SPA_SIM_"+points+"_points_radius_"+rad+"_nucleus_"+(i+1);
	run("Duplicate...", "duplicate slices=94");
	saveAs("Tiff...", outdir+File.separator+newname+".tif");
	run("Close All");
}

filelist=getFileList(outdir);
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".tif")) { 
        open(outdir + File.separator + filelist[i]);
    } 
}
run("merge all stacks jru v1");
saveAs("Tiff...", outdir+File.separator+"Simulated_NPCs_SPA_SIM_"+points+"_points_radius_"+rad+"_n="+sims+"_merged.tif");
run("stack statistics jru v2", "statistic=Avg");
saveAs("Tiff...", outdir+File.separator+"Simulated_NPCs_SPA_SIM_"+points+"_points_radius_"+rad+"_n="+sims+"_merged_avg.tif");
run("Close All");

//generate averaged images and plot profiles using macro
runMacro("spa_sim_tiffs_plots_batch_jmv.ijm");
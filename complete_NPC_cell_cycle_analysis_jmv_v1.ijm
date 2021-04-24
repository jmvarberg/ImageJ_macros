//NPC analysis with cell length measurements automated version.

runMacro("auto_nuc_thresh_roi_crop_batch_track_jmv_v1.ijm");

Dialog.create("Perfom Cell Length Analysis?");
Dialog.addChoice("Cell Length Analysis", newArray("yes", "no"), "yes");
Dialog.show();
choice = Dialog.getChoice();
if(choice == "no") continue;
else {
	runMacro("batch_cell_length_measure_SIM_v1.ijm");
}

import re
configfile: "config.yaml"

rule all:
    output:
        "complete.txt"


checkpoint split_frames:
    input:
        "data/sub-{sub}_bld{run}_rest_skip4_stc_mc_bp_0.0001_0.08.nii.gz"
    output:
        directory("data/sub-{sub}_bld{run}_frames/")
    run:
        shell("mkdir {output}")
        shell("fslsplit {input} {output}/frame- -t")



rule project_1mm:
    input:
        "data/sub-{sub}_bld{run}_frames/frame-{framenum}.nii.gz",
        "data/sub-{sub}_bld{run}_rest_skip4_stc_mc_reg.dat"
    output:
        "data/sub-{sub}_bld{run}_frames/frame-{framenum}_MNI1mm.nii.gz"
    run:
        shell(f"csh scripts/CBIG_vol2vol_m3z.csh -src-id sub-{wildcards.sub} \
        -src-dir {config['fs_subjects']} \
        -targ-id FSL_MNI152_FS4.5.0 -targ-dir {config['cbig_dir']}/data/templates/volume -in {input[0]} -out {output} \
        -reg {input[1]} -no-cleanup")

rule downsample_2mm:
    input:
        "data/sub-{sub}_bld{run}_frames/frame-{framenum}_MNI1mm.nii.gz"
    output:
        "data/sub-{sub}_bld{run}_frames/frame-{framenum}_MNI1mm_MNI2mm.nii.gz"
    run:
        shell(f"mri_vol2vol --mov {input} --s FSL_MNI152_FS4.5.0 --targ $FSL_DIR/data/standard/MNI152_T1_2mm_brain.nii.gz --o {output} --regheader --no-save-reg")



rule smooth:
    input:
        "data/sub-{sub}_bld{run}_frames/frame-{framenum}_MNI1mm_MNI2mm.nii.gz"
    output:
        "data/sub-{sub}_bld{run}_frames/frame-{framenum}_MNI1mm_MNI2mm_sm6.nii.gz"
    run:
        sm = 6
        std = sm / 2.35482
        # sm_mask = f"{config['cbig_dir']}/data/templates/volume/FS_nonlinear_volumetric_space_4.5/SubcortCerebellumWhiteMask.GCA.t0.5_resampled.nii.gz"
        sm_mask = "templates/SubcortCerebellumWhiteMask.GCA.t0.5_resampled.nii.gz"
        inverted_sm_mask = "templates/SubcortCerebellumWhiteMask.GCA.t0.5_resampled_inverted.nii.gz"
        framedir = f"data/sub-{wildcards.sub}_bld{wildcards.run}_frames/"
        input_masksmoothed =  f"{framedir}/input_masksmoothed_{wildcards.framenum}.nii.gz"
        input_outsidemask_smoothed = f"{framedir}/input_outsidemask_smoothed_{wildcards.framenum}.nii.gz"
        tmp1 = f"{framedir}/tmp1_{wildcards.framenum}.nii.gz"
        tmp2 = f"{framedir}/tmp2_{wildcards.framenum}.nii.gz"
        tmp3 = f"{framedir}/tmp3_{wildcards.framenum}.nii.gz"
        tmp4 = f"{framedir}/tmp4_{wildcards.framenum}.nii.gz"
        shell(f"fslmaths {input} -s {std} -mas {sm_mask} {tmp1}")
        shell(f"fslmaths {sm_mask} -s {std} -mas {sm_mask} {tmp2}")
        shell(f"fslmaths {tmp1} -div {tmp2} {input_masksmoothed}")
        shell(f"fslmaths {input} -mas {inverted_sm_mask} -s {std} -mas {inverted_sm_mask} {tmp3}")
        shell(f"fslmaths {inverted_sm_mask} -s {std} -mas {inverted_sm_mask} {tmp4}")
        shell(f"fslmaths {tmp3} -div {tmp4} {input_outsidemask_smoothed}")
        shell(f"fslmaths {input_masksmoothed} -add {input_outsidemask_smoothed} {output}")




def get_frames(wildcards):
    frame_dir = checkpoints.split_frames.get(**wildcards).output[0]
    frame_nums = glob_wildcards(f"{frame_dir}/frame-{{frame_num}}.nii.gz").frame_num
    # filter out ones that have already run
    pattern = r'[^0123456789]'
    frame_nums_clean = [i for i in frame_nums if not re.search(pattern, i)]
    frames = expand(rules.smooth.output, **wildcards, framenum=frame_nums_clean,frame_dir=frame_dir)
    return frames

rule merge:
    input:
        get_frames
    output:
        "data/sub-{sub}_bld{run}_sm6_merged.nii.gz"
    run:
        shell("fslmerge -t {output} {input}")

rule final_mask:
    input:
        "data/sub-{sub}_bld{run}_sm6_merged.nii.gz"
    output:
        "data/sub-{sub}_bld{run}_merged_sm6_finalmasked.nii.gz"
    run:
        shell("fslmaths {input} -mas ${{FSLDIR}}/data/standard/MNI152_T1_2mm_brain_mask_dil.nii.gz {output}")
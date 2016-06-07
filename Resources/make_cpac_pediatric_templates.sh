#!/bin/bash
# A script to generate C-PAC usable templates from the NIHPD templates.
# John Pellman, 2016
# Usage: make_cpac_templates.sh 
# Note: template.cnf must be in the directory this is run from.


base=$(pwd)

# Fetch all the templates from the NIHPD website if they are not there already.
if [ ! -d nihpd_sym_all_nifti ];
then
    if [ ! -f nihpd_sym_all_nifti.zip ];
    then
        wget http://www.bic.mni.mcgill.ca/~vfonov/nihpd/obj1/nihpd_sym_all_nifti.zip
    fi
    unzip nihpd_sym_all_nifti.zip
    mkdir nihpd_sym_all_nifti && cd nihpd_sym_all_nifti
    sym_templates=$(ls ${base} | grep t1w | sed -e 's/_t1w.nii//g')
    for template in ${sym_templates}; do mkdir ${template}; mv ${base}/${template}* ${template}; done
    cd ${base}
fi

if [ ! -d nihpd_asym_all_nifti ];
then
    if [ ! -f nihpd_asym_all_nifti.zip ];
    then
        wget http://www.bic.mni.mcgill.ca/~vfonov/nihpd/obj1/nihpd_asym_all_nifti.zip
    fi
    unzip nihpd_asym_all_nifti.zip
    mkdir nihpd_asym_all_nifti && cd nihpd_asym_all_nifti
    asym_templates=$(ls ${base} | grep t1w | sed -e 's/_t1w.nii//g')
    for template in ${asym_templates}; do mkdir ${template}; mv ${base}/${template}* ${template}; done
    cd ${base}
fi
 
for temp_type in asym sym;
do
    cd ${base}/nihpd_${temp_type}_all_nifti
    templates=$(ls)
    sizes=(1 2 3)

    for template in ${templates};
    do
        cd ${template}
        # Compress all scans if they are not already.
        gzip *.nii
       # Move the original to a backup and re-orient the original to RPI
        mv ${template}_t1w.nii.gz orig_${template}_t1w.nii.gz
        3dresample -orient RPI -prefix ${template}_t1w.nii.gz -inset orig_${template}_t1w.nii.gz

        # Re-do zero padding so that template and mask are the same dimensions as the FSL MNI templates.
        mv ${template}_t1w.nii.gz reoriented_${template}_t1w.nii.gz
        3dZeropad -prefix ${template}_t1w.nii.gz -R -8 -L -7 -A -7 -P -8 -S -7 reoriented_${template}_t1w.nii.gz
        mv ${template}_mask.nii.gz orig_${template}_mask.nii.gz
        3dZeropad -prefix ${template}_mask.nii.gz -R -8 -L -7 -A -7 -P -8 -S -7 orig_${template}_mask.nii.gz
        for size in ${sizes[@]};
        do
 
            if [ ${size} -eq 1 ];
            then
                # Original is already in 1 mm space so copy that.
                cp ${template}_t1w.nii.gz ${template}_t1w_${size}mm.nii.gz
                cp ${template}_mask.nii.gz ${template}_mask_${size}mm.nii.gz
            else
                # Resample to isotropic voxels of size 'size'.
                3dresample -prefix ${template}_t1w_${size}mm.nii.gz -dxyz ${size} ${size} ${size} -inset ${template}_t1w.nii.gz
                mv ${template}_t1w_${size}mm.nii.gz orig_${template}_t1w_${size}mm.nii.gz
                3dresample -orient RPI -prefix ${template}_t1w_${size}mm.nii.gz -inset orig_${template}_t1w_${size}mm.nii.gz
                
                # Resample the mask image to voxels of size 'size'.
                3dresample -prefix ${template}_mask_${size}mm.nii.gz -dxyz ${size} ${size} ${size} -inset ${template}_mask.nii.gz
            fi

            # Skull strip the T1w using the mask.
            3dcalc -prefix ${template}_t1w_${size}mm_ss.nii.gz -a ${template}_mask_${size}mm.nii.gz -b ${template}_t1w_${size}mm.nii.gz -expr 'a*b'
            mv ${template}_t1w_${size}mm_ss.nii.gz orig_${template}_t1w_${size}mm_ss.nii.gz
            3dresample -orient RPI -prefix ${template}_t1w_${size}mm_ss.nii.gz -inset orig_${template}_t1w_${size}mm_ss.nii.gz

            # Dilate the mask
            3dAutomask -prefix ${template}_mask_${size}mm_dil.nii.gz -dilate 5 ${template}_t1w_${size}mm_ss.nii.gz
            mv ${template}_mask_${size}mm_dil.nii.gz orig_${template}_mask_${size}mm_dil.nii.gz
            3dresample -orient RPI -prefix ${template}_mask_${size}mm_dil.nii.gz -inset orig_${template}_mask_${size}mm_dil.nii.gz

            config=${template}_${size}mm.cnf
            cp ${base}/template.cnf ${config}
            sed -i -e 's|REFPATH|'${template}_t1w_${size}mm'|g' ${config}
            sed -i -e 's|MASKPATH|'${template}_mask_${size}mm_dil'|g' ${config}
        done
        # Binarize the GM/WM/CSF probability maps
        fslmaths ${template}_gm.nii.gz -thr 0.66 -bin ${template}_gm_bin.nii.gz
        fslmaths ${template}_wm.nii.gz -thr 0.66 -bin ${template}_wm_bin.nii.gz
        fslmaths ${template}_csf.nii.gz -thr 0.66 -bin ${template}_csf_bin.nii.gz
        # Remove files not needed for C-PAC run.
        rm orig_*
        rm reoriented_*
        rm *_gm.nii.gz
        rm *_wm.nii.gz
        rm *_csf.nii.gz
        rm *_pdw.nii.gz
        rm *_t1w.nii.gz
        rm *_t2w.nii.gz
        rm *_mask.nii.gz
        cd ${base}/nihpd_${temp_type}_all_nifti
        zip -r ${template}.zip ${template}
        rm -r ${template}
    done
done

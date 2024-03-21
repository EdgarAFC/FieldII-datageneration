#!/usr/bin/bash
#SBATCH --gpus-per-node=1
#SBATCh --nodes=1
#SBATCH --partition=thinkstation-p360
#SBATCH --nodelist=worker10
#SBATCH --output="log_w10.out"

srun matlab -nosplash -nodesktop -nodisplay -r "gendata_w10; exit"


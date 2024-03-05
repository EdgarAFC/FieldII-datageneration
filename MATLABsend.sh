#!/usr/bin/bash
#SBATCH --gpus-per-node=1
#SBATCh --nodes=1
#SBATCH --partition=thinkstation-p340
#SBATCH --nodelist=worker7
#SBATCH --output="log.out"

srun matlab -nosplash -nodesktop -nodisplay -r "gendata; exit"


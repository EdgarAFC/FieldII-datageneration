#!/usr/bin/bash
#SBATCH --gpus-per-node=1
#SBATCh --nodes=1
#SBATCH --partition=gamerpcs
#SBATCH --nodelist=worker1
#SBATCH --output="log.out"

srun matlab -nosplash -nodesktop -nodisplay -r "gendata2; exit"


#!/usr/bin/bash

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --gpus-per-node=1
#SBATCh --nodes=1
#SBATCH --partition=gamerpcs
#SBATCH --nodelist=worker2
#SBATCH --output="log2.out"

srun matlab -nosplash -nodesktop -nodisplay -r "gendata2; exit"


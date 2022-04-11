# ================================================================================ #
#                   Lecture de l'alphabet d'encodage des variables
#                                       
# Juin 2020 - LUQUEZI Leonardo 
# ================================================================================ #

# ---------- 0. Librarys ----------
library(readr)
library(dplyr)
library(stringr)
source(file = "0_fonctionsR.R")

# ---------- 1. Paths Management ----------
# Path: lire la codification des regroupements (alphabetTable.RDV)
pathC.Alphabet = "TraitementBD/correspondance_ALPHABET.csv"

# Path : sauvegarder les nouvelles bases de données .RDS
# Note: Si besoin, modifier le nom du fichier pour ne pas effacer les autres données
PathR.alphaTable <- "DataR/alphaTable.RDS"

# Ceration du DataFrame alphabetTable .RDS 
alphabetTable <- alphabetTables(pathC.Alphabet)

# ---------- 2. Sauvegarder ----------
# Sauvegarder alphabetTable
save(alphabetTable, file = PathR.alphaTable)

# ---------- 3. Nettoyage Global Environement -----------
rm(list = ls())
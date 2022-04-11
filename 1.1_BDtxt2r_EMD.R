# ================================================================================ #
#       Transformation de l'Enquete Menage Deplacement de Loire Atlantique 
#                              au format .txt en .RDS 
#
# Juin 2020 - LUQUEZI Leonardo
# ================================================================================ #

# ---------- 0. Librarys ----------
library(readr)
library(dplyr)
library(stringr)
source(file = "0_fonctionsR.R")

# ---------- 1. Paths Management ----------
#Paths pour lire donnees brutes .txt de l'Enquête
PathBD.Menage <- "DataBD/02a_EDGT_44_MENAGE_FAF_TEL_2015-08-07_modifZF.txt"
PathBD.Personne <- "DataBD/02b_EDGT_44_PERSO_FAF_TEL_ModifPCS_2016-04-14.txt"
PathBD.Deplacement <- "DataBD/02c_EDGT_44_DEPLA_FAF_TEL_DIST_2015-11-10.txt"
PathBD.Trajet <- "DataBD/02d_EDGT_44_TRAJET_FAF_TEL_DIST_2015-11-10.txt"

#Paths correspondance entre les donnees; ce qu'il y a dans chaque ligne de chaque BD
PathC.Menage <- "TraitementBD/correspondance_BD/Fichier_Menage.txt"
PathC.Personne <- "TraitementBD/correspondance_BD/Fichier_Personne.txt"
PathC.Deplacement <- "TraitementBD/correspondance_BD/Fichier_Deplacement.txt" 
PathC.Trajet <- "TraitementBD/correspondance_BD/Fichier_Trajet.txt"

#Paths pour sauvegarder les donnees brutes .RDS de l'Enquête
PathR.Menage <- "DataR/BD_brute_menage.RDS"
PathR.Personne <- "DataR/BD_brute_personne.RDS"
PathR.Deplacement <- "DataR/BD_brute_depl.RDS"
PathR.Trajet <- "DataR/BD_brute_trajet.RDS"

# ---------- 2. Application de la fonction BD_lecture pour chauqe BD ----------
#BD_lecture ; lecture de toutes les données brutes .txt á l'aide du fichier dessin des variables 
#Donnes Brutes Menage
BD_menage_EMD <- BD_lecture(PathBD.Menage, PathC.Menage)

#Donnes Brutes Personne
BD_personne_EMD <- BD_lecture(PathBD.Personne, PathC.Personne)

#Donnes Brutes Deplacement
BD_depl_EMD <- BD_lecture(PathBD.Deplacement, PathC.Deplacement)

#Donnes Brutes Trajet
BD_trajet_EMD <- BD_lecture(PathBD.Trajet, PathC.Trajet)

# ---------- 3. Sauvegarder ----------
save(BD_menage_EMD, file = PathR.Menage)
save(BD_personne_EMD, file = PathR.Personne)
save(BD_depl_EMD, file = PathR.Deplacement)
save(BD_trajet_EMD, file = PathR.Trajet)

# ---------- 4. Nettoyage Global Environement -----------
rm(list = ls())


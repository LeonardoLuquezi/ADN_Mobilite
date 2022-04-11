# ================================================================================ #
#                    Traitement des bases de donnees EMD 
#                 et construction de l'Agenda des personnes
#                                       
# Juin 2020 - LUQUEZI Leonardo
# ================================================================================ #

# ---------- 0. Librarys ----------
library(stringr)
library(dplyr)
library(tidyr)
library(readr)
library(Hmisc)
library(reshape2)
source(file = "0_fonctionsR.R")

# ---------- 1. Paths management ----------
# Path: lire les données brutes .RDR de l'enquete
PathR.Deplacement <- "DataR/BD_brute_depl.RDS"

# Path correspondance Alphabet d'encodage
PathR.alphaTable <- "DataR/alphaTable.RDS"

# Path sauvegarder AGENDA Mobilité .RDS
PathR.AGENDA_Mobilite <- "DataR/Nantes_AGENDA_Mobi.RDS"

# Path : sauvegarder les nouvelles bases de données .RDS
# Note: si besoin, modifier le nom du fichier pour ne pas effacer les autres données
PathR.BD_Deplacement <- "DataR/Nantes_BD_pre_depl.RDS"

# ---------- 2. Chargement de la base de données brutes .RDS ----------
load(PathR.Deplacement)

# ---------- 3.1 Pretraitement: Creation des nouvelles tables avec les features des sequences ----------
tripTable <- BD_depl_EMD
rm(BD_depl_EMD)

# ---------- 3.2 Deplacement : construction de la table tripTable avec les variables utiles ----------
# Pour la creation de la Zone Fine Habitation; concatenation de Secteur de Tirage(DTIR), zone fine de residance(DP2)
tripTable <- tripTable %>%
  unite(ZF, c("DTIR","DP2"), sep = "", remove = F)

# Creation d'un identifiant unique pour chaque individu; 
# Concatenation de Secteur de Tirage(DTIR), Zone fine de residance(DP2), Nº Echantillon(ECH) et Nº Personne (PER)
tripTable <- tripTable %>% 
  unite(ID_IND, c("DTIR","DP2","ECH","PER"))

# Modification de l'heure
tripTable <- tripTable %>% 
  unite(D4, c("D4A","D4B"), sep = "", remove = T)

tripTable <- tripTable %>% 
  unite(D8, c("D8A","D8B"), sep = "", remove = T)

# Verification: nombre de personnes enquetees
nrow(tripTable %>% 
       select(ID_IND) %>% 
       group_by(ID_IND) %>% 
       count(ID_IND))

# ---------- 3.3 Zones Fines ----------
load(PathR.alphaTable)
# Selection des secteurs de tirage de l'Aire Urbaine de Nantes
st.encodage <- alphabet2TE(alphabetTable, classe.alphabet = "ZONAGE", variable.jointby = "PTIR")

tripTable <-  tripTable %>% 
  filter(substr(ID_IND, start = 1, stop = 3) %in% st.encodage[,1])

rm(st.encodage)

# ---------- 3.4 Agenda : construction de la table tripTable ----------
# Variables pour la creation de l'AGENDA
tripTable <- tripTable %>% 
  select(ID_IND, NDEP, D3, D7, MODP, D4, D8, D2A, D5A) %>% 
  mutate(NDEP = as.integer(NDEP))

# ---------- 4. Sauvegarder BD's pretraitees  ----------
save(tripTable, file = PathR.BD_Deplacement)


# ---------- 5. Creation AGENDA Mobilite ----------
# ---------- 5.1. Codification des activites en utilisant un DataFrame type tripTable .RDS ----------
actTable <- codificationActivite(tripTable)

rm(tripTable)

# ---------- 5.2. Codification des agendas en utilisant un DataFrame type actTable .RDS ----------
agendaTable <- codificationAgenda(actTable)

rm(actTable)

# ---------- 6. Sauvegarder AGENDA Mobilite Chaine de Caracteres .RDS ----------
save(agendaTable, file = PathR.AGENDA_Mobilite)

# ---------- 7. Nettoyage Global Environement -----------
rm(list = ls())

# ================================================================================ #
#                           Construction de l'ADN mobilite  
#                                       script
# Juin 2020 - LUQUEZI Leonardo
# ================================================================================ #

# 0. Librarys
library(stringr)
library(dplyr)
library(tidyr)
library(readr)
library(Hmisc)
library(janitor)
library(reshape2)
source(file = "0_fonctionsR.R")

# ---------- 1.Path management ----------

# Path lire AGENDA_mobilité .RDR 
PathR.AGENDA_Mobilite <- "DataR/Nantes_AGENDA_Mobi.RDS"

# Path correspondance Alphabet
PathR.alphaTable <- "DataR/alphaTable.RDS"

# Path sauvegarder l'ADN Mobilité .RDS
# Note: Si besoin, modifier le nom du fichier pour ne pas effacer les autres données
PathR.ADN_Mobilite <- "DataR/Nantes_ADN_Mobi.RDS"

# ---------- 2. Chargement de la base de donnees du prétraitement ----------
load(PathR.AGENDA_Mobilite)
load(PathR.alphaTable)

# ---------- 3. Creation des ADN Mobilite ----------

# Lecture de l'ecodage: alphabet et états
motifTable <-  alphabet2TE (alphabetTable, classe.alphabet = "MOTIF", variable.jointby = "ACT")
 
modeTable <- alphabet2TE (alphabetTable, classe.alphabet = "MODE", variable.jointby = "MODP")

# Verifier; normalement 33 lignes modeTable et 39 motifTable (EDGT44,2015)

# Correspondance MOTIF
motifTable <- motifTable %>% mutate(ACT = as.integer(ACT))
agendaTable <- agendaTable %>% mutate(ACT = as.integer(ACT))
agendaTable <- left_join(x = agendaTable, y = motifTable, by = "ACT")

# Correspondance MODE
modeTable <- modeTable %>% mutate(MODP = as.integer(MODP))
agendaTable <- agendaTable %>% mutate(MODP = as.integer(MODP))
agendaTable <- left_join(x = agendaTable, y = modeTable, by = "MODP")

rm(modeTable, motifTable)

# Filtrer variables essentiels à la creation de l'ADN Mobilite
adnTable <- agendaTable %>% 
  select("ID_IND", "D4", "D8","MOTIF","MODE")

rm(agendaTable)

# ---------- 3.4 Fonction : Creation des ADN Mobilite en utilisant un DataFrame type adnTable.RDS --------

ADN_M <- adnMobilite(adnTable)

# Adaptation du ADN_Mobilite à la bibliotheque TraMineR (columns = factors)
col.names <- c(as.character(1:1440))
alphabetTable <- alphabetTable %>% 
  filter(Classe == "MOTIF" | Classe == "MODE")

ADN_M[col.names] <- lapply(ADN_M[col.names], factor, levels = alphabetTable$Alphabet)

rm(adnTable, col.names, alphabetTable)

# ------- 4. Sauvegarder ADN Mobilite. RDS et les tables alphabet, mode et motif .RDS -------
save(ADN_M, file = PathR.ADN_Mobilite)

# 5. Nettoyage Global Environement
rm(list = ls())


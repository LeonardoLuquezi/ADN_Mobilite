# ================================================================================ #
#         Construction de la base de donnees des cracteristiques des personnes 
#                                     
# Juin 2020 - LUQUEZI Leonardo
# ================================================================================ #

# 0. Librarys
library(stringr)
library(dplyr)
library(tidyr)
library(readr)
library(Hmisc)
library(reshape2)
source(file = "0_fonctionsR.R")

# ---------- 1.Path management ----------
# Path: lire les données brutes .RDR de l'Enquête
# PathR.Menage <- "DataR/BD_brute_menage.RDS"
PathR.Personne <- "DataR/BD_brute_personne.RDS"
PathR.Deplacement <- "DataR/BD_brute_depl.RDS"
# PathR.Trajet <- "DataR/BD_brute_trajet.RDS"

# Path: lire la codification des regroupements (alphabetTable.RDV)
PathR.alphaTable <- "DataR/alphaTable.RDS"

# Path : sauvegarder les nouvelles bases de données .RDS
# Note: Si besoin, modifier le nom du fichier pour ne pas effacer les autres données
PathR.IND_Carac <- "DataR/Nantes_features.RDS"

# ---------- 2. Chargement de la base de données brutes .RDS ----------
load(PathR.alphaTable)

# ---------- 3. Prétraitement: Creation de la table IND_Carac.RDS avec les features d'interet ----------
load(PathR.Personne)
perTable <- BD_personne_EMD
rm(BD_personne_EMD)

# ---------- 3.1 Personne : construction de la table perTable avec les variables utiles ----------

# Creation de la variable Zone Fine (ZF)
perTable <- perTable %>%
  unite(ZF, c("PTIR","PP2"), sep = "", remove = F)

# Creation d'un identifiant unique pour chaque individu; 
# Concatenation de Secteur de Tirage(DTIR), Zone fine de residance(DP2), Nº Echantillon(ECH) et Nº Personne (PER)
perTable <- perTable %>% 
  unite(ID_IND, c("PTIR","PP2","ECH","PER"), remove = F)

# Ajustement de la difference d'individus entre la BD (29496 lignes) et l'EMD (20799 individus)
# Supprimer les individus pour lesquels COEQ=0 (ou conserver les individus pour lesquels PENQ=1)
perTable <-  perTable %>%
  filter(PENQ == "1") 

# # TESTE avec P7 et P9
# perTable <- perTable %>% select(ID_IND, P7, P9)
# 
# perTable[perTable$P9 == 0,]$P9 <- "1"
# 
# ADN_M <- ADN_M %>% left_join(x= ADN_M, y = perTable, by = "ID_IND", keep = TRUE)
# # Fin teste

# Classification des Secteurs de Tirage (PTIR) de Nantes Metropole
# 1 : Centre Ville | 2 : Nantes Ville | 3 : Nantes Metropole | 4 : Aire Urbaine |
st.encodage <- alphabet2TE( alphabetTable, classe.alphabet = "ZONAGE", variable.jointby = "PTIR")

perTable <- left_join(x = perTable , y = st.encodage, by = "PTIR", keep = F )

rm(st.encodage)


# Création de la variable classe d'âge (KAGE) 
# 0 : 15 ans ou moins | 1 : 16-24 | 2 : 25-34 | 3 : 35-64 | 4 : 65 ans ou plus
perTable <- perTable %>% 
  mutate(KAGE = case_when(as.numeric(P4) >= 16 & as.numeric(P4) <= 24 ~ 1,
                          as.numeric(P4) >= 25 & as.numeric(P4) <= 34 ~ 2,
                          as.numeric(P4) >= 35 & as.numeric(P4) <= 64 ~ 3,
                          as.numeric(P4) >= 65 ~ 4,
                          TRUE ~ 0))

# Creation de la variable Dsitance Domicile-Travail (DDT) 
# 1: DT[0;1[ | 2: DT[1;5[ | 3: DT[5;10[ | 4: DT[10;50[ | 5: DT[50+
           
perTable <- perTable %>% 
  mutate(DDT = case_when(as.numeric(DP13) >= 0 & as.numeric(DP13) < 1000 ~ 1,
                          as.numeric(DP13) >= 1000 & as.numeric(DP13) < 5000 ~ 2,
                          as.numeric(DP13) >= 5000 & as.numeric(DP13) < 10000 ~ 3,
                          as.numeric(DP13) >= 10000 & as.numeric(DP13) < 50000 ~ 4,
                          as.numeric(DP13) >= 50000 ~ 5))

# Possession du permis de conduire (PERMIS)
# 1: Oui | 2: Non | 3: Accompagnee ou lecons
perTable <- perTable %>% 
  mutate(PERMIS = P5)

# teste6 <- perTable %>%
#   group_by(P15) %>%
#   count(P15)

# Création de la variable niveau d'éducation (EDUC) en 4 modalités
# 1 : faible ; 2 : intermediaire ; 3 : eleve ; 4 : tres eleve 
educ.encodage <- alphabet2TE( alphabetTable, classe.alphabet = "EDUC", variable.jointby = "P6")

perTable <- left_join(x = perTable , y = educ.encodage, by = "P6", keep = F ) 

rm(educ.encodage)


# Création de la variable occupation principale en 5 modalités (OCC)
# 1 : active ; 2 : étudiant ; 3 : sans emploi ; 4 : retraites ; 5 : inactifs
occ.encodage <- alphabet2TE( alphabetTable, classe.alphabet = "OCC", variable.jointby = "P7")

perTable <- left_join(x = perTable , y = occ.encodage, by = "P7", keep = F )

rm(occ.encodage)

# Catégorie socioprofessionnelle : 
# 5: Cadres | 4: Intermédiaire | 3: Employés | 2: Ouvriers | 1: Inactifs
pcsc.encodage <- alphabet2TE( alphabetTable, classe.alphabet = "PCSC", variable.jointby = "P9")

perTable <- left_join(x = perTable , y = pcsc.encodage, by = "P9", keep = F ) 

rm(pcsc.encodage)

# Disposition d'une voiture en general DISV
# (DÉPLACEMENTS DOMICILE TRAVAIL OU ÉTUDES)
# 01: Oui | 02: Non | 03: Non concernee
disv.encodage <- alphabet2TE( alphabetTable, classe.alphabet = "DISV", variable.jointby = "P15")

perTable <- left_join(x = perTable , y = disv.encodage, by = "P15", keep = F ) 

# Dans le cas ou les reponses sont " " on les classe comme 2
perTable <- perTable %>% 
  replace_na(list(DISV = as.character(2)))

rm(disv.encodage)

# Construction de la table avec les variables utiles
perTable <- perTable %>% 
  transmute(ID_IND, ZF, ZONAGE, SEX = P2, KAGE, EDUC, OCC, PCSC, PERMIS, DDT, DISV)

#  teste0 <- perTable %>% 
#   filter(perTable$KAGE != 0) %>% 
#   group_by(EDUC) %>% 
#   count(EDUC)

# ---------- 3.2 Deplacement : construction de la table perTable avec les variables utiles ----------
load(PathR.Deplacement)

# Variable Disatance Parcorue pour le deplacement principal (DISTP)
tripTable <- BD_depl_EMD
rm(BD_depl_EMD)

# Creation d'un identifiant unique pour chaque individu; 
# Concatenation de Secteur de Tirage(DTIR), Zone fine de residance(DP2), Nº Echantillon(ECH) et Nº Personne (PER)
tripTable <- tripTable %>% 
  unite(ID_IND, c("DTIR","DP2","ECH","PER")) %>% 
  mutate(DIST = as.integer(DIST))

distp.encodage <- tripTable %>% 
  group_by(ID_IND) %>%
  filter(DIST == max(DIST)) %>% 
  slice(1) %>% 
  rename(DISTP = DIST) %>% 
  select(ID_IND, DISTP)

## Construction de la table avec les variables utiles
perTable <- perTable %>% 
  left_join(y = distp.encodage, by = "ID_IND", keep = F) %>% 
  replace_na(list(DISTP = 0))

rm(distp.encodage, tripTable)

perTable <- perTable %>% 
  mutate(DISTP = case_when(as.numeric(DISTP) > 0 & as.numeric(DISTP) < 1000 ~ 1,
                         as.numeric(DISTP) >= 1000 & as.numeric(DISTP) < 3000 ~ 2,
                         as.numeric(DISTP) >= 3000 & as.numeric(DISTP) < 10000 ~ 3,
                         as.numeric(DISTP) >= 10000  ~ 4,
                         as.numeric(DISTP) == 0 ~ 0))

# ---------- 4.2 Filtrer Secteurs de Tirage Clases ----------
# Filtrer Secteurs de Tirage Aire Urbaine
perTable <-  perTable %>% 
      filter( is.na(ZONAGE) == FALSE)

# ---------- 5. Sauvegarder ----------

# Sauvegarder features
save(perTable, file = PathR.IND_Carac)

# 6. Nettoyage Global Environement
rm(list = ls())

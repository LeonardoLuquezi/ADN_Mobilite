# ================================================================================ #
#                 Fonctions pour le traitement des donnees EDGT et
#                     pour l'analyse de sequences ADN Mobilite
#
# Juin 2020 - LUQUEZI Leonardo
# ================================================================================ #

# ---------- 0. Librarys ----------
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(TraMineR)
library(reshape2)
library(janitor)

# --------- 1 Fonction BD_lecture()  ----------
# Lecture des bases de donnees EDGT brutes .txt en utilisant le tableau de dessin des variables .txt 
# pour generer des donnees au format R .RDS

# Inputs : localisation des donnees EDGT (e.g. "DataBD/02a_EDGT_44_MENAGE_FAF_TEL_2015-08-07_modifZF.txt" ) 
#          localisation du tableau de dessin des variables (e.g. "Regroupement_Variables_txt/correspondance_BD/Fichier_Menage.txt" )
# Outputs : données EDGT au format R .RDS 

BD_lecture <- function(donnes_path, correspondance_path){
  
  # Lecture des donnees brutes EDGT
  BD_depl_EMD <- read_csv(donnes_path, col_names = FALSE)
  
  # Lecture du tableau de dessin des variables 
  corresp_BD <- read_delim(correspondance_path, "\t", escape_double = FALSE, trim_ws = TRUE, col_types = "iic")
  
  new_columns <- unlist(corresp_BD[3])
  BD_depl_EMD[ ,new_columns] <- NA
  
  # Traitement de chaque ligne de la base de donnees brute EDGT 
  for(i in 1:dim(corresp_BD)[1]){
    
    BD_depl_EMD[,i+1] = substr(BD_depl_EMD[["X1"]], corresp_BD[i,1], corresp_BD[i,1]+corresp_BD[i,2]-1)
    
  }
  
  BD_depl_EMD <- BD_depl_EMD %>% 
    select(-(X1))
  
  return(BD_depl_EMD)
  
}

# --------- 2 Fonction alphabetTable()   --------
# Lecture du tableau .CSV qui contient l'alphabet pour le traitement des variables de l'EDGT

# Inputs : localisation de l'alphabet d'encodage(e.g."Regroupement_Variables_txt/correspondance_ALPHABET.csv")
#          nombre maximale de variables qui sont regroupees dans le meme groupe
# Outputs : tableau alphabet au format R .RDS

alphabetTables <- function(pathC.Alphabet, NmaxCodification = 50) {
  
  col.names <- c(as.character(1:NmaxCodification))
  alphabet.Table <- read.csv(pathC.Alphabet, header = TRUE, sep =";", colClasses = "character")
  alphabet.Table <- alphabet.Table %>% 
    separate("Codification", sep = "_", remove = TRUE, into = col.names) %>% 
    remove_empty(which = "cols")
  
  return(alphabet.Table)
  
}

# --------- 3 Fonction alphabet2TE()    --------
# Creation d'un tableau d'encodage pret pour la jointure entre deux tableaux

# Inputs : alphabet utilise pour le traitement 
#          nom de la classe de la vabriable de l'alphabet qui est traitee
#          nom de l'element de jointure (joint_by)
# Outputs : tableau d'encodage de la classe choixsie 

alphabet2TE <- function(alphabet.table, classe.alphabet, variable.jointby ) {
  
  # library(reshape2)
  alphabet.table <- alphabet.table %>% 
    filter(alphabet.table$Classe == classe.alphabet) %>% 
    remove_empty(which = "cols")
  
  table.encodage <- alphabet.table %>%  
    melt(id.vars = "Alphabet", measure.vars = 5:ncol(alphabet.table))
  
  table.encodage <- table.encodage %>% 
    filter(!is.na(table.encodage$value)) %>% 
    select(value, Alphabet)
  
  table.encodage <- table.encodage[order(table.encodage$Alphabet),]
  
  names(table.encodage) <- c(variable.jointby, classe.alphabet)
  
  return(table.encodage)
  
}

# --------- 4 Fonction: codificationActivite()  ----------
# Codification des activites de chaque personne en utilisant un DataFrame type tripTable
# tripTable; tableau issue du pre-traitement de la base de donnes brute des deplacement 

# Inputs : tripTable  
# Outputs : tableau d'activites (actTable.RDS) des personnes avec leur identifiant, l'heure de debut et fin, etc. 
# Note : A la fin du traitement le tripTable devient l'actTable
#        L'algo analyse chaque ligne du DataFrame tripTable, ensuite les modifie au meme temps qu'il ajoute des nouvelles lignes si besoin 
#        pour en suite organiser/trier ces lignes
#        Les colonnes effacees a la fin du traitement sont precisees ci-dessous
#        (ID_IND = ID_IND , NACT = NDEP, effacer = D7, MODE_D = MODE, D4 = D4, D8 = D8, ACT = D2A, effacer = D5A, MODE_O = nouvelle collone )

codificationActivite <- function(tripTable) {
  
  # Modification de la colonne "MODE_O" 
  tripTable[ ,"MODE_O"] <- as.character(NA)
  
  # Variables auxiliaires;
  # Identification du changement de la personne a traiter
  chan_per <- FALSE
  # H1 et H2 pour traiter les horaires des activites
  H1 <- "0400"
  H2 <- "0400"
  # Mode de transport utilise pour arriver a l'activite
  mode_origine <- NA
  # Nombre de lignes a traiter
  dim_DB <- dim(tripTable)
  
  # Traitement de chaque ligne de la base de donnees brute EDGT
  for (i in 1:(dim_DB[1])){
    
    # Verifier le changement de personne en analysant la ligne suivante
    chan_per <- tripTable$ID_IND[i] != tripTable$ID_IND[i+1]
    
    # Creation de la derniere activite de la journee s'il y a le changment de personne
    if (chan_per == T | is.na(chan_per)){
      
      tripTable[nrow(tripTable)+1,] = list(tripTable$ID_IND[i],
                                         tripTable$NDEP[i]+1,
                                         tripTable$D7[i],
                                         NA,
                                         NA,
                                         tripTable$D8[i],
                                         "2800",
                                         tripTable$D5A[i],
                                         NA,
                                         tripTable$MODP[i])
      
    } 
    
    # Modification de la premiere activite de la journee
    if (tripTable$NDEP[i] == 1) {
      
      H1 <- "0400"
      H2 <- tripTable$D4[i]
      tripTable$D4[i] = H1
      H1 <- H2
      
      H2 <- tripTable$D8[i]
      tripTable$D8[i] = H1
      H1 <- H2
      
      mode_origine <- tripTable$MODP[i]
      
    } else {
      
      # Modification d'une activite au milieu de la journee
      H2 <- tripTable$D4[i]
      tripTable$D4[i] = H1
      H1 <- H2
      
      H2 <- tripTable$D8[i]
      tripTable$D8[i] = H1
      H1 <- H2
      
      tripTable$MODE_O [i] <- mode_origine
      mode_origine <- tripTable$MODP[i]
      
    } 
  }
  
  # Trier les donnees
  tripTable <- tripTable[order(tripTable$ID_IND),]
  
  # Chanchement du nom des variables et selection des donnees utiles
  actTable <- tripTable %>% 
    rename(NACT = NDEP, MODE_D = MODP, ACT = D2A ) %>% 
    select(ID_IND, NACT, D3, MODE_O, MODE_D, D4, D8, ACT)
  
  return(actTable)
}

# --------- 5 Fonction codificationAgenda()  ----------
# Codification des agendas mobilite en utilisant un DataFrame type actTable .RDS

# Inputs : actTable  
# Outputs : tableau agenda; informations des activites et des deplacements realisees dans la journee pour les personnes  

codificationAgenda <- function(actTable) {
  #Ajouter colonnes "Numero de Deplacement" et "ID_Deplacement" 
  new_columns <- c("NDEP", "ID_DEP","MODP")
  actTable[ ,new_columns] <- as.character(NA)
  actTable <- actTable %>%
    mutate(NDEP = as.integer(NDEP))
  
  
  #Variables Auxiliaires
  chan_per <- FALSE
  N_DEP <-as.integer(1)
  dim_DB <- as.integer(dim(actTable))
  
  # Algo: Analyser chaque ligne du DataFrame pour (re)ajouter les lignes deplacements entre chaque activite d'une personne pour en suite organiser/trier ces lignes
  # Obs: A la fin, chaque personne aura son agenda: activites entre 400(4h - Jour1) 2800(4h - Jour2)
  
  for (i in 1:(dim_DB[1])){
    
    #Verifier changement de personne
    chan_per <- actTable$ID_IND[i] != actTable$ID_IND[i+1]
    
    if (chan_per){
      
      chan_per <- FALSE
      N_DEP <- 1
      
      
    } else {
      
      #Activite 100 = Deplacement , Zone Fine = Concatenation ZF Origine et ZF Destination
      actTable[nrow(actTable)+1,] = list(actTable$ID_IND[i],
                                         as.integer(actTable$NACT[i]+1),
                                         str_c(actTable$D3[i],"_",actTable$D3[i+1]),
                                         as.character(NA), 
                                         as.character(NA),
                                         actTable$D8[i],
                                         actTable$D4[i+1],
                                         str_c(actTable$ACT[i],actTable$ACT[i+1]), 
                                         N_DEP,
                                         str_c(actTable$ID_IND[i],"_",as.character(N_DEP)),
                                         actTable$MODE_D[i])
      
      actTable$NACT[i+1] <- actTable$NACT[i+1]+ N_DEP
      N_DEP <- N_DEP+1
      
      
    } 
  }
  
  #Trier les donnes
  actTable <- actTable[order(actTable$ID_IND,actTable$NACT),]
  
  return(actTable)
}

# --------- 6 Fonction adnMobilite --------- 
# Creation des ADN Mobilite en utilisant un DataFrame type adnTable.RDS 

# Inputs : adnTable  
# Outputs : ADN_M; Chaque ligne represente une personne avec un ID_PER et une chaine de 1440 caracteres (24hx60min)
 
adnMobilite <- function(adnTable) {
  
  
  #Creation du data frame l'ADN mobilite vide
  col.Classes <-  c("character", "vector")
  col.names <- c("ID_IND", "ADN")
  ADN_M <- read.table(text = "",
                      colClasses = col.Classes,
                      col.names = col.names)
  
  # Variables Auxiliaires
  chan_per <- FALSE
  dim_DB <- dim(adnTable)
  minutes <- 0
  ADN_A <- ""
  
  for (i in 1:(dim_DB[1])){
    
    
    #Verifier changement de personne
    chan_per <- adnTable[i,"ID_IND"] != adnTable[i+1,"ID_IND"]
    
    # Traitement si deplacement
    if(is.na(adnTable[i,"MODE"]) == F){
      
      #Temps du deplacement
      #Calcul de la duree en minutes
      minutes <- (as.integer(substr(adnTable[i,"D8"],1,2)) -
                    as.integer(substr(adnTable[i,"D4"],1,2)))*60 +
        as.integer(substr(adnTable[i,"D8"],3,4)) -
        as.integer(substr(adnTable[i,"D4"],3,4))
      
      ADN_A <- paste(ADN_A, strrep(paste(adnTable[i,"MODE"],"_",sep=""),minutes), sep="")
      
      minutes <- 0
      
    } else {
      
      # Temps de l'activite
      # Calcul de la duree en minutes
      minutes <- (as.integer(substr(adnTable[i,"D8"],1,2)) -
                    as.integer(substr(adnTable[i,"D4"],1,2)))*60 +
        as.integer(substr(adnTable[i,"D8"],3,4)) -
        as.integer(substr(adnTable[i,"D4"],3,4))
      
      ADN_A <- paste(ADN_A, strrep(paste(adnTable[i,"MOTIF"],"_",sep=""),minutes), sep="")
      minutes <- 0
      
    }
    
    # Traitement derniere activite
    if (chan_per | (dim_DB[1])==i){
      
      ADN_M[nrow(ADN_M)+1,] = c(adnTable[i,"ID_IND"], ADN_A)
      ADN_A <- ""
      chan_per <- FALSE
      
    } 
    
  }
  
  # Si besoin, verifier si les ADN ont la meme taille 2880
  for (i in 1:184){
    if(nchar(ADN_M$ADN[i]) != 2880) {

      print(nchar(ADN_M$ADN[i]))
      print(i)
    }
  }
  
  #Chaque collone correspond a 1 minute
  ADN_M <- ADN_M %>% 
    separate(ADN, as.character(c(1:1441)), sep="_") %>% 
    select(-("1441"))
  
  print("Voila")
  return(ADN_M)
  
}

# --------- 7 Fonction ctimenames() ---------
# Creation des labels "pas de temps" pour chaque minute d'une journee pour aider la visualisation des ADN_Mobilite
# Output: Labels Pas de temps (label des colonnes de 04:00 jusqu'a 27:59, 04:00 du jour suivant)

ctimenames <- function() {
  
  minutes = c()
  
  for (i in 4:27) {
    
    if (i < 10) {
      HOUR = paste("0", as.character(i), sep = "")
    } else {
      HOUR = as.character(i)
    }
    
    for (j in 0:59) {
      
      if (j < 10) {
        MIN = paste("0", as.character(j), sep = "")
      } else {
        MIN = as.character(j)
      }
      minutes[(length(minutes)+1)] = paste(HOUR, MIN, sep = ":")
    }
  }
  
  return(minutes)
  
}

# --------- 8 Fonction seqtimestep() --------
# Definir un nouveau pas de temps pour les ADN_M; desagreger les donnnes de la sequence
# Input : sequece ADN_M et le pas de temps
# Output : nouvelle seauence ADN_M
# Algo: Définition des temps de pivotement selon le pas de temps demandé. Modification de l'état du temps de pivotement en fonction de l'activité ou du déplacement le plus présent dans l'intervalle donné.
# Sélection des temps de pivotement déjà modifiés

seqtimestep <- function(adnseq, tstep = 15) {
  
  # Creation des temps pivot
  alltpivot <- seq(1, ncol(adnseq), tstep)
  
  # For loop: aggregate data for each time step
  for (tpivot in alltpivot) {
    
    # State frequencies in each individual sequence
    freqindseq <- seqistatd(adnseq[ , tpivot:(tpivot+(tstep-1))])
    
    # For each row return the column name of the largest value
    statetstep <- colnames(freqindseq)[max.col(freqindseq,ties.method="first")]
    
    # Reset pivot time
    adnseq[,tpivot] = statetstep
  }
  
  # Select all pivot times
  adnseq <- adnseq[,alltpivot]
  return(adnseq)
  
}


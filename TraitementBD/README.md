# Comment utiliser l'alphabet ?
L'alphabet est un tableau qui contient des informations non seulement pour traiter les données de l'EMD mais aussi pour lister les caractéristiques et les covariables utilisées lors des analyses. En ce qui concerne le traitement, il indique comment les variables déctrites dans le fichier "Dessin de Variables" de l'EMD sont regroupées. Des alphabets différesnts, des regroupements différents, donc des résultats différents. Son but est de rendre plus simple la structuration d'un étude.

Consignes d'utilisation:
- La "classe" indique le nom de la nouvelle variable
- L'"alphabet" indique les valeurs de la "classe" en question
- La "codification" indique les variables de l'EMD qui apartiennent au groupe ("classe"+"alphabet") en question
- Pour regrouper plusieurs valeurs, il sufit d'utiliser "_" en separant les éléments de codification (e.g. "04_05_06")
- La lettre "N" en tant que codification indique que le groupe en question est traité directement sur le code
- Pour indiquer que l'élément vide " " appartient à la codification, il sufit d'ajouter un tiret bas à la fin de la codification (e.g. "01_")

**Attention**: la lecture automatique de l'Excel des fichiers .csv ne reconnait pas les élements type string qui commencent par zero quant ils sont seules dans une cellule, elle les efface (e.g. string "01" dans le fichier .csv devient intier "1" sur Excel). 

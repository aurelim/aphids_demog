import os
import sys

# ClassI:LINE
# ClassI:SINE
# ClassI:LTR
# ClassII:Helitron
# ClassII:Maverick
# ClassII:Sola
# ClassII:TIR

species = sys.argv[1]
TE_type = sys.argv[2]


path = f"../data/{species}/"

gff_file = path + f"{species}_refTEs.gff"
fichier_sortie = path + f"{species}_{TE_type}.gff3"

# open gff file, read mode, open output file , write mode
with open(gff_file, 'r') as fichier_entree, open(fichier_sortie, 'w') as sortie:
    # Loop through each line of the file
    for ligne in fichier_entree:
        # Ignore empty lines or comments starting with "#"
        if not ligne.strip() or ligne.startswith('#'):
            continue
        # Split lines in columns
        colonnes = ligne.strip().split('\t')
        # get TargetDescription attribut
        attributs = colonnes[8].split(';')
        target_description = None
        for attribut in attributs:
            if attribut.startswith('TargetDescription='):
                target_description = attribut.split('=')[1]
                break
        # filter rows according to the TargetDescription attribut
        if target_description is not None:
            # insert here the filtering condition
            if TE_type in target_description:
                # write filtered rows
                sortie.write(ligne)

print("filtering completed. The filtered lines were written to", fichier_sortie)

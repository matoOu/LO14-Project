#!/bin/bash

# Si le nombre d'argument n'est pas bon, il fait un echo à l'écran sous la forme souhaitée
if [ $# -ne 3 -a $# -ne 4 ]; then
	echo "Usage : vsh -mode serveur_name port [name_archive]"
	exit
fi
firstsuffixe="\\"
suffixe=$firstsuffixe
precsuffixe=$suffixe


function changedir {
    option=$(echo $commandwithoption | cut -d' ' -f2)
    #Si il n'y a pas d'option, il faut contourner cut qui donne "cd" pour valeur à option
    #comme c'est "cd" tout seul on revient alors à la racine
    if [ "$option" == "$command" ];
    then
	precsuffixe=$suffixe
	suffixe=$firstsuffixe
	directory="$prefixe$suffixe"
	return
    fi
    #On enlève tous les backslash à la fin du nom
    while [ "${option:$((-1))}" == "\\" ]
    do
	option=${option::-1}
    done
    #Si option est vide le chemin était du type "\\\\\\..."
    #C'est donc un cd tout seul
    if [ "$option" == "" ];
    then
	precsuffixe=$suffixe
	suffixe=$firstsuffixe
	directory="$prefixe$suffixe"
	return
    fi	   
    #Si l'option est "-" on rétablit le prédédent suffixe
    if [ "$option" == "-" ];
    then
	suffixetemp=$suffixe
	suffixe=$precsuffixe
	precsuffixe=$suffixetemp
	directory="$prefixe$suffixe"
	return
    fi
    #Si l'option est exactement ".." on remonte d'un répertoire
    doubledot=".."
    if [ "$option" == "$doubledot" ];
    then
       precsuffixe=$suffixe
       suffixe=$(echo "$suffixe" | rev | cut -d'\' -f2- | rev)
       #malheureusement si suffixe = "\" la chaîne devient vide
       if [ "$suffixe" == "" ];
       then
	   suffixe=$firstsuffixe
	   directory="$prefixe$suffixe"
       fi
       directory="$prefixe$suffixe"
       return
       #Si l'option commence par ".." on remonte d'un répertoire.
       #On fait ça, autant de ..\.. qu'il y aura.
    else
	while [[ "$option" =~ ^\.\. ]]
	do
	    suffixe=$(echo "$suffixe" | rev | cut -d'\' -f2- | rev)
	    option="${option:3}"	
	done
    fi
    # Si le chemin est absolu (il commence par "\")
    if [[ $option =~ ^\\+ ]];
    then
	suffixetemp=$option
	# Si le chemin est relatif
    else
	if [ "$suffixe" == "$firstsuffixe" ];
	then
	    suffixetemp="$suffixe$option"
	else
	    suffixetemp="$suffixe\\$option"
	fi
    fi
    directory="$prefixe$suffixetemp"
    #Pour savoir si le directory existe, if faut tenir compte du fait que "\"
    #est un caractère d'échappement
    recherchedirectory=$(echo $directory | sed 's/\\/\\\\/g')
    if grep  -q "$recherchedirectory" $archive; 
    then
	precsuffixe=$suffixe
	suffixe=$suffixetemp
	directory="$prefixe$suffixe"
    else
	echo "Directory does not exist!"
    fi
}


function listefichiers {
    backdirectory=$directory
    option=$(echo $commandwithoption | cut -d' ' -f2)
    affichage=""
    doubledot=".."
    #On change la variable directory si un nouveau repertoire est donne
    if [[ $option =~ ^- ]];
    then
	ajoutdir=$(echo $commandwithoption | cut -d' ' -f3)
    else
	ajoutdir=$(echo $commandwithoption | cut -d' ' -f2)
	#Cela semble idiot, mais ça permet d'unifier avec cut qui donne "ls" pour valeur à option
	#si il n'y a pas d'option
	option="ls"
    fi
    #Si il y a un repertoire de specifier
    if [[ "$ajoutdir" != "" && "$ajoutdir" != "ls" ]]; 
    then
	#On enlève tous les backslash à la fin du nom
	while [ "${ajoutdir:$((-1))}" == "\\" ]
	do
	    ajoutdir=${ajoutdir::-1}
	done
	#Si l'ajoutdir est exactement ".." on remonte d'un répertoire
	if [ "$ajoutdir" == "$doubledot" ];
	then
	    suffixetemp=$(echo "$suffixe" | rev | cut -d'\' -f2- | rev)
	    #malheureusement si suffixe = "\" la chaîne devient vide
	    if [ "$suffixetemp" == "" ];
	    then
		suffixetemp=$firstsuffixe
	    fi
	    directory="$prefixe$suffixetemp"
	else
	# Si le chemin est absolu (il commence par "\")
	    if [[ $ajoutdir =~ ^\\+ ]];
	    then
		suffixetemp=$ajoutdir
		# Si le chemin est relatif
		# Si ajoutdir commence par ".." on remonte d'un répertoire.
		#On fait ça, autant de ..\.. qu'il y aura.
	    else
		suffixels=$suffixe
		while [[ "$ajoutdir" =~ ^\.\. ]]
		do
		    suffixels=$(echo "$suffixels" | rev | cut -d'\' -f2- | rev)
		    ajoutdir="${ajoutdir:3}"	
		done
		if [ "$suffixels" == "$firstsuffixe" ];
		then
		    suffixetemp="$suffixels$ajoutdir"
		else
		    suffixetemp="$suffixels\\$ajoutdir"
		fi
	    fi
	    directory="$prefixe$suffixetemp"
	fi
    fi
    recherchedirectory=$(echo $directory | sed 's/\\/\\\\/g')
    if  ! grep  -q "$recherchedirectory" $archive;
    then
	echo le repertoire n\'existe pas
	directory=$backdirectory
	return
    fi
    case $option in 
	ls)
	    index=0
	    while read -r direc cheminarch
	    do
		if [ "$cheminarch" == "$directory" ];
		then
		    while read -r temporaire
		    do
			if [ "$temporaire" != "@" ];
			then
			    fichiertemp=$(echo $temporaire | cut -d' ' -f1)
			    if [ "${fichiertemp:0:1}" != "." ];
			    then
				typetemp=$(echo $temporaire | cut -d' ' -f2)
				if [[ "$typetemp" =~ ^d ]];
				then
				    fichiertemp=$fichiertemp"\\"
				else
				    if [[ "$typetemp" =~ x ]];
				    then
					fichiertemp=$fichiertemp"*"
				    fi
				fi
				affichage=$affichage" "$fichiertemp
			    fi
			else
			    break
			fi
		    done
		fi
	    done < $archive
	    echo $affichage
	    directory=$backdirectory
	    return
	    ;;
	-la|-al)
	    index=0
	    while read -r direc cheminarch
	    do
		if [ "$cheminarch" == "$directory" ];
		then
		    while read -r temporaire
		    do
			if [ "$temporaire" != "@" ];
			then
			    fichiertemp=$(echo $temporaire | cut -d' ' -f1)
			    typetemp=$(echo $temporaire | cut -d' ' -f2)
			    tailletemp=$(echo $temporaire | cut -d' ' -f3)
			    affichage=$typetemp" "$tailletemp" "$fichiertemp
			    echo $affichage
			else
			    break
			fi
		    done
		    directory=$backdirectory
		    return
		fi
	    done < $archive
	    ;;
	-l)
	    	    index=0
	    while read -r direc cheminarch
	    do
		if [ "$cheminarch" == "$directory" ];
		then
		    while read -r temporaire
		    do
			if [ "$temporaire" != "@" ];
			then
			    fichiertemp=$(echo $temporaire | cut -d' ' -f1)
			    if [ "${fichiertemp:0:1}" != "." ];
			    then
				typetemp=$(echo $temporaire | cut -d' ' -f2)
				tailletemp=$(echo $temporaire | cut -d' ' -f3)
				affichage=$typetemp" "$tailletemp" "$fichiertemp
				echo $affichage
			    fi
			else
			    break
			fi
		    done
		    directory=$backdirectory
		    return
		fi
	    done < $archive
	    ;;
	-a)
	    while read -r direc cheminarch
	    do
		if [ "$cheminarch" == "$directory" ];
		then
		    while read -r temporaire
		    do
			if [ "$temporaire" != "@" ];
			then
			    fichiertemp=$(echo $temporaire | cut -d' ' -f1)
			    typetemp=$(echo $temporaire | cut -d' ' -f2)
			    if [[ "$typetemp" =~ ^d ]];
			    then
				fichiertemp=$fichiertemp"\\"
			    else
				if [[ "$typetemp" =~ x ]];
				then
				    fichiertemp=$fichiertemp"*"
				fi
			    fi
			    affichage=$affichage" "$fichiertemp  
			else
			    break
			fi
		    done
		fi
	    done < $archive
	    echo $affichage
	    directory=$backdirectory
	    return
	    ;;
	*)
	    ;;
esac
}



function browse {
    while read -p "vsh:>" -r commandwithoption
    do
	command=$(echo $commandwithoption | cut -d' ' -f1)
	case $command in
	    pwd)
		echo "$suffixe"
		;;
	    cd)
		changedir
		;;
	    ls)
		listefichiers
		;;
	    exit)
		exit
		;;
	    *)
		echo $command
		;;
	esac
    done
}


function convertdroit {
    local chainedroit=$1
    local locali
    local localj
    local localcaract
    local localdeb
    localcode=0
    for ((locali=0 ; 3-$locali ; locali++))
    do
	localdeb=$((3*$locali))
	localcaract=${chainedroit:$localdeb:1}
#	echo $localcaract
	if [ $localcaract == "r" ];
	then
	    ((localcode+=4))
#	    echo $localcode 
	fi
	((localdeb++))
	localcaract=${chainedroit:$localdeb:1}
#	echo $localcaract
	if [ $localcaract == "w" ];
	then
	    ((localcode+=2))
#	    echo $localcode 
	fi	
	((localdeb++))
	localcaract=${chainedroit:$localdeb:1}
#	echo $localcaract
	if [ $localcaract == "x" ];
	then
	    ((localcode+=1))
#	    echo $localcode 
	fi
	((localcode*=10))	
    done
    ((localcode/=10))
    return 
}



function extractsousrep {
    local replocal=$1
    local newreplocal
    local entetelocal
    local cheminlocal
    local temporairelocal
    local fichierlocal
    local typelocal
    local replinuxlocal
    local newreplinuxlocal
    local beginfilelocal
    local endfilelocal
    local addfilelocal
    local essailocal
    local localk
    local fichierlinuxlocal
    local localdroits
    while read -r entetelocal cheminlocal
    do
	if [ "$cheminlocal" == "$replocal" ];
	then
	    #On enlève l eventuel backslash à la fin de replocal
	    if [ "${replocal:$((-1))}" == "\\" ];
	    then
		replocal=${replocal::-1}
	    fi
	    replinuxlocal=$(echo $replocal | sed 's/\\/\//g')
	    replinuxlocal=$replinuxlocal"/"
	    while read -r temporairelocal
	    do
		if [ "$temporairelocal" != "@" ];
		then
		    fichierlocal=$(echo $temporairelocal | cut -d' ' -f1)
		    typelocal=$(echo $temporairelocal | cut -d' ' -f2)
		    sizelocal=$(echo $temporairelocal | cut -d' ' -f3)
		    if [[ "$typelocal" =~ ^d ]];
		    then
			newreplocal=$replocal"\\"$fichierlocal
			newreplinuxlocal=$(echo $newreplocal | sed 's/\\/\//g')
			mkdir $newreplinuxlocal
			localdroits=${typelocal:1}
			convertdroit $localdroits
			chmod $localcode $newreplinuxlocal
			extractsousrep $newreplocal
		    else
			fichierlinuxlocal=$replinuxlocal$fichierlocal
			touch $fichierlinuxlocal
			localdroits=${typelocal:1}
			convertdroit $localdroits
			chmod $localcode $fichierlinuxlocal
			if [ $sizelocal -gt 0 ];
			then
			    beginfilelocal=$(echo $temporairelocal | cut -d' ' -f4)
			    ((beginfilelocal = $beginfilelocal + $beginbody -1))
			    addfilelocal=$(echo $temporairelocal | cut -d' ' -f5)
			    ((endfilelocal = $beginfilelocal + $addfilelocal))
			    for ((localk=$beginfilelocal ; $endfilelocal-$localk ; localk++))
			    do
				essailocal=$(awk 'NR == '$localk'{print}' $archive)
				echo $essailocal >> $fichierlinuxlocal
			    done
			fi
		    fi
		else
		    break
		fi
	    done    
	fi
    done< $archive
    }

function extraction {
    indexation=1
    while read -r ligne
    do
	if [ $indexation -lt $beginhead ];
	then
	    ((indexation++))
	    continue
	fi
	repertoire=$(echo $ligne | cut -d' ' -f2)
	#On vire de suite le backslash qui fait chier
	#car c'est un caractère d'echappement
	repertoirelinux=$(echo $repertoire | sed 's/\\/\//g')
	#Calcul du nombre de sous repertoires
	nbsousrep=$(echo $repertoirelinux | awk -F/ '{print NF}')
	#Le premier a un backslash en trop a la fin
	#Mais ca m\'arrange pour la boucle for
	debutrepertoire=$(echo $repertoirelinux | cut -d'/' -f1)
	mkdir $debutrepertoire
	for ((i=2 ; $nbsousrep - $i ; i++))
	do
	    debutrepertoire=$debutrepertoire"/"$(echo $repertoirelinux | cut -d'/' -f$i)
	    mkdir $debutrepertoire
	done
	break
    done< $archive
    extractsousrep $repertoire
    }





case $1 in

    -list)
	echo mode list
	;;
    -create)
	echo mode create
	;;
    -browse)
	#Puisque les fichiers sont créés par le mode create, si ils existent il sont au bon format
	if [[ -e $4 ]]; then
	    firstline=$(head -n 1 $4)
	    beginhead=$(echo $firstline | cut -d':' -f1)
	    beginbody=$(echo $firstline | cut -d':' -f2)
	    prefixe=$(awk 'NR == '$beginhead' {print $2}' $4)
	    prefixe=${prefixe::-1}
	    archive=$4
	    directory=$prefixe$firstsuffixe
	else
	    echo archive does not exist
	    exit
	fi
	browse
	;;
    -extract)
	if [[ -e $4 ]]; then
	    firstline=$(head -n 1 $4)
	    beginhead=$(echo $firstline | cut -d':' -f1)
	    beginbody=$(echo $firstline | cut -d':' -f2)
	    archive=$4
	else
	    echo archive does not exist
	    exit
	fi
	extraction
	;;    
    *)
	echo no mode found
	;;
esac	

#!/bin/bash


require() {
# require v0.1
# asks the user for installing a package installation by any means, if possible through gksudo

package=$1 # le nom du package
message=$2 # pour expliquer que l'on veut installer quelquechose et pourquoi

if [ -n `which gksudo` ]
then
	if test -n "$message"
	then
		gksudo --message "$message" "apt-get install $package"
	else   
	       	gksudo --message "Un programme veut installer le package : $package" "apt-get install $package"
	fi
else # defaults to sudo
	if test -n "$message"
	then
		echo $message
	else
		echo Un programme souhaite installer "$package"
	fi

	sudo "apt-get install $package"
fi

}


rebooter() { 
   gksudo -m "Redémarrage du poste" 'shutdown -r now'    
}

TITLEOPTION='--title xfce4-rescue'

# Recherche l'espace disque de la partition du home directory
ed=`df | grep "$HOME$" | awk '{print $4}' `
if test -z "$ed" 
then ed=`df | grep '/home$' | awk '{print $4}' `
fi
if test -z "$ed" 
then ed=`df | grep '/$' | awk '{print $4}' `
fi

echo espacedisque=${ed} ko
warning=5000000 # exprimé en kilo-octets.
             # =5000, en dessous de 5Mo, il faut faire de la place

if [[ "$ed" -lt "$warning" ]]
then
    if which zenity
    then
	zenity $TITLEOPTION --question --text="votre partition systeme manque de place, ce qui entraine souvent des problemes d'affichage. 

Ci-dessous les 3 dossiers les plus volumineux de votre espace personnel :
`cd ~; du --max-depth=1 2> /dev/null| sort -n | tail -n 4 | sed 's|\t\.$|\tTOTAL|' | sed 's|^\([0-9]\)\([0-9]\)[0-9]\{5\}|\1,\2Go|g' | sed 's|^\([0-9]\{1,3\}\)[0-9]\{3\}|\1Mo|g' | sed "s|\([0-9]\)\t|\1ko\t|"; cd -`


Faites de la place dans $HOME puis choisissez OUI pour rebooter.
Choisissez NON pour tester d'autres solutions."

     if test "$?" = 0; 
     then rebooter;
     fi
   else 
     echo "votre partition systeme manque de place, ce qui entraine souvent des problemes d'affichage. 

Ci-dessous les 3 dossiers les plus volumineux de votre espace personnel :"
cd ~; du --max-depth=1 2> /dev/null | sort -n | tail -n 4 | sed 's|\t\.$|\tTOTAL|' | sed 's|^\([0-9]\)\([0-9]\)[0-9]\{5\}|\1,\2Go|g' | sed 's|^\([0-9]\{1,3\}\)[0-9]\{3\}|\1Mo|g' | sed "s|\([0-9]\)\t|\1ko\t|"; cd -
echo "Faites de la place dans $HOME, puis répondez à la question ci-dessous.

Souhaitez-vous rebooter? (o/N)";
read x
     if test "$x" = "o" -o "$x" = "O"; 
     then rebooter;
     fi
   fi
fi



#######################
# On a de la place en théorie maintenant, on peut se permettre d'installer zenity
#

if ! which zenity 2> /dev/null
then
    require zenity "Bonjour, ce programme nécessite le package zenity pour fonctionner, m'autorisez-vous à l'installer?"
fi
 
if ! which zenity 2> /dev/null
then
    echo "Ce programme ne fonctionne pas sans zenity"
    echo "ARRET du PROGRAMME"
    exit;
fi

zenity $TITLEOPTION --question --text="Si vous avez perdu l'affichage de votre Bureau (icones &amp; fond d'écran), nous pouvons tenter une réinstallation de xfdesktop4

Voulez-vous essayer ?"
if [[ "$?" = 0 ]] 
then
    echo apt-get install xfdesktop4
    xterm -title "installation de xfdesktop4" -e "sudo apt-get install xfdesktop4; echo ' 
Appuyez sur ENTREE pour finir.'; read"
fi

zenity $TITLEOPTION --question --text="Nous pouvons également tenter d'effacer les informations de session.

Attention, la configuration de démarrage de session sera oubliée : disposition des fenêtres, sites et dossiers ouverts...

Souhaitez-vous essayer? "
if test "$?" = 0; then
    echo rm -r ~/.cache/sessions/*
    rm -r ~/.cache/sessions/*
   # rm -r ~/.config/xfce4* c'est trop vache on perd la config
fi


zenity $TITLEOPTION --question --text="A présent, nous vous conseillons de rebooter votre ordinateur."
if test "$?" = 0; then rebooter;
fi






# a faire en dernier car ca termine le script.


zenity --question --text="Enfin, si le problème n'est toujours pas résolu, nous allons redémarrer l'affichage du bureau (xfce4-panel)

Voulez-vous le faire ?"
if test "$?" = 0; then
    echo "xfce4-panel -r # relancer le tableau de bord xfce (les barres en haut et en bas"
    xfce4-panel -r

    echo "xfwm4 --replace # relancer le gestionnaire de fenêtres"
    xfwm4 --replace
fi


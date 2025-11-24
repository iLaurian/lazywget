#!/bin/bash


# ROMANA
### PRIMA RULARE ----------------
# creeaza folder cu adresa site-ului
# foloseste wget si descarca fisierul trimis ca argument ($1)
# scaneaza fisierul pentru atributele href/src/ TODO: verifica daca mai exista si altele
# pentru linkuri relative, adauga ca prefix adresa site-ului 
# intr-un fisier numit promises.txt, adauga linkurile gasite (LA SFARSIT)
# die :(

### Nth RULARE ----------------
# citeste linkurile din promises.txt
# pentru fiecare link, fa exact acelasi lucru de la prima rulare
#?TODO:? wget -r cum face? genereaza subfoldere? testeaza maine pe un site si discuta cu Laurian
# sterge linia din promises.txt 
# dupa ce ai facut toate liniile, die again :(


# ENGLISH
### FIRST RUN ----------------
# create folder with the name set as the website url
# use wget to download the website sent as an argument ($1)
# scan the downloaded file for attributes such as href/src/ TODO: check if there are more attributes that specify resources
# for relative links, add the website url as the prefix
# in a file named promises.txt, add the found resources links (AT THE END!!)
# die :(

### Nth RUN ----------------
# read the resources links line by line from promises.txt
#?TODO:? how does wget -r work? does it generate subfolders? I will test this tommorrow on a website and I will discuss with Laurian
# delete the first line of promises.txt
# die again at the end :(
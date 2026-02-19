#!/bin/bash

echo "=============================="
echo "   STRUTTURA PROGETTO JAVA"
echo "=============================="
echo ""

# Controllo se esiste tree
if command -v tree &> /dev/null
then
    echo "Uso TREE:"
    echo ""
    tree -L 4
else
    echo "TREE non installato, uso FIND:"
    echo ""
    find . -type d -maxdepth 4 | sed 's/[^-][^\/]*\//  /g;s/\//|/'
fi

echo ""
echo "=============================="
echo "   STRUTTURA FILE JAVA"
echo "=============================="
echo ""

find . -name "*.java"

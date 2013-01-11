#!/bin/bash

wget -O input/books-collector.csv https://dl.dropbox.com/u/15558282/books.txt
wget -O input/books-calibre.csv https://dl.dropbox.com/u/15558282/books/calibre.csv

./books.py input/books-collector.csv input/books-calibre.csv .

echo

make

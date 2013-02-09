INPUT_FILES = input/books-collector.csv input/books-calibre.csv
OUTPUT_FILES = $(wildcard library-data/*/*.json)
SCRIPTS = scripts/library.js

update: library-data/stamp

all: fetch update $(SCRIPTS)

fetch:
	wget -O input/books-collector.csv https://dl.dropbox.com/u/15558282/books.txt
	wget -O input/books-calibre.csv https://dl.dropbox.com/u/15558282/books/calibre.csv

library-data/stamp: $(INPUT_FILES)
	touch library-data/stamp
	python -OO books.py $(INPUT_FILES) .

clean:
	@rm -f $(INPUT_FILES)
	@rm -f $(OUTPUT_FILES)
	@rm -f $(SCRIPTS)

%.js: %.coffee
	/data/settlers/osadnici/tools/coffee-compile.py $< > $@

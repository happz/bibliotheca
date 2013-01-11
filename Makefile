SCRIPTS = library-data/authors.js library-data/genres.js library-data/publishers.js library-data/series.js library-data/subjects.js library-data/tags.js library-data/formats.js \
          library-data/books.js \
          scripts/library.js

all: $(SCRIPTS)

%.js: %.coffee
	/data/settlers/osadnici/tools/coffee-compile.py $< | slimit > $@

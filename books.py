#!/usr/bin/python2.7

import codecs
import collections
import hashlib
import json
import locale
import mako.exceptions
import mako.lookup
import mako.template
import os
import os.path
import pprint
import sys
import traceback
import types
import urllib

locale.setlocale(locale.LC_ALL, 'cs_CZ.UTF-8')

workdir = os.path.dirname(sys.argv[0])

def uid(s):
  return hashlib.md5(s.encode('ascii', 'replace')).hexdigest()

BookRecord = collections.namedtuple('BookRecord', ['authors', 'title', 'publication_year', 'publishers', 'ISBN', 'front_cover', 'genres', 'issue', 'mtime', 'rating', 'notes', 'series', 'subtitle', 'subjects', 'tags', 'plot', 'formats', 'download_prefix'])
Format = collections.namedtuple('Format', ['uid', 'name', 'books'])

class Parser(object):
  def check_br_field(self, kwargs, br, name, fn):
    val = getattr(br, name).strip()

    if len(val) > 0:
      kwargs[name] = fn(val) if fn else val

  def parse_multifield(self, values, constructor, data):
    parsed_values = []

    for entry_name in data.split(';'):
      entry_name = entry_name.strip()
      if entry_name not in values:
        values[entry_name] = constructor(entry_name)

      parsed_values.append(values[entry_name])

    return parsed_values

  def split_line(self, line):
    return None

  def parse_record(self, br, kwargs):
    self.check_br_field(kwargs, br, 'authors', lambda v: self.parse_multifield(AUTHORS, lambda name: Author(name = name), v))
    self.check_br_field(kwargs, br, 'title', unicode)
    self.check_br_field(kwargs, br, 'publication_year', int)
    self.check_br_field(kwargs, br, 'publishers', lambda v: self.parse_multifield(PUBLISHERS, lambda name: Publisher(name = name), v))
    self.check_br_field(kwargs, br, 'ISBN', unicode)
    self.check_br_field(kwargs, br, 'front_cover', unicode)
    self.check_br_field(kwargs, br, 'genres', lambda v: self.parse_multifield(GENRES, lambda name: Genre(name = name), v))
    self.check_br_field(kwargs, br, 'issue', int)
    self.check_br_field(kwargs, br, 'mtime', unicode)
    self.check_br_field(kwargs, br, 'rating', unicode)
    self.check_br_field(kwargs, br, 'notes', unicode)
    self.check_br_field(kwargs, br, 'series', lambda v: self.parse_multifield(SERIES, lambda name: Serie(name = name), v))
    self.check_br_field(kwargs, br, 'subtitle', unicode)
    self.check_br_field(kwargs, br, 'subjects', lambda v: self.parse_multifield(SUBJECTS, lambda name: Subject(name = name), v))
    self.check_br_field(kwargs, br, 'tags', lambda v: self.parse_multifield(TAGS, lambda name: Tag(name = name), v))
    self.check_br_field(kwargs, br, 'plot', unicode)
    self.check_br_field(kwargs, br, 'formats', lambda v: [FORMATS[e.strip()] for e in v.split(',')])
    self.check_br_field(kwargs, br, 'download_prefix', unicode)

  def update_book(self, record, book):
    pass

class ParserCalibre(Parser):
  def split_line(self, line):
    l1 = line.split('"')
    l2 = [l1[i] for i in range(1, len(l1) - 1, 2)]

    if len(l2[0]) > 0 and l2[0][-1] == '.':
      l2[0] = l2[0][:-1] + u'_'

    title = l2[14]
    if title.startswith('The '):
      title = title[4:] + u', The'

    l2.append('https://dl.dropbox.com/u/15558282/books/' + urllib.quote(title.encode('utf8')) + '%20-%20' + urllib.quote(l2[0].encode('utf8')))

    if len(l2[1]) > 0:
      src = l2[1].split(',')
      l2[1] = '; '.join([src[i].strip() + ', ' + src[i + 1].strip() for i in range(0, len(src) - 1, 2)])

    l2[3] = l2[18] + '.jpg'

    if len(l2[6]) > 0:
      l2[6] = l2[6].split('-')[0]
      if int(l2[6]) < 1000:
        l2[6] = ''

    if len(l2[9]) <= 0:
      l2[10] = ''

    if len(l2[10]) > 0:
      l2[10] = l2[10].split('.')[0]

    if len(l2[15]) > 0:
      l2[15] = ';'.join(eval(l2[15]))

    # 'authors', 'title', 'publication_year', 'publishers', 'ISBN', 'front_cover', 'genres', 'issue', 'mtime', 'rating', 'notes', 'series', 'subtitle', 'subjects', 'tags', 'plot', 'formats', 'download_prefix'
    # author_sort,authors,comments,cover,formats,isbn,pubdate,publisher,rating,series,series_index,size,tags,timestamp,title,#genre,#subject,#subtitle,download_prefix
    # 0           1       2        3     4       5    6       7         8      9      10           11   12   13        14    15     16       17        18
    return BookRecord._make([l2[1], l2[14], l2[6], l2[7], l2[5], l2[3], l2[15], l2[10], l2[13], l2[8], l2[2], l2[9], l2[17], l2[16], '', '', l2[4], l2[18]])

class ParserBookCollector(Parser):
  COVER_PREFIX = 'https://dl.dropbox.com/u/15558282/collectorz-books/Images/'

  def split_line(self, line):
    l1 = [e[1:-1] for e in line.strip().split('\t')] + ['paper']

    l1 += ['']

    if len(l1[5]) > 0:
      l1[5] = ParserBookCollector.COVER_PREFIX + '/' + l1[5].split('\\')[-1]

    return BookRecord._make(l1)

class BaseListObject(object):
  def __init__(self, name = None):
    super(BaseListObject, self).__init__()

    self.name			= unicode(name)
    self.books			= []

    self.uid			= uid(self.name)

class Author(BaseListObject):
  pass

class Publisher(BaseListObject):
  pass

class Genre(BaseListObject):
  pass

class Subject(BaseListObject):
  pass

class Tag(BaseListObject):
  pass

class Serie(BaseListObject):
  pass

class Book(object):
  FORMAT_PAPER			= 1
  FORMAT_MOBI			= 2
  FORMAT_EPUB			= 3

  def __init__(self, authors = None, title = None, subtitle = None, publishers = None, publication_year = None, ISBN = None, genres = None, subjects = None,
               series = None, issue = None, tags = None, notes = None, mtime = None, rating = None, front_cover = None, plot = None, formats = None, download_prefix = None):
    super(Book, self).__init__()

    self.authors		= authors

    self.title			= title
    self.subtitle		= subtitle

    self.ISBN			= ISBN

    self.publishers		= publishers
    self.publication_year	= publication_year

    self.genres			= genres
    self.subjects		= subjects
    self.tags			= tags

    self.series			= series
    self.issue			= issue

    self.notes			= notes
    self.rating			= rating

    self.mtime			= mtime

    self.front_cover		= front_cover.split('\\')[-1] if front_cover else None

    self.plot			= plot

    self.uid			= uid('/'.join([author.name for author in self.authors]) + ' - ' + self.title + ' - ' + '/'.join([serie.name for serie in self.series] if self.series else []) + ' - ' + str(self.issue))

    self.formats		= formats
    self.download_prefix	= download_prefix

  def __repr__(self):
    return '<Book(authors=%s, title=%s, subtitle=%s, series=%s, issue=%s, uid=%s)>' % (self.authors, self.title, self.subtitle, self.series, self.issue, self.uid)

AUTHORS		= {}
PUBLISHERS	= {}
GENRES		= {}
SUBJECTS	= {}
TAGS		= {}
SERIES		= {}

FORMATS		= {
  'paper':			Format._make(['paper', u'Paper', []]),
  'pdf':			Format._make(['pdf', u'PDF', []]),
  'mobi':			Format._make(['mobi', u'MOBI (Kindle)', []]),
  'epub':			Format._make(['epub', u'EPUB (iPad)', []]),
  'zip':			Format._make(['zip', u'ZIP', []]),
  'odt':			Format._make(['odt', u'ODT (OpenOffice)', []]),
  'txt':			Format._make(['txt', u'TXT', []]),
  'doc':			Format._make(['doc', u'DOC (MS Office)', []]),
  'docx':			Format._make(['docx', u'DOCX ()', []]),
  'pdb':			Format._make(['pdb', u'PDB ()', []]),
}

FORMATS_HIDDEN = ['zip', 'odt', 'txt', 'doc', 'docx', 'pdb']

BOOKS		= []

def load_data(data_file_path, delimiter = '\t', encoding = 'cp1250', parser = None):
  merged_books = []

  with codecs.open(data_file_path, encoding = encoding) as f:
    i = 0
    first = True

    for line in f:
      i += 1

      # skip first line, headers
      if first:
        first = False
        continue

      try:
        book_record = parser.split_line(line.strip())

      except Exception, e:
        print >> sys.stderr
        print >> sys.stderr, 'Parse error: %s - %i:' % (data_file_path, i)
        print >> sys.stderr
        traceback.print_exc(file = sys.stderr)
        sys.exit(1)

      kwargs = {
        'authors':                  [],  
        'title':                    None,
        'subtitle':                 None,
        'ISBN':                     None,
        'publishers':               None,
        'publication_year':         None,
        'genres':                   [],  
        'subjects':                 [],  
        'tags':                     [],  
        'series':                   None,
        'issue':                    None,
        'notes':                    None,
        'rating':                   None,
        'mtime':                    None,
        'front_cover':              None,
        'plot':                     None,
        'formats':			[],
        'download_prefix':		None
      }

      parser.parse_record(book_record, kwargs)
      new_book = Book(**kwargs)

      found = False
      for book in BOOKS:
        if book.title == new_book.title and book.subtitle == new_book.subtitle and book.issue == new_book.issue and cmp(sorted(book.authors), sorted(new_book.authors)) == 0:
          merged_books.append(new_book)

          found = True
          book.formats += new_book.formats
          book.download_prefix = new_book.download_prefix
          break

      if not found:
        BOOKS.append(new_book)

        for property in ['authors', 'publishers', 'genres', 'subjects', 'tags', 'series', 'formats']:
          entries = getattr(new_book, property)
          if entries != None:
            for entry in entries:
              entry.books.append(new_book)

  print '%i merged books' % len(merged_books)
  for book in sorted(merged_books, key = lambda x: x.title):
    print 'Merged books: "%s" (%s)' % (book.title.encode('ascii', 'replace'), ', '.join([f.uid for f in book.formats]))

def gen_lists(data_dir_path):
  def emit_if_not_none(v):
    if v != None:
      if type(v) in types.StringTypes:
        return '%s' % v.encode('ascii', 'xmlcharrefreplace')
      return '%s' % v
    return None

  def write_index(index_type, entity):
    index = [book.uid for book in entity.books]

    with codecs.open(os.path.join(data_dir_path, 'library-data', index_type, entity.uid + '.json'), 'w', 'utf-8') as f:
      f.write(json.dumps(index))

  def write_indexes(index_type, ls):
    for uid, entity in ls.items():
      write_index(index_type, entity)

  def write_list(list_type, ls):
    list = collections.OrderedDict()

    for uid in sorted(ls.keys(), cmp = locale.strcoll, key = lambda uid: ls[uid].name):
      entry = ls[uid]
      list[entry.uid] = {
        'name':			entry.name.encode('ascii', 'xmlcharrefreplace'),
        'uid':			entry.uid
      }

    with codecs.open(os.path.join(data_dir_path, 'library-data', list_type, 'list.json'), 'w', 'utf-8') as f:
      f.write(json.dumps(list))

  lists = [
    ('author', AUTHORS),
    ('publisher', PUBLISHERS),
    ('genre', GENRES),
    ('subject', SUBJECTS),
    ('tag', TAGS),
    ('serie', SERIES),
    ('format', FORMATS)
  ]

  for index_type, ls in lists:
    write_indexes(index_type, ls)

  for list_type, ls in lists:
    write_list(list_type, ls)

  for book in BOOKS:
    jbook = {
      'uid':			book.uid,
      'title':			emit_if_not_none(book.title),
      'subtitle':		emit_if_not_none(book.subtitle),
      'authors':		[author.uid for author in book.authors],
      'genres':			[genre.uid for genre in book.genres],
      'subjects':		[subject.uid for subject in book.subjects],
      'publishers':		[publisher.uid for publisher in book.publishers] if book.publishers else [],
      'publication_year':	book.publication_year if book.publication_year else None,
      'series':			[serie.uid for serie in book.series] if book.series else None,
      'issue':			emit_if_not_none(book.issue),
      'front_cover':		book.front_cover if book.front_cover else None,
      'formats':		[format.uid for format in book.formats if format.uid not in FORMATS_HIDDEN],
      'download_prefix':	book.download_prefix if book.download_prefix else None
    }

    with codecs.open(os.path.join(data_dir_path, 'library-data/books/' + book.uid + '.json'), 'w', 'utf-8') as f:
      f.write(json.dumps(jbook))

def main():
  load_data(sys.argv[1], encoding = 'cp1250', delimiter = '\t', parser = ParserBookCollector())
  load_data(sys.argv[2], encoding = 'utf-8', delimiter = ',',  parser = ParserCalibre())

  gen_lists(sys.argv[3])

if __name__ == '__main__':
  main()

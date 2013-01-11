<%
  import types

  def emit_if_not_none(v):
    if v != None:
      if type(v) in types.StringTypes:
        return '"%s"' % v.encode('ascii', 'xmlcharrefreplace')
      return '%s' % v
    return 'null'
%>

books =
  % for book in sorted(BOOKS, key = lambda book: book.title):
  "${book.uid}": {
    uid:			"${book.uid}"
    title:			${emit_if_not_none(book.title)}
    subtitle:			${emit_if_not_none(book.subtitle)}
    authors:			[ ${', '.join(['"%s"' % author.uid for author in book.authors])} ]
    genres:			[ ${', '.join(['"%s"' % genre.uid for genre in book.genres])} ]
    subjects:			[ ${', '.join(['"%s"' % subject.uid for subject in book.subjects])} ]
    % if book.publishers:
    publishers:			[ ${', '.join(['"%s"' % publisher.uid for publisher in book.publishers])} ]
    % else:
    publishers:			[]
    % endif
    % if book.publication_year:
    publication_year:		${book.publication_year}
    % else:
    publication_year:		null
    % endif
    % if book.series != None:
    series:			[ ${', '.join(['"%s"' % serie.uid for serie in book.series])} ]
    % else:
    series:			null
    % endif
    issue:			${emit_if_not_none(book.issue)}
    % if book.front_cover:
    front_cover:		"${book.front_cover}"
    % else:
    front_cover:		null
    % endif
    formats:			[ ${', '.join(['"%s"' % format for format in book.formats])} ]
    % if book.download_prefix:
    download_prefix:		"${book.download_prefix}"
    % else:
    download_prefix:		null
    % endif
  }
  % endfor

<%
  import locale
  locale.setlocale(locale.LC_ALL, 'cs_CZ.UTF-8')
%>

% if len(LIST) > 0:
${list_name} =
  % for uid in sorted(LIST.keys(), cmp = locale.strcoll, key = lambda uid: LIST[uid].name):
  <%
    entry = LIST[uid]
  %>
  "${entry.uid}": {
    name:		"${entry.name.encode('ascii', 'xmlcharrefreplace')}"
    uid:		"${entry.uid}"
    books:		[ ${', '.join(['"' + book.uid + '"' for book in entry.books])} ]
  }
  % endfor
% else:
${list_name} = {}
%endif

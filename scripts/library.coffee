window.library = window.library or {}

window.library.current_books = []

class FilterOption
  constructor:			(@name, @list) ->
    @fid = '#filter_' + name + 's'
    @ouid_attr = @name + '-uid'
    @ouid_class = '.' + @name + '-link'
    @list_name = name + 's'

    @filtered_list = null

    $(@fid).html ''
    $(@fid).append ('<option value="' + entry.uid + '">' + entry.name + '</option>') for own uid, entry of @list
    $(@fid).html()

    $(@fid).change () ->
      filter()
      true 

  click:			(event) ->
    o = @list[$(event.currentTarget).attr @ouid_attr]
    $(@fid).val o.uid
    filter()
    false

  bind_click:			() ->
    _option = @
    $(@ouid_class).click (event) ->
      _option.click event
      false

  filter_list:			() ->
    return ($(@fid).val() or [])

  filter_per_book:		(book, list) ->
    if list.length > 0
      book_list = book[@list_name]
      r = intersect book_list, list
      if r.length <= 0
        return false

      return true

class FilterOption_Author extends FilterOption
  constructor:			() ->
    super 'author', authors

class FilterOption_Genre extends FilterOption
  constructor:			() ->
    super 'genre', genres

class FilterOption_Subject extends FilterOption
  constructor:			() ->
    super 'subject', subjects

class FilterOption_Serie extends FilterOption
  constructor:			() ->
    super 'serie', series

  filter_per_book:		(book, list) ->
    if not book.series
      return false

    super book, list

class FilterOption_Publisher extends FilterOption
  constructor:			() ->
    super 'publisher', publishers

class FilterOption_Format extends FilterOption
  constructor:			() ->
    super 'format', formats

book_download_link_list = (book, format, label, icon) ->
  url = book.download_prefix + '.' + format

  '<a href="' + url + '" download-url="' + url + '" target="_blank"><i class="icon-' + icon + ' format-' + format + ' format-download" title="' + label + '" data-placement="top"></i></a>'

book_download_link_info = (book, format, label, icon) ->
  url = book.download_prefix + '.' + format

  '<a href="' + url + '" download-url="' + url + '" target="_blank"><i class="icon-' + icon + ' icon-format-large format-' + format + ' format-download" title="' + label + '" data-placement="top"></i></a>'

book_list_tmpl = doT.template '
  <tr>
    <td><span class="book-title" book-uid="{{= it.uid}}">{{= it.title}}</span></td>
    <td>
      {{~ it.authors :uid:aindex}}
        <span class="author-link" author-uid="{{= uid}}">{{= authors[uid].name}}</span>
      {{~}}
    </td>
    <td>
      {{~ it.genres :uid:aindex}}
        <span class="genre-link" genre-uid="{{= uid}}">{{= genres[uid].name}}</span>
      {{~}}
    </td>
    <td>
      {{~ it.subjects :uid:aindex}}
        <span class="subject-link" subject-uid="{{= uid}}">{{= subjects[uid].name}}</span>
      {{~}}
    </td>
    <td>
      <ul class="unstyled">
        {{~ it.series :uid:aindex}}
          <li>
            <span class="serie-link" serie-uid="{{= uid}}">{{= series[uid].name}}{{? it.issue != null}} - {{= it.issue}}.{{?}}</span>
          </li>
        {{~}}
      </ul>
    </td>
    <td>
      {{~ it.publishers :uid:pindex}}
        <span class="publisher-link" publisher-uid="{{= uid}}">{{= publishers[uid].name}}</span>
      {{~}}
    </td>
    <td>
      {{~ it.formats :format:findex}}
        {{? format == "paper"}}
          <i class="icon-book-alt2" title="Paper" book-uid="{{= it.uid}}" data-placement="top"></i>
        {{?? format == "pdf"}}
          {{= book_download_link_list(it, "pdf", "PDF", "file-pdf")}}
        {{?? format == "mobi"}}
          {{= book_download_link_list(it, "mobi", "Mobi (Kindle)", "tablet")}}
        {{?? format == "epub"}}
          {{= book_download_link_list(it, "epub", "EPUB (iPad)", "tablet")}}
        {{?}}
      {{~}}
    </td>
  </tr>
'

book_info_tmpl = doT.template '
  <div class="modal-header">
    <h3>{{= it.title}}</h3>
  </div>
  <div class="modal-body">
    {{? it.subtitle != null}}
      <h4><i>{{= it.subtitle}}</i></h4>
    {{?}}

    <div class="book-preview">
      {{? it.front_cover != null}}
        <img src="{{= it.front_cover}}" class="img-rounded pull-left book-front-cover" />
      {{?}}

      <div>
        {{~ it.authors :author_uid:index}}
          {{ author = authors[author_uid]; }}
          <span class="author-link" author-uid="{{= author.uid}}">{{= author.name}}</span>
        {{~}}
      </div>

      {{? it.publishers}}
        <div>
          Published by
          {{~ it.publishers :uid:index}}
            <span class="publisher-link" publisher-uid="{{= uid}}">{{= publishers[uid].name}}</span>
          {{~}}
          ({{= it.publication_year}})
        </div>
      {{?}}

      <div>
        <hr />
      </div>

      <div>
        <p></p>
      </div>
    </div>

    <div class="modal-footer">
      <div class="pull-left">
        {{~ it.formats :format:findex}}
          {{? format == "paper"}}
            <i class="icon-book-alt2 icon-format-large" title="Real, paper book" data-placement="top"></i>
          {{?? format == "pdf"}}
            {{= book_download_link_info(it, "pdf", "PDF", "file-pdf")}}
          {{?? format == "mobi"}}
            {{= book_download_link_info(it, "mobi", "MOBI (Kindle)", "tablet")}}
          {{?? format == "epub"}}
            {{= book_download_link_info(it, "epub", "EPUB (iPad)", "tablet")}}
          {{?}}
        {{~}}
      </div>
      <a href="#" class="btn btn-primary btn-close">Close</a>
    </div>
  </div>
'

intersect = (a, b) ->
  [a, b] = [b, a] if a.length > b.length
  value for value in a when value in b

refresh_ui = () ->
  $('i').tooltip()

  $('.format-download').click (event) ->
    if event.ctrlKey
      console.log 'clicked with ctrl, add to basket'
      return false

    true

  vals = []
  __per_option = (option) ->
    if not option.filtered_list or option.filtered_list.length <= 0
      return

    values = []
    values.push option.list[v].name for v in option.filtered_list
    vals.push ('(' + option.name + ': ' + values.join(' OR ')  + ')')

  __per_option option for own key, option of window.library.OPTIONS

  html = ''
  if vals.length > 0
    html += vals.join(' AND ') + ' => '
  html += window.library.current_books.length + ' books'

  $('.filter-info').html html

refresh_book_list = (bl) ->
  $('#books').html ''

  option.filtered_list = option.filter_list() for own key, option of window.library.OPTIONS

  $('#books').append book_list_tmpl book for book in bl

  option.bind_click() for own key, option of window.library.OPTIONS

  refresh_ui()

  $('.book-title').off 'click'
  $('.book-title').click (event) ->
    book = books[$(event.currentTarget).attr 'book-uid']

    $('#book_info').html book_info_tmpl book

    refresh_ui()

    $('.author-link').click (event) ->
      $('#book_info').modal 'hide'
      window.library.OPTIONS.author.click event
      false

    $('.publisher-link').click (event) ->
      $('#book_info').modal 'hide'
      window.library.OPTIONS.publisher.click event
      false

    $('.btn-close').click () ->
      $('#book_info').modal 'hide'

    $('#book_info').modal 'show'

filter = () ->
  matching_books = []
  selected_options = 0

  option.filtered_list = option.filter_list() for own key, option of window.library.OPTIONS
  (if option.filtered_list.length > 0 then selected_options += 1) for own key, option of window.library.OPTIONS

  if selected_options > 0
    __per_book = (book) ->
      matched_rules = 0

      (if option.filter_per_book(book, option.filtered_list) == true then matched_rules += 1) for own key, option of window.library.OPTIONS

      if matched_rules >= selected_options
        matching_books.push book

    __per_book book for own uid, book of books

    window.library.current_books = matching_books

  else
    window.library.current_books = []

  refresh_book_list window.library.current_books

startup = () ->
  window.library.OPTIONS =
    author:	new FilterOption_Author(),
    genre:	new FilterOption_Genre(),
    subject:	new FilterOption_Subject(),
    serie:	new FilterOption_Serie(),
    publisher:	new FilterOption_Publisher()
    formats:	new FilterOption_Format()

  $('.alert').alert();

  $('#filter_form').submit () ->
    false

  $('#book_info').modal
    show:			false

  refresh_ui()

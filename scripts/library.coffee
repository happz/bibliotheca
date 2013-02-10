window.library = window.library or {}

window.library.books = {}
window.library.current_books = []

class FilterOption
  constructor:			(@name) ->
    FO = @

    @fid = '#filter_' + name + 's'
    @ouid_attr = @name + '-uid'
    @ouid_class = '.' + @name + '-link'
    @list_name = name + 's'

    @list = null
    @indexes = {}

    @selected_values = null

    fetch_json_data ('/library-data/' + @name + '/list.json'), (data) ->
      FO.list = data

      $(FO.fid).html ''
      $(FO.fid).append ('<option value="' + entry.uid + '">' + entry.name + '</option>') for own uid, entry of FO.list
      $(FO.fid).html()

    $(@fid).change () ->
      filter()
      true 

  click:			(event) ->
    o = @list[$(event.currentTarget).attr @ouid_attr]
    $(@fid).val o.uid
    filter()
    false

  bind_click:			() ->
    FO = @
    $(@ouid_class).click (event) ->
      FO.click event
      false

  filter_list:			() ->
    return ($(@fid).val() or [])

  filter:			() ->
    FO = @
    selected_values = @filter_list()

    matching_books = []
    cnt_indexes_to_fetch = selected_values.length

    merge_indexes = () ->
      __per_selected_value = (uid) ->
        matching_books.push book_uid for book_uid in FO.indexes[uid]

      __per_selected_value uid for uid in selected_values

    index_fetched = () ->
      cnt_indexes_to_fetch -= 1

      if cnt_indexes_to_fetch > 0
        return

      merge_indexes()

    fetch_indexes = () ->
      $(n for n in [0..(cnt_indexes_to_fetch - 1)]).each (m) ->
        uid = selected_values[m]

        if FO.indexes.hasOwnProperty uid
          index_fetched()
        else
          fetch_json_data ('/library-data/' + FO.name + '/' + uid + '.json'), (data) ->
            FO.indexes[uid] = data
            index_fetched()

    if cnt_indexes_to_fetch <= 0
      merge_indexes()

    else
      fetch_indexes()

    if matching_books.length <= 0
      return null

    return matching_books

class FilterOption_Author extends FilterOption
  constructor:			() ->
    super 'author'

class FilterOption_Genre extends FilterOption
  constructor:			() ->
    super 'genre'

class FilterOption_Subject extends FilterOption
  constructor:			() ->
    super 'subject'

class FilterOption_Serie extends FilterOption
  constructor:			() ->
    super 'serie'

class FilterOption_Publisher extends FilterOption
  constructor:			() ->
    super 'publisher'

class FilterOption_Format extends FilterOption
  constructor:			() ->
    super 'format'

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
        <span class="author-link" author-uid="{{= uid}}">{{= window.library.OPTIONS["author"].list[uid].name}}</span>
      {{~}}
    </td>
    <td>
      {{ it.genres.sort(function (x, y) {return x.localeCompare(y)}); }}
      {{~ it.genres :uid:aindex}}
        <span class="genre-link" genre-uid="{{= uid}}">{{= window.library.OPTIONS["genre"].list[uid].name}}</span>
      {{~}}
    </td>
    <td>
      {{~ it.subjects :uid:aindex}}
        <span class="subject-link" subject-uid="{{= uid}}">{{= window.library.OPTIONS["subject"].list[uid].name}}</span>
      {{~}}
    </td>
    <td>
      <ul class="unstyled">
        {{~ it.series :uid:aindex}}
          <li>
            <span class="serie-link" serie-uid="{{= uid}}">{{= window.library.OPTIONS["serie"].list[uid].name}}{{? it.issue != null}} - {{= it.issue}}.{{?}}</span>
          </li>
        {{~}}
      </ul>
    </td>
    <td>
      {{~ it.publishers :uid:pindex}}
        <span class="publisher-link" publisher-uid="{{= uid}}">{{= window.library.OPTIONS["publisher"].list[uid].name}}</span>
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
          {{ author = window.library.OPTIONS["author"].list[author_uid]; }}
          <span class="author-link" author-uid="{{= author.uid}}">{{= author.name}}</span>
        {{~}}
      </div>

      {{? it.publishers && it.publishers.length > 0}}
        <div>
          Published by
          {{~ it.publishers :uid:index}}
            <span class="publisher-link" publisher-uid="{{= uid}}">{{= window.library.OPTIONS["publisher"].list[uid].name}}</span>
          {{~}}
          {{? it.publication_year}}
            ({{= it.publication_year}})
          {{?}}
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

fetch_json_data = (url, callback) ->
  opts =
    dataType:			'json'
    url:			url
    async:			false
    success:			(data) ->
      callback data

  $.ajax url, opts

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
    if not option.selected_values or option.selected_values.length <= 0
      return

    values = []
    values.push option.list[v].name for v in option.selected_values
    vals.push ('(' + option.name + ': ' + values.join(' OR ')  + ')')

  __per_option option for own key, option of window.library.OPTIONS

  html = ''
  if vals.length > 0
    html += vals.join(' AND ') + ' => '
  html += window.library.current_books.length + ' books'

  $('.filter-info').html html

refresh_book_list = (bl) ->
  $('#books').html ''

  cnt_books_to_fetch = bl.length

  render_book_list = () ->
    option.selected_values = option.filter_list() for own key, option of window.library.OPTIONS

    book_list = []
    book_list.push window.library.books[uid] for uid in bl

    book_list.sort (x, y) ->
      x.title.localeCompare y.title

    $('#books').append book_list_tmpl book for book in book_list

    option.bind_click() for own key, option of window.library.OPTIONS

    refresh_ui()

    $('.book-title').off 'click'
    $('.book-title').click (event) ->
      book = window.library.books[$(event.currentTarget).attr 'book-uid']

      $('#book_info').html book_info_tmpl book

      $('.book-front-cover').error () ->
        $('.book-front-cover').hide()

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

  fetch_books = () ->
    $(n for n in [0..(cnt_books_to_fetch - 1)]).each (m) ->
      uid = bl[m]

      if not window.library.books.hasOwnProperty uid
        fetch_json_data ('/library-data/books/' + uid + '.json'), (data) ->
          window.library.books[uid] = data

  if cnt_books_to_fetch > 0
    fetch_books()

  render_book_list()

filter = () ->
  $('.filter-running').show()

  matching_books = []
  selected_options = 0

  option.selected_values = option.filter_list() for own key, option of window.library.OPTIONS
  (if option.selected_values.length > 0 then selected_options += 1) for own key, option of window.library.OPTIONS

  if selected_options > 0
    matching_books = null

    __per_option = (option) ->
      option_matching_books = option.filter()

      if matching_books == null
        matching_books = option_matching_books

      if option_matching_books
        if matching_books == null
          matching_books = option_matching_books
        else
          matching_books = intersect matching_books, option_matching_books

    __per_option option for own key, option of window.library.OPTIONS

    if matching_books == null
      matching_books = []

    window.library.current_books = matching_books

  else
    window.library.current_books = []

  refresh_book_list window.library.current_books

  $('.filter-running').hide()

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

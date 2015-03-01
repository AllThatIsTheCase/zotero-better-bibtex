Zotero.BetterBibTeX.keymanager = {}

Zotero.BetterBibTeX.keymanager.log = Zotero.BetterBibTeX.log

Zotero.BetterBibTeX.keymanager.init = ->
  # three-letter month abbreviations. I assume these are the same ones that the
  # docs say are defined in some appendix of the LaTeX book. (I don't have the
  # LaTeX book.)
  @months = [ 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec' ]
  @journalAbbrevCache = Object.create(null)
  @cache = Object.create(null)
  for row in Zotero.DB.query('select itemID, citekey, citeKeyFormat from betterbibtex.keys')
    @cache[row.itemID] = {citekey: row.citekey, citeKeyFormat: row.citeKeyFormat}
  @log('CACHE PRIMED', @cache)

  @__exposedProps__ = {
    months: 'r'
    journalAbbrev: 'r'
    extract: 'r'
    get: 'r'
    keys: 'r'
  }
  for own key, value of @__exposedProps__
    @[key].__exposedProps__ = []
  return @

Zotero.BetterBibTeX.keymanager.reset = (hard) ->
  if hard
    Zotero.DB.query('delete from betterbibtex.keys')
    Zotero.DB.query('delete from betterbibtex.cache')

  @cache = Object.create(null)
  @log('KEY CACHE CLEARED')
  return

Zotero.BetterBibTeX.keymanager.journalAbbrev = (item) ->
  item = arguments[1] if item._sandboxManager # the sandbox inserts itself in call parameters

  return item.journalAbbreviation if item.journalAbbreviation
  return unless Zotero.BetterBibTeX.pref.get('auto-abbrev')

  if typeof @journalAbbrevCache[item.publicationTitle] is 'undefined'
    styleID = Zotero.BetterBibTeX.pref.get('auto-abbrev.style')
    styleID = (style for style in Zotero.Styles.getVisible() when style.usesAbbreviation)[0].styleID if styleID is ''
    style = Zotero.Styles.get(styleID) # how can this be null?

    if style
      cp = style.getCiteProc(true)

      cp.setOutputFormat('html')
      cp.updateItems([item.itemID])
      cp.appendCitationCluster({ citationItems: [{id: item.itemID}], properties: {} } , true)
      cp.makeBibliography()

      abbrevs = cp
      for p in ['transform', 'abbrevs', 'default', 'container-title']
        abbrevs = abbrevs[p] if abbrevs

      for own title,abbr of abbrevs or {}
        @journalAbbrevCache[title] = abbr

    @journalAbbrevCache[item.publicationTitle] ?= ''

  return @journalAbbrevCache[item.publicationTitle]

Zotero.BetterBibTeX.keymanager.extract = (item, insitu) ->
  if item._sandboxManager
    item = arguments[1]
    insitu = arguments[2]

  @log('extract:', item, insitu)
  switch
    when item.getField
      throw("#{insitu}: cannot extract in-situ for real items") if insitu
      @log('keymanager.extract: real item, converting to export item')
      item = {itemID: item.id, extra: item.getField('extra')}
    when !insitu
      @log('keymanager.extract: export item, cloning')
      item = {extra: item.extra.slice(0)}

  return item unless item.extra

  embeddedKeyRE = /bibtex: *([^\s\r\n]+)/
  andersJohanssonKeyRE = /biblatexcitekey\[([^\]]+)\]/

  m = embeddedKeyRE.exec(item.extra) or andersJohanssonKeyRE.exec(item.extra)
  return item unless m

  item.extra = item.extra.replace(m[0], '').trim()
  item.__citekey__ = m[1]

  @log('extract::', item)
  return item

Zotero.BetterBibTeX.keymanager.selected = (pinmode) ->
  win = Zotero.BetterBibTeX.windowMediator.getMostRecentWindow('navigator:browser')
  items = Zotero.Items.get((item.id for item in win.ZoteroPane.getSelectedItems() when !item.isAttachment() && !item.isNote()))

  for item in items
    @get(item, pinmode)

Zotero.BetterBibTeX.keymanager.set = (item, citekey) ->
  if Zotero.BetterBibTeX.pref.get('key-conflict-policy') == 'change'
    # remove soft-keys that conflict with pinned keys
    Zotero.DB.query("
      delete from betterbibtex.keys
      where citekey = ?
        and citeKeyFormat is not null
        and itemID in (
          select itemID from items where coalesce(libraryID, 0) in (
            select coalesce(libraryID, 0) from items where itemID = ?
          )
        )", [citekey, item.itemID])

  # store new key
  Zotero.DB.query('insert or replace into betterbibtex.keys (itemID, citekey, citeKeyFormat) values (?, ?, null)', [ item.itemID, citekey])

  @cache[item.itemID] = {citekey: citekey, citeKeyFormat: null}
  return

Zotero.BetterBibTeX.keymanager.remove = (item) ->
  Zotero.DB.query('delete from betterbibtex.keys where itemID = ?', [item.itemID])
  delete @cache[item.itemID]
  return

Zotero.BetterBibTeX.keymanager.get = (item, pinmode) ->
  if item._sandboxManager
    item = arguments[1]
    pinmode = arguments[2]

  # pinmode can be:
  #  reset: clear any pinned key, generate new dynamic key
  #  manual: generate and pin
  #  on-change: generate and pin if pin-citekeys is on-change, 'null' behavior if not
  #  on-export: generate and pin if pin-citekeys is on-export, 'null' behavior if not
  #  null: fetch -> generate -> return

  cached = @cache[item.itemID] || Zotero.DB.rowQuery('select citekey, citeKeyFormat from betterbibtex.keys where itemID=?', [item.itemID]) || {}
  @log('keymanager.get', item, pinmode, cached)
  extra = {
    save: false
    extra: ''
  }

  pinmode = 'manual' if pinmode == Zotero.BetterBibTeX.pref.get('pin-citekeys')
  citeKeyFormat = Zotero.BetterBibTeX.pref.get('citeKeyFormat')

  switch pinmode
    when 'reset', 'manual' # clear any pinned key
      if cached.citekey && !cached.citeKeyFormat # if we've found a key and it was pinned
        item = Zotero.Items.get(item.itemID) unless item.extra
        extra = {
          extra: @extract(item).extra || ''
          save: true
        }
        @log("keymanager.get reset #{pinmode}: extra", extra)
      cached = {citekey: null, citeKeyFormat: (if pinmode == 'manual' then null else citeKeyFormat)}

  if !cached.citekey
    @log('keymanager.get: generating new key')
    Formatter = Zotero.BetterBibTeX.formatter(citeKeyFormat)
    cached.citekey = new Formatter(Zotero.BetterBibTeX.toArray(item)).value
    postfix = { n: -1, c: '' }
    libraryID = item.libraryID || Zotero.DB.valueQuery('select libraryID from items where itemID = ?', [item.itemID]) || 0
    while Zotero.DB.valueQuery('select count(*) from betterbibtex.keys where citekey = ? and itemID <> ? and itemID in (select itemID from items where coalesce(libraryID, 0) = ?)', [cached.citekey + postfix.c, item.itemID, libraryID])
      postfix.n++
      postfix.c = String.fromCharCode('a'.charCodeAt() + postfix.n)

    cached.citekey += postfix.c
    cached.citeKeyFormat = (if pinmode == 'manual' then null else citeKeyFormat)

    # store new key
    Zotero.DB.query('insert or replace into betterbibtex.keys (itemID, citekey, citeKeyFormat) values (?, ?, ?)', [ item.itemID, cached.citekey, cached.citeKeyFormat ])

    if pinmode == 'manual'
      @log('keymanager.get, add key to body: extra', extra)
      extra.extra += " \nbibtex: #{cached.citekey}"
      extra.save = true

  @log('keymanager.get pre-save: extra', extra)
  if extra.save
    extra.extra = extra.extra.trim()
    item = Zotero.Items.get(item.itemID) if not item.getField
    if extra.extra != item.getField('extra')
      item.setField('extra', extra.extra)
      item.save()

  @cache[item.itemID] = cached

  return cached

Zotero.BetterBibTeX.keymanager.keys = ->
  return Zotero.DB.query('select * from betterbibtex.keys order by itemID')


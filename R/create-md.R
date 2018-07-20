xfun::pkg_attach2(c('purrr', 'dplyr', 'xml2'))

# Book listing ------------------------------------------------------------

# get book from sitemap
book_list = xml2::as_list(read_xml("https://bookdown.org/sitemap.xml"))[[1]]
book_urls = tibble(
  url = map_chr(book_list, list("loc", 1)),
  lastmod = map_chr(book_list, list("lastmod", 1)),
  from = "bookdown.org") %>%
  # and from external websites
  bind_rows(
    tibble(
      url = grep(
        '^https://bookdown[.]org', c(readLines("home.txt"), readLines("external.txt")),
        value = TRUE, invert = TRUE
      ),
      lastmod = as.POSIXct(NA),
      from = "external"
    )
  )


# helpers -----------------------------------------------------------------

# one xml_find for two use case
xml_find = function(x, xpath, all = FALSE) {
  FUN = if (all) xml_find_all else xml_find_first
  tryCatch(FUN(x, xpath), error = function(e) NULL)
}

# normalize to [0, 1] and highlight high percentages
normalize_toc_len = function(x) {
  x[x >= quantile(x, .8, na.rm = TRUE)] = max(x, na.rm = TRUE)
  r = range(x, na.rm = TRUE)
  x = (x - r[1])/(r[2] - r[1])
  paste0(100 * round(x, 3), '%')
}

# Get books meta ----------------------------------------------------------

# get metadata for a book from html content
get_book_meta = function(url, date) {
  html = try(read_html(url, encoding = 'UTF-8'))
  if (inherits(html, 'try-error')) return()

  title = xml_find(html, ".//title")
  if (length(title) == 0) return()
  title = xml_text(title)
  if (title == '') return()

  description = xml_find(html, './/meta[@name="description"]')
  if (!is.null(description)) description = xml_attr(description, 'content')
  if (length(description) == 0 || is.na(description) || description == 'NA') description = ''
  if (nchar(description) < 400) {
    # compute a summary from normal paragraphs without any attributes
    paragraphs = xml_text(xml_find(html, './/p[not(@*)]', TRUE))
    if (description == '' && length(paragraphs) == 0) return()
    description = paste(
      c(if (description != '' && length(grep(description, paragraphs, fixed = TRUE)) == 0)
        c(description, '[...]'), paragraphs), collapse = ' '
    )
    description = gsub('\\s{2,}', ' ', description)
    # fewer characters for wider chars
    description = substr(description, 1, 600 * nchar(description) / nchar(description, 'width'))
    description = paste(sub(' +[^ ]{1,20}$', '', description), '...')
  }

  author = xml_find(html, './/meta[@name="author"]', all = TRUE)
  if (length(author) == 0) {
    author = unlist(strsplit(url, '/'))  # https://bookdown.org/user/book
    author = author[length(author) - 1]
  } else {
    author = xml_attr(author, 'content')
    author = paste(author, collapse = ', ')
    # bookdown-demo published by other people
    if (title == 'A Minimal Book Example' && author == 'Yihui Xie' && !grepl('/yihui/', url))
      return()
  }

  if (is.na(date)) {
    date = xml_find(html, './/meta[@name="date"]')
    date = if (is.null(date)) NA else {
      date = xml_attr(date, 'content')
      # is it a valid date?
      if (inherits(xfun::try_silent(as.Date(date)), 'try-error')) NA else date
    }
  }

  cover = xml_find(html, './/meta[@property="og:image"]')
  if (!is.null(cover)) {
    cover = xml_attr(cover, 'content')
    # relative URL to absolute
    if (!grepl('^https?://', cover)) cover = paste0(url, cover)
    # is the cover image URL accessible?
    if (tryCatch(httr::http_error(cover), error = function(e) TRUE)) cover = NULL
  }

  repo = xml_find(html, './/meta[@name="github-repo"]')
  if (!is.null(repo)) repo = xml_attr(repo, 'content')
  generator = xml_find(html, './/meta[@name="generator"]')
  generator = if (length(generator)) xml_attr(generator, "content") else NA
  toc_len = if (grepl('gitbook', generator, ignore.case = TRUE)) {
    length(xml_find(html, './/li[@class="chapter"]', TRUE))
  } else NA

  data_frame(
    url = url, title = title, authors = author, date = date, description = description,
    cover = if (is.null(cover)) NA else cover,
    repo = if (is.null(repo)) NA else repo, toc_len = toc_len
  )
}

cache_rds = "_book_meta.rds"
books_metas = book_urls %>%
  # exclude some specific books
  filter(! url %in% readLines("exclude.txt")) %>%
  # exclude all bookdown demo except official one
  filter(! (grepl('/bookdown-demo/$', url) & !grepl('/yihui/', url))) %>%
  select(url, lastmod) %>%
  pmap_df( ~ {
    url = .x
    # pmap strips dates so they need to be character
    # https://github.com/tidyverse/purrr/issues/358
    date = .y
    message("processing ", url, " ### ", appendLF = FALSE)
    if (file.exists(cache_rds)) {
      book_metas = readRDS(cache_rds)
      if (!is.na(date) && identical((book_meta <- book_metas[[url]])[['date']], date)) {
        message("(from cache)")
        return(if (!is.null(book_meta[['title']])) book_meta)
      }
    } else book_metas = list()
    message("(from url)")
    book_meta = get_book_meta(url, date)
    book_metas[[url]] = if (is.null(book_meta)) list(date = date) else book_meta
    saveRDS(book_metas, cache_rds)
    book_meta
  })


# Cleaning published books ------------------------------------------------

books_to_keep = books_metas %>%
  # should have a substantial TOC (at least 9 items)
  filter(toc_len >= 9) %>%
  # remove possibly duplicated book by the same author (choose the latest)
  group_by(authors, title) %>%
  filter(is.na(date) | date == max(date)) %>%
  ungroup() %>%
  # remove entries that have the same titles and descriptions
  group_by(title, description) %>%
  filter(is.na(date) | date == max(date)) %>%
  ungroup() %>%
  # pencentiles of TOC lengths, which probably indicates the size of the book
  mutate(toc_weight = normalize_toc_len(toc_len)) %>%
  # mark pinned url (to be displayed on homepage)
  mutate(pinned = tolower(url %in% readLines("home.txt")))


# render_post -------------------------------------------------------------

make_post_filename = function(url) {
  name = gsub("^http[s]?://|/$", "", tolower(url))
  name = gsub("[^a-z0-9]+", "-", name)
  name = gsub("--+", "-", name)
  i = grepl('^bookdown-org-', name)
  name[i]  = sub('^bookdown-org-', 'internal/', name[i])
  name[!i] = file.path('external', name[!i])
  paste0(name, ".md")
}

write_md_post = function(post_name, post_content, path = "../content/archive") {
  xfun::write_utf8(post_content, file.path(path, post_name))
}

template = xfun::read_utf8("template.md")

xfun::in_dir('../content/archive', unlink(c('internal/*.md', 'external/*.md')))

books_to_keep %>%
  mutate(post_content = pmap_chr(., function(...) {
    ldata = list(...)
    ldata = ldata[!is.na(ldata)]
    whisker::whisker.render(template, data = ldata)
  })) %>%
  select(url, post_content) %>%
  mutate(post_name = make_post_filename(url)) %>%
  select(-url) %>%
  pwalk(write_md_post)

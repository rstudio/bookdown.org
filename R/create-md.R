if (basename(getwd()) != 'R') setwd('R')

if (!requireNamespace('xfun')) install.packages('xfun')
xfun::pkg_attach2(c('purrr', 'dplyr', 'xml2'))
xfun::pkg_load2(c('httr', 'whisker', 'anytime'))

# exit if on Travis and not a pull request build
is_pr = Sys.getenv('TRAVIS_PULL_REQUEST') != 'false'
if (Sys.getenv('TRAVIS') == 'true' && !is_pr) q('no')

local({
  x = xfun::read_utf8('external.txt')
  xfun::write_utf8(sort(unique(x)), 'external.txt')
})

options(pins.verbose = Sys.getenv("PINS_VERBOSE") == "true")

# Book listing ------------------------------------------------------------

book_urls = if (file.size('staging.txt') > 0) {
  tibble(
    url = xfun::read_utf8('staging.txt'),
    lastmod = as.POSIXct(NA),
    from = 'external'
  )
} else {
  # get book from sitemap
  book_list = xml2::as_list(read_xml('https://bookdown.org/sitemap.xml'))[[1]]
  tibble(
    url = map_chr(book_list, list('loc', 1)),
    lastmod = map_chr(book_list, list('lastmod', 1)),
    from = 'bookdown.org') %>%
    # and from external websites
    bind_rows(
      tibble(
        url = grep(
          '^https://bookdown[.]org', c(xfun::read_utf8('home.txt'), xfun::read_utf8('external.txt')),
          value = TRUE, invert = TRUE
        ),
        lastmod = NA,
        from = 'external'
      )
    )
}


# helpers -----------------------------------------------------------------

# one xml_find for two use case
xml_find = function(x, xpath, all = FALSE) {
  FUN = if (all) xml_find_all else xml_find_first
  res = tryCatch(FUN(x, xpath), error = function(e) NULL)
  if (length(res) > 0) res
}

# test if a URL is not accessible
na_url = function(x) {
  tryCatch(httr::http_error(x), error = function(e) TRUE)
}

# relative url to absolute
rel_to_abs = function(file, baseurl) {
  if (!grepl('^https?://', file)) file = paste0(baseurl, file)
  file
}

valid_date = function(date) {
  # will be NA if date is not converted. 
  # This allows to easily convert date like March 03 2021
  # we add a try_silent to prevent any issue
  if (inherits(xfun::try_silent(date <- anytime::anydate(date)), 'try-error')) {
    NA_character_ 
  } else {
    as.character(date)
  }
}

# normalize to [0, 1] and highlight high percentages
normalize_book_len = function(x) {
  x = sqrt(x)
  x[x >= quantile(x, .9, na.rm = TRUE)] = max(x, na.rm = TRUE)
  if (length(x) <= 1) return('0%')
  r = range(x, na.rm = TRUE)
  x = (x - r[1])/(r[2] - r[1])
  paste0(100 * round(x, 3), '%')
}

# alternative book covers
cover_list = list(
  'https://rafalab.github.io/dsbook/' = 'https://images.routledge.com/common/jackets/amazon/978036735/9780367357986.jpg',
  'https://r-graphics.org/' = 'https://r-graphics.org/cover.jpg',
  'https://www.gastonsanchez.com/r4strings/' = 'https://www.gastonsanchez.com/r4strings/images/cover.png',
  'https://www.datascienceatthecommandline.com/' = 'https://www.datascienceatthecommandline.com/images/cover.png',
  'https://serialmentor.com/dataviz/' = 'https://images-na.ssl-images-amazon.com/images/I/511%2BvIP1-aL._SX331_BO1,204,203,200_.jpg',
  'https://bookdown.org/rdpeng/RProgDA/' = 'https://bookdown.org/rdpeng/RProgDA/cover-image_sm.png',
  'https://zuguang.de/circlize_book/book/' = 'https://zuguang.de/circlize_book/book/images/circlize_cover.jpg'
)

# the length of search_index.json indicates the length of the book
book_length = function(url) {
  search_file = c("search_index.json", "search.json")
  # use first json found
  for (s in search_file) {
    head = httr::HEAD(paste0(url, s))
    if (httr::status_code(head) >= 400) next
    if (length(head) == 0) return(0)
    x = httr::headers(head)$`content-length`
    return(if (length(x) == 0) 0 else as.numeric(x))
  }
  # no json found
  0L
}

match_tags = function(text) {
  tags = trimws(sort(tools::toTitleCase(unique(xfun::read_utf8('tags.txt')))))
  xfun::write_utf8(tags, 'tags.txt')
  tags_low = tolower(tags)
  m = gregexpr(paste(tags, collapse = '|'), text, ignore.case = TRUE)
  unlist(lapply(regmatches(text, m), function(x) {
    if (length(x) == 0) return(NA)
    x = tags[match(tolower(x), tags_low)]
    paste0('[', paste(unique(x), collapse = ', '), ']')
  }))
}

# Get books meta ----------------------------------------------------------

# get metadata for a book from html content
get_book_meta = function(url, date = NA) {
  # try to read a URL for at most three times
  i = 1
  while (i < 4) {
    html = try(read_html(url, encoding = 'UTF-8'))
    if (!inherits(html, 'try-error')) break
    i = i + 1; Sys.sleep(30)
  }
  if (i >= 4) return()

  title = xml_find(html, './/title')
  if (length(title) == 0) return()
  title = xml_text(title)
  # Chapter name can be prepended to book title in other book format.
  # It happens due to `bookdown::prepend_chapter_title()`. 
  # See https://github.com/rstudio/bookdown.org/issues/62
  # TODO: adapt if change upstream.
  title = gsub('^.*\\|\\s*([^|]*)$', '\\1', title)
  if (title == '') return()

  description = xml_find(html, './/meta[@name="description"]')
  if (!is.null(description)) description = xml_attr(description, 'content')
  if (length(description) == 0 || is.na(description) || description == 'NA') description = ''
  if (nchar(description) < 400) {
    # compute a summary from normal paragraphs without any attributes
    # Two different cases: gitbook() and bs4_book().
    # Use XPATH operator AND (|) as they are noninclusive
    paragraphs = xml_find(html, './/main//p[not(@*)] | .//div[@class="page-inner"]//p[not(@*)]', TRUE)
    # in case it is not gitbook nor bs4_book (bookdown::tufte_html_book() ?)
    if (length(paragraphs) == 0) paragraphs = xml_find(html, './/p[not(@*)]', TRUE)
    paragraphs = if (length(paragraphs)) xml_text(paragraphs)
    if (description == '' && length(paragraphs) == 0) return()
    description = paste(
      c(if (description != '' && length(grep(description, paragraphs, fixed = TRUE)) == 0)
        c(description, '[...]'), paragraphs), collapse = ' '
    )
    description = gsub('\\s{2,}', ' ', description) # remove double space
    description = gsub('^\\s+', '', description) # trim left
    # fewer characters for wider chars
    description = substr(description, 1, 600 * nchar(description) / nchar(description, 'width'))
    description = paste(sub(' +[^ ]{1,20}$', '', description), '...')
  }

  author = xml_find(html, './/meta[@name="author"]', all = TRUE)
  if (length(author) == 0) {
    if (length(author <- xml_find(html, './/*[@class="author"]'))) {
      author = xml_text(author)
    } else {
      author = unlist(strsplit(url, '/'))  # https://bookdown.org/user/book
      author = author[length(author) - 1]
    }
  } else {
    author = xml_attr(author, 'content')
    author = paste(author, collapse = ', ')
    # bookdown-demo published by other people
    if (title == 'A Minimal Book Example' && author == 'Yihui Xie' && !grepl('/yihui/', url))
      return()
  }
  author = gsub('https?://.+', '', author)  # https://m-clark.github.io/generalized-additive-models/
  author = gsub('copyright [0-9]+', '', author, ignore.case = TRUE)  # https://thinkstats.org/
  author = gsub('.+, by ([^,]+),.+', '\\1', author)  # https://davidjohnbaker1.github.io/document/
  author = gsub('\\s+Foreword by .+', '', author)  # https://moderndive.com/
  author = gsub('\\\\[(].*\\\\[)]', '', author)  # https://bookdown.org/paulgonzaloparedes/derecho-de-daos/
  author = trimws(gsub('\\s+', ' ', author))

  if (is.na(date)) {
    date = xml_find(html, './/meta[@name="date"]')
    if (!is.null(date)) {
      date = xml_attr(date, 'content')
      date = valid_date(date)
    } else {
      # bs4_book() See if we find date in footer (as set in template)
      # we match date placeholder and won't catch any date formatted using .
      r = "It was last built on ([^\\.]*)\\."
      date = xml_find(html, './/footer')
      if (length(date) != 0 && grepl(r, date <- xml_text(date), perl = TRUE)) {
        date = regmatches(date, regexec(r, date, perl = TRUE))[[1]][2]
      }
      date = if (length(date) == 0) NA else valid_date(date)
    }
  }

  cover = xml_find(html, './/meta[@property="og:image"]')
  if (!is.null(cover)) {
    cover = xml_attr(cover, 'content')
    cover = rel_to_abs(cover, url)
    if (!grepl('^https://', cover) || na_url(cover)) cover = NULL
  }
  # is there a cover image on first page ?
  # this is useful for new bs4_book() format which don't have og:image meta
  # Simple algorithm: 
  #   1. look for first <img> on the main page
  #   2. See if it is related to a cover: filename, class, alt-text
  #   3. Use the image if one of this is true
  if (is.null(cover) && length(img_cover <- xml_find(html, ".//img")) != 0) { 
      img_url = xml_attr(img_cover, "src")
      # return early if the first image is encoded
      if (!grepl("^data:", img_url)) {
        # is the first image called cover ?
        cover_file = grepl("cover", basename(img_url))
        # is the image node has a class cover ?
        cover_class = any(grepl("cover", xml_attr(img_cover, "class")))
        # is the alt text related to cover ?
        cover_alt = any(grepl("cover", xml_attr(img_cover, "alt")))
        if (cover_file || cover_class || cover_alt) {
          cover = img_url
          cover = rel_to_abs(cover, url)
          if (!grepl('^https://', cover) || na_url(cover)) cover = NULL
        }
      }
  }
  # does the alternative cover URL work?
  if (is.null(cover)) {
    cover = cover_list[[url]]
    if (!is.null(cover) && na_url(cover)) cover = NULL
  }

  repo = xml_find(html, './/meta[@name="github-repo"]')
  if (!is.null(repo)) repo = gsub('^/+|/+$', '', xml_attr(repo, 'content'))
  if (is.null(repo)) {
    # try bs4_book
    repo = xml_find(html, './/a[@id="book-repo"]')
    if (!is.null(repo)) repo = gsub('^https://github.com/','', xml_attr(repo, 'href'))
  }
  
  generator = xml_find(html, './/meta[@name="generator"]')
  generator = if (length(generator)) xml_attr(generator, 'content') else NA

  tibble(
    url = url, title = title, authors = author, date = date, description = description,
    cover = if (is.null(cover)) NA else cover,
    repo = if (is.null(repo)) NA else repo, book_len = book_length(url)
  )
}

# Get meta from pins
cache_rds = '_book_meta.rds'
message("Fetching new book informations")
xfun::pkg_load2("pins")
if (!file.exists(cache_rds) && 
    !is.na(rsc_key <- Sys.getenv("RSC_BOOKDOWN_ORG_TOKEN", unset = NA))) {
  message("-> Retrieving cached meta from pins")
  pins::board_register_rsconnect(server = "https://bookdown.org", key = rsc_key)
  pin_exists = pins::pin_find(name = "cderv/bookdownorg_books_meta", board = "rsconnect")
  if (nrow(pin_exists) == 1) {
    cache_rds = pins::pin_get("cderv/bookdownorg_books_meta", board = "rsconnect", cache = FALSE)
    stopifnot("Cache not downloaded" = file.exists(cache_rds))
    message("-> Cached meta downloaded in ", dQuote(cache_rds))
  }
}

books_metas = book_urls %>%
  # exclude some specific books
  filter(! url %in% xfun::read_utf8('exclude.txt')) %>%
  # exclude all bookdown demo except official one
  filter(! (grepl('/bookdown-demo/$', url) & !grepl('/yihui/', url))) %>%
  select(url, lastmod) %>%
  pmap_df( ~ {
    url = .x
    # pmap strips dates so they need to be character
    # https://github.com/tidyverse/purrr/issues/358
    date = .y
    if (file.exists(cache_rds)) {
      book_metas = readRDS(cache_rds)
      if (!is.na(date) && identical((book_meta <- book_metas[[url]])[['date']], date)) {
        return(if (!is.null(book_meta[['title']])) book_meta)
      }
    } else book_metas = list()
    message('-> processing ', url)
    book_meta = get_book_meta(url, date)
    book_metas[[url]] = if (is.null(book_meta)) list(date = date) else book_meta
    saveRDS(book_metas, cache_rds)
    book_meta
  })

# save new book meta
if (!is.na(rsc_key)) {
  message("-> Pinning new cached meta to bookdown.org")
  pins::pin(cache_rds, name = "bookdownorg_books_meta", board = "rsconnect", 
            description = "Metadata for bookdown.org/ books page")
}

# Write data for debug to upload as artifacts on GHA
saveRDS(books_metas, "saved_books_metas.rds")

# Cleaning published books ------------------------------------------------

message("Cleaning retrieved informations")
books_to_keep = books_metas %>%
  # should have substantial content (> 2500 bytes)
  filter(book_len == 0 | book_len > 2500 | !grepl('^https://bookdown[.]org/', url)) %>%
  # remove possibly duplicated book by the same author (choose the latest)
  group_by(authors, title) %>%
  filter(is.na(date) | date == max(date)) %>%
  ungroup() %>%
  # remove entries that have the same titles and descriptions
  group_by(title, description) %>%
  filter(is.na(date) | date == max(date)) %>%
  ungroup() %>%
  mutate(title = gsub('\\', '\\\\', title, fixed = TRUE)) %>%
  mutate(cover = gsub('(?<!:)//', '/', cover, perl = TRUE)) %>%
  mutate(length_weight = normalize_book_len(book_len)) %>%
  mutate(tags = match_tags(paste(title, description))) %>%
  # mark pinned url (to be displayed on homepage)
  mutate(pinned = tolower(url %in% xfun::read_utf8('home.txt')))


# render_post -------------------------------------------------------------

make_post_filename = function(url) {
  name = gsub('^http[s]?://|/$', '', tolower(url))
  name = gsub('[^a-z0-9]+', '-', name)
  name = gsub('--+', '-', name)
  i = grepl('^bookdown-org-', name)
  name[i]  = sub('^bookdown-org-', 'internal/', name[i])
  name[!i] = file.path('external', name[!i])
  paste0(name, '.md')
}

write_md_post = function(post_name, post_content, path = '../content/archive') {
  xfun::write_utf8(post_content, file.path(path, post_name))
}

template = xfun::read_utf8('template.md')

if (Sys.getenv('TRAVIS') == '') {
  xfun::in_dir('../content/archive', unlink(c('internal/*.md', 'external/*.md')))
}

message("Writing md files")
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

message("Done!")
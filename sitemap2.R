library(purrr)
library(dplyr)
library(xml2)

# Book listing ------------------------------------------------------------

# get book from sitemap
xml <- "https://bookdown.org/sitemap.xml"
book_list <- xml2::as_list(read_xml(xml))[[1]]
book_urls <- tibble(
  url = map_chr(book_list, list("loc", 1)),
  lastmod = map_chr(book_list, list("lastmod", 1)),
  from = "bookdown.org") %>%
  # and from external websites
  bind_rows(
    tibble(
      url = readLines("external.txt"),
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

# check if covers url is accessible or do not use it
check_cover <- function(cover, url) {
  # relative URL to absolute
  if (!grepl('^https?://', cover)) cover = paste0(url, cover)
  # is the cover image URL accessible?
  if (tryCatch(httr::http_error(cover), error = function(e) TRUE)) cover = NA_character_
  cover
}

# get list of authors from url or html content
clean_authors <- function(author, url) {
  if (is.null(author) || length(author) == 0) {
    author = unlist(strsplit(url, '/'))  # https://bookdown.org/user/book
    author = author[length(author) - 1]
  } else {
    author = xml_attr(author, 'content')
    author = paste(author, collapse = ', ')
  }
  author
}




# Get books meta ----------------------------------------------------------

# get metadata for a book from html content
get_book_meta <- function(url, date) {
  tibble(
    url = url,
    html = url %>%
      possibly(~ read_html(.x, encoding = "UTF-8") %>% list(), otherwise = NA_character_)(),
    title = map_chr(html,
                    ~ xml_find(.x, ".//title") %>%
                      possibly(xml_text, otherwise = NA_character_)()),
    date = if_else(is.na(date), 
                   map_chr(html,
                           ~ xml_find(.x, './/meta[@name="date"]') %>%
                             possibly(~ xml_attr(.x, "content"), otherwise = NA_character_)()
                   ),
                   date),
    description = map_chr(html,
                          ~ xml_find(.x, './/meta[@name="description"]') %>%
                            possibly(~ xml_attr(.x, "content"), otherwise = NA_character_)()),
    cover = map_chr(html,
                    ~ xml_find(.x, './/meta[@property="og:image"]') %>%
                      possibly(~ xml_attr(.x, "content"), otherwise = NA_character_)() %>%
                      check_cover(url = url)),
    repo = map_chr(html,
                   ~ xml_find(.x, './/meta[@name="github-repo"]') %>%
                     possibly(~ xml_attr(.x, "content"), otherwise = NA_character_)()),
    authors = map_chr(html,
                      ~ xml_find(.x, './/meta[@name="author"]', all = TRUE) %>%
                        clean_authors(url = url)),
    # get generator to identify 
    generator = map_chr(html, 
                        ~ xml_find(.x, './/meta[@name="generator"]') %>%
                          possibly(~ xml_attr(.x, "content"), otherwise = NA_character_)())
  )
}

# delete book parsed list
unlink("listed.txt")
cache_rds <- "_book_meta_new.rds"
books_metas <- book_urls %>%
  # exclude some specific books
  filter(! url %in% readLines("exclude.txt")) %>%
  # exclude all bookdown demo except official one
  filter(! (grepl('/bookdown-demo/$', url) & !grepl('/yihui/', url))) %>%
  # exclude all book from one author
  filter(!grepl('^https://bookdown.org/ChaitaTest/', url)) %>%
  # slice(1:2) %>%
  select(url, lastmod) %>%
  pmap_df( ~ {
    url <- .x
    # pmap strips dates so they need to be character 
    # https://github.com/tidyverse/purrr/issues/358
    date <- .y
    message("processing ", url, " ### ", appendLF = FALSE)
    cat(url, sep = '\n', file = 'listed.txt', append = TRUE)
    if (file.exists(cache_rds)) {
      book_metas = readRDS(cache_rds)
      if (!is.na(date) && identical(book_metas[[url]][['date']], date)) {
        message("(from cache)")
        return(book_metas[[url]])
      }
    } else book_metas = list()
    message("(from url)")
    book_meta <- get_book_meta(url, date)
    book_metas[[url]] <- book_meta
    saveRDS(book_metas, cache_rds)
    book_meta
  })


# Cleaning published books ------------------------------------------------

pinned_urls <- c(
  "https://bookdown.org/yihui/bookdown/",
  "http://r4ds.had.co.nz/",
  "http://adv-r.hadley.nz/",
  "https://bookdown.org/rdpeng/rprogdatascience/",
  "https://tidytextmining.com/",
  "https://bookdown.org/rdpeng/exdata/",
  "https://bookdown.org/csgillespie/efficientR/",
  "https://otexts.org/fpp2/",
  "https://bookdown.org/yihui/blogdown/")

books_metas %>%
  # do not keep non accessible book
  filter(! is.na(html)) %>%
  # do not keep publication with no title
  filter(! is.na(title)) %>%
  # do not keep publication with no description
  filter(! is.na(description)) %>%
  # do not keep template book
  filter(!(title == 'A Minimal Book Example' & authors == 'Yihui Xie' & !grepl('/yihui/', url))) %>%
  # mark pinned url
  mutate(pinned = url %in% pinned_urls)










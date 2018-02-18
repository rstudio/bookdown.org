library(purrr)
library(dplyr)
library(xml2)

# Book listing ------------------------------------------------------------

# get book from sitemap
xml <- "https://bookdown.org/sitemap.xml"
book_list <- xml2::as_list(read_xml(xml))[[1]]
book_urls <- tibble(
  url = map_chr(book_list, list("loc", 1)),
  lastmod = map_chr(book_list, list("lastmod", 1)) %>% strptime(., '%Y-%m-%dT%H:%M:%SZ', 'UTC') %>% as.POSIXct(),
  from = "bookdown.org"
) %>%
  # and from external websites
  bind_rows(
    tibble(
      url = readLines("external.txt"),
      lastmod = as.POSIXct(NA),
      from = "external"
    )
  )
  

# helpers -----------------------------------------------------------------

xml_find = function(x, xpath, all = FALSE) {
  FUN = if (all) xml_find_all else xml_find_first
  tryCatch(FUN(x, xpath), error = function(e) NULL)
}

check_cover <- function(cover, url) {
  # relative URL to absolute
  if (!grepl('^https?://', cover)) cover = paste0(url, cover)
  # is the cover image URL accessible?
  if (tryCatch(httr::http_error(cover), error = function(e) TRUE)) cover = NA_character_
  cover
}

clean_authors <- function(author, url) {
  if (is.null(author) || length(author) == 0) {
    author = unlist(strsplit(url, '/'))  # https://bookdown.org/user/book
    author = author[length(author) - 1]
  } else {
    author = xml_attr(author, 'content')
    author = paste(author, collapse = ', ')
    if (title == 'A Minimal Book Example' && author == 'Yihui Xie' && !grepl('/yihui/', url))
      author = NA_character_
  }
  author
}


# Get books meta ----------------------------------------------------------

get_book_meta <- function(url) {
  tibble(
    html = url %>%
      possibly(~ read_html(.x, encoding = "UTF-8") %>% list(), otherwise = NA_character_)(),
    title = map_chr(html, 
                    ~ xml_find(.x, ".//title") %>% 
                      possibly(xml_text, otherwise = NA_character_)()),
    date = map_chr(html, 
                   ~ xml_find(.x, './/meta[@name="date"]') %>% 
                     possibly(~ xml_attr(.x, "content"), otherwise = NA_character_)()),
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
                        clean_authors(url = url))
  )
}

# delete book parsed list
unlink("listed.txt")

book_meta <- book_urls %>%
  # exclude some specific books
  filter(! url %in% readLines("exclude.txt")) %>%
  # exclude all bookdown demo except official one
  filter(! (grepl('/bookdown-demo/$', url) & !grepl('/yihui/', url))) %>%
  # exclude all book from one author
  filter(!grepl('^https://bookdown.org/ChaitaTest/', url))

%>%
  slice(1:2) %>%
  map2_df( ~ {
    url <- .x
    message("processing ", url)
    if (file.exists('_book_meta_new.rds')) {
      panels = readRDS('_book_meta_new.rds')
      if (!is.na(date) && identical(panels[[url]][['date']], date)) {
        return(structure(panels[[url]][['panel']], BOOK_DATE = as.Date(date)))
      }
    } else panels = list()
    cat(url, sep = '\n', file = 'listed.txt', append = TRUE)
    get_book_meta(url)
  }, .id = "url")


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









  
## This file is useful to DEBUG the cached values. Sometimes, it can be necessarry to clean up the cache.
rsc_key <- Sys.getenv("RSC_BOOKDOWN_ORG_TOKEN", unset = "")
message("-> Retrieving cached meta from pins")
pins::board_register_rsconnect(server = "https://bookdown.org", key = rsc_key, versions = TRUE)
pin_exists = pins::pin_find(name = "cderv/bookdownorg_books_meta", board = "rsconnect")
if (nrow(pin_exists) == 1) {
  cache_rds = pins::pin_get("cderv/bookdownorg_books_meta", board = "rsconnect", cache = FALSE)
  stopifnot("Cache not downloaded" = file.exists(cache_rds))
  message("-> Cached meta downloaded in ", dQuote(cache_rds))
}

book_metas <- readRDS(cache_rds)

reset_cache <- function(book_metas, urls) {
  for (i in urls) book_metas[[i]] <- NULL
  book_metas
}


book_metas <- reset_cache(book_metas, "https://bookdown.org/rfdapaz/visaogeral/")
book_metas <- reset_cache(book_metas, "https://bookdown.org/stephi_gascon/Guia-AAD-UdG/")
book_metas <- reset_cache(book_metas, "https://bookdown.org/thea_knowles/dissertating_rmd_presentation/")
book_metas <- reset_cache(book_metas, "https://bookdown.org/tpemartin/course-108-1-datavisualization/")
book_metas <- reset_cache(book_metas, "https://bookdown.org/tpemartin/ntpu-data-visualization/")
book_metas <- reset_cache(book_metas, "https://bookdown.org/tpemartin/ntpu-programming-for-data-science/")
book_metas <- reset_cache(book_metas, "https://bookdown.org/ugurdarr/cubukgrafigi/")
book_metas <- reset_cache(book_metas, "https://bookdown.org/wxhyihuan/Notebook-of-medical-statistics-1605856202966/")
book_metas <- reset_cache(book_metas, "https://tidytextmining.com/")

message("-> Pinning new cached meta to bookdown.org")
pins::pin(cache_rds, name = "bookdownorg_books_meta", board = "rsconnect",
          description = "Metadata for bookdown.org/ books page")

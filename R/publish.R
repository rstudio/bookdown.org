xfun::in_dir((blogdown:::site_root()), if ('yihui' %in% rsconnect::accounts('bookdown.org')[['name']]) {
  blogdown::hugo_build()
  options(rsconnect.force.update.apps = TRUE)
  rsconnect::deploySite('.', 'homepage', 'yihui', 'bookdown.org', launch.browser = FALSE)
})

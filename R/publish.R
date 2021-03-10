xfun::in_dir(
  (blogdown:::site_root()), 
  {
    # BUILD SITE
    blogdown::hugo_build()
    
    # DEPLOY
    if (Sys.getenv("CI") == "true") {
      rsconnect::addConnectServer('https://bookdown.org', 'bookdown.org')
      rsconnect::connectApiUser(
        account = 'GHA', server = 'bookdown.org',
        apiKey = Sys.getenv('RSC_BOOKDOWN_ORG_TOKEN')
      )
      rsconnect::deploySite(
        appId = Sys.getenv('CONTENT_ID'),
        server = 'bookdown.org',
        render = 'none', logLevel = 'verbose',
        forceUpdate = TRUE
      )
    } else {
      # for local deployment 
      rsconnect::deploySite('.', siteName = 'homepage', 
                            server = 'bookdown.org', 
                            forceUpdate = TRUE,
                            launch.browser = FALSE)
    }
  }
)

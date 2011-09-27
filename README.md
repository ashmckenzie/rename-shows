Rename shows
============

Very basic app to rename all tv shows from `<Show Name>/<Season X>/<Show.Name.SXXEXX.ext>` to `<Show Name>/<Season X>/<Show.Name.SXXEXX.Episode.Name.ext>`.
  
Example
-------

`Pawn Stars/Season 1/Pawn.Stars.S01E01.avi`
  
becomes
  
`Pawn Stars/Season 1/Pawn.Stars.S01E01.Pilot.Boom.Or.Bust.avi`

Usage
-----

`./@rename.rb [options] <directory>`
  
Help
----
    $ ./rename_shows.rb --help
    Options:
      --verbose, -v:   Verbose mode (default: true)
        --debug, -d:   Debug mode
      --logging, -l:   Enable logging
      --forreal, -f:   Really rename files
         --help, -h:   Show this message
## Notes

This repository is unmaintained and probably outdated by now.
It is kept online as it can be an interesting starting point to understand the text format.

## Ruby version
This app uses Ruby 2.2.0.

## Deployment on Heroku
    $ heroku login
    $ heroku create
    $ git push heroku master
    $ heroku run rake db:reset

## Local setup
    $ bundle install
    $ rake db:reset
    $ rails server

## How does it work ?
The main objective of this application is to parse the timetable text sent by the University of Technology of Compiègne.
Here is a sample text :

    EI03       C 1    LUNDI... 18:45-19:45,F1,S=RN104
    EI03       D 1    SAMEDI..  8:15-12:15,F1,S=RN104

    LG30       D 2    MERCREDI 10:15-12:15,F1,S=FA413
    LG30       T 3 A  LUNDI... 13:00-14:00,F1,S=FA410

    SR01       C 1    LUNDI... 14:15-16:15,F1,S=FA104
    SR01       D 1    LUNDI... 16:30-18:30,F1,S=FA506

    MT12       C 1    LUNDI...  8:00-10:00,F1,S=FA202
    MT12       D 1    MARDI... 16:30-18:30,F1,S=FA518

The format is the following :

    COURSECODE       TYPE GROUPNUMBER WEEK   DAYOFTHEWEEK STARTHOUR-ENDHOUR,FREQUENCY,S=CLASSROOM

Currently, the parsing is done using this regex :

    (\w+)\s*([a-zA-Z]+)\s*(\d*)\s*([A|B]{0,1})\s*(\w+)[\.]*\s*(\d+:\d+)-(\d\d:\d\d),F(\d),S=\s*(\w*).*
 
The application tries to match the regex with each of the lines after some pre-processing.
If the regex fails to recognize the text in the line, then a fallback method tries to parse the line using ruby.

Each line is converted into a non-persisted (not stored in database) Course object.

## Authentication
The application uses Devise and the University's CAS to handle authentication.

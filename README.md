# gitter
GIT Repository Downloader / Helper Script

Shell Script for downloading GIT repositories as zip files.

Add one or more text files with GIT/gitlab repository links beside the gitter.sh script.

USAGE:

./gitter.sh |nothing - go through all textfiles and download every repository, replaces already existing zip files if successful

./gitter.sh {certain-file without .txt extension} | download every repository from this specific file, replaces already existing zip files if successful

./gitter.sh -m | download only missing repositories

./gitter.sh {certain-file} -f={name} | (re)download from this file every repository filtered for links containing stated *name*

Text files:
You can add the links in differnt ways and also replace the save-filename with your own.
e.g.

https://github.com/FortySevenEffects/arduino_midi_library => gitter.sh will search for branch master.

If it cannot find /tree/master it will retry with the newer declaration main.

search directly for certain branches:

https://github.com/FortySevenEffects/arduino_midi_library/tree/master
https://github.com/FortySevenEffects/arduino_midi_library/tree/gh-pages

renaming the files:

https://github.com/danionescu0/arduino/tree/master danionescu0-arduino

arduino seems to be a very common name - not good if you want to save it with every other arduino project via arduino.txt

=> by adding a specific name after the link it will rename the download file + adding the branch.

rm -fR doc
rdoc -m README.rdoc -o doc -f hanna src/*.rb src/models/*.rb README.rdoc
cp -R img doc/files

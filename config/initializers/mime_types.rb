# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

# These are non-language versions
Mime::Type.register "application/ld+json", :jsonld
Mime::Type.register "application/n-triples", :nt
Mime::Type.register "text/turtle", :ttl
Mime::Type.register "text/xml", :xml
Mime::Type.register "text/xml", :marc

# These are language supported versions
Mime::Type.register "application/ld+json", :jsonldV2
Mime::Type.register "application/n-triples", :ntV2
Mime::Type.register "text/turtle", :ttlV2


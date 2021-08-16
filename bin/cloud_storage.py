#!/usr/bin/python3

from google.cloud import storage
import psycopg2

BUCKET='photo.festing.org'

# I am trying to use a role account from
# https://cloud.google.com/docs/authentication/production#cloud-console

# export GOOGLE_APPLICATION_CREDENTIALS=~/Downloads/festing-a3f29bee080e.json 

storage_client = storage.Client()

# Meanwhile, also connect to the Postgresql database so we can cross-reference
# the photos that exist in storage with the photos that exist in the database.
conn = psycopg2.connect("dbname=jaeger host=honor2.festing.org port=1284 user=jaeger")

# Starting at the top level of the bucket, get a list of all of the prefixes

root = storage_client.list_blobs(BUCKET, delimiter='/')
# We don't actually care what files exist in the top-level directory, but the
# API wants us to dereference them in order to get the list of prefixes, which
# we actually do want.
list(root)

# lol this is pretty undiscoverable from the Python API description :-/
for r in sorted(root.prefixes):
    print('Descending into round "%s"' % r)

    photos_in_db = {}
    cur = conn.cursor()
    cur.execute("select * from photo where round = %s and not hidden", (r.replace('/', ''),))
    for record in cur:
        photos_in_db[record[2]] = record

    files = {}

    for f in storage_client.list_blobs(BUCKET, prefix=r):
        parts = f.name.split('/')
        if len(parts) == 3:
            _, size, number = parts
            if number.endswith('.jpg'):
                if number not in files:
                    files[number] = {}
                files[number][size] = f

    for number, sizes in files.items():
        print('    Photo "%s" has sizes: %s' %
                (number, ', '.join(sizes.keys())))

        # Ok here's where I want to go with this:
        # - Check that each photo has exactly one in photo [new, full]
        # - Check that a photo has a thumbnail (256x192)
        # - Check that a photo has a full-size version. Need to decide how to
        #   encode this in the database so the photo viewer can make the right
        #   choices here.
        # - Check that the photo has any required smaller-scale images (640x480
        #   for embedding in changelogs and calvinlogan.com and
        #   julianlogan.com; 800x600 from embedding in rss)
        # - Check that the list of photos in 'sizes' matches what we see here
        # - Check that the photos that exist in storage identically match the
        #   photos that exist in the database

        photo_in_db = photos_in_db.get(number.replace('.jpg', ''), None)

        if photo_in_db is None:
            print('        This photo does not exist in the database')
            # We need to resolve whether this photo ought to exist before we
            # can claim that it's missing various sizes
            continue

        if ('new' not in sizes) and ('full' not in sizes):
            print('        ERROR: Neither size new nor full exist!')
            continue

        if ('new' in sizes) and ('full' in sizes):
            print('        Warning: Both size new and full exist!')

        if '256x192' not in sizes:
            print('        Groomer: Needs to create missing size 256x192')

        # Determine what the maximum size (in our standard buckets) that the
        # full-resolution photo will fit in, and check that this photo exists
        width = photo_in_db[14]
        height = photo_in_db[15]

        if (width is None) or (height is None):
            print('        Groomer: Width or height is missing')
            continue

        # Check if we need a smaller size to show on the web
        #if (width > 1600) or (height > 1200):
        #    if '1600x1200' not in sizes:
        #        print('        Groomer: Photo is %d x %d; need to create missing size 1600x1200' %
        #                (width, height))
        #else:
        #    if '1600x1200' in sizes:
        #        print('        Note: Photo is %d x %d; size 1600x1200 is unnecessary' % (width, height))
        
        # Actually I'm no longer certain I really want to do this in advance.
        # I think I'll still need an on-demand photo resize service
        # (implemented in Python, presumably, so it'll have full access to
        # Cloud Storage APIs) that will do this on demand. So the semantics are:
        #
        # - Existing Perl code sets the size property on a photo and calls
        #   resize()
        # - The Perl resize() method decides whether the full-resolution image
        #   is too big for the reduced size requested.
        #   - If not, it returns a reference to the full-size image.
        #   - If so, it checks whether the image already exists (in the "sizes"
        #     list). If it does not exist, it calls the resize service.

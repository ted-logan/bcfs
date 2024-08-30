#!/usr/bin/python3

import argparse
from google.cloud import storage
import os
import psycopg2
from wand.image import Image

BUCKET='photo.festing.org'

# I am trying to use a role account from
# https://cloud.google.com/docs/authentication/production#cloud-console

# Use a service account to access Cloud Storage

# https://googleapis.dev/python/storage/latest/blobs.html
storage_client = storage.Client.from_service_account_json(
        '/var/www/festing-service-account.json')
        #os.getenv('HOME') + '/festing-service-account.json')
bucket = storage.bucket.Bucket(storage_client, BUCKET)

# Meanwhile, also connect to the Postgresql database so we can cross-reference
# the photos that exist in storage with the photos that exist in the database.
# https://www.psycopg.org/
conn = psycopg2.connect("dbname=jaeger port=1284")

def cloud_resize(r, number, new_size):
    # Resize a photo to a specific size; and while we're at it make sure all
    # the metadata is correct in the database.

    print('Preparing to resize %s/%s to fit in %s' % (r, number, new_size))

    # Double-check that the image exists in the database.
    cur = conn.cursor()
    cur.execute("select * from photo where round = %s and number = %s and not hidden", (r, number,))
    row = cur.fetchone()

    # Find all of the available scaled images for this full-sized image.
    sizes = {}

    for f in storage_client.list_blobs(bucket, prefix=r + '/'):
        parts = f.name.split('/')
        if len(parts) == 3:
            _, size, n = parts
            if n == number + '.jpg':
                sizes[size] = f

    full_size = None
    if 'full' in sizes:
        full_size = sizes['full']
    elif 'new' in sizes:
        full_size = sizes['new']
    else:
        raise RuntimeError('Error: full-sized image for %s/%s not found' % (r, number))

    print('Full-size image found: %s' % full_size.name)

    # If any of the scaled images exist, check that they're at least as new as
    # the full-sized image. If they're not, delete them.
    for size, f in sizes.items():
        if size in ('full', 'new'):
            continue
        print('Scaled image (%s) found: %s' % (size, f.name))
        if f.time_created < full_size.time_created:
            print('Found size %s needs to be updated' % size)
            # TODO delete this scaled image
            # TODO there's a race condition here with deleting the image,
            # updating the database, etc. Maybe we resolve it by synchronously
            # replacing it?
            # f.delete()

    # If the scaled images for the sizes we want don't exist, create them.
    if new_size not in sizes:
        print('Preparing to resize %s/%s to fit in %s' % (r, number, new_size))

        # Download the full-size image into memory
        img = full_size.download_as_bytes()
        with Image(blob=img) as i:
            # TODO maybe update image dimensions
            width = i.width
            height = i.height
            print('Photo %s/%s size is %d x %d' % (r, number, width, height))

            # TODO maybe check that it makes sense to size the image this way

            # Scale the image to the prefered bounding box, preserving its aspect ratio
            i.transform(resize = new_size + '>')

            print('Transformed image is now %d x %d' % (i.width, i.height))

            scaled_image_path = '%s/%s/%s.jpg' % (r, new_size, number)
            scaled_image = storage.blob.Blob(scaled_image_path, bucket)

            scaled_image.upload_from_string(i.make_blob(format='jpeg'),
                    content_type='image/jpeg')

            sizes[new_size] = scaled_image

    # Update the metadata in the database with the image dimensions and
    # available scaled images.
    sizes_in_storage = ','.join(sizes.keys())
    sizes_in_db = row[16]
    if sizes_in_db != sizes_in_storage:
        print("        Updating sizes to '%s' (for id=%d)" % (sizes_in_storage, row[0]))
        cur = conn.cursor()
        cur.execute('update photo set sizes = %s where id = %s', (sizes_in_storage, row[0],))
        conn.commit()

parser = argparse.ArgumentParser()
parser.add_argument('--round', required=True, help='The photo round')
parser.add_argument('--number', required=True, help='The photo number')
parser.add_argument('--size', required=True, help='The desired size, eg 640x480')
args = parser.parse_args()

cloud_resize(args.round, args.number, args.size)

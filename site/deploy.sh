#!/bin/bash
# Deploys the site to a GCS bucket configured for static website hosting.
# Usage: site/deploy.sh <bucket-name>
#
# One-time bucket setup (public static site):
#   gsutil mb -l us-central1 gs://<bucket>
#   gsutil iam ch allUsers:objectViewer gs://<bucket>
#   gsutil web set -m index.html gs://<bucket>
# Then front it with a load balancer + managed cert for a custom domain,
# or serve directly via https://storage.googleapis.com/<bucket>/index.html.
set -euo pipefail

BUCKET="${1:?usage: site/deploy.sh <bucket-name>}"
cd "$(dirname "$0")"

gsutil -m rsync -r -d -x 'deploy\.sh$' . "gs://${BUCKET}"
# Cache headers: HTML revalidates every visit (instant deploys), images cache a day.
gsutil -m setmeta -h "Cache-Control:no-cache" "gs://${BUCKET}/index.html"
# The appcast must never be cached: the app's daily update check reads it,
# and each request reaching GCS is what the (disclosed) install counting uses.
gsutil -m setmeta -h "Cache-Control:no-cache" "gs://${BUCKET}/appcast.json" 2>/dev/null || true
gsutil -m setmeta -h "Cache-Control:public, max-age=86400" "gs://${BUCKET}/img/*" 2>/dev/null || true

echo "Deployed: https://storage.googleapis.com/${BUCKET}/index.html"

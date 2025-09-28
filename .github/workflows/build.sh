name: Build & Push Bluefin Images

on:
  workflow_run:
    workflows: ["Sync upstream"]   # must match sync.yml's name
    types: [completed]
  push:
    branches: [main]
    paths:
      - "Containerfile"
      - ".github/workflows/build.yml"
  workflow_dispatch: {}

concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    if: ${{ github.event_name == 'workflow_dispatch' || github.event_name == 'push' || github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    strategy:
      matrix:
        fedora: ["43"]   # add/remove versions here
    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build image
        uses: redhat-actions/buildah-build@v2
        with:
          image: ghcr.io/${{ github.repository_owner }}/bluefin
          tags: ${{ matrix.fedora }}
          containerfiles: Containerfile
          build-args: |
            FEDORA_MAJOR_VERSION=${{ matrix.fedora }}

      - name: Push image
        uses: redhat-actions/push-to-registry@v2
        with:
          image: ghcr.io/${{ github.repository_owner }}/bluefin
          tags: ${{ matrix.fedora }}

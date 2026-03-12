# Workshops

Internal workshop hub for Crunchloop.

Hosted at `workshops.tail21f0.ts.net`.

## Workshops

| Workshop | Description |
|----------|-------------|
| [git-workshop-for-docxers](git-workshop-for-docxers/) | Git & GitHub workshop for teams that collaborate in Google Docs and Sheets |

## Hosting

Each workshop is a self-contained folder with an `index.html` served as static files.

```
workshops.tail21f0.ts.net/<workshop-name>
```

### Run locally

```bash
npm install
node server.js
```

### Deploy with Docker

```bash
docker build -t workshops .
docker run -p 8090:8090 workshops
```

## Adding a new workshop

1. Create a folder at the root with your workshop name
2. Add an `index.html` (and any assets) inside it
3. Update the table above

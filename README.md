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

## Known limitations

**GHCR pull secret expiration**: The GHCR image pull secret is created during CD using `GITHUB_TOKEN`, which expires after the workflow ends. If a pod restarts or gets rescheduled to a new node, image pulls will fail until the next CD run refreshes the secret. To fix this permanently, switch to the ECR pull-through cache (like DAP does) by changing the image reference to `176434290504.dkr.ecr.sa-east-1.amazonaws.com/ghcr/crunchloop/workshops` and removing `imagePullSecrets`.

## Adding a new workshop

1. Create a folder at the root with your workshop name
2. Add an `index.html` (and any assets) inside it
3. Update the table above

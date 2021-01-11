# Traduire

**Transcription app**
- Accept/upload mp3 files via web interface
- Store mp3 in BLOB storage (Azure Storage)
- Add authentication provider (AAD for starters)
- Service layer that orchestrates transcription
- Pub/sub layer acts as proxy between web interface and service layer
- Query layer to query about existing transcriptions via REST
- Data layer to store data (Postgresql)
- Cognitive Services will transcribe mp3's

**Languages**
- Web interface written in React
- Query and Service layer written in dotnet 5

**Hosting choices**
- Web interface is SPA and hosted in containers
- Query and Service layers hosted in containers
- Pub/Sub, Blob, and Data Layer in PaaS

**Deployment**
- GitHub for SRC
- Actions for CI/CD
- Terraform (ARM later)
- Helm for container deployment

**Branching strategy**
- New feature == new branch
- Merge back to master when done
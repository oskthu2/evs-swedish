# Swedish FHIR Base Profiles Validator

This project brings nothing new to the table. It's just me learing how to seet up a Docker-based local FHIR validation service for the [HL7 Sweden Base Profiles](http://hl7.se/fhir/ig/base/), powered by [Matchbox](https://github.com/ahdis/matchbox), which is the same FHIR validation engine used by the [IHE Gazelle EVS Client](https://gazelle.ihe.net/content/evsfhirvalidation).

## Background

I initially set out to install my own copy of the Gazelle EVS Client, but it is a complex Java EE application that requires Wildfly, PostgreSQL, SSO, and many co-deployed services. Running it standalone seemed impractical for my use-cases.

**Matchbox** is a standalone open-source FHIR server (by [ahdis](https://www.ahdis.ch/)) built on HAPI FHIR. It provides:

- A **web GUI** for interactive validation
- A **`$validate` FHIR operation** for programmatic use
- **Gazelle EVS API** compatibility (`/gazelle/validation/validate`)
- Pre-loading of any **FHIR Implementation Guide** from the package registry

This repository has then pre-configures Matchbox to use the **Swedish Base Profiles IG** (`hl7se.fhir.base` v1.1.0) so you can validate FHIR resources for conformance to the Swedish national profiles. As more IG:s are published, the tool could ingest them as well. 

## Quick start

```bash
# 1. Clone this repo
git clone https://github.com/<your-username>/gazelle-evs-swedish.git
cd gazelle-evs-swedish

# 2. Start the service (first boot downloads ~200 MB of IG packages)
docker compose up -d

# 3. Watch the logs until you see "FHIR has been lit on this server"
docker compose logs -f matchbox

# 4. Open the validation GUI
open http://localhost:8080/matchboxv3/#/
```

First startup takes 2–5 minutes while IGs are downloaded and indexed. Subsequent starts are much faster since the data is persisted in a Docker volume.

## Validating resources

### Via the web GUI

1. Open http://localhost:8080/matchboxv3/#/
2. Select a profile from the dropdown (e.g. `SEBasePatient`)
3. Paste or upload your FHIR resource (JSON or XML)
4. Click **Validate**

### Via the `$validate` API

```bash
# Validate a Patient against SEBasePatient
curl -X POST "http://localhost:8080/matchboxv3/fhir/\$validate?profile=http://hl7.se/fhir/ig/base/StructureDefinition/SEBasePatient" \
  -H "Content-Type: application/fhir+json" \
  -H "Accept: application/fhir+json" \
  -d @examples/patient-se-base.json

# Or use the convenience script
chmod +x validate.sh
./validate.sh examples/patient-se-base.json
./validate.sh examples/organization-se-base.json http://hl7.se/fhir/ig/base/StructureDefinition/SEBaseOrganization
```

### Via the Gazelle EVS API

Matchbox also exposes the Gazelle-compatible endpoints:

```bash
# List available profiles
curl http://localhost:8080/matchboxv3/fhir/gazelle/validation/profiles

# Validate via EVS API
curl -X POST http://localhost:8080/matchboxv3/fhir/gazelle/validation/validate \
  -H "Content-Type: application/json" \
  -d @examples/patient-se-base.json
```

## Available Swedish profiles

The `hl7se.fhir.base` v1.1.0 IG includes profiles for:

| Profile | Canonical URL |
|---------|---------------|
| SEBasePatient | `http://hl7.se/fhir/ig/base/StructureDefinition/SEBasePatient` |
| SEBaseOrganization | `http://hl7.se/fhir/ig/base/StructureDefinition/SEBaseOrganization` |
| SEBasePractitioner | `http://hl7.se/fhir/ig/base/StructureDefinition/SEBasePractitioner` |
| SEBasePractitionerRole | `http://hl7.se/fhir/ig/base/StructureDefinition/SEBasePractitionerRole` |

Plus Swedish-specific extensions (address types, personnummer, etc.) and value sets.

## Adding more Implementation Guides

Edit `config/application.yaml` and add entries under `hapi.fhir.implementationguides`:

```yaml
      my_custom_ig:
        name: some.fhir.ig
        version: 1.0.0
```

Then restart:

```bash
docker compose down
docker compose up -d
```

Find packages on the [FHIR Package Registry](https://registry.fhir.org/) or [Simplifier](https://simplifier.net/packages).

## Configuration

| File | Purpose |
|------|---------|
| `config/application.yaml` | Matchbox configuration: IGs to load, terminology server, suppressed warnings |
| `docker-compose.yml` | Docker service definition, ports, memory, volumes |

Key settings in `application.yaml`:

- **`matchbox.fhir.context.txServer`** — external terminology server (default: `http://tx.fhir.org`)
- **`matchbox.fhir.context.onlyOneEngine`** — set to `true` for development mode (allows uploading custom StructureDefinitions)
- **`matchbox.fhir.context.suppressWarnInfo`** — suppress specific warning messages per IG

## Troubleshooting

**Container exits immediately?** — Increase Docker memory to ≥ 3 GB. Matchbox needs ~2.5 GB when loading multiple IGs.

**IGs not loading?** — Check that the container has internet access on first boot (it downloads packages from `packages.fhir.org`).

**Validation errors you don't expect?** — The terminology server (`tx.fhir.org`) may be slow or unavailable. You can disable external terminology checking by setting `txServer: ""` in `application.yaml`.

## References

- [Matchbox documentation](https://ahdis.github.io/matchbox/)
- [Matchbox on GitHub](https://github.com/ahdis/matchbox)
- [HL7 Sweden Base Profiles IG](http://hl7.se/fhir/ig/base/)
- [HL7 Sweden GitHub](https://github.com/HL7Sweden/basprofiler-r4)
- [Gazelle EVS Client FHIR Validation](https://gazelle.ihe.net/content/evsfhirvalidation)
- [FHIR Package Registry](https://registry.fhir.org/)

## License

The configuration files in this repository are provided under the [MIT License](LICENSE). Matchbox itself is licensed under its own terms. The Swedish base profiles are published by HL7 Sweden.

# Belluga Validation Overlay

This directory is temporary and local-validation-only.

It exists so the extracted generic root/docker base can be validated against
Belluga-specific runtime assumptions without promoting those assumptions into
the shared base.

Only `docker-compose.validation-belluga.yml` is allowed to activate these
surfaces.

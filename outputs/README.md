# Outputs layout

Exports are written by the scripts under `scripts/` using the centralized connection and logging helpers.

```
outputs/
  entra/
    <dataset>.csv
  azure/
    <dataset>.csv
```

Each CSV starts with `generated_at`, `tool_version`, and `dataset_name`, followed by the key inventory fields returned from Microsoft Graph or Azure.

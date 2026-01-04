#!/bin/bash
set -euo pipefail

GRAFANA_DASHBOARD_DIR="/var/lib/grafana/dashboards"
sudo mkdir -p "$GRAFANA_DASHBOARD_DIR"

# --------------------------
# Error Dashboard
# --------------------------
ERROR_DASHBOARD_FILE="alloy-log-dashboard-error.json"

cat >"$ERROR_DASHBOARD_FILE" <<'EOF'
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 847,
  "links": [],
  "panels": [
    {
      "datasource": {
        "type": "loki",
        "uid": "Loki"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "number of logs",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "lines",
            "fillOpacity": 0,
            "gradientMode": "none",
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 3,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": 0
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "expr": "sum by (filename) (count_over_time({filename=~\"$filename\"} |= \"error\"[1h]))",
          "refId": "A"
        }
      ],
      "title": "Error Logs Per Hour",
      "transparent": true,
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "loki",
        "uid": "ef80315p0s2kgf"
      },
      "fieldConfig": {
        "defaults": {
          "custom": {
            "filterable": true,
            "cellOptions": {
              "type": "auto"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": 0
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "Time"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 200
              },
              {
                "id": "custom.fixed",
                "value": true
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "filename"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 200
              },
              {
                "id": "custom.fixed",
                "value": true
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 13,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "id": 3,
      "options": {
        "cellHeight": "sm",
        "enablePagination": true,
        "showHeader": true,
        "sortBy": [
          {
            "desc": true,
            "displayName": "Time"
          }
        ]
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "loki",
            "uid": "ef80315p0s2kgf"
          },
          "direction": "backward",
          "editorMode": "builder",
          "expr": "{filename=~\"$filename\"} |= \"error\"",
          "queryType": "range",
          "refId": "A"
        }
      ],
      "title": "Error Logs Table",
      "transformations": [
        {
          "id": "extractFields",
          "options": {
            "delimiter": ",",
            "format": "kvp",
            "keepTime": false,
            "replace": false,
            "source": "labels"
          }
        },
        {
          "id": "filterFieldsByName",
          "options": {
            "byVariable": false,
            "include": {
              "names": [
                "Time",
                "Line",
                "filename"
              ]
            }
          }
        }
      ],
      "transparent": true,
      "type": "table"
    }
  ],
  "preload": false,
  "refresh": "1m",
  "schemaVersion": 42,
  "tags": [],
  "templating": {
    "list": [
      {
        "allValue": ".+",
        "current": {
          "text": "All",
          "value": [
            "$__all"
          ]
        },
        "datasource": {
          "type": "loki",
          "uid": "Loki"
        },
        "includeAll": true,
        "label": "Filename",
        "multi": true,
        "name": "filename",
        "query": "label_values({source=\"file\"}, filename)",
        "type": "query"
      }
    ]
  },
  "time": {
    "from": "now-7d",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Alloy Error Logs",
  "uid": "alloy-error-logs",
  "version": 1
}
EOF

sudo mv "$ERROR_DASHBOARD_FILE" "$GRAFANA_DASHBOARD_DIR/$ERROR_DASHBOARD_FILE"

# --------------------------
# Warning Dashboard
# --------------------------
WARNING_DASHBOARD_FILE="alloy-log-dashboard-warning.json"

cat >"$WARNING_DASHBOARD_FILE" <<'EOF'
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 847,
  "links": [],
  "panels": [
    {
      "datasource": {
        "type": "loki",
        "uid": "Loki"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "number of logs",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "lines",
            "fillOpacity": 0,
            "gradientMode": "none",
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 3,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": 0
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "expr": "sum by (filename) (count_over_time({filename=~\"$filename\"} |= \"warn\"[1h]))",
          "refId": "A"
        }
      ],
      "title": "Warn Logs Per Hour",
      "transparent": true,
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "loki",
        "uid": "ef80315p0s2kgf"
      },
      "fieldConfig": {
        "defaults": {
          "custom": {
            "filterable": true,
            "cellOptions": {
              "type": "auto"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": 0
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "Time"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 200
              },
              {
                "id": "custom.fixed",
                "value": true
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "filename"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 200
              },
              {
                "id": "custom.fixed",
                "value": true
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 13,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "id": 3,
      "options": {
        "cellHeight": "sm",
        "enablePagination": true,
        "showHeader": true,
        "sortBy": [
          {
            "desc": true,
            "displayName": "Time"
          }
        ]
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "loki",
            "uid": "ef80315p0s2kgf"
          },
          "direction": "backward",
          "editorMode": "builder",
          "expr": "{filename=~\"$filename\"} |= \"warn\"",
          "queryType": "range",
          "refId": "A"
        }
      ],
      "title": "Warn Logs Table",
      "transformations": [
        {
          "id": "extractFields",
          "options": {
            "delimiter": ",",
            "format": "kvp",
            "keepTime": false,
            "replace": false,
            "source": "labels"
          }
        },
        {
          "id": "filterFieldsByName",
          "options": {
            "byVariable": false,
            "include": {
              "names": [
                "Time",
                "Line",
                "filename"
              ]
            }
          }
        }
      ],
      "transparent": true,
      "type": "table"
    }
  ],
  "preload": false,
  "refresh": "1m",
  "schemaVersion": 42,
  "tags": [],
  "templating": {
    "list": [
      {
        "allValue": ".+",
        "current": {
          "text": "All",
          "value": [
            "$__all"
          ]
        },
        "datasource": {
          "type": "loki",
          "uid": "Loki"
        },
        "includeAll": true,
        "label": "Filename",
        "multi": true,
        "name": "filename",
        "query": "label_values({source=\"file\"}, filename)",
        "type": "query"
      }
    ]
  },
  "time": {
    "from": "now-7d",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Alloy Warn Logs",
  "uid": "alloy-warn-logs",
  "version": 1
}
EOF

sudo mv "$WARNING_DASHBOARD_FILE" "$GRAFANA_DASHBOARD_DIR/$WARNING_DASHBOARD_FILE"

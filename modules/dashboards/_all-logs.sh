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

# --------------------------
# HEALING Dashboard
# --------------------------
HEALING_DASHBOARD_FILE="alloy-log-dashboard-healing.json"

cat >"$HEALING_DASHBOARD_FILE" <<'EOF'
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
  "id": 1441,
  "links": [],
  "panels": [
    {
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 7,
        "x": 0,
        "y": 0
      },
      "id": 15,
      "options": {
        "alertInstanceLabelFilter": "",
        "alertName": "",
        "dashboardAlerts": false,
        "groupBy": [],
        "groupMode": "default",
        "maxItems": 20,
        "showInactiveAlerts": false,
        "sortOrder": 1,
        "stateFilter": {
          "error": true,
          "firing": true,
          "noData": false,
          "normal": false,
          "pending": true,
          "recovering": true
        },
        "viewMode": "list"
      },
      "pluginVersion": "12.3.1",
      "title": "Alert Panel",
      "type": "alertlist"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "0": {
                  "color": "red",
                  "index": 1,
                  "text": "DOWN"
                },
                "1": {
                  "color": "green",
                  "index": 0,
                  "text": "UP"
                }
              },
              "type": "value"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": 0
              },
              {
                "color": "green",
                "value": 1
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 6,
        "x": 7,
        "y": 0
      },
      "id": 1,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "center",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "apache_up{job=\"apache\"}",
          "refId": "A"
        }
      ],
      "title": "Apache Status",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "0": {
                  "color": "red",
                  "index": 1,
                  "text": "DOWN"
                },
                "1": {
                  "color": "green",
                  "index": 0,
                  "text": "UP"
                }
              },
              "type": "value"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": 0
              },
              {
                "color": "green",
                "value": 1
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 6,
        "x": 13,
        "y": 0
      },
      "id": 3,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "center",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "pg_up{instance=\"localhost:9187\"}",
          "refId": "C"
        }
      ],
      "title": "PostgreSQL Status",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "0": {
                  "color": "red",
                  "index": 1,
                  "text": "DOWN"
                },
                "1": {
                  "color": "green",
                  "index": 0,
                  "text": "UP"
                }
              },
              "type": "value"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": 0
              },
              {
                "color": "green",
                "value": 1
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 6,
        "x": 7,
        "y": 4
      },
      "id": 2,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "center",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "mysql_up{job=\"mysql\"}",
          "refId": "B"
        }
      ],
      "title": "MySQL Status",
      "type": "stat"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "id": 4,
      "panels": [],
      "title": "Success",
      "type": "row"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "fixedColor": "green",
            "mode": "fixed"
          },
          "decimals": 0,
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
        "h": 3,
        "w": 7,
        "x": 0,
        "y": 9
      },
      "id": 5,
      "options": {
        "colorMode": "value",
        "displayMode": "lcd",
        "graphMode": "area",
        "justifyMode": "auto",
        "legend": {
          "showLegend": false
        },
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "showUnfilled": true,
        "textMode": "auto",
        "valueMode": "color",
        "wideLayout": true
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "sum(selfheal_service_success_total)",
          "legendFormat": "Total Successes",
          "refId": "A"
        }
      ],
      "title": "Total Self-Heal Successes",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
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
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
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
          "decimals": 0,
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
        "w": 17,
        "x": 7,
        "y": 9
      },
      "id": 6,
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
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "increase(selfheal_service_success_total[5m])",
          "legendFormat": "{{service}}",
          "refId": "A"
        }
      ],
      "title": "Self-Heal Success Rate (increase)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "fixedColor": "green",
            "mode": "fixed"
          },
          "decimals": 0,
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
        "h": 5,
        "w": 7,
        "x": 0,
        "y": 12
      },
      "id": 7,
      "options": {
        "colorMode": "value",
        "displayMode": "lcd",
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "maxVizHeight": 300,
        "minVizHeight": 16,
        "minVizWidth": 8,
        "namePlacement": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showUnfilled": true,
        "sizing": "auto",
        "valueMode": "color"
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "selfheal_service_success_total",
          "legendFormat": "{{service}}",
          "refId": "A"
        }
      ],
      "title": "Self-Heal Success per Service",
      "type": "bargauge"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 17
      },
      "id": 8,
      "panels": [],
      "title": "Failure",
      "type": "row"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "fixedColor": "red",
            "mode": "fixed"
          },
          "decimals": 0,
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
        "h": 3,
        "w": 7,
        "x": 0,
        "y": 18
      },
      "id": 9,
      "options": {
        "colorMode": "value",
        "displayMode": "lcd",
        "graphMode": "area",
        "justifyMode": "auto",
        "legend": {
          "showLegend": false
        },
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "showUnfilled": true,
        "textMode": "auto",
        "valueMode": "color",
        "wideLayout": true
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "sum(selfheal_service_failure_total)",
          "legendFormat": "Total Failures",
          "refId": "A"
        }
      ],
      "title": "Total Self-Heal Failures",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
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
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
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
          "decimals": 0,
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
        "w": 17,
        "x": 7,
        "y": 18
      },
      "id": 10,
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
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "increase(selfheal_service_failure_total[5m])",
          "legendFormat": "{{service}}",
          "refId": "A"
        }
      ],
      "title": "Self-Heal Failure Rate (increase)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "Prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "fixedColor": "red",
            "mode": "fixed"
          },
          "decimals": 0,
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
        "h": 5,
        "w": 7,
        "x": 0,
        "y": 21
      },
      "id": 11,
      "options": {
        "colorMode": "value",
        "displayMode": "lcd",
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "maxVizHeight": 300,
        "minVizHeight": 16,
        "minVizWidth": 8,
        "namePlacement": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showUnfilled": true,
        "sizing": "auto",
        "valueMode": "color"
      },
      "pluginVersion": "12.3.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus"
          },
          "expr": "selfheal_service_failure_total",
          "legendFormat": "{{service}}",
          "refId": "A"
        }
      ],
      "title": "Self-Heal Failures per Service",
      "type": "bargauge"
    }
  ],
  "preload": false,
  "refresh": "5s",
  "schemaVersion": 42,
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-24h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "browser",
  "title": "Self-Healing Service",
  "uid": "selfheal-dashboard",
  "version": 2
}
EOF

sudo mv "$HEALING_DASHBOARD_FILE" "$GRAFANA_DASHBOARD_DIR/$HEALING_DASHBOARD_FILE"

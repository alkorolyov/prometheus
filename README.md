git clone https://github.com/alkorolyov/prometheus; cd prometheus; sudo bash ./install.sh


### custom prometheus metrics

```
groups:
  - name: custom_metrics
    rules:
      # CPU usage percentage
      - record: node_cpu_usage_percentage
        expr: |
          (100 * sum(irate(node_cpu_seconds_total {mode!="idle"} [1m])) by (instance)) /
          sum(irate(node_cpu_seconds_total[1m])) by (instance)

      # Memory Usage Percentage
      - record: node_memory_usage_percentage
        expr: |
          100 * (1 - (sum by (instance) (node_memory_MemAvailable_bytes) / 
          sum by (instance) (node_memory_MemTotal_bytes)))
```




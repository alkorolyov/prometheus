git clone https://github.com/alkorolyov/prometheus; cd prometheus; sudo bash ./install.sh


### custom prometheus metrics

```
groups:
  - name: custom_metrics
    rules:
      - record: node_cpu_usage_total
        expr: (100 * sum(irate(node_cpu_seconds_total {mode!="idle"} [1m])) by (instance)) / sum(irate(node_cpu_seconds_total[1m])) by (instance)
      - record: node_
```




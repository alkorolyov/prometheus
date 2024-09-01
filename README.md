git clone https://github.com/alkorolyov/prometheus; cd prometheus; sudo bash ./install.sh

```
./node_exporter --collector.disable-defaults --collector.cpu --collector.diskstats --collector.filesystem --collector.netdev --collector.meminfo --collector.mdadm --collector.textfile --collector.textfile.direc
tory .
```


### custom prometheus metrics
prometheus.yml
```
# my global config
global:
  scrape_interval: 1s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 1s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
#  - job_name: "prometheus"
#    static_configs:
#      - targets: ["localhost:9090"]

  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]

    metric_relabel_configs:
      - source_labels: [__name__]
        action: keep
        regex: 'node_cpu_seconds_total|node_memory_MemAvailable_bytes|node_memory_MemTotal_bytes|node_network_receive_bytes_total|node_network_transmit_bytes_total|node_disk_read_bytes_total|node_disk_written_bytes_total|node_filesystem_size_bytes'
```

rules.yml

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


metrics to keep
```
node_cpu_seconds_total
node_memory_MemAvailable_bytes
node_memory_MemTotal_bytes
node_network_receive_bytes_total
node_network_transmit_bytes_total
node_disk_read_bytes_total
node_disk_written_bytes_total
node_filesystem_size_bytes
```

check all prometheus metrics
```
curl -s http://localhost:9090/api/v1/label/__name__/values
```

check specific metric
```
watch -n 1 curl -s 'http://localhost:9090/api/v1/query?query=node_cpu_usage_percent'
```

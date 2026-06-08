# demos
Website for demos.openmoq.org

## Health Status Automation

Card metadata is stored in [data/cards.json](data/cards.json).

Runtime health status is generated into [data/status.json](data/status.json) by [health_check/check_status.sh](health_check/check_status.sh).

Rules:
- HTTP 200 -> Available
- any other response or error -> Offline

### Run Manually

```bash
./health_check/check_status.sh
```

### systemd (Ubuntu 24.04)

1. Update the path in [health_check/systemd/openmoq-healthcheck.service](health_check/systemd/openmoq-healthcheck.service) if your checkout is not in `/srv/openmoq/demos`.
2. Install units:

```bash
sudo cp health_check/systemd/openmoq-healthcheck.service /etc/systemd/system/
sudo cp health_check/systemd/openmoq-healthcheck.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now openmoq-healthcheck.timer
```

3. Verify:

```bash
systemctl status openmoq-healthcheck.timer
systemctl list-timers --all | grep openmoq-healthcheck
```

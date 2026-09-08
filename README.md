# demos
This repo maintains the data used to provide the site: [demos.openmoq.org](demos.openmoq.org)

## Adding/modifying a demo


### Method 1 - Open an issue

Please open an issue and provide the following information:

- Title
- Type: live, vod, interface, etc.
- Image: 640x360
- Brief description
- URL link to demo
- Any credentials required

### Method 2 - Edit metadata and open a pull request

If you need to update an existing demo, you can edit the following file and open a PR

Card metadata is stored in [data/cards.json](data/cards.json).

Example of demo item:
```
          {
            "id": "cisco-moqt-client",
            "tag": "Interactive",
            "title": "Cisco MoQT client",
            "image": "assets/ciscodemo.jpg",
            "imageStyle": "max-width:60%;object-fit:contain;",
            "desc": "Web based demo of Cisco MoQT application running on Multi CDN OpenMoQ relay network",
            "link": "https://quicr.github.io/moq-web/",
            "buttonText": "Launch demo"
          }
```

## Health Status Automation

Each demo as a status indicator, this updated by a periodic curl against the link URL, if the link doesn't return a 200 OK the indicator will be updated

Rules:
- HTTP 200 -> Available
- HTTP 401 -> Auth Required
- any other response or error -> Offline

Runtime health status is generated into [data/status.json](data/status.json) by [health_check/check_status.sh](health_check/check_status.sh).

### Running the script manually

```bash
./health_check/check_status.sh
```

### Running as background task using systemd (Ubuntu 24.04)

1. Update the path in [health_check/systemd/openmoq-healthcheck.service](health_check/systemd/openmoq-healthcheck.service) if your checkout is not in `/opt/health_check`.
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

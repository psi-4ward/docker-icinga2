# Icinga2 Docker Image

[![Image Size](https://images.microbadger.com/badges/image/psitrax/icinga2.svg)](https://microbadger.com/images/psitrax/icinga2)
[![Docker Stars](https://img.shields.io/docker/stars/psitrax/icinga2.svg)](https://hub.docker.com/r/psitrax/icinga2/)
[![Docker Pulls](https://img.shields.io/docker/pulls/psitrax/icinga2.svg)](https://hub.docker.com/r/psitrax/icinga2/)
[![Docker Automated buil](https://img.shields.io/docker/automated/psitrax/icinga2.svg)](https://hub.docker.com/r/psitrax/icinga2/)

* CentOS based
* Automated Database initialization and update
* Waits at least 60 seconds for database to come up
* Auto populate config (if volume is empty)
* Monitoring plugins included
* Some additional helper scripts and plugins included
* Functional Bash included
* Requires MySQL/MariaDB
* Docker-Healthcheck support

**Exposed Volume: `/icinga2`**: Contains all persistent data like config, ssh-key, cmd-pipe.  
**Exposed Port: `5665`**: Icinga2 API Port

### Supported tags

* Exact: i.e. `2.6.0-r3`: Icinga2 Version 2.6.0, image build 3
* `2.6`: Icinga2 Version 2.6.x, latest image build

### Example

See [docker-compose.yml](): Icinga2 stack with UI and Graphing **(TODO)**  

```bash
# Set container hostname to get correct API Cert DN
sudo docker run \
  --rm -t \
  --name icinga2 \
  --hostname icinga2 \
  --link mysql \
  -v $PWD/_data:/icinga2 \
  -p 5665:5665 \
  -e TIMEZONE=Europe/Berlin \
  -e ICINGA_API_PASS=damn-secret \
  psitrax/icinga2
```

```bash
sudo docker exec -ti icinga2 bash
```

### Configuration with env vars

| ENV-Var            | default           | description                                    |
|--------------------|-------------------|------------------------------------------------|
| `TIMEZONE`         | UTC               | Timezone                                       |
| `MYSQL_AUTOCONF`   | true              | Enable MySQL auto configuration                |
| `MYSQL_HOST`       | mysql             | MySQL hostname                                 |
| `MYSQL_PORT`       | mysql             | MySQL Port                                     |
| `MYSQL_DB`         | icinga2           | Database name                                  |
| `MYSQL_USER`       | root              | User                                           |
| `MYSQL_PASS`       | root              | Password                                       |
| `ICINGA_API_PASS`  |                   | Password for icingaweb2 API user               |
| `ICINGA_FEATURES`  | command ido-mysql | Space separated list of Icinga Feature-Modules |
| `ICINGA_LOGLEVEL`  | warning           | Log level                                      |


## Maintainer
* Christoph Wiechert <wio@psitrax.de>
